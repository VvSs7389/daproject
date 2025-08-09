WITH
cost_var_2 as ( SELECT time::date as date, courier_id, action, order_id,
                       case when action = 'deliver_order' then 150 end as cost_delivery,
                       case when date_part('month', time) <= '8' and
                                 date_part('year', time) = '2022' and
                                 action = 'accept_order' then 140
                            when date_part('month', time) >= '9' and
                                 date_part('year', time) = '2022' and
                                 action = 'accept_order' then 115 end as cost_сборка
                FROM   courier_actions
                WHERE  order_id not in (SELECT order_id
                                        FROM   user_actions
                                        WHERE  action = 'cancel_order')
                ORDER BY courier_id, date), 

cost_var_3 as (SELECT courier_id, date, action,
                      count(distinct order_id) as count_orders,
                      sum(cost_сборка) as cost_сборка,
                      sum(cost_delivery) as cost_delivery,
                      case when date_part('month', date) <= '8' and
                                date_part('year', date) = '2022' and
                                count(order_id) >= 5 and
                                action = 'deliver_order' then 400
                           when date_part('month', date) >= '9' and
                                date_part('year', date) = '2022' and
                                count(order_id) >= 5 and
                                action = 'deliver_order' then 500
                           else 0 end as bonus_delivery
               FROM   cost_var_2
               GROUP BY courier_id, date, action
               ORDER BY courier_id, date), 
  
cost_var_all as (SELECT date, sum (bonus_delivery) + sum(cost_сборка) + sum(cost_delivery) as all_var_cost,
                        case when date_part('month', date) <= '8' and
                                  date_part('year', date) = '2022' then 120000
                             when date_part('month', date) >= '9' and
                                  date_part('year', date) = '2022' then 150000 end as fix_cost
                 FROM   cost_var_3
                 GROUP BY date
                 ORDER BY date), 
  
products_cte as (SELECT creation_time::date as date, order_id, unnest(product_ids) as product_id
                 FROM   orders
                 WHERE  order_id not in (SELECT order_id
                                         FROM   user_actions
                                         WHERE  action = 'cancel_order')), 
  
products_cte_vat_temp as (SELECT *,  case when products.name in ('сахар', 'сухарики', 'сушки', 'семечки', 'масло льняное',
                                               'виноград', 'масло оливковое', 'арбуз', 'батон',
                                               'йогурт', 'сливки', 'гречка', 'овсянка', 'макароны',
                                               'баранина', 'апельсины', 'бублики', 'хлеб', 'горох',
                                               'сметана', 'рыба копченая', 'мука', 'шпроты', 'сосиски',
                                               'свинина', 'рис', 'масло кунжутное', 'сгущенка',
                                               'ананас', 'говядина', 'соль', 'рыба вяленая', 'масло подсолнечное',
                                               'яблоки', 'груши', 'лепешка', 'молоко', 'курица',
                                               'лаваш', 'вафли', 'мандарины') then 0.10
                                      else 0.20 end as tax
                          FROM   products_cte
                          LEFT JOIN products using(product_id)), 
  
products_cte_vat as (SELECT *, round((price / (1 + products_cte_vat_temp.tax)) * products_cte_vat_temp.tax, 2) as tax_1
                     FROM   products_cte_vat_temp), 
  
basic_metrics_1 as (SELECT date,
                           sum(products_cte_vat.price) as revenue, --выручка
                           all_var_cost + fix_cost as costs,
                           sum(tax_1) as tax
                    FROM   products_cte_vat
                    LEFT JOIN cost_var_all using (date)
                    GROUP BY date, costs
                    ORDER BY date)

SELECT date, revenue, costs, tax,
       revenue - costs - tax as gross_profit,
       sum(revenue) OVER (ORDER BY date) as total_revenue,
       sum(costs) OVER (ORDER BY date) as total_costs,
       sum(tax) OVER (ORDER BY date) as total_tax,
       sum(revenue - costs - tax) OVER (ORDER BY date) as total_gross_profit,
       round(((revenue - costs - tax)*100/revenue), 2) as gross_profit_ratio,
       round((sum(revenue - costs - tax) OVER (ORDER BY date) * 100 / sum(revenue) OVER (ORDER BY date)), 2) as total_gross_profit_ratio
FROM   basic_metrics_1