-- Rostou v prùbìhu let mzdy ve všech odvìtvích, nebo v nìkterých klesají?

SELECT DISTINCT
	prim.hrube_mzdy_odvetvi_kod,
	prim.rok,
	prim.hrube_mzdy_prumer_czk
FROM t_vladan_pivovarnik_project_sql_primary_final AS prim
JOIN t_vladan_pivovarnik_project_sql_primary_final AS prim_shift
ON prim_shift.hrube_mzdy_odvetvi_kod = prim.hrube_mzdy_odvetvi_kod AND
prim_shift.rok - 1 = prim.rok
WHERE (prim_shift.hrube_mzdy_prumer_czk - prim.hrube_mzdy_prumer_czk) < 0
ORDER BY
	prim.hrube_mzdy_odvetvi_kod,
	prim.rok;
	
-- Kolik je možné si koupit litrù mléka a kilogramù chleba za první a poslední 
-- srovnatelné období v dostupných datech cen a mezd?

SELECT
    rok,
    FLOOR(hrube_mzdy_prumer_czk) AS hrube_mzdy_prumer_czk,
    hrube_mzdy_odvetvi_jmeno,
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
ORDER BY
	komodita_jmeno,
	rok,
	hrube_mzdy_prumer_czk;

-- Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroèní nárùst)?

-- Existuje rok, ve kterém byl meziroèní nárùst cen potravin výraznì vyšší než rùst mezd (vìtší než 10 %)?

-- Má výška HDP vliv na zmìny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výraznìji v jednom
-- roce, projeví se to na cenách potravin èi mzdách ve stejném nebo násdujícím roce výraznìjším rùstem?