
SELECT *,
RANK() OVER(PARTITION BY game_number ORDER BY running_points_total DESC, running_scored_total - running_conceded_total DESC) as league_position,
running_scored_total - running_conceded_total as goal_difference,
RANK() OVER(PARTITION BY home_away, home_away_game_number ORDER BY running_home_away_points DESC, home_away_running_scored_total - home_away_running_conceded_total DESC) AS home_away_league_position,
home_away_running_scored_total - home_away_running_conceded_total AS home_away_goal_difference
INTO running_league_positions
FROM PremierLeague2021_22.dbo.running_totals
