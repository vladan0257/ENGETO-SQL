CREATE OR REPLACE TABLE t_vladan_pivovarnik_project_SQL_secondary_final AS
	SELECT
		eco.country,
		eco.`year`,
		eco.GDP,
		eco.gini,
		eco.population 
	FROM economies AS eco
	LEFT JOIN countries AS co ON eco.country = co.country 
	WHERE co.continent = 'Europe';