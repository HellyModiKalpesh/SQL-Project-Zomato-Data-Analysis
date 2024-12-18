-- Zomato Data Analysis using SQL

use zomato_db;

create table customers(
customer_id INT primary key ,
customer_name varchar(30),
reg_date Date
);

create table restaurants(
restaurant_id INT primary key ,
restaurant_name varchar(30),
city varchar(30),
opening_hours varchar(55)
);

create table orders(
order_id INT primary key,
customer_id int, -- this is foreign key from customers
restaurant_id int,-- this is foreign key from restaurant
order_item varchar(55),
order_date date,
order_time time,
order_status varchar(55),
total_amount float
);


create table riders(
rider_id INT primary key ,
rider_name varchar(30),
sign_up date
);

create table deliveries(
delivery_id INT primary key,
order_id int, -- this is foreign key from order
delivery_status varchar(55),
delivery_time time,
rider_id int -- this is coming from rider
);

-- Analysis and reports

-- Q.1
-- Write a query to find the top 5 most frequently ordered dishes by the customer "Arjun Mehta" in the last 1 year.

SELECT COUNT(*) AS frequency,
       order_item
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_name = 'Arjun Mehta'
  AND o.order_date >= CURDATE() - INTERVAL 1 YEAR
GROUP BY order_item
ORDER BY frequency DESC;

-- Q.2
-- Identify the time slots during which the most orders are placed, based on 2-hour intervals

-- 1 st approach

select 
case when extract(hour from order_time) between 0 and 1 then '00.00-02.00'
	when extract(hour from order_time) between 2 and 3 then '02.00-04.00'
    when extract(hour from order_time) between 4 and 5 then '04.00-06.00'
    when extract(hour from order_time) between 6 and 7 then '06.00-08.00'
    when extract(hour from order_time) between 8 and 9 then '08.00-10.00'
    when extract(hour from order_time) between 10 and 11 then '10.00-02.00'
    when extract(hour from order_time) between 11 and 12 then '00.00-12.00'
    when extract(hour from order_time) between 12 and 13 then '12.00-14.00'
    when extract(hour from order_time) between 14 and 15 then '14.00-16.00'
    when extract(hour from order_time) between 16 and 17 then '16.00-18.00'
    when extract(hour from order_time) between 18 and 19 then '18.00-20.00'
    when extract(hour from order_time) between 20 and 21 then '20.00-22.00'
    when extract(hour from order_time) between 22 and 23 then '22.00-00.00'
    end as time_slot,
    count(*) as frequency
 from orders
 group by time_slot
 order by frequency desc;

-- 2 nd approach

 select
 floor(extract(hour from order_time)/2)*2 as start_time, 
 floor(extract(hour from order_time)/2)*2+2 as end_time,
 count(*)as frequency
 from orders 
 group by start_time,end_time
 order by frequency desc;
 
 -- 23:55PM /2 -- 11 * 2 = 22 start, 22 +2 
-- 22-11:59:59 PM

-- SELECT 00:59:59AM -- 0
-- SELECT 01:59:59AM -- 1
-- 0
 
 -- Q.3
 -- Find the average order value (AOV) per customer who has placed more than 750 orders.
 -- Return: customer_name, aov (average order value).
 
 -- group by customers
 -- order count must be greater than 750
 
 select customer_name,avg(total_amount) as aov from orders join customers
 on orders.customer_id=customers.customer_id
 group by orders.customer_id
 having count(*)>750;
 
 -- Q.4
 -- List the customers who have spent more than 100K in total on food orders.
-- Return: customer_name, customer_id.

select customer_name,sum(total_amount) as total_spend
from orders join customers 
on orders.customer_id=customers.customer_id
group by customers.customer_id
having sum(total_amount)>100000
order by total_spend desc;

-- Q.5
-- Write a query to find orders that were placed but not delivered.
-- Return: restaurant_name, city, and the number of not delivered orders.

select restaurant_name,city,count(*) as undelivered_order from 
restaurants join orders
on restaurants.restaurant_id=orders.restaurant_id
join deliveries
on orders.order_id=deliveries.order_id
where delivery_status='Not Delivered'
group by  restaurasysnt_name,city
order by undelivered_order desc;
 
-- Q. 6
-- Restaurant Revenue Ranking: 
-- Rank restaurants by their total revenue from the last year, including their name, 
-- total revenue, and rank within their city.

with cte as (
select city,restaurant_name,sum(total_amount) as revenue,
rank() over(partition by city order by sum(total_amount) desc) as rnk
from orders join restaurants 
on orders.restaurant_id=restaurants.restaurant_id
where order_date>=current_date()-interval 1 year
group by city,restaurant_name
)
select * from cte where rnk=1;

-- Question:7
-- Identify the most popular dish in each city based on the number of orders

-- dish name group by city count(order_id
-- rank

with cte as (
select order_item,city,count(order_id) as no_of_order,
rank()over(partition by city  order by count(order_id) desc) as rnk
from orders join restaurants
on orders.restaurant_id=restaurants.restaurant_id
group by city,order_item
)
select * from cte where rnk=1;

-- Question: 8
-- Find customers who haven’t placed an order in 2024 but did in 2023.

 SELECT DISTINCT customer_id
FROM orders
WHERE YEAR(order_date) = 2023 and 
customer_id not in (
select distinct customer_id from orders where year(order_date)=2024);

-- Question:9
-- Calculate and compare the order cancellation rate for each restaurant between the current year
 -- and the previous year
 
 -- cancellation rate=cancel/total 
 -- previous year and current year 

 with cte as (
 SELECT 
    o.restaurant_id, 
    COUNT(o.order_id) AS total_order,
    SUM(CASE WHEN deliveries.delivery_id is Null THEN 1 ELSE 0 END) AS undelivered
FROM 
    orders as o 
left JOIN 
    deliveries 
    ON o.order_id = deliveries.order_id
WHERE 
    EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY 
    o.restaurant_id
),
cte2 as (
 SELECT 
    o.restaurant_id, 
    COUNT(o.order_id) AS total_order,
    SUM(CASE WHEN deliveries.delivery_id is null THEN 1 ELSE 0 END) AS undelivered
FROM 
    orders as o 
JOIN 
    deliveries
    ON o.order_id = deliveries.order_id
WHERE 
    EXTRACT(YEAR FROM o.order_date) = 2024
GROUP BY 
    o.restaurant_id
)
select cte.restaurant_id,round((cte.undelivered/cte.total_order)*100,2) as ratio_23,
round((cte2.undelivered/cte2.total_order)*100,2) as ratio_24
from cte join cte2
on cte.restaurant_id=cte2.restaurant_id;

-- Question: 10
-- Determine each rider's average delivery time.


with cte as (
select rider_id,
o.order_time,
d.delivery_time,
case when d.delivery_time<o.order_time then 
timestampdiff(minute,o.order_time,Addtime(d.delivery_time,'24:00:00')) else
timestampdiff(minute,o.order_time,d.delivery_time) end as time_inminute
from 
orders as o join deliveries as d
on o.order_id=d.order_id
where d.delivery_status='Delivered'
)
select rider_id,avg(time_inminute) as average_delivery_time from cte group by rider_id;

-- Q11. Monthly Restaurant Growth Ratio
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining.

-- monthly growth ratio=current month-last/last month


with cte as (
select o.restaurant_id,
count(o.order_id) as order_count,
extract(month from order_date) as months,
lag(count(o.order_id),1) over(partition by o.restaurant_id order by  extract(month from order_date)) as previous
from orders as o join deliveries as d
on o.order_id=d.order_id
where delivery_status='Delivered'
group by 1,3
order by 1,3
)
select 
restaurant_id,order_count,months,previous,
round((order_count-previous)/previous* 100,2)as growth_ratio
from cte;

-- Question-12 customer segmentation
-- Segment customers into 'Gold' or 'Silver' groups based on their total spending compared to the average order value (AOV). 
-- If a customer's total spending exceeds the AOV, label them as
-- 'Gold'; otherwise, label them as 'Silver'.
-- Return: The total number of orders and total revenue for each segment.

with cte as (
select o.customer_id,customer_name,avg(total_amount) as aov,sum(total_amount) as total_spending,count(o.order_id) as total_orders,
case when sum(total_amount)>avg(total_amount) then 'Gold' else 'Silver' end as segment
from orders as o left join customers as c
on o.customer_id=c.customer_id
group by 1
)
select segment,sum(total_orders) as tot_orders,sum(total_spending) as revenue from cte group by segment;

-- Q13. Rider Monthly Earnings
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.

select d.rider_id,
sum(total_amount)*0.08 as rider_earning,
extract(month from order_date) as months from orders as o join deliveries as d
on o.order_id=d.order_id
where delivery_status='Delivered'
group by rider_id,extract(month from order_date)
order by 1,3;

-- Question: 14
/* Find the number of 5-star, 4-star, and 3-star ratings each rider has.
Riders receive ratings based on delivery time:
● 5-star: Delivered in less than 15 minutes
● 4-star: Delivered between 15 and 20 minutes
● 3-star: Delivered after 20 minutes
*/
with cte as (
select rider_id,
case when delivery_time<order_time then 
timestampdiff(minute,order_time,Addtime(delivery_time,'24:00:00'))
 else timestampdiff(minute,order_time,delivery_time) end as time_diff
 from orders as o join deliveries as d
on o.order_id=d.order_id
where delivery_status='Delivered'
)
select rider_id,
sum(case when time_diff<15 then 1 else 0 end ) as "5-star",
sum(case when time_diff between 15 and 20 then 1 else 0 end) as "4-star",
sum(case when time_diff > 20 then 1 else 0 end) as "3-star"
from cte
group by rider_id
order by 1;

--  Q.15 Order Frequency by Day: 
-- Analyze order frequency per day of the week and identify the peak day for each restaurant

select restaurant_name,days,total_orders from(
select orders.restaurant_id,restaurant_name,
count(order_id) as total_orders,
row_number()over(partition by restaurant_id order by count(order_id) desc) as rnk,
dayname(order_date) as days from orders left join restaurants
on orders.restaurant_id=restaurants.restaurant_id
group by 1,5
) as orders_freq
where rnk=1;

-- Q16. Customer Lifetime Value (CLV)
-- Calculate the total revenue generated by each customer over all their orders.

select * from orders;

select customer_name,
sum(total_amount) as revenue
from orders join customers
on orders.customer_id=customers.customer_id
group by orders.customer_id;

-- Q17. Monthly Sales Trends
-- Identify sales trends by comparing each month's total sales to the previous month.

select 
extract(year from order_date) as years,
extract(month from order_date) as months,
sum(total_amount) as total_sales,
lag(sum(total_amount),1)over(order by extract(year from order_date), extract(month from order_date)) as previous
from orders
group by 1,2;

-- Q18. Rider Efficiency
-- Evaluate rider efficiency by determining average delivery times and identifying those with the
-- lowest and highest averages.

with cte as (
select o.order_id,d.rider_id,
case when delivery_time<order_time then
timestampdiff(minute,order_time,Addtime(delivery_time,'24:00:00'))
else timestampdiff(minute,order_time,delivery_time) end as time_diff
 from orders as o join deliveries as d
on o.order_id=d.order_id
where delivery_status='Delivered'
),
cte1 as (
select rider_id,
avg(time_diff) as average_time
from cte
group by 1
)
select min(average_time) as min ,max(average_time) as max from cte1;


-- Q19. Order Item Popularity
-- Track the popularity of specific order items over time and identify seasonal demand spikes.

-- season winter,summer,monsoon
-- winter:11-2
-- summer:3-6
-- monsoon:7-10

with cte as (
select *, case when extract(month from order_date) between 3 and 6 then 'summer'
when extract(month from order_date) between 7 and 10 then 'monsoon' else 'winter' end as seasons,
extract(month from order_date) as months
 from orders
 )
 select order_item,count(order_item) as total_orders,seasons
 from cte group by seasons,order_item
 order by 1,2 desc;
 
 
 -- Q20. City Revenue Ranking
-- Rank each city based on the total revenue for the last year (2023).

select city,
sum(total_amount) as revenue
from orders as o join restaurants as r
on o.restaurant_id=r.restaurant_id
where extract(year from order_date)=2023
group by city
order by revenue desc;

