CREATE OR REPLACE TABLE t_vladan_pivovarnik_project_SQL_primary_final AS
	SELECT 
		cp.id AS hrube_mzdy_id,
		cp.value AS hrube_mzdy_prumer_czk,
		cp.payroll_year AS hrube_mzdy_rok,
		cp.payroll_quarter AS hrube_mzdy_kvartal,
		cp.industry_branch_code AS hrube_mzdy_odvetvi_kod,
		cpib.name AS hrube_mzdy_odvetvi_jmeno,	
		cprcat.name AS komodita, 
		cprcat.price_unit AS komodita_merna_jednotka,
		cprcat.price_value AS komodita_merna_jednotka_mnozstvi,
		cpr.region_code AS komodita_kraj,
		cpr.value AS komodita_cena	-- cena za mnozstvi merne jednotky komodity v danem kraji a kvartale daneho roku
	FROM czechia_payroll AS cp
	JOIN czechia_payroll_value_type AS cpvt ON cp.value_type_code = cpvt.code
	LEFT JOIN czechia_payroll_unit AS cpu ON cp.unit_code = cpu.code
	LEFT JOIN czechia_payroll_industry_branch AS cpib ON cp.industry_branch_code = cpib.code
	LEFT JOIN czechia_payroll_calculation AS cpc ON cp.calculation_code = cpc.code
	LEFT JOIN czechia_price AS cpr ON
		cp.payroll_year IN (YEAR(cpr.date_from), YEAR(cpr.date_to)) 
		AND (
			(cp.payroll_quarter = 1 AND MONTH(cpr.date_from) AND MONTH(cpr.date_to) IN (1, 2, 3)) OR 
			(cp.payroll_quarter = 2 AND MONTH(cpr.date_from) AND MONTH(cpr.date_to) IN (4, 5, 6)) OR 
			(cp.payroll_quarter = 3 AND MONTH(cpr.date_from) AND MONTH(cpr.date_to) IN (7, 8, 9)) OR 
			(cp.payroll_quarter = 4 AND MONTH(cpr.date_from) AND MONTH(cpr.date_to) IN (10, 11, 12))
		)
	LEFT JOIN czechia_price_category AS cprcat ON cpr.category_code = cprcat.code
	WHERE 
		cpvt.name LIKE "%mzda%" AND 
		cpu.name LIKE "%kè%";