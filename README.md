# Google_play_store_data_workbench
This project processes and analyzes the Google Play Store dataset using MySQL. It includes schema definition, data cleaning, error handling, and post-load analytics such as category performance, price sensitivity, content rating insights, and more.

---

## Dataset

Source: `googleplaystore.csv`

The dataset includes app metadata like name, category, rating, reviews, size, installs, type (Free/Paid), price, content rating, genres, update dates, and versions.

---

## Table Schema

```sql
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
```


## Data Load (with Cleaning)

Use LOAD DATA INFILE (assuming the file is in MySQL's configured secure file path like /var/lib/mysql-files/ or C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/):

``` sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/googleplaystore.csv'
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
  Rating        = CASE 
                    WHEN TRIM(@Rating) = '' OR LOWER(TRIM(@Rating)) = 'nan' 
                    THEN NULL 
                    ELSE CAST(@Rating AS DECIMAL(2,1)) 
                  END,
  Reviews       = CAST(@Reviews AS UNSIGNED),
  Size_MB       = CASE
                    WHEN @Size LIKE '%M' THEN CAST(REPLACE(@Size,'M','') AS DECIMAL(7,3))
                    WHEN @Size LIKE '%k' THEN CAST(REPLACE(@Size,'k','') AS DECIMAL(7,3)) / 1024
                    ELSE NULL
                  END,
  Installs      = CAST(REPLACE(REPLACE(@Installs,'+',''), ',', '') AS UNSIGNED),
  Type          = NULLIF(TRIM(@Type), ''),
  Price         = CASE
                    WHEN TRIM(@Price) = '' OR @Price = '0' 
                    THEN 0.00 
                    ELSE CAST(REPLACE(@Price,'$','') AS DECIMAL(6,2))
                  END,
  ContentRating = TRIM(@ContentRating),
  Genres        = TRIM(@Genres),
  LastUpdated   = STR_TO_DATE(@LastUpdated, '%M %e, %Y'),
  CurrentVer    = CASE 
                    WHEN TRIM(LOWER(@CurrentVer)) IN ('', 'varies with device', 'nan') 
                    THEN NULL 
                    ELSE TRIM(@CurrentVer) 
                  END,
  AndroidVer    = CASE 
                    WHEN TRIM(LOWER(@AndroidVer)) IN ('', 'varies with device') 
                    THEN NULL 
                    ELSE TRIM(@AndroidVer) 
                  END;
```



## Data Cleaning 
* Varies with device and blank values → converted to NULL

* Sizes in k and M normalized into MB

* Commas and + symbols removed from Installs

* $ removed from Price

* Invalid dates and ratings handled as NULL


## Key Insights Generated

### Top Apps by Install Count (Dense Rank)
Ranks apps by number of installs using `DENSE_RANK()` window function to identify top performers.

### Duplicate App Check
Detects duplicate entries by comparing total vs distinct `App` names.

### Top Performing Categories
Identifies the most saturated and high-performing categories by app count, average rating, and total installs.

### Free vs Paid App Comparison
Analyzes how Free and Paid apps differ in volume, ratings, installs, and review counts.

### Genre-Level Engagement
Highlights the top genres by total installs, app count, and average rating.

### Trends Over Time (Update Year)
Examines how app installs and ratings vary across years based on the `LastUpdated` date.

### Age-Based Content Ratings
Explores the distribution and average rating of apps grouped by `ContentRating` (e.g., Everyone, Teen).



## Aggrgations
* COUNT(*) by Category, Type, ContentRating

* AVG(Rating), AVG(Price), AVG(Size_MB)

* SUM(Installs) by Category, Genre, Type

* DENSE_RANK() on Installs for ranking

## Data Quality Checks
  ###Nullity Check: % NULLs in fields like Rating, Size_MB, etc.

  ###Duplicate Detection: App as the key; count and remove duplicates

