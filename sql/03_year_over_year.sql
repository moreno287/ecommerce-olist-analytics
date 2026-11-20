-- Compare Jan-Aug 2017 with Jan-Aug 2018 (same months, fair comparison).
SELECT YEAR(order_month)                  AS year,
       COUNT(*)                           AS orders,
       ROUND(SUM(revenue), 0)             AS revenue_brl,
       ROUND(AVG(revenue), 2)             AS avg_order_value_brl
FROM fact_orders
WHERE order_status NOT IN ('canceled', 'unavailable')
  AND MONTH(order_month) BETWEEN 1 AND 8
GROUP BY 1
ORDER BY 1;
