WITH 
PLANESACTIVOS AS(
SELECT DISTINCT 
  ACT_ACCT_CD, FECHA_EXTRACCION, DATE_TRUNC(FECHA_EXTRACCION, MONTH) AS Mes
, TRIM(ACT_PRVNC_CD) AS Provincia, TRIM(ACT_CANTON_CD) AS Canton, TRIM(ACT_RGN_CD) AS Distrito
, PD_BB_PROD_NM, PD_BB_PROD_ID, PD_TV_PROD_ID, PD_VO_PROD_ID
, BB_FI_TOT_MRC_AMT - BB_FI_TOT_MRC_AMT_DESC AS MONTO,
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
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
HAVING EXTRACT(YEAR FROM FECHA_EXTRACCION)=2021
)
, CATALOGOINTERNET AS (
SELECT DISTINCT RangoVelocidad, Velocida, ActivoInternet
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-13_CR_CATALOGUE_TV_INTERNET_2021_T` 
GROUP BY 1,2,3
)
, TABLAPRELIMINAR AS(
SELECT DISTINCT FECHA_EXTRACCION,Mes,ACT_ACCT_CD,PFLAG,RangoVelocidad,Monto/Velocida AS PrecioMbp
, Provincia, Canton,Distrito
FROM PLANESACTIVOS p INNER JOIN CATALOGOINTERNET c ON p.PD_BB_PROD_NM=c.ActivoInternet
GROUP BY 1,2,3,4,5,6,7,8,9
)

SELECT Mes,Provincia,Canton,Distrito, ROUND(AVG(PrecioMbp),2) AS PrecioMbp
FROM TABLAPRELIMINAR
WHERE RangoVelocidad="<30"
--AND PFLAG="1P - BB"
--AND PFLAG="2P - BB+TV"
--AND PFLAG="2P - BB+VO"
AND PFLAG="3P"

GROUP BY 1,2,3,4
ORDER BY Mes,Provincia,Canton,Distrito
