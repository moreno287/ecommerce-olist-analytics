-- Delivery speed and late rate by customer state (states with 500+ delivered orders).
SELECT customer_state,
       COUNT(*)                                                     AS delivered_orders,
       ROUND(AVG(delivery_days), 1)                                 AS avg_delivery_days,
       ROUND(100 * AVG(CASE WHEN days_vs_estimate > 0 THEN 1 ELSE 0 END), 1) AS pct_late,
       ROUND(AVG(review_score), 2)                                  AS avg_review
FROM fact_orders
WHERE order_status = 'delivered' AND delivered_at IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) >= 500
ORDER BY pct_late DESC;
