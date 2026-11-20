-- Top 10 product categories by revenue, with share of total and average review score.
WITH item_level AS (
    SELECT COALESCE(t.product_category_name_english, 'unknown') AS category,
           oi.price + oi.freight_value AS revenue,
           f.review_score,
           f.order_id
    FROM order_items oi
    JOIN fact_orders f USING (order_id)
    LEFT JOIN products p USING (product_id)
    LEFT JOIN category_en t USING (product_category_name)
    WHERE f.order_status NOT IN ('canceled', 'unavailable')
)
SELECT category,
       COUNT(DISTINCT order_id)                                   AS orders,
       ROUND(SUM(revenue), 0)                                     AS revenue_brl,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)   AS pct_of_revenue,
       ROUND(AVG(review_score), 2)                                AS avg_review
FROM item_level
GROUP BY category
ORDER BY revenue_brl DESC
LIMIT 10;
