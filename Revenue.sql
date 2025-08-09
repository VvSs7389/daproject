WITH 
cost_orders as (SELECT creation_time::date as date, unnest(product_ids) as product_id
                FROM   orders
                WHERE  order_id not in (SELECT order_id
                                        FROM   user_actions
                                        WHERE  action = 'cancel_order')), 

revenue_orders as (SELECT date, sum(price) as revenue,
                          sum(sum(price)) OVER (ORDER BY date) as total_revenue
                   FROM   cost_orders
                   LEFT JOIN products using (product_id)
                   GROUP BY date
                   ORDER BY date)
  
SELECT date, revenue, total_revenue,
       round(((revenue - lag(revenue, 1) OVER (ORDER BY date)) *100/ lag(revenue, 1) OVER (ORDER BY date)),
             2) as revenue_change
FROM   revenue_orders