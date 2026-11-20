-- How does being late change the review score? Delivered orders with a review only.
SELECT CASE
         WHEN days_vs_estimate <= 0  THEN '1. on time or early'
         WHEN days_vs_estimate <= 3  THEN '2. 1-3 days late'
         WHEN days_vs_estimate <= 7  THEN '3. 4-7 days late'
         WHEN days_vs_estimate <= 14 THEN '4. 8-14 days late'
         ELSE                             '5. 15+ days late'
       END                                              AS delivery_bucket,
       COUNT(*)                                          AS orders,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct_of_orders,
       ROUND(AVG(review_score), 2)                       AS avg_review,
       ROUND(100 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 1) AS pct_bad_reviews
FROM fact_orders
WHERE order_status = 'delivered'
  AND delivered_at IS NOT NULL
  AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;
