


-- Analyze Users					

-- 1. Which language do they use?	

SELECT language,COUNT(DISTINCT(location)) AS countries
FROM tutorial.yammer_users AS users
LEFT JOIN tutorial.yammer_events AS events
USING(user_id)
GROUP BY language
ORDER BY countries DESC;


-- 2. How many companies are in the database?	

SELECT COUNT(DISTINCT(company_id)) AS num_of_companies_in_db
FROM tutorial.yammer_users AS users
ORDER BY num_of_companies_in_db DESC;




-- 3. Which is the company with the most users?

SELECT company_id,
COUNT(user_id) AS num_of_users_per_company, 
SUM(CASE WHEN state='active' THEN 1 ELSE 0 END) AS active_users,
SUM(CASE WHEN state='pending' THEN 1 ELSE 0 END) AS pending_users
FROM tutorial.yammer_users AS users
WHERE state IS NOT NULL
GROUP BY company_id
ORDER BY num_of_users_per_company DESC
LIMIT 10;






-- Analyze Events	

-- 1. From which location are most of the events?	


SELECT location,
COUNT(event_type) AS interactions
FROM tutorial.yammer_events AS events
GROUP BY location
ORDER BY interactions DESC
LIMIT 10;



-- 2. Which are the most frequent events?	

SELECT event_name,
COUNT(event_name) As action_count
FROM tutorial.yammer_events AS events
GROUP BY event_name
ORDER BY action_count DESC;



-- 3. Which devices are used?

SELECT DISTINCT(device)
FROM tutorial.yammer_events AS events
ORDER BY device ASC;



-- 4. How many events are there per day?

SELECT DISTINCT day_of_week,
CASE 
WHEN subquery.day_of_week=0 THEN 'Sunday'
WHEN subquery.day_of_week=1 THEN 'Monday'
WHEN subquery.day_of_week=2 THEN 'Tuesday'
WHEN subquery.day_of_week=3 THEN 'Wednesday'
WHEN subquery.day_of_week=4 THEN 'Thursday'
WHEN subquery.day_of_week=5 THEN 'Friday'
WHEN subquery.day_of_week=6 THEN 'Saturday'
END AS day,
COUNT(event_name) AS interactions
FROM
(
SELECT occurred_at,
        EXTRACT(DOW FROM occurred_at) AS day_of_week,
        event_name
FROM tutorial.yammer_events
) AS subquery
GROUP BY day_of_week
ORDER BY interactions DESC;



-- 5. Create a chart for the events per day

SELECT DISTINCT day_of_week,
CASE 
WHEN subquery.day_of_week=0 THEN 'Sunday'
WHEN subquery.day_of_week=1 THEN 'Monday'
WHEN subquery.day_of_week=2 THEN 'Tuesday'
WHEN subquery.day_of_week=3 THEN 'Wednesday'
WHEN subquery.day_of_week=4 THEN 'Thursday'
WHEN subquery.day_of_week=5 THEN 'Friday'
WHEN subquery.day_of_week=6 THEN 'Saturday'
END AS day,
COUNT(event_name) AS interactions
FROM
(
SELECT occurred_at,
        EXTRACT(DOW FROM occurred_at) AS day_of_week,
        event_name
FROM tutorial.yammer_events
) AS subquery
GROUP BY day_of_week
ORDER BY interactions DESC;




			
-- Analyze Users and Events

-- 1. Which company has the most logins?

SELECT sub.company_id, 
 sub.login_count
FROM (
    SELECT company_id,
           SUM(CASE WHEN event_name = 'login' THEN 1 ELSE 0 END) AS login_count
    FROM tutorial.yammer_users AS users
    LEFT JOIN tutorial.yammer_events AS events
    USING(user_id)
    GROUP BY company_id
) AS sub
WHERE sub.login_count = (
    SELECT MAX(login_count) 
    FROM (
        SELECT company_id, 
               SUM(CASE WHEN event_name = 'login' THEN 1 ELSE 0 END) AS login_count 
        FROM tutorial.yammer_users AS users 
        LEFT JOIN tutorial.yammer_events AS events 
        USING(user_id) 
        GROUP BY company_id
    ) AS max_sub
)
ORDER BY sub.login_count DESC;
*
-For me this was tricky because I tried to use the max() on 
Sub.login_count in the bigger SELECT but always returned a 
list of login count for each company.

-Of Course I was able to select the max(login_count) value itself
without the company name as MAX() With no GROUP BY 
returns one row. But then, how would we know which 
Company is this.

-Finally i figured that i have to get the max(login_count)in a separate nested query. 
*e
How many interactions are there daily via mobile devices?
SELECT
CASE 
WHEN subquery.day_of_week=0 THEN 'Sunday'
WHEN subquery.day_of_week=1 THEN 'Monday'
WHEN subquery.day_of_week=2 THEN 'Tuesday'
WHEN subquery.day_of_week=3 THEN 'Wednesday'
WHEN subquery.day_of_week=4 THEN 'Thursday'
WHEN subquery.day_of_week=5 THEN 'Friday'
WHEN subquery.day_of_week=6 THEN 'Saturday'
END AS day,
COUNT(event_type)
FROM
(
SELECT occurred_at,
        device,event_type,
        EXTRACT(DOW FROM occurred_at) AS day_of_week,
        event_name
FROM tutorial.yammer_events
WHERE NOT device ILIKE ANY(ARRAY['%desktop%','%chrom%book','%thinkpad%','%macbook%',
'%mac%','%notebook%','%windows%'])
) AS subquery
GROUP BY day,subquery.day_of_week
ORDER BY subquery.day_of_week ASC;




-- 2. What is interesting to you?
				
-- Problem:
-- To investigate why there is a drop in user engagement.


-- [STEP 1] Visualizing the drop in users per month to detect when interactions started to drop 

SELECT DATE_TRUNC('month',occurred_at) AS month,
    count(event_type) AS interactions
    FROM tutorial.yammer_events AS events
    WHERE event_type='engagement'
    GROUP BY month
    ORDER BY month ASC;

-- We can notice that the drop happened in August


-- [STEP 2] Investigate the location to know in which country/countries caused that drop


SELECT location,
COUNT(event_name)   AS event_count
FROM tutorial.yammer_events AS events
WHERE event_type='engagement'
GROUP BY location
ORDER BY event_count DESC
 LIMIT 10;


SELECT 
   location,
   COUNT(event_name)   AS event_count
   FROM tutorial.yammer_events AS events
   WHERE event_type='engagement' 
   AND  occurred_at >= '2014-05-1'
   AND occurred_at <= '2014-7-31'
  GROUP BY location
  ORDER BY event_count DESC
  LIMIT 10;


-- Results show that United States has the most interactions in this data set, so The investigation moves towards finding the reasons interactions drop in USA in August




