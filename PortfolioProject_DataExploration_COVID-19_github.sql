-- EXPLORING COVID-19 DATA 

-- Skills used: Joins, CTE's, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

--Calculating the Percentage of Total Death versus Total Cases
--This shows the likelihod of dying if covid-19 was contracted

SELECT continent, Location, date, total_cases, total_deaths, ROUND ((total_deaths/total_cases)*100,2) AS PercentDeath_TotalCases
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2,3

--Calculating the Percentage of Total Death versus Total population
--This shows the percentage of the population that died as a result of COVID-19

SELECT continent, Location, date, population, total_deaths, ROUND ((total_deaths/population)*100,2) AS PercentDeath_TotalPopulation
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2,3

			--For my country:Nigeria

SELECT Location, date, population, total_deaths, ROUND ((total_deaths/population)*100,2) AS PercentDeath_TotalPopulation
FROM CovidDeaths
WHERE location = 'Nigeria' AND continent IS NOT NULL
ORDER BY 1, 2


--Calculating the Percentage of Total Cases versus Total population
--This shows the percentage of the population that contracted COVID-19

SELECT continent, Location, date, population, total_cases, ROUND ((total_cases/population)*100,2) AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2,3


-- Which country had the highest infection rate compared with the population?

SELECT continent, location, population, MAX (total_cases) AS TotalCasesPerCountry, ROUND (MAX(total_cases/population)*100,2) AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent, location, population
ORDER BY 1,2,4 DESC

				
--What country has the highest death count?

SELECT continent, location, MAX (CAST (total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent, location
ORDER BY continent, location, TotalDeathCount DESC


-- BREAKING THINGS DOWN BY CONTINENT	

--Total death count by CONTINENT

SELECT continent, MAX (CAST (total_deaths AS int)) AS ContinentTotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY ContinentTotalDeathCount DESC

--Total case count by CONTINENT

SELECT continent, MAX(CAST (total_cases AS int)) AS ContinentTotalCaseCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY 1 


-- GOING GLOBAL


SELECT date, SUM (new_cases) WorldTotalCases, SUM (CAST (new_deaths AS int)) WorldTotalDeaths, 
		ROUND ((SUM (CAST (new_deaths AS int))/SUM (new_cases))*100,2) AS WorldPercentDeathperCase
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1,2
--The above query gives the world stat on a daily basis


--The world stat without date;

SELECT SUM (new_cases) WorldTotalCases, SUM (CAST (new_deaths AS int)) WorldTotalDeaths, 
		ROUND ((SUM (CAST (new_deaths AS int))/SUM (new_cases))*100,2) AS WorldPercentDeath 
FROM CovidDeaths
WHERE continent IS NOT NULL 


-- USING JOINS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3

-- What is the total amount of people in the world that has been vaccinated?

SELECT SUM(dea.population) World_Total_Population, SUM(CAST (vac.new_vaccinations AS int)) World_Total_Vaccination
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL


-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.population, SUM (CAST (dea.new_deaths AS int)) total_deaths, SUM (CAST (vac.new_vaccinations AS int)) total_vaccinations,
		ROUND ((SUM (CAST (vac.new_vaccinations AS int))/(dea.population))*100,4) percent_population_vaccinated
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
GROUP BY dea.continent, dea.location, dea.population
ORDER BY 1, 2


-- Rolling Sum of Vaccinations per day using PARTITION BY

SELECT dea.continent, dea.location, dea.population, dea.date, vac.new_vaccinations,
		SUM (CAST (vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated	
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3


-- Rolling Percentage of Population Vaccinated per day.

-- USING A CTE

WITH PopulationVaccinated (continent, location, population, date, new_vaccinations, daily_rollinig_sum_of_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.population, dea.date, vac.new_vaccinations,
		SUM (CAST (vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) daily_rollinig_sum_of_vaccinations	
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, ROUND (((daily_rollinig_sum_of_vaccinations/population)*100), 6) RollingPercentagePopulationVaccinated
FROM PopulationVaccinated

-- USING A TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar (250), location nvarchar (250), population numeric, 
date datetime, new_vaccinations int, daily_rollinig_sum_of_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.population, dea.date, vac.new_vaccinations,
		SUM (CAST (vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) daily_rollinig_sum_of_vaccinations	
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL


SELECT *, (daily_rollinig_sum_of_vaccinations/population)*100 RollingPercentagePopulationVaccinated
FROM #PercentPopulationVaccinated




-- CREATING VIEWS TO STORE DATA FOR VISUALIZATION

CREATE VIEW daily_rollinig_sum_of_vaccinations AS 

SELECT dea.continent, dea.location, dea.population, dea.date, vac.new_vaccinations,
		SUM (CAST (vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) daily_rollinig_sum_of_vaccinations	
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
-- vac.new_vaccinations IS NOT NULL is included because the vaccination data has some NULL entries
--ORDER BY 1, 2, 3


CREATE VIEW InfectionRate AS

SELECT continent, location, population, MAX (total_cases) AS TotalCasesPerCountry, ROUND (MAX(total_cases/population)*100,2) AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent, location, population


CREATE VIEW TotalDeathCount AS

SELECT continent, location, MAX (CAST (total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent, location


CREATE VIEW TotalCaseCount AS

SELECT continent, MAX(CAST (total_cases AS int)) AS ContinentTotalCasesCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent


CREATE VIEW PercentPopulationVaccinated AS

SELECT dea.continent, dea.location, dea.population, SUM (CAST (dea.new_deaths AS int)) total_deaths, SUM (CAST (vac.new_vaccinations AS int)) total_vaccinations,
		ROUND ((SUM (CAST (vac.new_vaccinations AS int))/(dea.population))*100,4) percent_population_vaccinated
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
-- vac.new_vaccinations IS NOT NULL is included because the vaccination data has some NULL entries
GROUP BY dea.continent, dea.location, dea.population