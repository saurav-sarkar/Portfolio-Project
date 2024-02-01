SELECT * 
FROM projects ..CovidDeaths$
WHERE continent is not null
ORDER BY 3,4


--SELECT * 
--FROM projects ..CovidVaccination$
--ORDER BY 3,4

--SELECT THE DATA THAT WE ARE GOING TO BE USING

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM projects ..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2 

--TOTAL CASES VS TOTAL DEATHS
--SHOWS LIKELIHOOD OF DYING IF YOU CONTRACT COVID IN YOUR COUNTRY

SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM projects ..CovidDeaths$
WHERE location like 'India' and  continent is not null
ORDER BY 1,2

--LOOKING AT THE TOTAL CASES VS THE POPULATION
--SHOWS WHAT PERCENTAGE OF POPULATION GOT COVID  

SELECT location,date,total_cases,population, (total_cases/population)*100 as CasePercentage
FROM projects ..CovidDeaths$
--WHERE location like 'India'
WHERE continent is not null
ORDER BY 1,2

--LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION 

SELECT location,MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population))*100 as CasePercentage
FROM projects ..CovidDeaths$
--WHERE location like 'India'
WHERE continent is not null
GROUP BY location,population
ORDER BY  CasePercentage desc

--LOOKING AT COUNTRIES WITH HIGHEST DEATH COUNT AS PER THE POPULATION 

SELECT location,MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM projects ..CovidDeaths$
--WHERE location like 'India'
WHERE continent is not null
GROUP BY location
ORDER BY  TotalDeathCount desc

--LET'S GET THINGS BY CONTINENT 
--SHOWING THE CONTINENTS WITH THE HIGHEST DEATH COUNT PER POPULATION

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM projects ..CovidDeaths$
--WHERE location like 'India'
WHERE continent is not null
GROUP BY continent
ORDER BY  TotalDeathCount desc

--GLOBAL NUMBERS OF COVID 

SELECT SUM(new_cases)as Total_cases,SUM(CAST(new_deaths as int))as Total_deaths, 
SUM(CAST(new_deaths as int)) / SUM(new_cases)*100 as DeathPercentage
FROM projects ..CovidDeaths$
--WHERE location like 'India' 
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

--LOOKING AT TOTAL POPULATION VS TOTAL VACCINATION 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.Location ORDER BY dea.location, 
dea.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated / population)*100 as 
FROM projects..CovidDeaths$ dea
JOIN projects..CovidVaccination$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--USING CTE TO PERFORM CALCULATION ON PARTITION

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From projects..CovidDeaths$ dea
Join projects..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

--USING TEMP TO PERFORM CALCULATION ON PARTITION

DROP TABLE IF exists #PercentPopulationVaccinated
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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From projects..CovidDeaths$ dea
Join projects..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--CREATING VIEW TO STORE DATA FOR DATA VISULIZATION

Create View PercentPopulationVaccinate as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From projects..CovidDeaths$ dea
Join projects..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
