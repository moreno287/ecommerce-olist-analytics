-- Basic checks before analysis.
SELECT 'orders in raw table'                    AS check_name, COUNT(*) AS value FROM orders
UNION ALL SELECT 'duplicate order_id',          COUNT(*) - COUNT(DISTINCT order_id) FROM orders
UNION ALL SELECT 'orders in analysis window',   COUNT(*) FROM fact_orders
UNION ALL SELECT 'orders with no items',        COUNT(*) FROM fact_orders WHERE n_items IS NULL
UNION ALL SELECT 'delivered with no delivery date', COUNT(*) FROM fact_orders WHERE order_status = 'delivered' AND delivered_at IS NULL
UNION ALL SELECT 'orders with no review',       COUNT(*) FROM fact_orders WHERE review_score IS NULL
UNION ALL SELECT 'unique customers',            COUNT(DISTINCT customer_unique_id) FROM fact_orders;
