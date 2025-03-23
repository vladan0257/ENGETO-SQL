-- Rostou v prubehu let mzdy ve vsech odvetvich, nebo v nekterych klesaji?

SELECT DISTINCT
	prim.hrube_mzdy_odvetvi_kod,
	prim.rok,
	prim.hrube_mzdy_prumer_czk,
	CASE
		WHEN ISNULL(prim_shift.hrube_mzdy_prumer_czk) OR ISNULL(prim.hrube_mzdy_prumer_czk) THEN NULL 
		ELSE (prim_shift.hrube_mzdy_prumer_czk - prim.hrube_mzdy_prumer_czk) 
	END AS prirustek_oproti_predchozimu_roku
FROM t_vladan_pivovarnik_project_sql_primary_final AS prim
JOIN t_vladan_pivovarnik_project_sql_primary_final AS prim_shift
ON 
	prim_shift.hrube_mzdy_odvetvi_kod = prim.hrube_mzdy_odvetvi_kod AND
	prim_shift.rok - 1 = prim.rok
WHERE (prim_shift.hrube_mzdy_prumer_czk - prim.hrube_mzdy_prumer_czk) < 0
ORDER BY
	prim.hrube_mzdy_odvetvi_kod,
	prim.rok;
	
-- Kolik je mozne si koupit litru mleka a kilogramu chleba za prvni a posledni 
-- srovnatelne obdobi v dostupnych datech cen a mezd?

SELECT
    rok,
    AVG(hrube_mzdy_prumer_czk) AS hrube_mzdy_prumer_czk,
    komodita_jmeno,
    komodita_merna_jednotka,
    komodita_merna_jednotka_mnozstvi,
    komodita_cena,
    CASE
        WHEN komodita_cena = 0 THEN NULL
        ELSE FLOOR(hrube_mzdy_prumer_czk / komodita_cena)
    END AS komodita_dostupne_mnozstvi
FROM t_vladan_pivovarnik_project_sql_primary_final
WHERE 
    (
    rok = (SELECT MIN(rok) FROM t_vladan_pivovarnik_project_sql_primary_final) OR 
    rok = (SELECT MAX(rok) FROM t_vladan_pivovarnik_project_sql_primary_final)
     ) AND 
    (
    komodita_jmeno LIKE '%ml%ko%' OR
    komodita_jmeno LIKE '%chl%b%'
    ) AND
    NOT ISNULL(hrube_mzdy_odvetvi_jmeno)
GROUP BY
	komodita_jmeno,
	rok
ORDER BY
	komodita_jmeno,
	rok,
	hrube_mzdy_prumer_czk;

-- Ktera kategorie potravin zdrazuje nejpomaleji (je u ni nejnizsi percentualni mezirocni narust)?

SELECT DISTINCT
	t_second.komodita_jmeno,
	ROUND(AVG(100 * ((t_second.komodita_cena / t_first.komodita_cena) - 1)), 2)
	AS prumerna_mezirocni_procentualni_cenova_zmena_2007_2018
FROM t_vladan_pivovarnik_project_sql_primary_final AS t_first
LEFT JOIN t_vladan_pivovarnik_project_sql_primary_final AS t_second
ON
	t_first.komodita_jmeno = t_second.komodita_jmeno AND 
	t_first.rok + 1 = t_second.rok
WHERE
	NOT ISNULL(t_second.komodita_jmeno)
GROUP BY 
	t_second.komodita_jmeno
ORDER BY
	prumerna_mezirocni_procentualni_cenova_zmena_2007_2018;

-- Existuje rok, ve kterem byl mezirocni narust cen potravin vyrazne vyssi nez rust mezd (vetsi nez 10 %)?
-- 1/2
CREATE OR REPLACE VIEW v_salaries_prices_change AS
	SELECT
	    t_second.rok,
	    ROUND(100 * (AVG(t_second.hrube_mzdy_prumer_czk) / AVG(t_first.hrube_mzdy_prumer_czk) - 1), 2) AS 
	    meziroc_procent_zmena_prumer_hrubych_mezd_vsech_odvetvi,
	    ROUND(100 * (AVG(t_second.komodita_cena) / AVG(t_first.komodita_cena) - 1), 2) AS
	    meziroc_procent_zmena_prumer_cen_vsech_potravin,
	    (ROUND(100 * (AVG(t_second.komodita_cena) / AVG(t_first.komodita_cena) - 1), 2) - 
	     ROUND(100 * (AVG(t_second.hrube_mzdy_prumer_czk) / AVG(t_first.hrube_mzdy_prumer_czk) - 1), 2)) AS
	    rozdil_zmen_v_cenach_oproti_zmenam_ve_mzdach
	FROM t_vladan_pivovarnik_project_sql_primary_final AS t_first
	JOIN t_vladan_pivovarnik_project_sql_primary_final AS t_second
	ON t_first.rok + 1 = t_second.rok
	GROUP BY t_second.rok
	ORDER BY rozdil_zmen_v_cenach_oproti_zmenam_ve_mzdach DESC;

-- 2/2
SELECT *
FROM v_salaries_prices_change;
	
-- Ma vyska HDP vliv na zmeny ve mzdach a cenach potravin? Neboli, pokud HDP vzroste vyrazneji v jednom
-- roce, projevi se to na cenach potravin ci mzdach ve stejnem nebo nasdujicim roce vyraznejsim rustem?

-- 1/2
CREATE OR REPLACE VIEW v_salaries_prices_change_fin AS
	SELECT
	    gdp_change.rok,
	    gdp_change.meziroc_procent_zmena_HDP AS meziroc_zmena_hdp_proc,
	    salaries_prices_change.meziroc_procent_zmena_prumer_hrubych_mezd_vsech_odvetvi AS meziroc_zmena_mezd_proc,
	    salaries_prices_change.meziroc_procent_zmena_prumer_cen_vsech_potravin AS meziroc_zmena_cen_proc
	FROM (
	    SELECT
	        scnd_shift.country AS zeme,
	        scnd_shift.`year` AS rok,
	        ROUND((100 * ((scnd_shift.GDP / scnd.GDP) - 1)), 2) AS meziroc_procent_zmena_HDP
	    FROM t_vladan_pivovarnik_project_sql_secondary_final AS scnd
	    LEFT JOIN t_vladan_pivovarnik_project_sql_secondary_final AS scnd_shift
	        ON scnd_shift.`year` = scnd.`year` + 1 AND scnd.country = scnd_shift.country
	    WHERE
	        scnd_shift.country LIKE '%czech%rep%' AND
	        scnd_shift.`year` >= 2007 AND
	        scnd_shift.`year` <= 2018
	) AS gdp_change
	LEFT JOIN (
	    SELECT 
	        rok,
	        meziroc_procent_zmena_prumer_hrubych_mezd_vsech_odvetvi,
	        meziroc_procent_zmena_prumer_cen_vsech_potravin	
	    FROM v_salaries_prices_change
	) AS salaries_prices_change 
	    ON gdp_change.rok = salaries_prices_change.rok;

-- 2/2
SELECT
	CONCAT(MIN(fin.rok), '-', MAX(fin.rok)) AS obdobi,	-- sledovane obdobi
    (SUM(fin.meziroc_zmena_hdp_proc * fin.meziroc_zmena_mezd_proc) - 
     (SUM(fin.meziroc_zmena_hdp_proc) * SUM(fin.meziroc_zmena_mezd_proc) / COUNT(*))) /
    (SQRT(SUM(fin.meziroc_zmena_hdp_proc * fin.meziroc_zmena_hdp_proc) -
          (SUM(fin.meziroc_zmena_hdp_proc) * SUM(fin.meziroc_zmena_hdp_proc) / COUNT(*))) *
     SQRT(SUM(fin.meziroc_zmena_mezd_proc * fin.meziroc_zmena_mezd_proc) -
          (SUM(fin.meziroc_zmena_mezd_proc) * 
           SUM(fin.meziroc_zmena_mezd_proc) / COUNT(*))) 
     ) AS 'korelace_HDP_(rok_R)_vs_MZDY_(rok_R)',	-- 1. korelace
    (SUM(fin.meziroc_zmena_hdp_proc * fin_shift.meziroc_zmena_mezd_proc) - 
     (SUM(fin.meziroc_zmena_hdp_proc) * SUM(fin_shift.meziroc_zmena_mezd_proc) / COUNT(*))) /
    (SQRT(SUM(fin.meziroc_zmena_hdp_proc * fin.meziroc_zmena_hdp_proc) -
          (SUM(fin.meziroc_zmena_hdp_proc) * SUM(fin.meziroc_zmena_hdp_proc) / COUNT(*))) *
     SQRT(SUM(fin_shift.meziroc_zmena_mezd_proc * fin_shift.meziroc_zmena_mezd_proc) -
          (SUM(fin_shift.meziroc_zmena_mezd_proc) * 
           SUM(fin_shift.meziroc_zmena_mezd_proc) / COUNT(*))) 
     ) AS 'korelace_HDP_(rok_R)_vs_MZDY_(rok_R+1)',	-- 2. korelace
    (SUM(fin.meziroc_zmena_hdp_proc * fin.meziroc_zmena_cen_proc) - 
     (SUM(fin.meziroc_zmena_hdp_proc) * SUM(fin.meziroc_zmena_cen_proc) / COUNT(*))) /
    (SQRT(SUM(fin.meziroc_zmena_hdp_proc * fin.meziroc_zmena_hdp_proc) -
          (SUM(fin.meziroc_zmena_hdp_proc) * SUM(fin.meziroc_zmena_hdp_proc) / COUNT(*))) *
     SQRT(SUM(fin.meziroc_zmena_cen_proc * fin.meziroc_zmena_cen_proc) -
          (SUM(fin.meziroc_zmena_cen_proc) * 
           SUM(fin.meziroc_zmena_cen_proc) / COUNT(*))) 
     ) AS 'korelace_HDP_(rok_R)_vs_CENY_(rok_R)',	-- 3. korelace
    (SUM(fin.meziroc_zmena_hdp_proc * fin_shift.meziroc_zmena_cen_proc) - 
     (SUM(fin.meziroc_zmena_hdp_proc) * SUM(fin_shift.meziroc_zmena_cen_proc) / COUNT(*))) /
    (SQRT(SUM(fin.meziroc_zmena_hdp_proc * fin.meziroc_zmena_hdp_proc) -
          (SUM(fin.meziroc_zmena_hdp_proc) * SUM(fin.meziroc_zmena_hdp_proc) / COUNT(*))) *
     SQRT(SUM(fin_shift.meziroc_zmena_cen_proc * fin_shift.meziroc_zmena_cen_proc) -
          (SUM(fin_shift.meziroc_zmena_cen_proc) * 
           SUM(fin_shift.meziroc_zmena_cen_proc) / COUNT(*))) 
     ) AS 'korelace_HDP_(rok_R)_vs_CENY_(rok_R+1)'	-- 4. korelace
FROM v_salaries_prices_change_fin AS fin
LEFT JOIN v_salaries_prices_change_fin AS fin_shift
    ON fin_shift.rok = fin.rok + 1;
