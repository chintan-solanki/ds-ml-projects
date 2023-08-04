use target;
/*
1. Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset
	1. Data type of columns in a table
	2. Time period for which the data is given
	3. Cities and States of customers ordered during the given period
*/

/* helper constructs */

/* create SP to populate reference time series months */

drop table if exists ts_year_month_ref; 
create table ts_year_month_ref(
	year int,
    month int,
    order_year_month char(7)
);

drop procedure if exists populate_ref_ts;
DELIMITER //
create procedure populate_ref_ts(IN dt1 datetime, IN dt2 datetime)
sp:begin
	declare year_curr int default extract(year from dt1);
    declare year_end int default extract(year from dt2);
    declare mon_curr int default extract(month from dt1);
    declare mon_end int default extract(month from dt2);
    
	while year_curr <= year_end do
		while mon_curr <= 12 do
			insert into ts_year_month_ref values(
				year_curr, 
				mon_curr, 
				concat(year_curr, '-', lpad(mon_curr, 2, 0))
			);
            
            if(year_curr = year_end and mon_curr >= mon_end) then
				leave sp;
			end if;
                        
			set mon_curr = mon_curr + 1;			
        end while;
        set mon_curr = 1;
        set year_curr = year_curr + 1;
    end while;
end //
DELIMITER ;

set @min_date = (select min(order_purchase_ts) from orders);
set @max_date = (select max(order_purchase_ts) from orders);
call populate_ref_ts(@min_date, @max_date);

select * from ts_year_month_ref;

/* create view for orders with derived fields */
drop view if exists orders_details;
create view orders_details as (select 	
	order_id,	
    customer_id,
    order_status,
    order_purchase_ts,
    extract(month from order_purchase_ts) as order_month,
    extract(year from order_purchase_ts) as order_year,
    concat(extract(year from order_purchase_ts), '-', lpad(extract(month from order_purchase_ts), 2, 0)) as order_year_month    
from orders o 
where order_status not in ('canceled', 'unavailable')
order by order_year_month);

select * from orders_details;





/* 1. Data type of columns */
desc geolocation;
desc customers;
desc sellers;
desc products;
desc orders;
desc order_items;
desc order_payment;
desc order_reviews;

/* 2. Time period for which the data is given */
select min(order_purchase_ts), max(order_purchase_ts) from orders;

/* 3. Cities and States of customers ordered during the given period */
/* unique states */
select distinct state from customers;

select distinct city from customers;

/* unique cities (a city name may be repeated across states
, so we take unique combination of city and state) */
select distinct city, state from customers;


/* 2. In-depth Exploration: */

/* a.	Is there a growing trend on e-commerce in Brazil? How can we describe a complete scenario? Can we see some seasonality with peaks at specific months? */

/* calculate yoy monthly growth in total sale price and number of orders */

with order_price as
(select order_id, sum(price) as price
from order_items
group by order_id),

orders_by_year_month as  
(select od.order_year_month, od.order_year, od.order_month, sum(op.price) as total_order_sale, count(1) as total_order_count 
from orders_details od inner join order_price op on od.order_id = op.order_id
group by od.order_year_month, od.order_year, od.order_month
)

select t.*, 
	case 
		when t.prev_yoy_total_order_sale = 0 then 0.0
        else round(((t.total_order_sale - t.prev_yoy_total_order_sale) / t.prev_yoy_total_order_sale) * 100, 1)
    end as yoy_order_sale_growth,
    case 
		when t.prev_yoy_total_order_count = 0 then 0.0
        else round(((t.total_order_count - t.prev_yoy_total_order_count) / t.prev_yoy_total_order_count) * 100, 1)
    end as yoy_order_count_growth
from
(	select 
		order_month, 
		order_year,
		total_order_sale,
		lag(total_order_sale, 1, 0) over(win) as prev_yoy_total_order_sale,
		total_order_count,
		lag(total_order_count, 1, 0) over(win) as prev_yoy_total_order_count
	from orders_by_year_month
	window win as (partition by order_month order by order_year asc)
) as t;


/* identify monthly seasonality */

with order_price as
(select order_id, sum(price) as price
from order_items
group by order_id),

monthly_sales_data as
(select 
	od.order_month as month, 
	count(distinct order_year) as unique_years, 
    sum(op.price) as total_monthly_sale_all_years,     
    count(*) as total_orders_all_years, 
    (sum(op.price) / count(distinct order_year)) as avg_monthly_sale,
    (count(1) / count(distinct order_year)) as avg_monthly_orders
    
from orders_details od inner join order_price op on od.order_id = op.order_id
group by od.order_month
)

-- select * from monthly_sales_data order by avg_monthly_sale desc;

select * from monthly_sales_data order by avg_monthly_orders desc;











/* b.	What time do Brazilian customers tend to buy (Dawn, Morning, Afternoon or Night)? */

set @total_orders = (select count(1) from orders);

/*
   By time of the day..
   dawn - 5-6
   morning - 7 to 11
   afternoon - 12 to 16
   evening - 17 to 21
   night - 22 - 4
*/

select 	
	case 
		when hour(order_purchase_ts) between 5 and 6 then 'dawn'
        when hour(order_purchase_ts) between 7 and 11 then 'morning'
        when hour(order_purchase_ts) between 12 and 16 then 'afternoon'
        when hour(order_purchase_ts) between 17 and 21 then 'evening'
        when hour(order_purchase_ts) between 22 and 23 then 'night'
        when hour(order_purchase_ts) between 0 and 4 then 'night'
		else 'invalid time'
	end time_of_day,
    count(*) as order_count,
    round((count(1) / @total_orders) * 100, 2) as order_percent
from orders 
group by time_of_day
order by order_count desc;

/* By each hour */

select 	
	hour(order_purchase_ts) as purchase_hour, 
    count(1) as order_count,
    round((count(1) / @total_orders) * 100, 2) as order_percent
from orders 
group by purchase_hour
order by order_count desc;



/* 3.	Evolution of E-commerce orders in the Brazil region: */




/* a.	Get month on month orders by states */

select order_status, count(*) as count_order from orders group by order_status;

/* reference time series per state */

with
state_ts as ( 
	select *
    from (select distinct state from customers) as states, ts_year_month_ref
),

/* 
	To address gaps in timeseries, we take left outer join of state_ts with orders_details and customers table.
    We then group by (state and order_year_month) and count number of orders per group. 
*/
orders_by_state_and_year_month as (
	select s_ts.state, 
		s_ts.order_year_month, 
        count(t.order_purchase_ts) as order_count,
        lag(count(t.order_purchase_ts), 1, 0) over(partition by s_ts.state order by s_ts.order_year_month asc) as prev_month_order_count
	from state_ts s_ts left outer join
		(select c.state, o.order_purchase_ts, o.order_year_month
			from orders_details o join customers c on o.customer_id = c.customer_id
		) as t on t.state = s_ts.state and t.order_year_month = s_ts.order_year_month
	group by s_ts.state, s_ts.order_year_month
	order by s_ts.state, s_ts.order_year_month
)

/* show mom orders by state */
select state, 
	order_year_month, 
    order_count,
	prev_month_order_count,
    case 
		when prev_month_order_count = 0 then 0.0
        else round(((order_count - prev_month_order_count) / prev_month_order_count) * 100, 1)
    end as mom_order_growth_percent
from orders_by_state_and_year_month;




/* b.	Distribution of customers across the states in Brazil */

set @total_cust = (select count(*) from customers);

select state, 
	count(*) as customer_count,
    round((count(*) / @total_cust) * 100, 2) as customer_percent
from customers
group by state
order by count(*) desc;



/* 4.	Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others. */

/* a.	Get % increase in cost of orders from 2017 to 2018 (include months between Jan to Aug only) - You can use payment_value column in payments table. */

with cost_by_year as
(select o.order_year, sum(op.payment_value) as total_order_cost
from (select order_id,	            
		extract(month from order_purchase_ts) as order_month,
		extract(year from order_purchase_ts) as order_year        
		from orders o where order_status not in ('canceled', 'unavailable')) as o 
	join order_payment as op on o.order_id = op.order_id
where o.order_month between 1 and 8 and o.order_year in (2017, 2018)
group by o.order_year
order by o.order_year asc)

select order_year, 
	case 
		when prev_year_order_cost = 0 then 0.0
        else round((total_order_cost - prev_year_order_cost) * 100 / prev_year_order_cost , 1) 
    end as cost_growth
from (select 
	order_year,
    total_order_cost,
    lag(total_order_cost, 1, 0) over(order by order_year asc) as prev_year_order_cost
from cost_by_year) as t;
 

/* b.	Mean & Sum of price and freight value by customer state */

with price_freight_by_State as
(select c.state, sum(order_price) as total_price, avg(order_price) as avg_price, sum(order_freight_value) as total_freight_value, avg(order_freight_value) as avg_freight_value
from 
	/* aggregate price and freight values at order level*/
    (select o.order_id, o.customer_id, sum(oi.price) as order_price, sum(oi.freight_value) as order_freight_value
	from orders o join order_items oi on o.order_id = oi.order_id
	group by o.order_id, o.customer_id) as t 
    inner join customers c on t.customer_id = c.customer_id
group by c.state)

-- select * from price_freight_by_State order by total_price desc;
-- select * from price_freight_by_State order by avg_price desc;
-- select * from price_freight_by_State order by total_freight_value desc;
select * from price_freight_by_State order by avg_freight_value desc;




/* 5.	Analysis on sales, freight and delivery time */

-- a.	Calculate days between purchasing, delivering and estimated delivery
-- b.	Find time_to_delivery & diff_estimated_delivery. Formula for the same given below:
	-- i.	time_to_delivery = order_purchase_timestamp-order_delivered_customer_date
	-- ii.	diff_estimated_delivery = order_estimated_delivery_date-order_delivered_customer_date
    
with delivery_details as
(select order_id, order_purchase_ts, order_estimated_delivery_date, 
	datediff(order_estimated_delivery_date, order_purchase_ts) estimated_time_to_delivery,
    datediff(order_delivered_customer_date, order_purchase_ts) time_to_delivery,
    datediff(order_estimated_delivery_date, order_delivered_customer_date) diff_estimated_delivery
from orders 
where order_status = 'delivered')

select * from delivery_details;


-- c.	Group data by state, take mean of freight_value, time_to_delivery, diff_estimated_delivery

 
/* calculate time_to_delivery and diff_estimated_delivery for delivered orders */
drop view if exists delivery_details;
create view delivery_details as
(select order_id, order_purchase_ts, order_estimated_delivery_date, 
    datediff(order_delivered_customer_date, order_purchase_ts) time_to_delivery,
    datediff(order_estimated_delivery_date, order_delivered_customer_date) diff_estimated_delivery
from orders 
where order_status = 'delivered');

/* aggregate price and freight at order level */
drop view if exists order_price_details;
create view order_price_details as 
(select o.order_id, o.customer_id, c.state, sum(oi.price) as order_price, sum(oi.freight_value) as order_freight_value
	from orders o 
		inner join order_items oi on o.order_id = oi.order_id
        inner join customers c on o.customer_id = c.customer_id
	group by o.order_id, o.customer_id, c.state); 

/* aggregate price, freight, time_to_delivery, and diff_estimated_delivery at state level */
drop view if exists state_delivery_metrics;
create view state_delivery_metrics as 
(select od.state, 
	avg(order_freight_value) avg_freight_value, 
    avg(time_to_delivery) avg_time_to_delivery, 
    avg(diff_estimated_delivery) avg_diff_estimated_delivery
from order_price_details od inner join delivery_details dd on od.order_id = dd.order_id
group by od.state);
    
select * from state_delivery_metrics;

-- d.	Sort the data to get the following:
	-- i.	Top 5 states with highest/lowest average freight value - sort in desc/asc limit 5
    select * from state_delivery_metrics
    order by avg_freight_value asc limit 5;

	select * from state_delivery_metrics
    order by avg_freight_value desc limit 5;
    
	-- ii.	Top 5 states with highest/lowest average time to delivery
    
    select * from state_delivery_metrics
    order by avg_time_to_delivery asc limit 5;

	select * from state_delivery_metrics
    order by avg_time_to_delivery desc limit 5;
    
	-- iii.	Top 5 states where delivery is really fast/ not so fast compared to estimated date

	select * from state_delivery_metrics
    order by avg_diff_estimated_delivery asc limit 5;

	select * from state_delivery_metrics
    order by avg_diff_estimated_delivery desc limit 5;
    


/* 6. Payment type analysis: */

/* Month over Month count of orders for different payment types */

with
payment_type_ts as ( 
	select *
    from (select distinct payment_type from order_payment) as payment_types, ts_year_month_ref
),

order_payment_type as (select distinct order_id, payment_type from order_payment),

orders_by_payment_type_and_year_month as (
	select pt_ts.payment_type, 
		pt_ts.order_year_month, 
        count(t.order_purchase_ts) as order_count,
        lag(count(t.order_purchase_ts), 1, 0) over(partition by pt_ts.payment_type order by pt_ts.order_year_month asc) as prev_month_order_count
	from payment_type_ts pt_ts left outer join
		(select op.payment_type, o.order_purchase_ts, o.order_year_month
			from orders_details o join order_payment_type op on o.order_id = op.order_id
		) as t on t.payment_type = pt_ts.payment_type and t.order_year_month = pt_ts.order_year_month
	group by pt_ts.payment_type, pt_ts.order_year_month
	order by pt_ts.payment_type, pt_ts.order_year_month
)

/* show mom orders by payment_type */
select payment_type, 
	order_year_month, 
    order_count,
	prev_month_order_count,
    case 
		when prev_month_order_count = 0 then 0.0
        else round(((order_count - prev_month_order_count) / prev_month_order_count) * 100, 1)
    end as mom_order_growth_percent
from orders_by_payment_type_and_year_month;





/* Count of orders based on the no. of payment installments */

with
payment_installment_count_ts as ( 
	select *
    from (select distinct payment_installment from order_payment order by payment_installment) as payment_installment, ts_year_month_ref
),

order_payment_installment as (select distinct order_id, payment_installment from order_payment),

orders_by_payment_installment_and_year_month as (
	select pi_ts.payment_installment, 
		pi_ts.order_year_month, 
        count(t.order_purchase_ts) as order_count,
        lag(count(t.order_purchase_ts), 1, 0) over(partition by pi_ts.payment_installment order by pi_ts.order_year_month asc) as prev_month_order_count
	from payment_installment_count_ts pi_ts left outer join
		(select op.payment_installment, o.order_purchase_ts, o.order_year_month
			from orders_details o join order_payment_installment op on o.order_id = op.order_id
		) as t on t.payment_installment = pi_ts.payment_installment and t.order_year_month = pi_ts.order_year_month
	group by pi_ts.payment_installment, pi_ts.order_year_month
	order by pi_ts.payment_installment, pi_ts.order_year_month
)

/* show mom orders by payment_installment */
select payment_installment, 
	order_year_month, 
    order_count,
	prev_month_order_count,
    case 
		when prev_month_order_count = 0 then 0.0
        else round(((order_count - prev_month_order_count) / prev_month_order_count) * 100, 1)
    end as mom_order_growth_percent
from orders_by_payment_installment_and_year_month;





/* orders by states */

select c.state, sum(order_price) as total_sale, count(*) as total_orders
from orders o 
	inner join customers c on o.customer_id = c.customer_id 
    inner join (select order_id, sum(price) as order_price from order_items group by order_id) as op on o.order_id = op.order_id
group by c.state
order by total_sale desc;

/* orders by payment type */
select op.payment_type, sum(payment_value) as total_payment, count(*) as total_orders, count(*)
from orders o 
	inner join customers c on o.customer_id = c.customer_id 
    inner join (select order_id, payment_type, sum(payment_value) as payment_value from order_payment group by order_id, payment_type) as op on o.order_id = op.order_id
group by op.payment_type
order by total_payment desc;



set @order_count = (select count(distinct order_id) from order_payment);

select t.payment_installment, count(*) as total_orders, round((count(*)/ @order_count)*100, 2) as orders_percent
from 
(select order_id, payment_installment, sum(payment_value) as payment_value
from order_payment op
group by order_id, payment_installment) as t
group by t.payment_installment
order by total_orders desc;



select t.state, sum(iscanceled) as cancel_count, count(*) as order_count, round((sum(iscanceled)/count(*))*100, 2) as cancel_rate
from
(select o.order_id, c.state, o.order_status,
	case 
		when o.order_status = 'canceled' then 1
        else 0
    end iscanceled
from orders o inner join customers c on o.customer_id = c.customer_id) as t
group by t.state




select * from 

