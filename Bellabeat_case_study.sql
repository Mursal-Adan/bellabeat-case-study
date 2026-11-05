-- set up

CREATE DATABASE bellabeat;
USE bellabeat;
SET GLOBAL local_infile = 1;

-- Inserting tables
CREATE TABLE daily_activity (
    Id BIGINT,
    Activity_Date DATE,
    Total_Steps INT,
    Total_Distance DOUBLE,
    Tracker_Distance DOUBLE,
	Logged_Activities_Distance DOUBLE,
	Very_Active_Distance DOUBLE,
	Moderately_Active_Distance DOUBLE,
	Light_Active_Distance DOUBLE,
	Sedentary_Active_Distance DOUBLE,
	Very_Active_Minutes INT,
	Fairly_Active_Minutes INT,
	Lightly_Active_Minutes	INT,
    Sedentary_Minutes INT,
	Calories INT,
	likely_not_worn	BOOL,
    zero_steps_flag BOOL

);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/daily_activity_clean.csv'
INTO TABLE daily_activity
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Id, Activity_Date, Total_Steps, Total_Distance, Tracker_Distance,	Logged_Activities_Distance,	Very_Active_Distance,
	Moderately_Active_Distance,	Light_Active_Distance,	Sedentary_Active_Distance,	Very_Active_Minutes, Fairly_Active_Minutes,
	Lightly_Active_Minutes,	Sedentary_Minutes, Calories, @likely, @zero)
SET likely_not_worn = (@likely = 'True'),
    zero_steps_flag = (@zero = 'True');

SELECT *
from daily_activity
limit 3;

CREATE TABLE sleep_day (
    Id BIGINT,
    Sleep_Day DATE,
    Total_Sleep_Records INT,
	Total_Minutes_Asleep INT,
	Total_Time_In_Bed INT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sleep_day_clean.csv'
INTO TABLE sleep_day
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Id, Sleep_Day,	Total_Sleep_Records, Total_Minutes_Asleep, Total_Time_In_Bed);

TRUNCATE TABLE sleep_day;
-- 	Analysis
-- a descriptive summary of daily usage

SELECT COUNT(DISTINCT(id)) AS Unique_Id
FROM daily_activity;

SELECT COUNT(*) FROM daily_activity WHERE likely_not_worn = 0;

SELECT ROUND(AVG(Total_Steps),1) AS Avg_steps, 
		ROUND(AVG(Calories),1) AS Avg_calories, 
		ROUND(AVG(Sedentary_Minutes),1) AS avg_sedentary_minutes
FROM daily_activity
WHERE likely_not_worn = 0;

SELECT SUM(Total_Steps >= 10000) / COUNT(*) AS share_of_days
FROM daily_activity
WHERE likely_not_worn = 0;

-- ## Users are sedentary for about 66% of the day, which includes sleep. They average about 8,000 steps a day, and about one third of days reach 10,000. This shows moderate movement, but the data cannot show whether it is “enough.”##

-- steps by day of the week

SELECT DAYOFWEEK(Activity_Date) AS day_num,
       DAYNAME(Activity_Date) AS day_name,
       ROUND(AVG(Total_Steps), 1) AS avg_steps,
       COUNT(*) AS days_count
FROM daily_activity
WHERE likely_not_worn = 0
GROUP BY day_name, day_num
ORDER BY day_num;

-- ##Average steps are fairly steady across the week. Saturday is highest (8,523) and Sunday lowest (7,371), a difference of about 1,150 steps. With 35 users and about 170 to 200 days per weekday, this difference may be small relative to normal variation. Sunday could be a possible time for reminders, but more data is needed.##
--
SELECT ROUND(AVG(Lightly_Active_Minutes),1) AS avg_lightly_active_mins, 
		ROUND(AVG(Fairly_Active_Minutes),1) AS avg_fairly_active_mins,
        ROUND(AVG(Very_Active_Minutes),1) AS avg_very_active_mins,
        ROUND(AVG(Sedentary_Minutes),1) AS avg_sedentary_minutes
FROM daily_activity
WHERE likely_not_worn = 0;

-- ##On average, users spend about 949 minutes (about 66% of the day) sedentary. Light activity is about 204 minutes (14%), and fairly and very active time together is only 36 minutes (2.5%). Light activity is about 5.6 times larger than the fairly and very active time combined. About 252 minutes a day (4.2 hours) are not recorded in any category, and about 229 minutes remain unrecorded even when the likely-not-worn days are included. The reason is not known. Limits: averages only, 35 users, and 2016 data.##
-- activity and calories

SELECT
    CASE
        WHEN Total_Steps < 5000 THEN 'Low Steps'
        WHEN Total_Steps BETWEEN 5000 AND 9999 THEN 'Medium Steps'
        ELSE 'High Steps'
    END AS step_groups,
    ROUND(AVG(Calories), 1) AS avg_calories,
    COUNT(*) AS days_count
FROM daily_activity
WHERE likely_not_worn = 0
GROUP BY step_groups
ORDER BY avg_calories;

-- ## On average, daily calories rise as steps rise: about 1,810 for low-step days (under 5,000 steps), 2,379 for medium-step days, and 2,719 for high-step days (10,000 or more). This shows that steps and calories go together, but it does not prove that steps cause the extra calories. Other factors, such as body size and age, matter too, and the device only estimates calories. Group averages also mix different users. The sample is small (35 users over two months, in 2016), so the results should be treated carefully.##
-- sleep vs activity


 SELECT 
	CASE
        WHEN da.Total_Steps < 5000 THEN 'Low Steps'
        WHEN da.Total_Steps BETWEEN 5000 AND 9999 THEN 'Medium Steps'
        ELSE 'High Steps'
    END AS step_groups,
    ROUND(AVG(Total_Minutes_Asleep), 1) AS avg_min_sleep,
		count(*) AS days_count, count(DISTINCT(da.Id)) AS unique_id
 From daily_activity AS da
 INNER JOIN sleep_day AS sd
  ON da.Id = sd.Id
 AND da.Activity_Date = sd.Sleep_Day
 WHERE likely_not_worn = 0
 GROUP BY step_groups
 ORDER BY avg_min_sleep
;
SELECT Id, Activity_Date
FROM daily_activity
GROUP BY Id, Activity_Date HAVING COUNT(*) > 1;

SELECT COUNT(*) AS distinct_rows
FROM (SELECT DISTINCT * FROM daily_activity) AS t;

;


SELECT SUM(Total_Steps = 0) AS zero_step_rows,
       SUM(Total_Steps = 0 AND Sedentary_Minutes = 1440) AS likely_not_worn_rows
FROM daily_activity;

SET SQL_SAFE_UPDATES = 0;

UPDATE daily_activity
SET zero_steps_flag = (Total_Steps = 0),
    likely_not_worn = (Total_Steps = 0 AND Sedentary_Minutes = 1440);

SELECT SUM(zero_steps_flag) AS zero_step_rows,
       SUM(likely_not_worn) AS likely_not_worn_rows
FROM daily_activity;

 