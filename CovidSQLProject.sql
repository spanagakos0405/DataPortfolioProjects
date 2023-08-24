Select
	*
From
	CovidDeaths$
order by 3, 4
;


--Select
--	*
--From
--	CovidVaccinations$
--order by 3, 4
--;

--Selecting data that will be used

Select
	d.Location
  , d.date
  , d.total_cases
  , d.new_cases
  , d.total_deaths
  , d.population
From
	[SQL PORTFOLIO]..CovidDeaths$ d
order by 1, 2
;

--Looking at Total Cases vs Total Deaths
--Shows the chance of dying from Covid
Select
	d.Location
  , d.date
  , d.total_cases
  , d.total_deaths
  , (d.total_deaths / d.total_cases) * 100 as Death_Percentage
From
	[SQL PORTFOLIO]..CovidDeaths$ d
order by 1, 2
;

--Checking specifically the US
Select
	d.Location
  , d.date
  , d.total_cases
  , d.total_deaths
  , (d.total_deaths / d.total_cases) * 100 as Death_Percentage
From
	[SQL PORTFOLIO]..CovidDeaths$ d
Where
	Location like '%states'
order by 1, 2
;

--Looking at Total Cases vs Population (US)
--Shows percentage of US population got Covid
Select
	d.Location
  , d.date
  , d.total_cases
  , d.Population
  , (d.total_cases / d.Population) * 100 as Death_Percentage
From
	[SQL PORTFOLIO]..CovidDeaths$ d
Where
	Location like '%states'
order by 1, 2
;

--Looking at countries with the highest infection rate (compared to population)
Select
	d.Location
  , d.Population
  , MAX(d.total_cases) as Total_Infection_Count
  , (MAX(d.total_cases) / d.Population) * 100 as Infection_Percentage
From
	[SQL PORTFOLIO]..CovidDeaths$ d
Group by
	Location, Population
order by Infection_Percentage desc
;

--Looking at the countries with the most deaths (per population)
Select
	d.Location
  , MAX(cast(d.total_deaths as bigint)) as Total_Death_Count
From
	[SQL PORTFOLIO]..CovidDeaths$ d
Where continent is not null
Group by
	Location
order by Total_Death_Count desc
;


--Using null and location to dial down on continents in location column 
Select
	d.location
  , MAX(cast(d.total_deaths as bigint)) as Total_Death_Count
From
	[SQL PORTFOLIO]..CovidDeaths$ d
Where continent is null
Group by
	location
order by Total_Death_Count desc
;

--Looking at continents with highest death count
Select
	d.continent
  , MAX(cast(d.total_deaths as bigint)) as Total_Death_Count
From
	[SQL PORTFOLIO]..CovidDeaths$ d
Where continent is not null
Group by
	continent
order by Total_Death_Count desc
;

--Global Numbers
Select
    d.date
  , SUM(d.new_cases) as total_new_cases_daily
  , SUM(cast(d.new_deaths as int)) as total_deaths_daily
  , (SUM(cast(d.new_deaths as int))/SUM(d.new_cases) * 100) as global_death_percentage_per_day
From
	[SQL PORTFOLIO]..CovidDeaths$ d
Where
	continent is not null
Group by
	date
order by 1, 2
;


--Checking out the vaccinations table
Select
	*
From 
	[SQL PORTFOLIO]..CovidVaccinations$
;

--Joining both Death and Vaccine tables (Looking at total vaccinations vs Population)
Select
	d.continent
  , d.location
  , d.date
  , d.population
  , v.new_vaccinations as new_vaccinations_per_day
  , SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location 
    Order by d.location, d.date) as rolling_people_vaccinated
  , 
From
	[SQL PORTFOLIO]..CovidDeaths$ d
	join [SQL PORTFOLIO]..CovidVaccinations$ v
		on d.location = v.location
		and d.date = v.date
Where
	d.continent is not null 
order by 2, 3
;

--Using CTE (Now can use rolling_people_vaccinated for calculations)
With PopVac 
	(Continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as 
(
Select
	d.continent
  , d.location
  , d.date
  , d.population
  , v.new_vaccinations as new_vaccinations_per_day
  , SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location 
    Order by d.location, d.date) as rolling_people_vaccinated
From
	[SQL PORTFOLIO]..CovidDeaths$ d
	join [SQL PORTFOLIO]..CovidVaccinations$ v
		on d.location = v.location
		and d.date = v.date
Where
	d.continent is not null 
--order by 2, 3
)
Select
	*
  , (rolling_people_vaccinated/population)*100
From
	PopVac
;

--Using a temp table
DROP Table if exists #Percent_Population_Vaccinated
Create Table #Percent_Population_Vaccinated (
	Continent nvarchar(255)
  , Location nvarchar(255)
  , date datetime
  , Population numeric
  , New_Vaccinations bigint
  , Rolling_People_Vaccinated bigint
)

Insert into #Percent_Population_Vaccinated
Select
	d.continent
  , d.location
  , d.date
  , d.population
  , v.new_vaccinations as new_vaccinations_per_day
  , SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location 
    Order by d.location, d.date) as rolling_people_vaccinated
From
	[SQL PORTFOLIO]..CovidDeaths$ d
	join [SQL PORTFOLIO]..CovidVaccinations$ v
		on d.location = v.location
		and d.date = v.date
Where
	d.continent is not null 
--order by 2, 3

Select
	*
  , (rolling_people_vaccinated/population)*100
From
	#Percent_Population_Vaccinated
;


--Creating a view to store data for future visualizations
Create View Percent_Population_Vaccinated as  
Select
	d.continent
  , d.location
  , d.date
  , d.population
  , v.new_vaccinations as new_vaccinations_per_day
  , SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location 
    Order by d.location, d.date) as rolling_people_vaccinated
From
	[SQL PORTFOLIO]..CovidDeaths$ d
	join [SQL PORTFOLIO]..CovidVaccinations$ v
		on d.location = v.location
		and d.date = v.date
Where
	d.continent is not null 
--order by 2, 3

