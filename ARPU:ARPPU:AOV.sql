WITH
cost_orders as (SELECT creation_time::date as date, unnest(product_ids) as product_id, order_id
                FROM   orders
                WHERE  order_id not in (SELECT order_id
                                        FROM   user_actions
                                        WHERE  action = 'cancel_order')), 
  
paying_values as (SELECT date, sum(price) as revenue,
                         count(distinct user_id) as paying_users,
                         count(distinct order_id) as paying_users_orders
                  FROM cost_orders
                  LEFT JOIN products using (product_id)
                  LEFT JOIN user_actions using (order_id)
                  GROUP BY date
                  ORDER BY date), 
  
all_users as (SELECT time::date as date, count(distinct user_id) as all_users
              FROM   user_actions
              GROUP BY date)

SELECT date,
       round((revenue::decimal/all_users), 2) as arpu,
       round((revenue::decimal/paying_users), 2) as arppu,
       round((revenue::decimal/paying_users_orders), 2) as aov
FROM   paying_values
LEFT JOIN all_users using(date)