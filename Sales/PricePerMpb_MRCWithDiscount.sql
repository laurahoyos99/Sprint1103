WITH
NOMBRESPLANES AS (
SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD),10) AS ACT_ACCT_CD, PD_BB_PROD_NM,PD_BB_PROD_ID, BB_FI_TOT_MRC_AMT, BB_FI_TOT_MRC_AMT_DESC
FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
GROUP BY 1,2,3,4,5
)
, VELOCIDAD AS (
SELECT DISTINCT RIGHT(CONCAT('0000000000',Contrato),10) AS Contrato, Rango_Velocidad, Velocidad
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-13_CR_PARQUE_EMPAQUETADO_2021_T` 
GROUP BY 1,2,3
)
, PRECIONORMALIZADO AS (
SELECT DISTINCT PD_BB_PROD_ID, PD_BB_PROD_NM, AVG(BB_FI_TOT_MRC_AMT-BB_FI_TOT_MRC_AMT_DESC) AS MRC_ConDescuento, Rango_Velocidad, Velocidad, COUNT(DISTINCT ACT_ACCT_CD) AS Reg
FROM NOMBRESPLANES n INNER JOIN VELOCIDAD v ON n.ACT_ACCT_CD=v.Contrato
GROUP BY 1,2,4,5
)
SELECT DISTINCT PD_BB_PROD_ID, PD_BB_PROD_NM, Rango_Velocidad, ROUND(MRC_SinDescuento,2) AS MRC_ConDescuento, Velocidad, Reg
FROM PRECIONORMALIZADO
GROUP BY 1,2,3,4,5,6
ORDER BY 6 desc
