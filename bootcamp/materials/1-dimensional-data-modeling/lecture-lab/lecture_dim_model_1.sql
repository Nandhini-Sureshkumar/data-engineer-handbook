SELECT
	*
FROM
	PUBLIC.PLAYER_SEASONS;
	
CREATE TYPE SEASON_STATS AS (
	SEASON INTEGER,
	GP INTEGER,
	PTS REAL,
	REB REAL,
	AST REAL
);

CREATE TYPE scoring_class as
ENUM('star','good','average','bad');

 --Drop table players;
CREATE TABLE PLAYERS (
	PLAYER_NAME TEXT,
	HEIGHT TEXT,
	COLLEGE TEXT,
	COUNTRY TEXT,
	DRAFT_YEAR TEXT,
	DRAFT_ROUND TEXT,
	DRAFT_NUMBER TEXT,
	SEASON_STATS SEASON_STATS[],
	scoring_class scoring_class, --added 2 more columns
	years_since_last_season INTEGER, --added 2 more columns
	CURRENT_SEASON INTEGER,
	PRIMARY KEY (PLAYER_NAME, CURRENT_SEASON)
)

--Select MIN(season ) from player_seasons
--delete from players;

INSERT INTO
	PLAYERS
WITH
	YESTERDAY AS (
		SELECT
			*
		FROM
			PLAYERS
		WHERE
			CURRENT_SEASON = 2000
	),
	TODAY AS (
		SELECT
			*
		FROM
			PLAYER_SEASONS
		WHERE
			SEASON = 2001
	)
SELECT
	COALESCE(T.PLAYER_NAME, Y.PLAYER_NAME) AS PLAYER_NAME,
	COALESCE(T.HEIGHT, Y.HEIGHT) AS HEIGHT,
	COALESCE(T.COLLEGE, Y.COLLEGE) AS COLLEGE,
	COALESCE(T.COUNTRY, Y.COUNTRY) AS COUNTRY,
	COALESCE(T.DRAFT_YEAR, Y.DRAFT_YEAR) AS DRAFT_YEAR,
	COALESCE(T.DRAFT_ROUND, Y.DRAFT_ROUND) AS DRAFT_ROUND,
	COALESCE(T.DRAFT_NUMBER, Y.DRAFT_NUMBER) AS DRAFT_NUMBER,
	CASE
		WHEN Y.SEASON_STATS IS NULL THEN ARRAY[
			ROW (T.SEASON, T.GP, T.PTS, T.REB, T.AST)::SEASON_STATS
		]
		WHEN T.SEASON IS NOT NULL THEN Y.SEASON_STATS || ARRAY[
			ROW (T.SEASON, T.GP, T.PTS, T.REB, T.AST)::SEASON_STATS
		]
		ELSE Y.SEASON_STATS
	END AS SEASON_STATS,
	CASE
		WHEN T.SEASON IS NOT NULL THEN 
		CASE
			WHEN T.PTS > 20 THEN 'star'
			WHEN T.PTS > 15 THEN 'good'
			WHEN T.PTS > 10 THEN 'average'
			ELSE 'bad'
		END::SCORING_CLASS
	ELSE Y.SCORING_CLASS
	END AS SCORING_CLASS,
	CASE
		WHEN T.SEASON IS NOT NULL THEN 0
		ELSE Y.YEARS_SINCE_LAST_SEASON + 1
	END AS YEARS_SINCE_LAST_SEASON, --- cummulation 
	COALESCE(T.SEASON, Y.CURRENT_SEASON + 1) AS CURRENT_SEASON
	-- case when t.season is not NULL then t.season
	-- else y.current_season +1
	-- end
FROM
	TODAY T
	FULL OUTER JOIN YESTERDAY Y ON Y.PLAYER_NAME = T.PLAYER_NAME;

Select * from players
where current_season = 2001;


Select *
from players
--where current_season = 2001
where player_name = 'Michael Jordan';

Select player_name,
UNNEST(season_stats) as season_stats
from players
where current_season = 2001
and player_name = 'Michael Jordan';

-- player from 1st season to the most reason season who has improved a lot.

select 
	player_name,
	(season_stats[cardinality(season_stats)]::season_stats).pts /
case when (season_stats[1]::season_stats).pts = 0 then 1
else (season_stats[1]::season_stats).pts end as percentage_diff
	from players
	where current_season = 2001
	and scoring_class = 'star'
	order by 2 desc	;



-- for all players
with unnested as (Select player_name,
UNNEST(season_stats) as season_stats
from players
)
select player_name,
	(season_stats::season_stats).*
	
	from unnested;
