-- How many customers ever come back? customer_unique_id identifies a person across orders.
WITH per_customer AS (
    SELECT customer_unique_id, COUNT(*) AS n_orders, SUM(revenue) AS revenue
    FROM fact_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
)
SELECT CASE WHEN n_orders = 1 THEN '1 order' WHEN n_orders = 2 THEN '2 orders' ELSE '3+ orders' END AS customer_type,
       COUNT(*)                                          AS customers,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct_of_customers,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS pct_of_revenue
FROM per_customer
GROUP BY 1
ORDER BY 1;
