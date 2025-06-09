use saasdataset;

CREATE TABLE tech_companies (
    company_name VARCHAR(100),
    founded_year INT,
    hq VARCHAR(100),
    industry VARCHAR(100),
    total_funding VARCHAR(50),
    arr VARCHAR(50),
    valuation VARCHAR(50),
    employees VARCHAR(20),
    top_investors TEXT,
    product TEXT,
    g2_rating DECIMAL(2,1)
);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/top_100_saas_companies_2025.csv'
INTO TABLE tech_companies
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from tech_companies;



-- Average valuation per industry
SELECT 
    industry, 
    AVG(CAST(REPLACE(REPLACE(valuation, '$', ''), 'B', '') AS DECIMAL(10,2))) AS avg_valuation_in_billion
FROM tech_companies
GROUP BY industry
ORDER BY avg_valuation_in_billion DESC;

-- Count companies by HQ location
SELECT 
    hq, COUNT(*) AS company_count
FROM tech_companies
GROUP BY hq
ORDER BY company_count DESC;


-- Funding vs. Valuation correlation (clean B and M into numeric)
SELECT 
    company_name,
    REPLACE(REPLACE(total_funding, '$', ''), 'B', '') AS funding_billion,
    REPLACE(REPLACE(valuation, '$', ''), 'B', '') AS valuation_billion
FROM tech_companies
WHERE total_funding LIKE '%B%' AND valuation LIKE '%B%';


-- Compare top 5 companies in CRM by G2 rating
SELECT 
    company_name, g2_rating, arr, valuation
FROM tech_companies
WHERE industry LIKE '%CRM%'
ORDER BY g2_rating DESC;



-- Companies founded before 2000 with $1B+ valuation
SELECT 
    company_name, founded_year, valuation
FROM tech_companies
WHERE founded_year < 2000
  AND valuation LIKE '$%B'
ORDER BY founded_year;


-- What do companies with high G2 ratings (≥4.6) have in common
SELECT 
    company_name, industry, g2_rating, total_funding, employees
FROM tech_companies
WHERE g2_rating >= 4.6
ORDER BY g2_rating DESC;




