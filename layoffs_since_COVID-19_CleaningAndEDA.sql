-- SQL Project - Data Cleaning and EDA for My Project

-- Select all records from the original layoffs table
SELECT * 
FROM my_project.layoffs;

-- Create a staging table to work on data cleaning. This keeps the raw data intact.
CREATE TABLE my_project.project_layoffs_staging 
LIKE my_project.layoffs;

INSERT INTO my_project.project_layoffs_staging 
SELECT * FROM my_project.layoffs;

-- 1. Remove Duplicates

-- Check for duplicates based on key columns
SELECT *
FROM my_project.project_layoffs_staging;

SELECT company, industry, total_laid_off, `date`,
       ROW_NUMBER() OVER (
           PARTITION BY company, industry, total_laid_off, `date`) AS row_num
FROM 
    my_project.project_layoffs_staging;

-- Identify duplicates
SELECT *
FROM (
    SELECT company, industry, total_laid_off, `date`,
           ROW_NUMBER() OVER (
               PARTITION BY company, industry, total_laid_off, `date`
           ) AS row_num
    FROM 
        my_project.project_layoffs_staging
) duplicates
WHERE 
    row_num > 1;

-- Confirm duplicates for a specific company
SELECT *
FROM my_project.project_layoffs_staging
WHERE company = 'Oda';

-- Identify real duplicates based on all columns
SELECT *
FROM (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
           ) AS row_num
    FROM 
        my_project.project_layoffs_staging
) duplicates
WHERE 
    row_num > 1;

-- Delete duplicates
WITH DELETE_CTE AS (
    SELECT *
    FROM (
        SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
               ROW_NUMBER() OVER (
                   PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
               ) AS row_num
        FROM 
            my_project.project_layoffs_staging
    ) duplicates
    WHERE 
        row_num > 1
)
DELETE
FROM DELETE_CTE
;

-- 2. Standardize Data

SELECT * 
FROM my_project.project_layoffs_staging;

-- Check for null or empty values in the industry column
SELECT DISTINCT industry
FROM my_project.project_layoffs_staging
ORDER BY industry;

SELECT *
FROM my_project.project_layoffs_staging
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- Update null or empty values in the industry column
UPDATE my_project.project_layoffs_staging
SET industry = NULL
WHERE industry = '';

-- Populate null industry values based on other rows with the same company name
UPDATE my_project.project_layoffs_staging t1
JOIN my_project.project_layoffs_staging t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Standardize industry values
UPDATE my_project.project_layoffs_staging
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Standardize country values
UPDATE my_project.project_layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);

-- Fix date columns
UPDATE my_project.project_layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Convert the data type properly
ALTER TABLE my_project.project_layoffs_staging
MODIFY COLUMN `date` DATE;

-- 3. Look at Null Values

-- The null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. I don't think I want to change that
-- I like having them null because it makes it easier for calculations during the EDA phase

-- so there isn't anything I want to change with the null values

-- 4. Remove any columns and rows we need to

SELECT *
FROM my_project.project_layoffs_staging
WHERE total_laid_off IS NULL;

SELECT *
FROM my_project.project_layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use
DELETE FROM my_project.project_layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM my_project.project_layoffs_staging;

ALTER TABLE my_project.project_layoffs_staging
DROP COLUMN row_num;

SELECT * 
FROM my_project.project_layoffs_staging;

-- EDA

SELECT * 
FROM my_project.project_layoffs_staging;

-- Looking at Percentage to see how big these layoffs were
SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM my_project.project_layoffs_staging
WHERE  percentage_laid_off IS NOT NULL;

-- Which companies had 1 which is basically 100 percent of they company laid off
SELECT *
FROM my_project.project_layoffs_staging
WHERE  percentage_laid_off = 1;

-- if we order by funcs_raised_millions we can see how big some of these companies were
SELECT *
FROM my_project.project_layoffs_staging
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Companies with the biggest single Layoff

SELECT company, total_laid_off
FROM my_project.project_layoffs_staging
ORDER BY 2 DESC
LIMIT 5;

-- now that's just on a single day

-- Companies with the most Total Layoffs
SELECT company, SUM(total_laid_off)
FROM my_project.project_layoffs_staging
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;

-- by location
SELECT location, SUM(total_laid_off)
FROM my_project.project_layoffs_staging
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- this it total in the past 3 years or in the dataset

SELECT country, SUM(total_laid_off)
FROM my_project.project_layoffs_staging
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(date), SUM(total_laid_off)
FROM my_project.project_layoffs_staging
GROUP BY YEAR(date)
ORDER BY 1 ASC;

SELECT industry, SUM(total_laid_off)
FROM my_project.project_layoffs_staging
GROUP BY industry
ORDER BY 2 DESC;

SELECT stage, SUM(total_laid_off)
FROM my_project.project_layoffs_staging
GROUP BY stage
ORDER BY 2 DESC;

-- Earlier we looked at Companies with the most Layoffs. Now let's look at that per year. It's a little more difficult.
-- I want to look at 

WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM my_project.project_layoffs_staging
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;

-- Rolling Total of Layoffs Per Month
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM my_project.project_layoffs_staging
GROUP BY dates
ORDER BY dates ASC;

-- now use it in a CTE so we can query off of it
WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM my_project.project_layoffs_staging
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;