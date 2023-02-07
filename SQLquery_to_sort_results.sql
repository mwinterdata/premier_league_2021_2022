
SELECT date,
home_team AS team,
home_score AS goals_scored,
away_score AS goals_conceded,
'home' AS home_away
INTO PremierLeague2021_22.dbo.results_sorted
FROM PremierLeague2021_22.dbo.results AS home
UNION ALL 
SELECT date,
away_team AS team,
away_score AS goals_scored,
home_score AS goals_conceded,
'away' AS home_away
FROM PremierLeague2021_22.dbo.results AS away

