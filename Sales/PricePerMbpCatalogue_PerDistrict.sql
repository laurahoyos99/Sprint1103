
WITH
NOMBRESPLANES AS (
SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD),10) AS ACT_ACCT_CD, PD_BB_PROD_NM,BB_FI_TOT_MRC_AMT, BB_FI_TOT_MRC_AMT_DESC, ACT_RGN_CD
FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
WHERE PD_BB_PROD_NM IS NOT NULL AND PD_BB_PROD_ID IS NOT NULL
GROUP BY 1,2,3,4,5
)
, VELOCIDAD AS (
SELECT DISTINCT RangoVelocidad, Velocida, ActivoInternet
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-13_CR_CATALOGUE_TV_INTERNET_2021_T` 
GROUP BY 1,2,3
)
, PRECIONORMALIZADO AS (
SELECT DISTINCT ACT_RGN_CD, BB_FI_TOT_MRC_AMT AS MRC_SinDescuento,BB_FI_TOT_MRC_AMT-BB_FI_TOT_MRC_AMT_DESC AS MRC_ConDescuento
 , RangoVelocidad
 , Velocida AS Velocidad
 , ACT_ACCT_CD
FROM NOMBRESPLANES n INNER JOIN VELOCIDAD v ON n.PD_BB_PROD_NM=v.ActivoInternet
GROUP BY 1,2,3,4,5,6
)

SELECT DISTINCT ACT_RGN_CD
, ROUND(AVG(MRC_SinDescuento)/AVG(Velocidad),2) AS CostoVelocidad_SinDesc
, ROUND(AVG(MRC_ConDescuento)/AVG(Velocidad),2) AS CostoVelocidad_ConDesc
, COUNT(ACT_ACCT_CD) AS Reg
FROM PRECIONORMALIZADO 
GROUP BY 1
ORDER BY Reg DESC
