-- Business questions:

-- Which support channels correlate with poor satisfaction?
-- Does response time actually impact CSAT—or is that assumed?
-- Are repeat customers more forgiving than first-time buyers?
-- Do delivery delays hurt NPS equally across product categories?
-- Which are high value customers and what is the risk of losing them?

-- Expected results from this project:


-- Customer Experience KPI Framework
-- Segmentation (high-value / high-risk customers)
-- Root-Cause Insights
-- Clear Recommendations
-- Process changes
-- SLA adjustments
-- CX investment priorities

SELECT *
FROM customer_statistics_staging3;

-- Which support channels correlate with poor satisfaction?

-- Now here we can look at the total scores segregated by support_channel and draw a conclusion, however we must understand deeper if the total score is leveraged by a large number of negative scores or 
-- a smaller number of worst possible scores, and for us to understand this we must define what categorizes as a negative review. As such for this purpose we will use the global standard:

-- 0-6 - Demoters,  Unhappy customers who can damage the brand through negative word-of-mouth.
-- 7-8 - Passives, Satisfied but unenthusiastic; vulnerable to competitor offers.
-- 9-10 - Promoters, Loyal, enthusiastic customers who will likely keep buying and refer others.

-- Range: -100 to +100.
-- Good Score: Above 0 is good, above 20 favorable, and above 50 excellent, according to Bain & Company.

SELECT 
support_channel,
ROUND(AVG(nps_score),2) AS average_score
FROM customer_statistics_staging3
GROUP BY support_channel
ORDER BY average_score;

-- Looking at the overall average we can see that the only channel that has a positive score is tickets logged over the phone, which is not by a large margin, 0.48
-- This does provide some insight on the overall situation, however we will dive deeper so that we may understand the overall numbers which are driving these results

WITH negative_num AS (

SELECT 
support_channel,
COUNT(nps_score) AS negative_count
FROM customer_statistics_staging3
WHERE nps_score < 0
GROUP BY support_channel
),
positive_num AS (
SELECT 
support_channel,
COUNT(nps_score) AS positive_count
FROM customer_statistics_staging3
WHERE nps_score > 0
GROUP BY support_channel
),
average_score AS (
SELECT 
support_channel,
ROUND(AVG(nps_score),2) AS average_nps_score
FROM customer_statistics_staging3
GROUP BY support_channel)

SELECT
nn.support_channel,
Negative_count,
positive_count,
average_nps_score
FROM negative_num nn
JOIN positive_num pn
	ON nn.support_channel = pn.support_channel
JOIN average_score avs
	ON nn.support_channel = avs.support_channel
ORDER BY 4 DESC;

-- Now we understand not only the utilization percentage of each support channel, we also understand the ratios for each of them, for example we can see that the built in App option to reach out to support is utilized the least
-- This is to be expected as customers are always more likely to reach out to a person for assistance and in most cases, these built-in app options include a bot which assists first before engaging an agent.
-- Now once we draw conclusions from this data we can do so with more clarity as we understand the data deeper, even though the In-App score is the lowest, we will hold other support channels in higher regard for the sole reason that they have double the users of the App

-- Does response time actually impact CSAT—or is that assumed?
-- Moving forward we will attempt to understand what is driving these numbers, from past experience we know that one of the main driving factors would be the response times

SELECT 
support_channel,
ROUND(AVG(support_response_time_hrs),2) * 60 AS avg_response_time_minutes,
ROUND(AVG(support_response_time_hrs),2) AS avg_response_time
FROM customer_statistics_staging3
GROUP BY support_channel
ORDER BY avg_response_time;

-- Running the same query to find the overall average segregated by channel we can see an interesting fact, the numbers line up for the Phone channel, however the App channel which has the lowest score, has the second best response time

WITH negative_score AS (
SELECT
support_channel,
COUNT(nps_score) AS negative_num,
ROUND(AVG(support_response_time_hrs),2) AS avg_negative_response_time,
MAX(support_response_time_hrs) longest_negative_response_time,
MIN(support_response_time_hrs) shortest_negative_response_time
FROM customer_statistics_staging3
WHERE nps_score < 0
GROUP BY support_channel
),
positive_score AS (
SELECT
support_channel,
COUNT(nps_score) AS positive_num,
ROUND(AVG(support_response_time_hrs),2) AS avg_positive_response_time,
MAX(support_response_time_hrs) longest_positive_response_time,
MIN(support_response_time_hrs) shortest_positive_response_time
FROM customer_statistics_staging3
WHERE nps_score > 0
GROUP BY support_channel
)
SELECT
ns.support_channel,
negative_num,
positive_num,
avg_negative_response_time,
avg_positive_response_time,
longest_negative_response_time,
longest_positive_response_time,
shortest_negative_response_time,
shortest_positive_response_time
FROM negative_score ns
JOIN positive_score ps
	ON ns.support_channel = ps.support_channel;
    
-- When cross-referencing values for positive and negative scores we can see interestingly enough that the negative scores actually have a shorter average resolution time when compared to positive scores
-- We have also compared both longest and shortest resolution times, this provided little insight as they are almost identical
-- We can draw the conclusion that resolution times are not directly indicative of low nps scores

-- Since time for resolution is not the main driver, the next best thing to check would be the number of chases that were actually resolved

WITH negative_unresolved_count AS (
SELECT
support_channel,
COUNT(issue_resolved) negative_unresolved
FROM customer_statistics_staging3
WHERE issue_resolved = 'NO' AND nps_score < 0
GROUP BY support_channel
),
positive_unresolved_count AS (
SELECT
support_channel,
COUNT(issue_resolved) AS positive_unresolved
FROM customer_statistics_staging3
WHERE issue_resolved = 'NO' AND nps_score > 0
GROUP BY support_channel
)

SELECT
nc.support_channel,
negative_unresolved,
positive_unresolved
FROM negative_unresolved_count nc
JOIN positive_unresolved_count pc
	ON nc.support_channel = pc.support_channel
GROUP BY nc.support_channel;

-- After running a quick query, the results show that the number of un-resolved cases in the negative nps score are significantly higher than in the positive nps group

-- Are repeat customers more forgiving than first-time buyers?

WITH returning_customer_satisfaction AS (
SELECT
COUNT(*) AS satisfied_returning_customers,
ROUND(AVG(nps_score),2) AS satisfied_returning_customer_avg_score
FROM customer_statistics_staging3
WHERE repeat_customer = 'Yes' AND
satisfaction_score_text LIKE 'satisfied' OR 
satisfaction_score_text LIKE 'Very satisfied'
),
returning_customer_unsatisfaction AS (
SELECT 
COUNT(*) AS unsatisfied_returning_customers,
ROUND(AVG(nps_score),2) AS unsatisfied_returning_customer_avg_score
FROM customer_statistics_staging3
WHERE repeat_customer = 'Yes' AND
satisfaction_score_text LIKE 'Not satisfied' OR 
satisfaction_score_text LIKE 'Very unsatisfied'
),
new_customer_satisfaction AS (
SELECT 
COUNT(*) AS satisfied_new_customers,
ROUND(AVG(nps_score),2) AS satisfied_new_customer_avg_score
FROM customer_statistics_staging3
WHERE repeat_customer = 'No' AND
satisfaction_score_text LIKE 'satisfied' OR 
satisfaction_score_text LIKE 'Very satisfied'
),
new_customer_unsatisfaction AS (
SELECT 
COUNT(*) AS unsatisfied_new_customers,
ROUND(AVG(nps_score),2) AS unsatisfied_new_customer_avg_score
FROM customer_statistics_staging3
WHERE repeat_customer = 'No' AND
satisfaction_score_text LIKE 'Not satisfied' OR 
satisfaction_score_text LIKE 'Very unsatisfied'
)

SELECT
satisfied_returning_customers,
satisfied_returning_customer_avg_score,
unsatisfied_returning_customers,
unsatisfied_returning_customer_avg_score,
satisfied_new_customers,
satisfied_new_customer_avg_score,
unsatisfied_new_customers,
unsatisfied_new_customer_avg_score
FROM returning_customer_satisfaction rcs
JOIN returning_customer_unsatisfaction rcu
JOIN new_customer_satisfaction
JOIN new_customer_unsatisfaction

-- We can see that the returning customers are indeed more forgiving than new customers, the un-satisfaction rate is lower for returning customers, however the satisfaction rate is higher with new customers

-- Do delivery delays hurt NPS equally across product categories?
-- We will calculate how many orders were completed and the ones which were, how long did it take for them to be delivered


SELECT
COUNT(*),
DATEDIFF(delivery_date, order_date) AS days_to_deliver
FROM customer_statistics_staging3
GROUP BY days_to_deliver
ORDER BY days_to_deliver

-- We can see that there is 491 orders which were not completed at all, these could be refunds, however a percentage of these could be lost orders etc. causing nps to go down
-- The company standard is to have all orders delivered between 1-21 business days, we need to also check how many orders were completed after the agreed date

WITH delivery_days AS (
SELECT
COUNT(*) AS late_orders,
DATEDIFF(delivery_date, order_date) AS days_to_deliver
FROM customer_statistics_staging3
WHERE DATEDIFF(delivery_date, order_date) > 21
GROUP BY days_to_deliver
ORDER BY days_to_deliver
)
SELECT
SUM(late_orders),
MAX(late_orders)
FROM delivery_days

-- We found our root problem with the extremely low nps score, the main driver is late delivery/no delivery, from here we can build upon a conclusion and provide clear next steps and a path forward for the company
-- Next let's take a look at the failed orders, to determine what percentage are refunds

WITH not_delivered_count AS (
SELECT 
COUNT(*) AS num_not_delivered
FROM customer_statistics_staging3
WHERE DATEDIFF(delivery_date, order_date) IS NULL
),

confirmed_failed_deliveries AS (
SELECT
COUNT(*) AS failed_confirmed_num
FROM customer_statistics_staging3
WHERE DATEDIFF(delivery_date, order_date) IS NULL
AND customer_comments = 'Not Delivered'
)

SELECT
num_not_delivered,
failed_confirmed_num,
ROUND((failed_confirmed_num / num_not_delivered) * 100,2) AS failed_delivery_percentage
FROM not_delivered_count
JOIN confirmed_failed_deliveries

-- After analyzing further we can be certain that at least 17.31% of all non-delivered orders were either never sent or were lost, the majority of the other 82.69% will most likely be refunds requested due to late shipment

SELECT *
FROM customer_statistics_staging3

-- In order to determine the risk of loosing high income/loyal customers we need to first find who they are and see what nps score they gave
-- To start off we will find the top customers by income and then segregate them by country, for the purposes of this project we will find the top 10

WITH top_customers AS (
SELECT
customer_id,
SUM(order_value) AS total_spent
FROM customer_statistics_staging3
GROUP BY customer_id 
)
SELECT
tc.customer_id,
total_spent,
country,
DENSE_RANK() OVER(ORDER BY total_spent DESC) AS ranking
FROM top_customers tc
JOIN customer_statistics_staging3 cst3
	ON tc.customer_id = cst3.customer_id
LIMIT 10

-- Now that we have found the top 10 by income, we will dig deeper and find the top 10 per country, we will use row_number here instead of dense_rank so that we don't have customers share a rating

WITH top_customers AS (
SELECT
customer_id,
SUM(order_value) AS total_spent
FROM customer_statistics_staging3
GROUP BY customer_id 
), 
largest_sale_ranking AS (
SELECT
tc.customer_id,
total_spent,
cst3.country,
nps_score,
ROW_NUMBER() OVER(PARTITION BY cst3.country ORDER BY total_spent DESC) AS ranking
FROM top_customers tc
JOIN customer_statistics_staging3 cst3
	ON tc.customer_id = cst3.customer_id
),
avg_top_score AS (
SELECT
AVG(nps_score) avg_score
FROM largest_sale_ranking
)
SELECT
*
FROM largest_sale_ranking
JOIN avg_top_score
WHERE ranking < 11 

-- We can see that there are only 3 positive nps scores among the high value customers, and 10 with negative scores, the rest did not leave a score, with this we can conclude that the risk of losing them is valid.

SELECT *
FROM customer_statistics_staging3

