-- Q1 Which product categories generate the highest average order value (aov)?

select category, printf("%.0f",avg(amount)) as average_order_value  from amazon
where status not in ('cancelled', 'shipped - returned to seller', 'shipped - rejected by buyer', 'shipped - lost in transit', 'shipped - returning to seller')
group by  category
order by avg(amount) desc
limit 3


-- Q2 Which states drive the most revenue?

select ship_state, (sum(amount)*1.0/total_revenue)*100 as revenue_percentage
from  (
select ship_state, amount, sum(amount) over () as total_revenue from amazon
where status not in ('cancelled', 'shipped - returned to seller', 'shipped - rejected by buyer', 'shipped - lost in transit', 'shipped - returning to seller')
)
group by ship_state
order by revenue_percentage desc
limit 3


-- Q3 What percentage of total revenue is generated from b2b customers?

select type, printf("%.2f",(sum(amount)*1.0/total_revenue)*100) as revenue_percentage  from (
select case when b2b = 1 then 'b2b' else 'non_b2b' end as type, amount, sum(amount) over () as total_revenue, order_id from amazon
where status not in ('cancelled', 'shipped - returned to seller', 'shipped - rejected by buyer', 'shipped - lost in transit', 'shipped - returning to seller')
)
group by type


-- Q4 Do customers prefer expedited shipping level over standard shipping level?

select ship_service_level, (count(*)*1.0/total_orders)*100 as orders_percentage from (
select ship_service_level, count(*) over () as total_orders from amazon
where status not in ('Cancelled', 'Shipped - Returned to Seller', 'Shipped - Rejected by Buyer', 'Shipped - Lost in Transit', 'Shipped - Returning to Seller')
)
group by ship_service_level


-- Q5 Which product categories contribute the most to the total revenue?

select category, (sum(amount)*1.0/total_revenue)*100 as revenue_percentage from (
select category, amount, sum(amount) over () as total_revenue  from amazon
where status not in ('cancelled', 'shipped - returned to seller', 'shipped - rejected by buyer', 'shipped - lost in transit', 'shipped - returning to seller')
)
group by  category
order by revenue_percentage desc
limit 3


-- Q6 What are the monthly revenue trends?

select month, revenue, printf("%.2f",((revenue - lag_revenue)*1.0/lag_revenue)*100) as percentage_change from (
select month, revenue, lag(revenue) over (order by month) as lag_revenue from (
select substr(date, 1, 2) as month, sum(amount) as revenue from amazon
where substr(date, 1, 2) in ('04', '05', '06')
and status not in ('cancelled', 'shipped - returned to seller', 'shipped - rejected by buyer', 'shipped - lost in transit', 'shipped - returning to seller')
group by month
))


-- Q7 How does average order value (aov) differ between promotional and non-promotional orders?

select month, printf("%.0f",non_promotion_aov) as non_promotion_aov, printf("%.0f",promotion_aov) as promotion_aov from (
select substr(date, 1, 2) as month, avg(case when promotion_ids is null then amount else 0 end) as non_promotion_aov,
avg(case when promotion_ids is not null then amount else 0 end) as promotion_aov
from amazon
group by month
)
where month in ('04', '05', '06')


-- Q8 Which categories have the highest cancellation rate and What is the associated revenue loss?

select category, printf("%.2f",cancellation_rate) as cancellation_rate, printf("%.0f",revenue_lost) as revenue_lost from (
select category, (sum(case when status = 'cancelled' then 1.0 else 0 end)/count(*))*100 as cancellation_rate,
(sum(case when status = 'cancelled' then amount else 0 end)) as revenue_lost
 from amazon
group by category
order by cancellation_rate desc
limit 3
)


-- Q9 How many orders fail due to logistics issues for each of the fulfilment methods?

select fulfilment,
       sum(case when status in ('shipped - lost in transit', 'shipped - damaged') then 1 else 0 end) as failed_orders
from amazon
group by fulfilment


-- Q10 How does revenue trend on a daily basis within a selected month?

select day, printf("%.0f",revenue) as revenue, printf("%.2f",((revenue - lag_revenue)*1.0/lag_revenue)*100) as percentage_change from (
select day, revenue, lag(revenue) over (order by day) as lag_revenue from
(
select substr(date, 4, 2) as day, sum(amount) as revenue from amazon
where substr(date, 1, 2) = '04'
and status not in ('cancelled', 'shipped - returned to seller', 'shipped - rejected by buyer', 'shipped - lost in transit', 'shipped - returning to seller')
group by day
))


-- Q11 Among postal codes with more than 100 orders, Which have the highest return or rejection rates?

select printf("%.0f",ship_postal_code) as ship_postal_code, count(*) as total_orders,
       sum(case when status in ('shipped - returned to seller', 'shipped - rejected by buyer') then 1 else 0 end) as returns_or_rejections,
       round(100.0 * sum(case when status in ('shipped - returned to seller', 'shipped - rejected by buyer') then 1 else 0 end)/count(*),2) as percentage
from amazon
group by ship_postal_code
having total_orders > 100
order by percentage desc
limit 3


-- Q12 Which product categories grew or declined between April and May?

with cte1 as (
select category, substr(date, 1, 2) as month, sum(amount) as revenue from amazon
where substr(date, 1, 2) in ('04')
and status not in ('cancelled', 'shipped - returned to seller', 'shipped - rejected by buyer', 'shipped - lost in transit', 'shipped - returning to seller')
group by category
),
cte2 as (
select category, substr(date, 1, 2) as month, sum(amount) as revenue from amazon
where substr(date, 1, 2) in ('05')
and status not in ('cancelled', 'shipped - returned to seller', 'shipped - rejected by buyer', 'shipped - lost in transit', 'shipped - returning to seller')
group by category
)
select category, printf("%.0f",april_revenue) as april_revenue, printf("%.0f",may_revenue) as may_revenue,
printf("%.2f",percentage_change) as percentage_change from (
select cte1.category, cte1.revenue as april_revenue, cte2.revenue as may_revenue,
((cte2.revenue - cte1.revenue)*1.0/cte1.revenue)*100 as percentage_change
from cte1 join cte2 on cte1.category = cte2.category
)


-- Q13 What is the most in-demand size within each product category?

select category, size, units_ordered from (
select category, size,  count(*) as units_ordered, dense_rank() over (partition by category order by count(*) desc) as rnk
from amazon
where status not in ('cancelled')
group by category, size
)
where rnk = 1;


-- Q14 How can shipping cities be segmented into low, medium and high-value tiers?

select ship_state, printf("%.0f",aov) as average_order_value, case when buckets = 1 then 'low_value'
            when buckets = 2 then 'medium_value'
            when buckets = 3 then 'high_value'
            end as tier_segment from (
select ship_state, aov, ntile(3) over (order by aov) as buckets from (
select ship_state, avg(amount) as aov from amazon
where status not in ('cancelled', 'shipped - returned to seller', 'shipped - rejected by buyer', 'shipped - lost in transit', 'shipped - returning to seller')
group by ship_state
)
)
order by average_order_value desc


-- Q15 Which product categories are most frequently purchased together?

select (a.category || ' & ' || b.category) as combos, count(*) as frequency
from amazon a
join amazon b
on a.order_id = b.order_id
where a.category != b.category
and a.category < b.category
group by combos
order by count(*) desc
limit 3

