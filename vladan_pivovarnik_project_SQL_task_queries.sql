-- Rostou v pr�b�hu let mzdy ve v�ech odv�tv�ch, nebo v n�kter�ch klesaj�?

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
	
-- Kolik je mo�n� si koupit litr� ml�ka a kilogram� chleba za prvn� a posledn� 
-- srovnateln� obdob� v dostupn�ch datech cen a mezd?

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

-- Kter� kategorie potravin zdra�uje nejpomaleji (je u n� nejni��� percentu�ln� meziro�n� n�r�st)?

SELECT DISTINCT
	t_second.komodita_jmeno,
	ROUND(AVG(100 * ((t_second.komodita_cena / t_first.komodita_cena) - 1)), 2)
	AS prumerna_mezirocni_procentualni_cenova_zmena_2007_2018
FROM t_vladan_pivovarnik_project_sql_primary_final AS t_first
LEFT JOIN t_vladan_pivovarnik_project_sql_primary_final AS t_second
ON
	t_first.komodita_jmeno = t_second.komodita_jmeno AND 
	t_first.rok + 1 = t_second.rok
GROUP BY 
	t_second.komodita_jmeno
ORDER BY
	prumerna_mezirocni_procentualni_cenova_zmena_2007_2018;

-- Existuje rok, ve kter�m byl meziro�n� n�r�st cen potravin v�razn� vy��� ne� r�st mezd (v�t�� ne� 10 %)?

SELECT
    t_second.rok,
    ROUND(100 * (AVG(t_second.hrube_mzdy_prumer_czk) / AVG(t_first.hrube_mzdy_prumer_czk) - 1), 2) AS 
    mezirocni_procentualni_zmena_prumernych_hrubych_mezd_vsech_odvetvi,
    ROUND(100 * (AVG(t_second.komodita_cena) / AVG(t_first.komodita_cena) - 1), 2) AS
    mezirocni_procentualni_zmena_prumernych_cen_vsech_potravin,
    (ROUND(100 * (AVG(t_second.komodita_cena) / AVG(t_first.komodita_cena) - 1), 2) - 
     ROUND(100 * (AVG(t_second.hrube_mzdy_prumer_czk) / AVG(t_first.hrube_mzdy_prumer_czk) - 1), 2)) AS
    rozdil_zmen_v_cenach_oproti_zmenam_ve_mzdach
FROM t_vladan_pivovarnik_project_sql_primary_final AS t_first
JOIN t_vladan_pivovarnik_project_sql_primary_final AS t_second
ON 
    t_first.rok + 1 = t_second.rok
GROUP BY t_second.rok
ORDER BY rozdil_zmen_v_cenach_oproti_zmenam_ve_mzdach DESC;
	

-- M� v��ka HDP vliv na zm�ny ve mzd�ch a cen�ch potravin? Neboli, pokud HDP vzroste v�razn�ji v jednom
-- roce, projev� se to na cen�ch potravin �i mzd�ch ve stejn�m nebo n�sduj�c�m roce v�razn�j��m r�stem?