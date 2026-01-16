-- First and foremost, we must create the database into which we plan to import the data either through the built-in import wizard or
-- (My preferred method) by executing LOAD DATA INFILE, I personally prefer this method as it offers more control over the import and column creation

CREATE DATABASE Aurelius_Commerce_Group_ACG;

-- We must specify in which database we are going to be working in, for the purpose of this project we will select the one created above

USE Aurelius_Commerce_Group_ACG;

-- Here we imported the data through the Wizard so that we may have the data as messy as possible, so that we may demonstrate everything through SQL
-- Ideally, we would first analyze the data in Excel and do some cleaning there before manually importing it into pre created rows in MySQL workbench
-- To summarize a manual import would look like the below:
-- CREATE TABLE `customer_statistics` (
-- `customer_id` INT,
--  `order_id` int DEFAULT NULL,
-- `order_date` DATE,
-- `delivery_date` DATE,
 -- `country` VARCHAR(25),
-- `customer_age` INT,
-- `gender` VARCHAR(10),
-- `product_category` VARCHAR(50),
-- `order_value` double DEFAULT NULL,
-- `support_channel` VARCHAR(225),
-- `support_response_time_hrs` double DEFAULT NULL,
-- `issue_resolved` VARCHAR(25),
-- `satisfaction_score_text` VARCHAR(25),
-- `nps_score` INT,
-- `customer_comments` VARCHAR(225),
-- `repeat_customer` VARCHAR(25) )

-- Now that we have our pre-created table, we will proceed with importing data into it as shown below:
 -- LOAD DATA INFILE 'customer_experience_messy_dataset.csv'
 -- INTO TABLE sale_statistics1
 -- FIELDS TERMINATED BY ','
 -- IGNORE 1 LINES;

-- We'll quickly rename the table for better readability 
ALTER TABLE customer_experience_messy_dataset
RENAME TO customer_statistics;

-- a quick select statement to see what we are working with, we also increased the number of lines so that we can view all the data as this dataset has 10.000 lines
SELECT *
FROM customer_statistics
LIMIT 0, 100000;

-- Before we begin working on the data it is best practice to never work on raw data, rather we will create a staging version which we will be working on, this way we have a lifeline to go back if it comes to data loss
-- First we must create an identical copy of the table imported
CREATE TABLE `customer_statistics_staging` (
  `customer_id` text,
  `order_id` int DEFAULT NULL,
  `order_date` text,
  `delivery_date` text,
  `country` text,
  `customer_age` text,
  `gender` text,
  `product_category` text,
  `order_value` double DEFAULT NULL,
  `support_channel` text,
  `support_response_time_hrs` double DEFAULT NULL,
  `issue_resolved` text,
  `satisfaction_score_text` text,
  `nps_score` text,
  `customer_comments` text,
  `repeat_customer` text
);

-- Then we will copy all of the data from the raw file to the staging table 

INSERT INTO customer_statistics_staging
SELECT *
FROM customer_statistics;

SELECT *
FROM customer_statistics_staging
LIMIT 0, 100000

-- After we have copied all the data into the staging table, we can finally start to manipulate the data, first off we will scan for duplicate entries and remove them.

WITH cleanse_duplicates AS (
SELECT 
*,
ROW_NUMBER () OVER(PARTITION BY order_id, order_date, delivery_date ORDER BY customer_id) AS ranking
FROM customer_statistics_staging
)
SELECT 
*
FROM cleanse_duplicates
WHERE ranking > 1

-- USING the CTE above we have found 56 hits, we have accomplished this by using the ROW_NUMBER window function, it will run through the data and add a ranking based on the number of duplicates
-- We can manipulate this ranking by creating a new table with an extra column named "Ranking" and insert this data into it, then using that column we can filter out the duplicates

CREATE TABLE `customer_statistics_staging2` (
  `customer_id` text,
  `order_id` int DEFAULT NULL,
  `order_date` text,
  `delivery_date` text,
  `country` text,
  `customer_age` text,
  `gender` text,
  `product_category` text,
  `order_value` double DEFAULT NULL,
  `support_channel` text,
  `support_response_time_hrs` double DEFAULT NULL,
  `issue_resolved` text,
  `satisfaction_score_text` text,
  `nps_score` text,
  `customer_comments` text,
  `repeat_customer` text,
  `ranking` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Inserting data pulled by our CTE into the new table

INSERT INTO customer_statistics_staging2
SELECT 
*,
ROW_NUMBER () OVER(PARTITION BY customer_id, order_date, delivery_date ORDER BY customer_id) AS ranking
FROM customer_statistics_staging;

-- Now we can easily pull the duplicate records

SELECT *
FROM customer_statistics_staging2
WHERE ranking > 1
LIMIT 0, 100000;

-- Removing duplicate entries (We always need to take measures to not delete data from the raw file, for this project we currently have 2 backups, the raw data and the previous staging table)

DELETE 
FROM customer_statistics_staging2
WHERE ranking > 1;

-- Moving on we will now find all Null values and handle them accordingly, we will see if we can use some of the data that we have to fill in the missing entries, 
-- This usually is the case with Numerical columns
SELECT 
*
FROM customer_statistics_staging2
WHERE delivery_date = '' 
OR  country = '' 
OR customer_age = ''
OR customer_age = ''
OR gender = ''
OR product_category = ''
OR order_value = ''
OR support_channel = ''
OR support_response_time_hrs = ''
OR issue_resolved = ''
OR satisfaction_score_text = ''
OR nps_score = ''
OR repeat_customer = ''
LIMIT 0, 100000;

-- We can see that there is a lot of empty fields and the vast amount is personal customer information which we cannot populate so we will proceed with updating these to strigs like 'Unknown'
-- We do this for better readability by non technical shareholders and for better standardization

SELECT
*
FROM customer_statistics_staging2
WHERE customer_age = 0
LIMIT 0, 10000;

UPDATE  customer_statistics_staging2
SET customer_age = NULL
WHERE customer_age = 'Unknown';
-- We unfortunately do not have any personal information like a first name which we can use to fill in some of the empty fields in the gender column

UPDATE  customer_statistics_staging2
SET gender = 'Unknown'
WHERE gender = '';


UPDATE  customer_statistics_staging2
SET customer_comments = 'No comment'
WHERE customer_comments = '';

UPDATE  customer_statistics_staging2
SET repeat_customer = 'Unkown'
WHERE repeat_customer = '';

-- Now we will move on to standardization, we will accomplish this by utilizing SELECT DISTINCT on each column that we plan to use, this way we can see all the unique values of each column

SELECT DISTINCT
customer_id 
FROM customer_statistics_staging2;

-- We can see that all customer_id entires are indeed unique, so it is already standardized, however we will remove the string as we want this column to be numeric only
UPDATE customer_statistics_staging2
SET customer_id = SUBSTRING(customer_id, 6);

-- In order to adjust the data type for the columns order_date and delivery_date we need to adjust the format to the default for MySQL which is the shortdate
-- There are a couple of ways to achieve this, for the purpose of this project we will be doing so by separating each column into 3(DD, MM, YY) and then combining them in the Format which suits us


SELECT
order_date,
SUBSTRING(order_date, 1, LOCATE('/', order_date)-1 ) AS order_month,
SUBSTRING(order_date, LOCATE('/', order_date)+1) AS order_day_year,
delivery_date,
SUBSTRING(delivery_date, 1, LOCATE('/', delivery_date)-1) AS delivery_month,
SUBSTRING(delivery_date, LOCATE('/', delivery_date)+1) AS delivery_day_year
FROM customer_statistics_staging2;

-- We have split the order and delivery dates into 2 columns each, one defines the month and the other one contains both the year and day, we now need to split those two

-- Adding columns to populate with the dates that we have split

ALTER TABLE customer_statistics_staging2
ADD COLUMN order_month VARCHAR(20);

ALTER TABLE customer_statistics_staging2
ADD COLUMN order_day_year VARCHAR(20);

ALTER TABLE customer_statistics_staging2
ADD COLUMN delivery_month VARCHAR(20);

ALTER TABLE customer_statistics_staging2
ADD COLUMN delivery_day_year VARCHAR(20);

UPDATE customer_statistics_staging2
SET order_month = SUBSTRING(order_date, 1, LOCATE('/', order_date)-1 );

UPDATE customer_statistics_staging2
SET order_day_year = SUBSTRING(order_date, LOCATE('/', order_date)+1);

UPDATE customer_statistics_staging2
SET delivery_month = SUBSTRING(delivery_date, 1, LOCATE('/', delivery_date)-1);

UPDATE customer_statistics_staging2
SET delivery_day_year = SUBSTRING(delivery_date, LOCATE('/', delivery_date)+1);

-- Splitting the day from the year into two individual columns

SELECT
order_date,
order_day_year,
SUBSTRING(order_day_year,1, LOCATE('/', order_day_year)-1) AS order_day,
SUBSTRING(order_day_year, LOCATE('/', order_day_year)+1) AS order_year,
delivery_date,
delivery_day_year,
SUBSTRING(delivery_day_year,1, LOCATE('/', delivery_day_year)-1) AS delivery_day,
SUBSTRING(delivery_day_year, LOCATE('/', delivery_day_year)+1) AS delivery_year
FROM customer_statistics_staging2;

ALTER TABLE customer_statistics_staging2
ADD COLUMN order_year VARCHAR(20);

ALTER TABLE customer_statistics_staging2
ADD COLUMN delivery_year VARCHAR(20);

UPDATE customer_statistics_staging2
SET order_year = SUBSTRING(order_day_year, LOCATE('/', order_day_year)+1);

UPDATE customer_statistics_staging2
SET delivery_year = SUBSTRING(delivery_day_year, LOCATE('/', delivery_day_year)+1);

ALTER TABLE customer_statistics_staging2
ADD COLUMN order_day VARCHAR(20);

ALTER TABLE customer_statistics_staging2
ADD COLUMN delivery_day VARCHAR(20);

UPDATE customer_statistics_staging2
SET order_day = SUBSTRING(order_day_year,1, LOCATE('/', order_day_year)-1);

UPDATE customer_statistics_staging2
SET delivery_day = SUBSTRING(delivery_day_year,1, LOCATE('/', delivery_day_year)-1);

SELECT *
FROM customer_statistics_staging2;

-- Now that we have our Year, Month and Day columns separated and ready, we will combine them into one colum with the data type of DATE

SELECT
order_date,
CONCAT(order_year,'/',order_day,'/',order_month) AS order_dates
FROM customer_statistics_staging2;

ALTER TABLE customer_statistics_staging2
ADD COLUMN order_dates DATE;

UPDATE customer_statistics_staging2
SET order_dates = TRIM(CONCAT(order_year,'-',order_month,'-',order_day));

ALTER TABLE customer_statistics_staging2
ADD COLUMN delivery_dates DATE;

UPDATE customer_statistics_staging2
SET delivery_dates = TRIM(CONCAT(delivery_year,'-',delivery_month,'-',delivery_day));

-- SELECTING the previous messy date and the clean one we created in order to compare and make sure it is correct

SELECT DISTINCT
order_dates,
delivery_dates,
delivery_date
FROM customer_statistics_staging2
ORDER BY 2;

SELECT *
FROM customer_statistics_staging2;

-- Checking the entries for Country and we can see that they are not standardized at all, for example for USA we have 3 entries (US, United States, USA)

SELECT DISTINCT
country
FROM customer_statistics_staging2;

UPDATE customer_statistics_staging2
SET country = 'United States'
WHERE country = 'US' OR country = 'USA';

UPDATE customer_statistics_staging2
SET country = 'Germany'
WHERE country = 'DE';

UPDATE customer_statistics_staging2
SET country = 'France'
WHERE country = 'FR';

-- The next column which requires adjusting is the Gender column, it has the same messy entries as the Country column
SELECT DISTINCT
gender
FROM customer_statistics_staging2;

UPDATE customer_statistics_staging2
SET gender = 'Male'
WHERE gender = 'M';

UPDATE customer_statistics_staging2
SET gender = 'Female'
WHERE gender = 'F';

-- We will now go through the rest of the columns and adjust accordingly 

SELECT DISTINCT
issue_resolved
FROM customer_statistics_staging2

UPDATE customer_statistics_staging2
SET issue_resolved = 'No'
WHERE issue_resolved = 'N';

UPDATE customer_statistics_staging2
SET issue_resolved = 'Yes'
WHERE issue_resolved = 'Y';

SELECT DISTINCT
satisfaction_score_text
FROM customer_statistics_staging2

UPDATE customer_statistics_staging2
SET satisfaction_score_text = 'Satisfied'
WHERE satisfaction_score_text ='100% satisfied'

UPDATE customer_statistics_staging2
SET satisfaction_score_text = 'Satisfied'
WHERE satisfaction_score_text ='Completely satisfied'

UPDATE customer_statistics_staging2
SET satisfaction_score_text = 'Very Satisfied'
WHERE satisfaction_score_text ='super satisfied'

-- Now we will adjust the DATA types for the columns as the data is now clean, we have already adjusted it for the newly created DATE columns

ALTER TABLE customer_statistics_staging2
CHANGE COLUMN `customer_id` `customer_id` INT NULL DEFAULT NULL ;

ALTER TABLE customer_statistics_staging2
CHANGE COLUMN `customer_age` `customer_age` INT NULL DEFAULT NULL ;


-- The last step is to drop all unnecessary columns, however before we do this, we will create a backup just in case

CREATE TABLE `customer_statistics_staging3` (
  `customer_id` int DEFAULT NULL,
  `order_id` int DEFAULT NULL,
  `order_date` text,
  `delivery_date` text,
  `country` text,
  `customer_age` int DEFAULT NULL,
  `gender` text,
  `product_category` text,
  `order_value` double DEFAULT NULL,
  `support_channel` text,
  `support_response_time_hrs` double DEFAULT NULL,
  `issue_resolved` text,
  `satisfaction_score_text` text,
  `nps_score` text,
  `customer_comments` text,
  `repeat_customer` text,
  `ranking` int DEFAULT NULL,
  `order_month` varchar(20) DEFAULT NULL,
  `order_day_year` varchar(20) DEFAULT NULL,
  `delivery_month` varchar(20) DEFAULT NULL,
  `delivery_day_year` varchar(20) DEFAULT NULL,
  `order_year` varchar(20) DEFAULT NULL,
  `delivery_year` varchar(20) DEFAULT NULL,
  `delivery_day` varchar(20) DEFAULT NULL,
  `order_day` varchar(20) DEFAULT NULL,
  `order_dates` date DEFAULT NULL,
  `delivery_dates` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO customer_statistics_staging3
SELECT *
FROM customer_statistics_staging2;

ALTER TABLE customer_statistics_staging3
DROP COLUMN order_date

ALTER TABLE customer_statistics_staging3
DROP COLUMN delivery_date

ALTER TABLE customer_statistics_staging3
DROP COLUMN order_day

ALTER TABLE customer_statistics_staging3
DROP COLUMN order_year

ALTER TABLE customer_statistics_staging3
DROP COLUMN order_day_year

ALTER TABLE customer_statistics_staging3
DROP COLUMN delivery_day

ALTER TABLE customer_statistics_staging3
DROP COLUMN delivery_year

ALTER TABLE customer_statistics_staging3
DROP COLUMN delivery_day_year

ALTER TABLE customer_statistics_staging3
DROP COLUMN delivery_month

ALTER TABLE customer_statistics_staging3
DROP COLUMN order_month

ALTER TABLE customer_statistics_staging3
DROP COLUMN ranking

-- One last thing would be to rename our re-created date columns and to check if the data is now ready

ALTER TABLE customer_statistics_staging3
RENAME COLUMN order_dates TO order_date

ALTER TABLE customer_statistics_staging3
RENAME COLUMN delivery_dates TO delivery_date

-- All is in order and the data is now ready to be used for analysis 

SELECT *
FROM customer_statistics_staging3
