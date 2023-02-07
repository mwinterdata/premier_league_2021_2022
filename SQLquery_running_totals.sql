WITH result
AS
(SELECT *,
CASE WHEN goals_scored > goals_conceded THEN 'Win' 
WHEN goals_scored < goals_conceded THEN 'Loss'
WHEN goals_scored = goals_conceded THEN 'Draw'
ELSE NULL END AS result, 
CASE WHEN goals_scored > goals_conceded THEN 3 
WHEN goals_scored < goals_conceded THEN 0
WHEN goals_scored = goals_conceded THEN 1
ELSE NULL END AS match_points
FROM PremierLeague2021_22.dbo.results_sorted)

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
FROM result
ORDER BY date,team
