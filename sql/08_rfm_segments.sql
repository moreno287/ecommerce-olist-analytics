-- RFM segmentation. Snapshot date = day after the last order in the window.
-- Because almost everyone orders once, Frequency is 1 vs 2+, and segments lean on Recency and Monetary.
WITH snapshot AS (SELECT MAX(purchased_at) + INTERVAL 1 DAY AS d FROM fact_orders),
per_customer AS (
    SELECT customer_unique_id,
           DATE_DIFF('day', MAX(purchased_at), (SELECT d FROM snapshot)) AS recency_days,
           COUNT(*)      AS frequency,
           SUM(revenue)  AS monetary
    FROM fact_orders
    WHERE order_status NOT IN ('canceled', 'unavailable') AND revenue IS NOT NULL
    GROUP BY 1
),
scored AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,   -- 4 = most recent
           CASE WHEN frequency > 1 THEN 2 ELSE 1 END   AS f_score,
           NTILE(4) OVER (ORDER BY monetary)          AS m_score    -- 4 = highest spend
    FROM per_customer
),
segmented AS (
    SELECT *,
           CASE
             WHEN f_score = 2 AND r_score >= 3                 THEN 'Loyal (repeat, recent)'
             WHEN f_score = 2                                  THEN 'Repeat, lapsing'
             WHEN r_score >= 3 AND m_score >= 3                THEN 'New high-value'
             WHEN r_score >= 3                                 THEN 'New low-value'
             WHEN m_score >= 3                                 THEN 'Lapsed high-value'
             ELSE                                                   'Lapsed low-value'
           END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*)                                           AS customers,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS pct_customers,
       ROUND(AVG(recency_days), 0)                        AS avg_recency_days,
       ROUND(AVG(monetary), 0)                            AS avg_spend_brl,
       ROUND(100 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue
FROM segmented
GROUP BY segment
ORDER BY pct_revenue DESC;
