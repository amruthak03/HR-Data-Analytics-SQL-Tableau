CREATE DATABASE hr_analytics;
USE hr_analytics;
SELECT COUNT(*) FROM hr;	#22,214
SELECT * FROM hr;

# Data Cleaning and analysis
#changing the id column name to emp_id
ALTER TABLE hr CHANGE COLUMN id emp_id VARCHAR(20) NULL;

#checking the data types of all the columns
DESCRIBE hr;

#since the all datecolumns doen't have consistent format and are text type. So converting them to a proper date column
UPDATE hr SET birthdate = CASE
    WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
    END;
#ow changing the data type of birthdate column to date as they're still in text type
ALTER TABLE hr MODIFY COLUMN birthdate DATE;

#same for the hire_date column as well
 UPDATE hr SET hire_date = CASE
    WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
    END;

ALTER TABLE hr MODIFY COLUMN hire_date DATE;

#changing term date as well
UPDATE hr SET termdate = date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate != '';
# having null values where termdate is not available or empyt
UPDATE hr SET termdate = NULL WHERE termdate = '';
ALTER TABLE hr MODIFY COLUMN termdate DATE;

#adding age column to the dataset - feature engineering
ALTER TABLE hr ADD COLUMN age INT;
UPDATE hr SET age = timestampdiff(YEAR, birthdate, curdate());
#min and max of age
SELECT MIN(age) AS youngest, 
	MAX(age) AS oldest
    FROM hr;

#younest is -45 which is not ideal
SELECT COUNT(*) FROM hr WHERE age < 18;
# we're going to exclude these (967) from our analysis since it's an employee data and people below 18 working is not an ideal case

-- Questions:
-- 1. What is the gender breakdown of employees in the company?
SELECT gender, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY gender;

-- 2. What is the race/ethinicity breakdown of employees in the company?
SELECT race, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY race
ORDER BY COUNT(*) DESC;

-- 3. What is the age distribution of employees in the company?
SELECT
	MIN(age) AS youngest,
    MAX(age) AS oldest
FROM hr
WHERE age >= 18 AND termdate IS NULL;

SELECT 
	CASE
	WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65+'
	END AS age_group,
	COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY age_group
ORDER BY age_group;

# how the gender is distributed among the age groups
SELECT 
	CASE
	WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65+'
	END AS age_group,gender,
	COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- 4. How many employees work at headquarters versus remote locations
SELECT location, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY location;	

-- 5. What is the average length of employment for employees who have been terminated?
SELECT ROUND(AVG(year(termdate) - year(hire_date)), 0) AS avg_length_emp
FROM hr
WHERE age >= 18 AND termdate IS NOT NULL AND termdate <= curdate();

-- 6. How does gender distribution vary across departments and job titles?
SELECT department, jobtitle, gender, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY department, jobtitle, gender
ORDER BY department, jobtitle, gender;

SELECT department, gender, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY department, gender
ORDER BY department, gender;

-- 7. What is the distribution of jobtitles across the company?
SELECT jobtitle, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY jobtitle
ORDER BY jobtitle;

-- 8. Which department has the highest turnover/termination rate?
SELECT department, total_count, terminated_count, ROUND((terminated_count/total_count)*100, 2) AS termination_rate
FROM
(SELECT department,
count(*) AS total_count,
SUM(CASE WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1 ELSE 0 END) AS terminated_count
FROM hr
WHERE age >= 18
GROUP BY department) AS subquery
ORDER BY termination_rate DESC;

-- 9. What is the distribution of employees across locations by state?
SELECT location_state, COUNT(*) AS count
FROM hr
WHERE age >= 18 AND termdate IS NULL
GROUP BY location_state
ORDER BY count DESC;

-- 10. How has the company's employee count changed over time based on hire and term dates?
 SELECT year, hires, terminations, 
		hires - terminations AS net_change,
        ROUND((hires - terminations)/hires * 100, 2) AS net_change_percent
FROM(
	SELECT 
	YEAR(hire_date) AS year,
        COUNT(*) AS hires,
        SUM(CASE WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1 ELSE 0 END) AS terminations
        FROM hr
        WHERE age >= 18
        GROUP BY Year(hire_date)) AS subquery
ORDER BY year ASC;

-- 11. What is the tenure distribution for each department?
SELECT department, ROUND(avg(datediff(termdate, hire_date)/365),0) AS avg_tenure
FROM hr
WHERE termdate IS NOT NULL AND termdate <= curdate() AND age >= 18
GROUP BY department;
