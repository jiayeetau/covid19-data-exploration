--Covid 19 Data Exploration

--Skill Used: Joins, Converting Data Types, Windows Functions, Aggregate Functions, CTE, Temporary Tables, Creating Views



--Selecting data

SELECT*
FROM [Covid Deaths]
ORDER BY 3,4

SELECT*
FROM [Covid Vaccinations]
ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Covid Deaths]
ORDER BY 1, 2


--Calculating death percentage for each date in the locations with the word 'state'

SELECT Location, date, total_cases, total_deaths, 
CONVERT(float, total_deaths)/NULLIF(CONVERT(float, total_cases), 0) *100 AS DeathPercentage
FROM [Covid Deaths]
WHERE location LIKE '%state%'
ORDER BY 1, 2


--Calculating the percentage of the population infected

SELECT location, date, population, total_cases, 
NULLIF(CONVERT(float, total_cases), 0)/CONVERT(float, population) *100 AS PercentagePopulationInfected
FROM [Covid Deaths]
WHERE total_cases IS NOT NULL
ORDER BY 1,2


--Finding the highest percentage of the population infected for each location

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
MAX(total_cases/population)*100 AS PercentagePopulationInfected
FROM [Covid Deaths]
GROUP BY location, population
ORDER BY 4 DESC


--Finding the countries and continents with the highest death count

SELECT location, MAX(CAST(total_deaths AS int)) AS HighestDeathCount
FROM [Covid Deaths]
GROUP BY location
ORDER BY 2 DESC

SELECT continent, MAX(CAST(total_deaths AS int)) AS HighestDeathCount
FROM [Covid Deaths]
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC


--Finding the continents with the highest death per population

SELECT continent, MAX(total_deaths/population)*100 AS HighestDeathPerPopulation
FROM [Covid Deaths]
GROUP BY continent
ORDER BY 2 DESC


--Calculating death percentage for each date

SELECT
	date, 
	SUM(new_cases) AS NewCases, 
	SUM(new_deaths) AS NewDeaths,
CASE
	WHEN SUM(new_cases) <> 0
	THEN SUM(new_deaths)/SUM(new_cases)*100 
	ELSE NULL
END AS DeathsPercentage
FROM [Covid Deaths]
GROUP BY date
ORDER BY 1,2


--Calculating total death percentage

SELECT
	SUM(new_cases) AS TotalCases, 
	SUM(new_deaths) AS TotalDeaths,
CASE
	WHEN SUM(new_cases) <> 0
	THEN SUM(new_deaths)/SUM(new_cases)*100 
	ELSE NULL
END AS DeathsPercentage
FROM [Covid Deaths]
ORDER BY 1,2


--Calculating the accumulative sum of new vaccinations for each location

SELECT
	dea.continent,
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Covid Deaths] AS dea
JOIN [Covid Vaccinations] AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
ORDER BY 2,3


--Find vaccination percentages using CTE

WITH CTE_PercentPopulationVaccinated AS
(
SELECT
	dea.continent,
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Covid Deaths] AS dea
JOIN [Covid Vaccinations] AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
)
SELECT continent, location, date, population, new_vaccinations, 
(RollingPeopleVaccinated/population)*100 AS VaccinationPercentages
FROM CTE_PercentPopulationVaccinated
WHERE new_vaccinations IS NOT NULL


--Find vaccination percentages using Temporary Table

DROP TABLE IF EXISTS #temp_PercentPopulationVaccinated
CREATE Table #temp_PercentPopulationVaccinated
(
Continent nvarchar(100),
Location nvarchar(100),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
)

INSERT INTO #temp_PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Covid Deaths] AS dea
JOIN [Covid Vaccinations] AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations

SELECT*, (Rolling_People_Vaccinated/Population)*100 AS Percentage_People_Vaccinated
FROM #temp_PercentPopulationVaccinated


--Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT
	dea.continent,
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Covid Deaths] AS dea
JOIN [Covid Vaccinations] AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT*
FROM PercentPopulationVaccinated