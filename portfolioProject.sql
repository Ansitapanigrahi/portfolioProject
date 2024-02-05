select * from portfolioProject..covid_deaths
where continent is not null 
order by 3,4
--select * from portfolioProject..covid_vaccinations order by 3,4


--select data that we are going to be using

select location,date,total_cases,total_deaths
from portfolioProject..covid_deaths order by 1,2

-- looking at total cases vs total deaths 
-- shows likelihood of dying if you contract covid in your country
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    (TRY_CONVERT(numeric, total_deaths) * 100.0 / TRY_CONVERT(numeric, total_cases)) as DeathPercentage
FROM
    portfolioProject..covid_deaths
Where location like '%India%'
ORDER BY
    1, 2;


--look at the total cases vs total population
SELECT
    location,
    date,
    total_cases,
    population,
    (TRY_CONVERT(numeric, total_deaths)  / TRY_CONVERT(numeric, population))* 100.0 as DeathPercentage
FROM
    portfolioProject..covid_deaths
Where location like '%India%'
ORDER BY
    1, 2;


-- looking at countries with Highest Infection Rate compared to population
select Location,Population,MAX(total_cases) 
as HighestInfectionCount,MAX((total_cases/population))*100 
as PercentPopulationInfected
From portfolioProject..covid_deaths
group by location,Population 
order by
PercentPopulationInfected desc

--Lets break things down by continent

SELECT
    location,
    MAX(total_deaths) as TotaldeathCount
FROM
    portfolioProject..covid_deaths
WHERE
    continent IS NULL
GROUP BY
    location
ORDER BY
    TotaldeathCount DESC;

--showing continents with the highest death coun per population

SELECT
    continent,
    MAX(total_deaths) as TotaldeathCount
FROM
    portfolioProject..covid_deaths
WHERE
    continent IS NOT NULL
GROUP BY
    continent
ORDER BY
    TotaldeathCount DESC;


--GLOBAL NUMBERS
SELECT
    SUM(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 as deathPercentage
	FROM
    portfolioProject..covid_deaths
Where continent is not null
--group by date
ORDER BY
    1, 2;

--TOTAL POPULATION VS VACCINATIONS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location order by dea.location,dea.date) as RollingPeopleVaccinated
FROM
    portfolioProject..covid_deaths dea
JOIN
    portfolioProject..covid_vaccinations vac
ON
    dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    2, 3;

--USE CTE 
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (cast(RollingPeopleVaccinated as decimal)/(cast(Population as decimal))*100) AS VaccinationPercentage
From PopvsVac

--TEMP TABLE 
drop table if exists PercentPopulationVaccinated
Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar (255),
date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
    PortfolioProject..covid_deaths dea
JOIN
    PortfolioProject..covid_vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;


Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated

--Creating View to store data for later visualization
CREATE VIEW PercentPopVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    --, (CAST(RollingPeopleVaccinated AS decimal) / dea.population) * 100 AS VaccinationPercentage
FROM
    portfolioProject..covid_deaths dea
JOIN
    portfolioProject..covid_vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;


Select * 
From PercentPopVaccinated