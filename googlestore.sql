use google_play_store1;

CREATE TABLE googleplaystore_typed (
  App             VARCHAR(200)     NOT NULL,
  Category        VARCHAR(20)      NOT NULL,
  Rating          DECIMAL(2,1)     NULL,
  Reviews         BIGINT           NOT NULL,
  Size_MB         DECIMAL(7,3)     NULL,
  Installs        BIGINT           NOT NULL,
  Type            VARCHAR(6)       NULL,
  Price           DECIMAL(6,2)     NOT NULL DEFAULT 0.00,
  ContentRating   VARCHAR(20)      NOT NULL,
  Genres          VARCHAR(50)      NOT NULL,
  LastUpdated     DATE             NOT NULL,
  CurrentVer      VARCHAR(50)      NULL,
  AndroidVer      VARCHAR(20)      NULL
);

-- Load & transform the CSV 
LOAD DATA INFILE 'googleplaystore.csv'
INTO TABLE googleplaystore_typed
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @App, @Category, @Rating, @Reviews, @Size, @Installs,
  @Type, @Price, @ContentRating, @Genres, @LastUpdated,
  @CurrentVer, @AndroidVer
)
SET
  App           = TRIM(@App),
  Category      = TRIM(@Category),

  -- Handle NaN or blank ratings
  Rating        = CASE 
                    WHEN TRIM(@Rating) = '' OR TRIM(LOWER(@Rating)) = 'nan' 
                    THEN NULL 
                    ELSE CAST(@Rating AS DECIMAL(2,1)) 
                  END,

  Reviews       = CAST(@Reviews AS UNSIGNED),

  -- Normalize "M"/"k" sizes, others → NULL
  Size_MB       = CASE
                    WHEN @Size LIKE '%M' THEN CAST(REPLACE(@Size,'M','') AS DECIMAL(7,3))
                    WHEN @Size LIKE '%k' THEN CAST(REPLACE(@Size,'k','') AS DECIMAL(7,3)) / 1024
                    ELSE NULL
                  END,

  -- Strip commas/plus and cast
  Installs      = CAST(
                    REPLACE(
                      REPLACE(@Installs,'+',''),
                    ',', '') 
                  AS UNSIGNED),

  Type          = NULLIF(TRIM(@Type), ''),

  -- Blank or 0 → 0.00, else strip $
  Price         = CASE
                    WHEN TRIM(@Price) = '' OR TRIM(@Price) = '0' 
                    THEN 0.00 
                    ELSE CAST(REPLACE(@Price,'$','') AS DECIMAL(6,2))
                  END,

  ContentRating = TRIM(@ContentRating),
  Genres        = TRIM(@Genres),

  -- Parse Month DD, YYYY
  LastUpdated   = STR_TO_DATE(@LastUpdated, '%M %e, %Y'),

  --  Varies with device or blank as NULL
    -- Replace NaN and Varies with device with NULL in CurrentVer
  CurrentVer    = CASE 
                    WHEN TRIM(LOWER(@CurrentVer)) IN ('', 'nan', 'varies with device') 
                    THEN NULL 
                    ELSE TRIM(@CurrentVer) 
                  END,
 --  Varies with device or blank as NULL
 -- Replace NaN and Varies with device with NULL in AndroidVer
AndroidVer = CASE 
               WHEN LOWER(REPLACE(REPLACE(REPLACE(TRIM(@AndroidVer), '\r', ''), '\n', ''), ' ', '')) = 'varieswithdevice'
                 OR TRIM(@AndroidVer) = ''
               THEN NULL
               ELSE TRIM(@AndroidVer)
             END;

                  
                  
show warnings;

UPDATE googleplaystore_typed
SET Type = NULL
WHERE LOWER(TRIM(Type)) = 'nan';

                  
select * from googleplaystore_typed;

 -- Query for Dense Rank by Installs
SELECT 
  distinct App,
  Installs,
  DENSE_RANK() OVER (ORDER BY Installs DESC) AS install_rank
FROM 
  googleplaystore_typed;



-- Check for duplicates
SELECT 
  COUNT(*) AS total_apps,
  COUNT(DISTINCT App) AS unique_apps,
  COUNT(*) - COUNT(DISTINCT App) AS duplicate_apps
FROM googleplaystore_typed;


-- which categories are most populated and perform well.
SELECT
  Category,
  COUNT(*)               AS app_count,
  ROUND(AVG(Rating), 2)  AS avg_rating,
  SUM(Installs)          AS total_installs
FROM googleplaystore_typed
GROUP BY Category
ORDER BY app_count DESC;



-- free vs Paid comparison grouped by Type
SELECT
  Type,
  COUNT(*)               AS app_count,
  ROUND(AVG(Rating), 2)  AS avg_rating,
  SUM(Installs)          AS total_installs,
  SUM(Reviews)           AS total_reviews
FROM googleplaystore_typed
GROUP BY Type;


-- genre combinations group by genre and order by total installs.
SELECT
  Genres,
  COUNT(*) AS app_count,
  AVG(Rating) AS avg_rating,
  SUM(Installs) AS total_installs
FROM googleplaystore_typed
GROUP BY Genres
ORDER BY total_installs DESC
LIMIT 15;

-- Tracks how average ratings and installs have changed over time based on the year
SELECT 
  YEAR(LastUpdated) AS update_year,
  ROUND(AVG(Rating), 2) AS avg_rating,
  AVG(Installs) AS avg_installs
FROM googleplaystore_typed
WHERE LastUpdated IS NOT NULL
GROUP BY update_year
ORDER BY update_year DESC;



-- age-based content ratings for the apps
SELECT 
  ContentRating,
  COUNT(*) AS app_count,
  ROUND(AVG(Rating), 2) AS avg_rating
FROM googleplaystore_typed
GROUP BY ContentRating;









