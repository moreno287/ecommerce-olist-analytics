-- Monthly orders, revenue and average order value (canceled / unavailable orders excluded).
SELECT order_month,
       COUNT(*)                          AS orders,
       ROUND(SUM(revenue), 0)            AS revenue_brl,
       ROUND(AVG(revenue), 2)            AS avg_order_value_brl,
       COUNT(DISTINCT customer_unique_id) AS customers
FROM fact_orders
WHERE order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;
