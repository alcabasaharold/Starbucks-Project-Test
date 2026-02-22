-- Q1. Estimated Coffee Consumer Market by City
-- How many people in each city are estimated to consume coffee, 
-- assuming 25% of the population are regular coffee drinkers?
SELECT 
    city,
    population,
    ROUND(population * 0.25, 0) AS estimated_coffee_consumers
FROM stores
ORDER BY estimated_coffee_consumers DESC;



-- Q2. City Population vs Estimated Coffee Consumers
-- Provide a list of cities with their total population and estimated coffee consumers.
SELECT 
    city,
    SUM(population) AS total_population,
    ROUND(SUM(population) * 0.25, 0) AS estimated_coffee_consumers
FROM stores
GROUP BY city
ORDER BY estimated_coffee_consumers DESC;




-- Q3. Total Revenue – Last Quarter of 2023
-- What is the total revenue generated across all Starbucks stores in the last quarter of 2023?
-- Store-level breakdown
SELECT
	st.store_name,
	SUM(s.total) as total_revenue
FROM sales s
JOIN stores st
ON st.store_id = s.store_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date) = 2023
AND 
	EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Grand total
SELECT 
	SUM(total) AS total_revenue_last_quarter_2023 
FROM sales 
WHERE sale_date BETWEEN '2023-10-01' AND '2023-12-31';

-- Q4. Monthly Sales Growth
-- What is the month-over-month percentage growth (or decline) in total sales?
WITH growth_decline AS(
SELECT
	EXTRACT(YEAR FROM sale_date) as year,
	EXTRACT(MONTH FROM sale_date) as month,
	SUM(total) as total_sales,
	LAG(SUM(total),1) OVER (PARTITION BY EXTRACT(YEAR FROM sale_date) ORDER BY EXTRACT(MONTH FROM sale_date)) as prev_month
FROM sales
GROUP BY 1,2
ORDER BY 1,2
)
SELECT
	year,
	month,
	total_sales,
	prev_month,
	ROUND(
		(total_sales-prev_month)::numeric
			/prev_month::numeric * 100
				,2) as growth_ratio
FROM growth_decline;
-- If you want to remove NULL values (WHERE prev_month IS NOT NULL;)


-- Q5. Peak Sales Month
-- Which month recorded the highest total revenue?
WITH total_rev AS(
SELECT
	EXTRACT(YEAR FROM sale_date) as year,
	EXTRACT(MONTH FROM sale_date) as month,
	SUM(total) as total_revenue
FROM sales
GROUP BY 1,2
ORDER BY 1,2
),
rank_total_rev AS(
SELECT
	year,
	month,
	total_revenue,
	DENSE_RANK() OVER (PARTITION BY year ORDER BY total_revenue DESC) as rnk
FROM total_rev
)
SELECT
	year,
	month,
	total_revenue
FROM rank_total_rev
WHERE rnk = 1;
--If you want to see all the months with revenue and ranking 
--(SELECT * FROM rank_total_rev;) use this as main query



-- Q6. Product Performance Analysis
-- How many units of each Starbucks product have been sold?
SELECT
	p.product_id,
	p.product_name,
	SUM(s.quantity) as units_sold
FROM sales s
JOIN products p
ON p.product_id = s.product_id
GROUP BY 1, 2
ORDER BY 3 DESC;


-- Q7. Top 3 Selling Products per City
-- What are the top three best-selling products in each city based on sales volume?
-- If you want to see all the products you can use this:
SELECT
	st.city,
	p.product_name,
	SUM(quantity) as sales_volume
FROM sales s
JOIN products p
ON p.product_id = s.product_id
JOIN stores st
ON st.store_id = s.store_id
GROUP BY 1,2
ORDER BY 1,3 DESC;

-- If you want to see the top 3 you can use this:
WITH product_sales AS(
SELECT
	st.city,
	p.product_name,
	SUM(quantity) as sales_volume
FROM sales s
JOIN products p
ON p.product_id = s.product_id
JOIN stores st
ON st.store_id = s.store_id
GROUP BY 1,2
ORDER BY 1,3 DESC
),
product_ranking AS(
SELECT
	city,
	product_name,
	sales_volume,
	DENSE_RANK() OVER (PARTITION BY city ORDER BY sales_volume DESC) as rnk
FROM product_sales
)
SELECT
	city,
	product_name,
	sales_volume
FROM product_ranking
WHERE rnk <=3;



-- Q8. Revenue Contribution by Product Category
-- Which product category (e.g., Coffee, Tea, Food, Frappuccino)
-- contributes the highest percentage of total revenue?
WITH total_revenue_category AS
(SELECT
	p.category,
	SUM(s.total) as rev_per_category
FROM sales s
JOIN products p
ON p.product_id = s.product_id
GROUP BY 1
),
total_revenue AS(
SELECT
	SUM(rev_per_category) as grand_total
FROM total_revenue_category
)
SELECT
	t.category,
	t.rev_per_category,
	(t.rev_per_category/tr.grand_total *100) as prcnt
FROM total_revenue_category t
CROSS JOIN total_revenue tr
ORDER BY 3;



-- Q9. Customer Distribution by City
-- How many unique customers have made purchases in each city?
SELECT 
    st.city,
    COUNT(DISTINCT s.customer_id) AS unique_customers
FROM sales s
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.city
ORDER BY unique_customers DESC;



-- Q10. Average Sales per Customer by City
-- What is the average sales amount per customer in each city?
SELECT
	st.city,
	ROUND
	(SUM(s.total)::numeric
	/COUNT(DISTINCT s.customer_id)::numeric
	,2) as avg_sales_customer_city
FROM sales s
JOIN stores st
ON st.store_id = s.store_id
GROUP BY 1
ORDER BY 2 DESC;



-- Q11. Average Sales vs Estimated Rent
-- For each city, what is the average sales per customer compared to estimated rent costs?
SELECT
	st.city,
	ROUND
		(SUM(s.total)::numeric
			/COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sales_customer_city,
	MAX(st.avg_rent) as estimated_rent,
	ROUND(
		(SUM(s.total)::numeric
			/COUNT(DISTINCT s.customer_id)::numeric)
				/MAX(st.avg_rent)::numeric *100
					,4) as sales_rent_ratio
FROM sales s
JOIN stores st
ON st.store_id = s.store_id
GROUP BY 1
ORDER BY 4 DESC;


-- Q12. Store-Level Performance
-- Which individual Starbucks stores generate the highest and lowest revenue?
WITH total_rev AS
(SELECT
	st.store_name,
	SUM(s.total) as total_revenue
FROM sales s
JOIN stores st
ON st.store_id = s.store_id
GROUP BY 1
ORDER BY total_revenue DESC
)
SELECT
	store_name,
	total_revenue
FROM total_rev
WHERE total_revenue = (SELECT MAX(total_revenue)
						FROM total_rev
						)
OR total_revenue = (SELECT MIN(total_revenue)
					FROM total_rev);



-- Q13. Revenue per Store vs Population
-- Is there a relationship between city population size and total store revenue?
SELECT
	st.city,
	st.population,
	SUM(s.total) as total_revenue,
	ROUND(
		SUM(s.total)::numeric
			/st.population::numeric
				,4) as revenue_per_capita
FROM sales s
JOIN stores st
ON st.store_id = s.store_id
GROUP BY 1, 2
ORDER BY 4 DESC;

-- Q14. Market Expansion Potential (Top 3 Cities)
-- Which three cities show the strongest potential for expansion based on:
-- High total sales
-- Strong customer base (assuming 25% of the population are regular coffee drinkers)
-- Manageable rent costs
-- Large estimated coffee consumer population?

-- Simple ranking, prioritizes sales first, then consumers, then rent. 
WITH city_metrics AS(
SELECT
	st.city,
	st.population,
	(st.population*0.25) est_coffee_consumers,
	COUNT(DISTINCT s.customer_id) AS customer_base,
	SUM(s.total) as total_sales,
	ROUND(AVG(st.avg_rent)::numeric,2) AS avg_rent_cost
FROM sales s
JOIN stores st
ON st.store_id = s.store_id
GROUP BY 1, 2
)
SELECT
	city,
	customer_base,
	est_coffee_consumers,
	total_sales,
	avg_rent_cost
FROM city_metrics
ORDER BY 4 DESC, 3 DESC, 5;


-- Balanced scoring system, integrates all four factors into one weighted score for fairer comparison.
-- It applies weights to each factor:
-- Sales = 40%
-- Customer base = 25%
-- Coffee consumers = 20%
-- Rent = 15% (inverted so lower rent increases score).
WITH city_metrics AS (
    SELECT
        st.city,
        st.population,
        (st.population * 0.25) AS est_coffee_consumers,
        COUNT(DISTINCT s.customer_id) AS customer_base,
        SUM(s.total) AS total_sales,
        ROUND(AVG(st.avg_rent)::numeric, 2) AS avg_rent_cost
    FROM sales s
    JOIN stores st ON s.store_id = st.store_id
    GROUP BY st.city, st.population
),
normalized AS(
	SELECT
		city,
		customer_base,
		est_coffee_consumers,
		total_sales,
		avg_rent_cost,
		customer_base/MAX(customer_base) OVER () as customer_norm,
		est_coffee_consumers/MAX(est_coffee_consumers) OVER() as consumer_norm,
		total_sales/MAX(total_sales) OVER () as sales_norm,
		avg_rent_cost/MAX(avg_rent_cost) OVER () as rent_norm
	FROM city_metrics
)
SELECT 
	city,
	customer_base,
	est_coffee_consumers,
	total_sales,
	avg_rent_cost,
	ROUND(
		(0.4 * sales_norm +
		0.25 * customer_norm +
		0.20 * consumer_norm +
		0.15 * (1-rent_norm))::numeric * 100
	,4) as expansion_score
FROM normalized
ORDER BY 6 DESC;





