-- R. 22 - 37: Pod aliasem kom spoj pres kod komodity tabulku s cenami komodit s tabulkou se jmeny komodit. 
-- V teto nove tabulce vrat celorepublikove prumerne ceny komodit za kazdy rok.
-- R. 39 - 52: Pod aliasem mz spoj pres kody hospodarskych odvetvi tabulku prumernych mezd s tabulkou se 
-- jmeny hospodarskych odvetvi. V teto nove tabulce vrat prumerne mzdy v jednotlivych odvetvich vzdy za 
-- jeden rok.
-- R. 52: Spoj tabulky kom a mz, a to pres hodnoty roku.
-- R. 10 - 21: Ze spojeni techto dvou tabulek vytahni vybranne hodnoty a uloz je do nove tabulky 
-- t_vladan_pivovarnik_project_SQL_primary_final

CREATE OR REPLACE TABLE t_vladan_pivovarnik_project_SQL_primary_final AS
	SELECT
	    mz.rok,
	    mz.hrube_mzdy_prumer_czk,
	    mz.hrube_mzdy_odvetvi_kod,
	    mz.hrube_mzdy_odvetvi_jmeno,
	    kom.komodita_jmeno,
	    kom.komodita_kod,
	    kom.komodita_merna_jednotka,
	    kom.komodita_merna_jednotka_mnozstvi,
	    kom.komodita_cena
	FROM (
	    SELECT
	        cprcat.name AS komodita_jmeno,
	        cprcat.code AS komodita_kod,
	        cprcat.price_unit AS komodita_merna_jednotka,
	        cprcat.price_value AS komodita_merna_jednotka_mnozstvi,
	        AVG(cpr.value) AS komodita_cena,
	        CASE
	            WHEN YEAR(cpr.date_from) = YEAR(cpr.date_to) THEN YEAR(cpr.date_to)
	            ELSE NULL
	        END AS rok
	    FROM czechia_price AS cpr
	    LEFT JOIN czechia_price_category AS cprcat ON cpr.category_code = cprcat.code
	    GROUP BY 
	        cpr.category_code,
	        YEAR(cpr.date_to)
	) AS kom
	LEFT JOIN (
	    SELECT 
	        AVG(cpay.value) AS hrube_mzdy_prumer_czk,
	        cpay.payroll_year AS rok,
	        cpay.industry_branch_code AS hrube_mzdy_odvetvi_kod,
	        cpib.name AS hrube_mzdy_odvetvi_jmeno
	    FROM czechia_payroll AS cpay
	    LEFT JOIN czechia_payroll_industry_branch AS cpib ON cpay.industry_branch_code = cpib.code
	    WHERE 
	        cpay.value_type_code = 5958 AND -- 5958 -> prumer. hruba mzda na zamestnance 
	        cpay.unit_code = 200 -- 200 -> czk
	    GROUP BY
	        cpay.industry_branch_code,
	        cpay.payroll_year
	) AS mz ON kom.rok = mz.rok;