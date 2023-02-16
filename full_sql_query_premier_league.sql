/* 
Premier League 2021/22 data preparation

Skills used:
aggregate functions
joins
unions
subqueries
table creation, removal, and editing
data insertion
window functions
CTEs
CASE WHEN functions

NOTE FOR READER:
-- has been used for standard commenting
/* */ has been used to highlight when each of the above tools is used for the first time
*/


-- Table One: results_sorted

-- Splitting each game into two rows with home and away team each getting distinct row

/* 
	using use DROP TABLE IF EXISTS to remove 'results_sorted' table in case this script has been run before
	using UNION ALL to give home and away teams for each game own row
	renaming columns for clarity
	using INTO to put results of query into table 'results_sorted'
*/

DROP TABLE IF EXISTS results_sorted

SELECT date,
home_team AS team,
home_score AS goals_scored,
away_score AS goals_conceded,
'home' AS home_away
INTO results_sorted
FROM PremierLeague2021_22.dbo.results AS home
UNION ALL 
SELECT date,
away_team AS team,
away_score AS goals_scored,
home_score AS goals_conceded,
'away' AS home_away
FROM PremierLeague2021_22.dbo.results AS away;


-- Table Two: 'running_totals'

-- Creating 'running_totals' table to give each teams cumulative results as season progresses 

/*	
	using CASE WHEN to add 'result' and 'match_points' columns
	using subquery in FROM clause to select from here for 'running_totals'
	using window functions to calculate running totals for key metrics;
		SUM() to calculate running points and goals totals
		COUNT() to calculate game numbers for each team
*/

DROP TABLE IF EXISTS running_totals

SELECT *,
SUM(match_points) OVER(PARTITION BY team ORDER BY date) AS running_points_total,
SUM(match_points) OVER(PARTITION BY team, home_away ORDER BY date) AS running_home_away_points,
COUNT(team) OVER(PARTITION BY team ORDER BY date) AS game_number,
COUNT(team) OVER(PARTITION BY team, home_away ORDER BY date) AS home_away_game_number,
SUM(goals_scored) OVER(PARTITION BY team ORDER BY date) AS running_scored_total,
SUM(goals_scored) OVER(PARTITION BY team, home_away ORDER BY date) AS home_away_running_scored_total,
SUM(goals_conceded) OVER(PARTITION BY team ORDER BY date) AS running_conceded_total,
SUM(goals_conceded) OVER(PARTITION BY team, home_away ORDER BY date) AS home_away_running_conceded_total
INTO running_totals
FROM 
(SELECT *,
CASE WHEN goals_scored > goals_conceded THEN 'Win' 
WHEN goals_scored < goals_conceded THEN 'Loss'
WHEN goals_scored = goals_conceded THEN 'Draw'
ELSE NULL END AS result, 
CASE WHEN goals_scored > goals_conceded THEN 3 
WHEN goals_scored < goals_conceded THEN 0
WHEN goals_scored = goals_conceded THEN 1
ELSE NULL END AS match_points
FROM PremierLeague2021_22.dbo.results_sorted) as results
ORDER BY date, team;


-- Table Three: 'running_league_positions'

-- Creating 'running_league_positions' table to give each teams actual positon in the league after x amount of games, and...
-- ... where they would be based soley off of home or away performances

/*
	using RANK() window function to show current position at each point in the season
*/


DROP TABLE IF EXISTS running_totals

SELECT *,
RANK() OVER(PARTITION BY game_number ORDER BY running_points_total DESC, running_scored_total - running_conceded_total DESC) as league_position,
running_scored_total - running_conceded_total as goal_difference,
RANK() OVER(PARTITION BY home_away, home_away_game_number ORDER BY running_home_away_points DESC, home_away_running_scored_total - home_away_running_conceded_total DESC) AS home_away_league_position,
home_away_running_scored_total - home_away_running_conceded_total AS home_away_goal_difference
INTO running_league_positions
FROM PremierLeague2021_22.dbo.running_totals;


-- Table Four: 'summary'

-- Changing Column Types in 'running_totals' for calculating averages

/*
	using ALTER TABLE 
		  ALTER COLUMN to change required columns to FLOAT(1) data type
*/

ALTER TABLE PremierLeague2021_22.dbo.running_totals 
ALTER COLUMN match_points FLOAT(1)

ALTER TABLE PremierLeague2021_22.dbo.running_totals 
ALTER COLUMN goals_scored FLOAT(1)

ALTER TABLE PremierLeague2021_22.dbo.running_totals 
ALTER COLUMN goals_conceded FLOAT(1)
 
-- creating 'home', 'away', and 'total' CTEs with summary stats for the entire season in each category

/*
	using CTEs to creat 'home', 'away', and 'total' tables to use for summary stats
	using AVG() to create season averages
	using ROUND() to round averages to make results more readable 
*/

WITH home AS
(SELECT team as hometeam,
SUM(match_points) AS total_home_points,
ROUND(AVG(match_points),2) AS avg_home_points,
SUM(goals_scored) AS total_home_goals,
ROUND(AVG(goals_scored),2) AS avg_home_goals,
SUM(goals_conceded) AS total_home_conceded,
ROUND(AVG(goals_conceded),2) AS avg_home_conceded,
SUM(goals_scored) - SUM(goals_conceded) AS total_home_gd,
ROUND(AVG(goals_scored) - AVG(goals_conceded),2) AS avg_home_gd
FROM PremierLeague2021_22.dbo.running_totals
WHERE home_away = 'home'
GROUP BY team),

away AS
(SELECT team as awayteam,
SUM(match_points) AS total_away_points,
ROUND(AVG(match_points),2) AS avg_away_points,
SUM(goals_scored) AS total_away_goals,
ROUND(AVG(goals_scored),2) AS avg_away_goals,
SUM(goals_conceded) AS total_away_conceded,
ROUND(AVG(goals_conceded),2) AS avg_away_conceded,
SUM(goals_scored) - SUM(goals_conceded) AS total_away_gd,
ROUND(AVG(goals_scored) - AVG(goals_conceded),2) AS avg_away_gd
FROM PremierLeague2021_22.dbo.running_totals
WHERE home_away = 'away'
GROUP BY team),

total AS
(SELECT team,
SUM(match_points) AS total_points,
ROUND(AVG(match_points),2) AS avg_points,
SUM(goals_scored) AS total_goals,
ROUND(AVG(goals_scored),2) AS avg_goals,
SUM(goals_conceded) AS total_conceded,
ROUND(AVG(goals_conceded),2) AS avg_conceded,
SUM(goals_scored) - SUM(goals_conceded) AS total_gd,
ROUND(AVG(goals_scored) - AVG(goals_conceded),2) AS avg_gd
FROM PremierLeague2021_22.dbo.running_totals
GROUP BY team)

-- Create 'summary' table using CTEs 

/* 
	using LEFT JOIN to join CTEs together
*/

DROP TABLE IF EXISTS summary

SELECT *
INTO summary
FROM total
LEFT JOIN home
ON total.team = home.hometeam
LEFT JOIN away
ON total.team = away.awayteam

-- Delete redundant team columns

/* 
	using ALTER TABLE
		  DROP COLUMN to remove redundant columns
*/

ALTER TABLE PremierLeague2021_22.dbo.summary   
DROP COLUMN hometeam,
awayteam;

/* FOLLOWING WAS NOT USED TO CREATE FINAL TABLES AS INCLUDING GAME ZERO DID NOT IMPROVE VISUALISATIONS,
REDUCED EXAMPLE WITH ONLY ONE TEAM INCLUDED TO DEMONSTRATE INSERTING DATA */

-- Inserting game zero data to provide zero points for visualisations

/*
	using INSERT INTO
		  VALUES to add rows to already created table
*/

INSERT INTO PremierLeague2021_22.dbo.running_totals
(date,
 team,
 goals_scored,
 goals_conceded,
 home_away,
 result,
 match_points,
 running_points_total,
 running_home_away_points, 
 game_number,
 home_away_game_number,
 running_scored_total,
 home_away_running_scored_total,
 running_conceded_total,
 home_away_running_conceded_total)
VALUES
(2021-08-07,
 'Arsenal',
 0,
 0,
 'home',
 0,
 0,
 0,
 0,
 0,
 0,
 0,
 0,
 0,
 0);
