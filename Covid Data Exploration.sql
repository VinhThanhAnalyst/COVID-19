SELECT *
FROM CovidDeaths
WHERE continent is not NULL
ORDER BY 3, 4

SELECT *
FROM CovidVaccinations
WHERE continent is not NULL
ORDER BY 3, 4

--Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2 

--Looking at Total cases vs Total Deaths
--Show likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE location like '%vietnam'
and continent is not NULL
ORDER BY 1,2 

--Looking at Total cases vs Population
--Shows what percentage of population got Infected
SELECT Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths
--WHERE location like '%vietnam'
WHERE continent is not NULL
ORDER BY 1,2 

--Looking at Countries with highest Infection rate compared to Population

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths
--WHERE location like '%vietnam%'
WHERE continent is not NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC


--Showing Countries with Highest Death Count per Population
SELECT Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE location like '%vietnam%'
WHERE continent is not NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

--LET'S BREAK THINGS DOWNS BY CONTINENT
--Showing continents with the highest death count per population
SELECT continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE location like '%vietnam%'
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT  SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
--WHERE location like '%vietnam%'
WHERE continent is not NULL
--GROUP BY date
ORDER BY 1,2 


--Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, (RollinggPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3

--Use CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, (RollinggPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

--TEMP TABLE to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths  dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths  dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

SELECT *
FROM PercentPopulationVaccinated