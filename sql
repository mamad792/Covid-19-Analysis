-- List all countries along with their population and continent.
SELECT country_name, continent, population FROM countries

-- Find the total number of cases reported in each country.
SELECT country_name, SUM(new_cases) AS total_cases_reported FROM cases INNER JOIN countries ON cases.country_id = countries.country_id 
GROUP BY country_name
ORDER BY SUM(new_cases)

-- Retrieve all records where the number of new cases exceeded 30,000.
SELECT * FROM cases
WHERE new_cases > 30000

-- Display the daily cases, deaths, and recoveries for "India" in January 2021.
SELECT date_reported, new_cases, new_deaths, new_recoveries 
FROM cases INNER JOIN countries ON cases.country_id = countries.country_id
WHERE country_name = 'India' AND date_reported > '2021-01-01'

-- Calculate the total cases, deaths, and recoveries for each country.
SELECT country_name, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_recoveries) AS total_recoveries
FROM cases INNER JOIN countries ON cases.country_id = countries.country_id
GROUP BY country_name

-- Identify the country with the highest vaccination rate (fully vaccinated as a percentage of the population).
SELECT country_name, population, ROUND ((((SUM(fully_vaccinated)::NUMERIC) / population) * 100),2)  AS vaccination_rate FROM vaccinations INNER JOIN countries ON vaccinations.country_id = countries.country_id
GROUP BY country_name, population 
ORDER BY vaccination_rate DESC
LIMIT 1

-- Determine the 7-day rolling average of new cases for the USA.
SELECT countries.*, new_cases, ROUND(AVG(new_cases) OVER(ORDER BY date_reported ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS sevendaysmoving_average
FROM countries INNER JOIN cases ON countries.country_id = cases.country_id
WHERE country_name = 'USA'

-- Find the date when each country reported its highest number of new cases.
SELECT country_name,date_reported, maxcases FROM (SELECT country_name, new_cases, date_reported, MAX(new_cases) OVER (PARTITION BY country_name ) AS maxcases
FROM cases INNER JOIN countries ON cases.country_id = countries.country_id
ORDER BY country_name)
WHERE new_cases = maxcases

-- Compare vaccination rates and case rates for all countries.
SELECT countries.country_id, country_name, 
ROUND ((SUM(fully_vaccinated) / population::NUMERIC ) * 100, 3) AS vaccinationrate,
ROUND ((SUM(new_cases) / population::NUMERIC ) * 100, 3) AS casesrate,
CASE 
	WHEN ROUND ((SUM(fully_vaccinated) / population::NUMERIC ) * 100, 3) > ROUND ((SUM(new_cases) / population::NUMERIC ) * 100, 3) THEN 'Vaccinated people are more than the case'
	ELSE 'Vaccinated people are more than the case'
END
FROM countries 
INNER JOIN vaccinations ON countries.country_id = vaccinations.country_id
INNER JOIN cases ON countries.country_id = cases.country_id
GROUP BY country_name, population, countries.country_id
ORDER BY countries.country_id

-- Identify countries where the vaccination rate is below 50% but have reported a case fatality rate (deaths/cases) higher than 2%.
SELECT countries.country_id, country_name, 
ROUND ((SUM(fully_vaccinated) / population::NUMERIC ) * 100, 3) AS vaccinationrate,
ROUND ((SUM(new_cases) / population::NUMERIC ) * 100, 3) AS casesrate, 
ROUND(SUM(new_deaths)::NUMERIC / SUM (new_cases) * 100 ,3) AS fatality_rate
FROM countries 
INNER JOIN vaccinations ON countries.country_id = vaccinations.country_id
INNER JOIN cases ON countries.country_id = cases.country_id
GROUP BY country_name, population, countries.country_id
HAVING  ROUND ((SUM(fully_vaccinated) / population::NUMERIC ) * 100, 3) < 50 AND ROUND(SUM(new_deaths)::NUMERIC / SUM (new_cases) * 100 ,3) > 2
ORDER BY countries.country_id

-- Create a summary report showing total cases, total vaccinations, and vaccination rate for each continent.
SELECT continent,
SUM(new_cases) AS total_case,
SUM(fully_vaccinated) AS total_vaccination,
ROUND ((SUM(fully_vaccinated) / SUM(population)::NUMERIC ) * 100, 3) AS vaccinationrate
FROM countries 
INNER JOIN vaccinations ON countries.country_id = vaccinations.country_id
INNER JOIN cases ON countries.country_id = cases.country_id
GROUP BY continent
ORDER BY continent

-- Determine the total number of cases per continent and rank continents by the severity of the outbreak.
SELECT continent, SUM(new_cases) as total_cases, RANK() OVER(ORDER BY SUM(new_cases) DESC)
FROM cases INNER JOIN countries ON cases.country_id = countries.country_id 
GROUP BY continent

-- Build a view summarizing total cases, deaths, recoveries, and vaccinations for each country.
CREATE VIEW country_covid_summary AS (SELECT country_name, 
SUM(new_cases) AS total_cases,
SUM(new_deaths) AS total_deaths,
SUM(new_recoveries) AS new_recoveries,
SUM(vaccinations.doses_administered) AS total_doses_administered,
SUM(fully_vaccinated) AS vaccinations
FROM countries 
LEFT JOIN cases ON countries.country_id = cases.country_id
LEFT JOIN vaccinations ON countries.country_id = vaccinations.country_id
GROUP BY country_name
)

SELECT * FROM country_covid_summary
