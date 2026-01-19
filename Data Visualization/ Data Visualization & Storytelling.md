


### Result Breakdown:
<h1 align = "center">ACG Dashboard </h1>
<p align="center">
 <img src="https://github.com/MilosB-Analytics/Aurelius-Commerce-Group-ACG-EDA-Customer-Experience/blob/main/Dashboard.png" style="width:100%; height:auto;" />
</p>

<h1 align = "center"> Business Questions & Answers </h1>

<p>
⁉️ Which support channels correlate with poor satisfaction?
<br>✔️ The channels with the poorest satisfaction scores are coincidently the most utilized channels (Phone & Email), this is to be expected as these two channels are globally most standardized of the 4 available. The Phone channel is the only one that has a positive overall rating of 0.54 which is far from desirable, as for the worst score rating, that would be the in-App channel with an average of -1.74. The ratios themselves do not differ from one another to the extent where we could say that measures need to be taken to migrate the clients to a specific channel. This further indicates that the communication & speed of service itself is not the issue rather the service provided should be looked at.
</p>

<p align = "center">
<img src="https://github.com/MilosB-Analytics/Aurelius-Commerce-Group-ACG-EDA-Customer-Experience/blob/main/Data%20Visualization/Images/Question%201.0.png" style="width:40%; height:auto;"/>
<img src="https://github.com/MilosB-Analytics/Aurelius-Commerce-Group-ACG-EDA-Customer-Experience/blob/main/Data%20Visualization/Images/Question%201.1.png" style="width:48%; height:auto;"/>
</p>

<p>
⁉️ Does response time actually impact CSAT—or is that assumed?
<br>✔️ As briefly touched upon on the previous question, we can say with certainty that the response times are not directly tied with low NPS scores. The data shows that response time is almost identical across both positive and negative reviews.
 </p>
 <p align = "center">
 <img  src="https://github.com/MilosB-Analytics/Aurelius-Commerce-Group-ACG-EDA-Customer-Experience/blob/main/Data%20Visualization/Images/Question%202.0.png" style="width:60%; height:auto;"/>
 <img  src="https://github.com/MilosB-Analytics/Aurelius-Commerce-Group-ACG-EDA-Customer-Experience/blob/main/Data%20Visualization/Images/Question%201.2.png" style="width:100%; height:auto;"/>
 </p>
 
 
<p>
⁉️ Are repeat customers more forgiving than first-time buyers?
<br>✔️ Yes however only by a slight margin, loyal/returning customers have an overall higher satisfaction rate and a lower un-satisfaction rate, which is not significant enough for us to say with confidence that the loyal client population is satisfied and will not migrate to the competition at this moment. Given the current situation more work is required on service delivery in order to stop the decline and maintain the current loyal customer population.
</p>
<table> 
 <tr>
  <td>
 <p align = "center">
 <img src="https://github.com/MilosB-Analytics/Aurelius-Commerce-Group-ACG-EDA-Customer-Experience/blob/main/Data%20Visualization/Images/Question%203.0.png" style="width:100%; height:auto;"/>
 </p>
 </td>
  <td>
   
```SQL
WITH returning_customer_satisfaction AS (
SELECT
COUNT(*) AS satisfied_returning_customers,
ROUND(AVG(nps_score),2) AS satisfied_returning_customer_avg_score
FROM customer_statistics_staging3
WHERE repeat_customer = 'Yes' AND
satisfaction_score_text LIKE 'satisfied' OR 
satisfaction_score_text LIKE 'Very satisfied'
),
```
  </td>
</tr>
</table
<p>
⁉️ Do delivery delays hurt NPS equally across product categories?
<br>✔️ We can see that the most ordered product category is Electronics, with it having more than double the orders of the other two categories, that being said the average score across all category’s ranges from -50 to -58. The biggest gap between these is 6.83% which taking into account the overwhelmingly negative scores across all categories it would be safe to say that they are all equally impacted.
</p>
<table>
 <tr>
  <td>
 <p align = "center">
<img src="https://github.com/MilosB-Analytics/Aurelius-Commerce-Group-ACG-EDA-Customer-Experience/blob/main/Data%20Visualization/Images/Question%204.0.png" style="width:100%; height:auto;"/>
 </p>
</td>
  <td>
 <img src="https://github.com/MilosB-Analytics/Aurelius-Commerce-Group-ACG-EDA-Customer-Experience/blob/main/Data%20Visualization/Images/Question%204.2.png" style="width:100%; height:auto;"/>

</td>
</tr>
</table>

<p>
⁉️ Which are high value customers and what is the risk of losing them?
<br>✔️ 60% of the highest value customers are from the United States and 30% are from Germany, the risk of losing them is high as their average score comes up to a -0.22. Top customers are categorized by total spent, all customers which have spent more than 1000$ are categorized as top customers, currently globally there is around 2100 top customers out of the 9139 provided, which is 22.97%. As there is a valid concern in losing more than 20% of the entire buyer population, reaching a resolution for this issue should be prioritized.
</p>
<table>
 <tr>
 <td>
  
```SQL
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
```
</td>
<td>
<p align = "center">
<img src="https://github.com/MilosB-Analytics/Aurelius-Commerce-Group-ACG-EDA-Customer-Experience/blob/main/Data%20Visualization/Images/Question%205.0.png" style="width:100%; height:auto;"/>
</p>
 </td>
</tr>
</table>

<h1 align = "center">💹 Recommended Next Steps </h1>

📘 When looking through the scores of top customers per country we were able to see that the overall number of positive scores is extremely low, this brings a real risk of losing them, further analysis shows that the main driver for negative scores overall is due to orders failing on delivery, out of the 491 total non-delivered orders we can be certain that 17.31% were lost, unfortunately the customers did not specify which orders are refunds so we cannot be certain of the exact amount of orders lost vs refunds, taking into account that not all customers specify when an order has failed, this number is likely much larger.

📘 Investigate the delivery routes/process in order to locate the point of failure, possibly look at changing delivery vendors if significant % is being lost in transport, prepare for transition if it comes down to changing vendors.
We can be certain that non-delivered orders directly corelate to negative reviews. Another main factor is delivery times, ACG has committed to 21 business days to deliver an order, however we can see that there has been a total of 845 late deliveries on top of the 491 which were not delivered, the average score is negative (-1.35) for these late orders.

📘 Along with delivery vendor shift, implement a delivery tracking option (if no option exists, otherwise look into upgrading the current option), where the whole lifecycle can be tracked, from the point when an order comes in - to delivery, once data is acquired we can analyze and pinpoint bottlenecks.
The last major factor contributing to low ratings is the support provided, we can see that when it comes to un-resolved issues there is an 20.37% increase of negative reviews. A staggering total of 2,387 cases out of 9139 were not resolved, that leaves a staggering 26% of unresolved cases in total which highly contributes to negative reviews.

📘 Re-evaluate SLAs for support and locate breaches. Most common issues in these cases can be stemmed from either process gaps (knowledge gaps) or inadequate headcount (team volume). Analyze ticket volume, locate peak times and shift team schedule to accommodate process changes (additional training). Additionally, if support is provided externally, look into new options which provide better service, prepare for transition if it comes down to changing vendors.

