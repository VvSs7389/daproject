SELECT product_name,
       sum(revenue) as revenue,
       sum(share_in_revenue) as share_in_revenue
FROM   (SELECT case when share_in_revenue < 0.5 then 'ДРУГОЕ'
                    when share_in_revenue > 0.5 then product_name end as product_name,
               revenue,
               share_in_revenue
        FROM   (SELECT name as product_name,
                       sum(price) as revenue, --выручка по каждому товару за весь период
                       round((sum(price)*100/sum(sum(price)) OVER ()), 2) as share_in_revenue
                FROM   (SELECT unnest(product_ids) as product_id
                        FROM   orders
                        WHERE  order_id not in (SELECT order_id
                                                FROM   user_actions
                                                WHERE  action = 'cancel_order'))t1
                LEFT JOIN products using(product_id)
                GROUP BY product_name) t2) t3
GROUP BY product_name
ORDER BY revenue desc