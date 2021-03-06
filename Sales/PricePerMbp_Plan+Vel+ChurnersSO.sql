WITH 

CHURNERSSO AS
(SELECT DISTINCT RIGHT(CONCAT('0000000000',NOMBRE_CONTRATO) ,10) AS CONTRATOSO, Min(FECHA_APERTURA) AS FECHA_APERTURA,
 FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_ORDENES_SERVICIO_2021-01_A_2021-11_D`
 WHERE
  TIPO_ORDEN = "DESINSTALACION" 
  AND (ESTADO <> "CANCELADA" OR ESTADO <> "ANULADA")
 AND FECHA_APERTURA IS NOT NULL
 GROUP BY CONTRATOSO
)
, CHURNERSSOCLASIF AS
(SELECT DISTINCT RIGHT(CONCAT('0000000000',NOMBRE_CONTRATO) ,10) AS CONTRATOSO, Min(t.FECHA_APERTURA) AS FECHA_APERTURA,
CASE WHEN SUBMOTIVO = "MOROSIDAD" THEN RIGHT(CONCAT('0000000000',NOMBRE_CONTRATO) ,10) END AS INVOLUNTARIO,
CASE WHEN SUBMOTIVO <> "MOROSIDAD" THEN RIGHT(CONCAT('0000000000',NOMBRE_CONTRATO) ,10) END AS VOLUNTARIO
 FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_ORDENES_SERVICIO_2021-01_A_2021-11_D` t
 INNER JOIN CHURNERSSO s ON RIGHT(CONCAT('0000000000',t.NOMBRE_CONTRATO) ,10)= s.CONTRATOSO AND t.FECHA_APERTURA = s.FECHA_APERTURA
 WHERE
  TIPO_ORDEN = "DESINSTALACION" 
  AND (ESTADO <> "CANCELADA" OR ESTADO <> "ANULADA")
 AND t.FECHA_APERTURA IS NOT NULL
 GROUP BY CONTRATOSO, INVOLUNTARIO, VOLUNTARIO
 )
, CHURNERSCRM AS(
  SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS CONTRATOCRM, MAX(DATE(CST_CHRN_DT)) AS Maxfecha,Extract(Month from Max(CST_CHRN_DT)) AS MesChurnF
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (MONTH FROM Maxfecha) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
)
, FIRSTCHURN AS(
 SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS CONTRATOPCHURN, Min(DATE(CST_CHRN_DT)) AS PrimerChurn, Extract(Month from Min(CST_CHRN_DT)) AS MesChurnP
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (YEAR FROM PrimerChurn) = 2021
)
, REALCHURNERS AS(
 SELECT DISTINCT CONTRATOCRM AS CHURNER, MaxFecha, PrimerChurn, MesChurnF, MesChurnP
 FROM CHURNERSCRM c  INNER JOIN FIRSTCHURN f ON c.CONTRATOCRM = f.CONTRATOPCHURN AND f.PrimerChurn <= c.MaxFecha
   GROUP BY CHURNER, MaxFecha, PrimerChurn, MesChurnF, MesChurnP
)
, CRUCECHURNERS AS(
SELECT CONTRATOSO, CHURNER, VOLUNTARIO, INVOLUNTARIO, MaxFecha, PrimerChurn, MesChurnF, MesChurnP,
EXTRACT(MONTH FROM s.FECHA_APERTURA ) AS MesS
FROM REALCHURNERS c INNER JOIN CHURNERSSOCLASIF s ON CONTRATOSO = CHURNER
AND c.PrimerChurn >= s.FECHA_APERTURA AND date_diff(c.PrimerChurn, s.FECHA_APERTURA, MONTH) <= 3
GROUP BY contratoso, CHURNER, MesS, VOLUNTARIO, INVOLUNTARIO, MaxFecha, PrimerChurn, MesChurnF, MesChurnP
)
, PLANESACTIVOS AS(
SELECT DISTINCT 
  RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS ACT_ACCT_CD, FECHA_EXTRACCION, DATE_TRUNC(FECHA_EXTRACCION, MONTH) AS Mes
, PD_BB_PROD_NM, PD_BB_PROD_ID, PD_TV_PROD_ID, PD_VO_PROD_ID
, BB_FI_TOT_MRC_AMT - BB_FI_TOT_MRC_AMT_DESC AS MONTO, MIN(DATE(CST_CHRN_DT)) AS MinfechaP,
    CASE
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NOT NULL THEN "3P"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NULL THEN "2P - BB+TV"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NOT NULL THEN "2P - BB+VO"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NOT NULL THEN "2P - TV+VO"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NULL THEN "1P - BB"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NULL THEN "1P - TV"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NOT NULL THEN "1P - VO"
    END AS PFLAG,
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D` 
GROUP BY 1,2,3,4,5,6,7,8,10
HAVING EXTRACT(YEAR FROM FECHA_EXTRACCION)=2021
)
, CRUCEPLANMINCHURN AS(
    SELECT DISTINCT c.CONTRATOSO, EXTRACT(MONTH FROM  c.maxFecha) as MESC, EXTRACT(MONTH FROM c.PrimerChurn) AS MESMIN, p.Pflag, c.Voluntario, c.Involuntario
    , p.PD_BB_PROD_NM, P.mes,p.Monto
    FROM CRUCECHURNERS c INNER JOIN PLANESACTIVOS p on C.CONTRATOSO =p.ACT_ACCT_CD AND c.PrimerChurn = p.MinFechaP
)
, CATALOGOINTERNET AS (
SELECT DISTINCT RangoVelocidad, Velocida, ActivoInternet
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-13_CR_CATALOGUE_TV_INTERNET_2021_T` 
GROUP BY 1,2,3
)
, TABLAPRELIMINAR AS(
SELECT DISTINCT MESC,CONTRATOSO,PFLAG,RangoVelocidad, Monto/Velocida AS PrecioMbp
FROM CRUCEPLANMINCHURN p INNER JOIN CATALOGOINTERNET c ON p.PD_BB_PROD_NM=c.ActivoInternet
GROUP BY 1,2,3,4,5
)

SELECT MesC,PFLAG, RangoVelocidad, ROUND(AVG(PrecioMbp),2) AS PrecioMbp, COUNT(CONTRATOSO) AS Reg
FROM TABLAPRELIMINAR
GROUP BY 1,2,3
ORDER BY MesC, PFLAG, RangoVelocidad


