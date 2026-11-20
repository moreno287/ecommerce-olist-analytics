-- Load the raw CSVs into DuckDB tables and build one clean order-level table.
CREATE OR REPLACE TABLE customers   AS SELECT * FROM read_csv_auto('data/olist_customers_dataset.csv');
CREATE OR REPLACE TABLE orders      AS SELECT * FROM read_csv_auto('data/olist_orders_dataset.csv');
CREATE OR REPLACE TABLE order_items AS SELECT * FROM read_csv_auto('data/olist_order_items_dataset.csv');
CREATE OR REPLACE TABLE payments    AS SELECT * FROM read_csv_auto('data/olist_order_payments_dataset.csv');
CREATE OR REPLACE TABLE reviews     AS SELECT * FROM read_csv_auto('data/olist_order_reviews_dataset.csv');
CREATE OR REPLACE TABLE products    AS SELECT * FROM read_csv_auto('data/olist_products_dataset.csv');
CREATE OR REPLACE TABLE sellers     AS SELECT * FROM read_csv_auto('data/olist_sellers_dataset.csv');
CREATE OR REPLACE TABLE category_en AS SELECT * FROM read_csv_auto('data/product_category_name_translation.csv');

-- One row per order. Revenue = item price + freight (what the customer paid for the goods and shipping).
-- Some orders have more than one review; keep the latest one.
CREATE OR REPLACE TABLE fact_orders AS
WITH items AS (
    SELECT order_id,
           COUNT(*)                     AS n_items,
           SUM(price)                   AS product_revenue,
           SUM(freight_value)           AS freight_revenue,
           SUM(price + freight_value)   AS revenue
    FROM order_items
    GROUP BY order_id
),
latest_review AS (
    SELECT order_id, review_score
    FROM reviews
    QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) = 1
)
SELECT o.order_id,
       c.customer_unique_id,
       c.customer_state,
       o.order_status,
       o.order_purchase_timestamp                         AS purchased_at,
       DATE_TRUNC('month', o.order_purchase_timestamp)    AS order_month,
       o.order_delivered_customer_date                    AS delivered_at,
       o.order_estimated_delivery_date                    AS estimated_at,
       DATE_DIFF('day', o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_days,
       DATE_DIFF('day', o.order_estimated_delivery_date, o.order_delivered_customer_date) AS days_vs_estimate,
       i.n_items, i.product_revenue, i.freight_revenue, i.revenue,
       r.review_score
FROM orders o
JOIN customers c USING (customer_id)
LEFT JOIN items i USING (order_id)
LEFT JOIN latest_review r USING (order_id)
-- Full months only: Jan 2017 to Aug 2018 (2016 is a test period, Sep-Oct 2018 have a handful of orders).
WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';
