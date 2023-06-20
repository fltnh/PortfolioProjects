-- Check datasets--

SELECT * 
FROM PortfolioProject..CovidDeaths$
ORDER BY 3,4

SELECT * 
FROM PortfolioProject..CovidVaccinations$
ORDER BY 3,4


-- Select data that we are going to be using--

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths --
-- Shows the likelihood of dying if someone contracts covid in a particular country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1,2



-- Looking at Total Cases vs Population in the US
-- Shows what percentage of population contracted covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Looking at Total Cases vs Population in Australia
-- Shows what percentage of population contracted covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
WHERE location LIKE '%Australia%'
ORDER BY 1,2


-- Looking at countried with highest infection rate compared to population --
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC
-- Andorra has the highest percentage of infection rate with 17% of population infected




-- Showing the countries with the Highest Death Count per Population --
-- we need to CAST the total_deaths variable as an integer
SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- data appears to be grouping entire continents
-- after assessing data, it appears some entries have continent and location as 'Asia'
-- some continents are also NULL
-- can add condition to script to look at data where continent is not null

SELECT * 
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 3,4


--- LET'S BREAK THINGS DOWN BY CONTINENT ---
-- Showing the Continents with the highest death count -- 

SELECT continent, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC
--some small issues; North America won't include data from Canada


SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
-- these are the correct numbers but for the purpose of this project we will use the previous query output



-- Global Numbers --

SELECT date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date -- gives error as we need to use aggregate functions on other variables --
ORDER BY 1,2

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- remove group by date --
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2


-- Looking at Vaccinations Data -- 
SELECT *
FROM PortfolioProject..CovidVaccinations$


-- Join the two tables --
SELECT *
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date


-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS int)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE --
WITH PopvsVac (continent, location, date, population,new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac
-- at the latest date, 12% of the Albanian population were vaccinated


-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualisations --

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3


SELECT*
FROM PercentPopulationVaccinated