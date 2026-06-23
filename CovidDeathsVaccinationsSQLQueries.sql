--check that tables copied over properly

SELECT
	*
FROM
	PortfolioProject..CovidDeaths2
WHERE
	location like '%afghanistan%'
--WHERE
	--continent IS NOT NULL --some countries are listed as the entire continent
ORDER BY
	3,4

SELECT
	*
FROM
	PortfolioProject..CovidVaccinations$
ORDER BY
	3,4

-- select necessary data

SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM
	PortfolioProject..CovidDeaths2
ORDER BY
	1,2

-- total cases vs total deaths
--likelihood of dying if you contract covid from jan 2020 to april 2021
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS death_percentage
FROM
	PortfolioProject..CovidDeaths2
--WHERE
	--location like '%taiwan%'
ORDER BY
	1,2

--total cases vs population
--what percentage of the population got covid
SELECT
	location,
	date,
	total_cases,
	population,
	(total_cases/population)*100 AS infection_percentage
FROM
	PortfolioProject..CovidDeaths2
--WHERE
	--location like '%states%'
ORDER BY
	1,2

-- countries with highest infection count compared to population
SELECT
	location,
	population,
	MAX(total_cases) AS highest_infection_count,
	MAX((total_cases/population))*100 AS infection_percent
FROM
	PortfolioProject..CovidDeaths2
--WHERE
	--location like '%states%'
GROUP BY
	location, population
ORDER BY
	infection_percent DESC

-- countries with the highest death count per population
SELECT
	location,
	MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM
	PortfolioProject..CovidDeaths2
WHERE
	continent IS NOT NULL
GROUP BY
	location
ORDER BY
	total_death_count DESC


-- percent of people by country who died from covid
WITH CountryDeathPercent (location, date, population, new_deaths, rolling_deaths)
AS
(
SELECT
	location,
	date,
	population,
	new_deaths,
	SUM(CONVERT(FLOAT, new_deaths)) OVER (PARTITION BY location ORDER BY location, date) AS rolling_deaths
FROM
	PortfolioProject..CovidDeaths2
WHERE
	continent IS NOT NULL
)

SELECT
	*,
	(rolling_deaths/population)*100 AS percent_died
FROM
	CountryDeathPercent
ORDER BY
	1,2



-- create a view of the percent of the population that died from covid for later visualizations
CREATE VIEW PercentPopulationDeaths AS
WITH CountryDeathPercent (Location, Date, population, New_Deaths, Rolling_Deaths)
AS
(
SELECT
	Location,
	Date,
	Population,
	New_Deaths,
	SUM(CONVERT(FLOAT, new_deaths)) OVER (PARTITION BY location ORDER BY location, date) AS Rolling_Deaths
FROM
	PortfolioProject..CovidDeaths2
WHERE
	continent IS NOT NULL
)

SELECT
	*,
	(rolling_deaths/population)*100 AS Percent_Died
FROM
	CountryDeathPercent



-- continents with the highest death count per population
SELECT
	continent,
	SUM(CAST(new_deaths AS INT)) AS total_death_count
FROM
	PortfolioProject..CovidDeaths2
WHERE
	continent is not null
GROUP BY
	continent
ORDER BY
	total_death_count DESC




-- global death rate per day
SELECT
	date,
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100 AS death_percentage
FROM PortfolioProject..CovidDeaths2
WHERE
	continent IS NOT NULL
GROUP BY
	date
ORDER BY
	1,2


-- create a view for global death rate by day
CREATE VIEW GlobalDeathRateByDay AS
SELECT
	date,
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100 AS death_percentage
FROM PortfolioProject..CovidDeaths2
WHERE
	continent IS NOT NULL
GROUP BY
	date
ORDER BY
	date asc


-- check view
SELECT
	*
FROM
	GlobalDeathRateByDay
ORDER BY
	date

--total global death rate
SELECT SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100 AS death_percentage
FROM
	PortfolioProject..CovidDeaths2
WHERE
	continent IS NOT NULL
ORDER BY
	1,2



--total population vs vaccinations
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(FLOAT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM
	PortfolioProject..CovidDeaths2 AS dea
JOIN PortfolioProject..CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
ORDER BY
	dea.location, dea.date



-- use CTE (like a temp table)
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(FLOAT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM
	PortfolioProject..CovidDeaths2 AS dea
JOIN PortfolioProject..CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
)

SELECT
	*,
	(rolling_people_vaccinated/population)*100 AS percent_vaccinated
FROM
	PopvsVac



-- temp table (does the same as the above)
DROP TABLE IF EXISTS #PercentPopulationVaccinated --deletes the temp table if you want to edit it
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(FLOAT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM
	PortfolioProject..CovidDeaths2 AS dea
JOIN PortfolioProject..CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE
--	dea.continent IS NOT NULL

SELECT
	*,
	(rolling_people_vaccinated/population)*100 AS Percent_Vaccinated
FROM
	#PercentPopulationVaccinated



-- create a view to store for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(FLOAT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM
	PortfolioProject..CovidDeaths2 AS dea
JOIN PortfolioProject..CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
)

SELECT
	*,
	(rolling_people_vaccinated/population)*100 AS percent_vaccinated
FROM
	PopvsVac


-- check view
SELECT
	*
FROM
	PercentPopulationVaccinated
