-- Changing Column Types in table for future use

/*
ALTER TABLE PremierLeague2021_22.dbo.running_totals 
ALTER COLUMN match_points FLOAT(1)

ALTER TABLE PremierLeague2021_22.dbo.running_totals 
ALTER COLUMN goals_scored FLOAT(1)

ALTER TABLE PremierLeague2021_22.dbo.running_totals 
ALTER COLUMN goals_conceded FLOAT(1)
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


--DROP TABLE IF EXISTS PremierLeague2021_22.dbo.summary

SELECT *
--INTO PremierLeague2021_22.dbo.summary
FROM total
LEFT JOIN home
ON total.team = home.hometeam
LEFT JOIN away
ON total.team = away.awayteam

--Delete redundant team columns

/*
ALTER TABLE PremierLeague2021_22.dbo.summary   
DROP COLUMN hometeam,
awayteam
*/




