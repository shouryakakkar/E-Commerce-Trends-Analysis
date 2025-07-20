create database eta;
use eta;

create table customers (customer_id varchar(50) primary key, customer_name varchar(100));

load data infile 'Customers.csv'
into table customers
fields terminated by ',' 
lines terminated by '\n'
ignore 1 rows;

create table products (product_id varchar(50) primary key, product_name varchar(100), category varchar(50), price decimal(10,2), stock int, price_range varchar(50));

load data infile 'Products.csv'
into table products
fields terminated by ',' 
lines terminated by '\n'
ignore 1 rows;

create table orders (order_id varchar(50) primary key, customer_id varchar(50), order_date date, order_status varchar(50), discount_amount decimal(10,2), shipment_carrier varchar(50), delivery_date date, delivery_time_days int, order_month varchar(20), foreign key (customer_id) references customers(customer_id));

load data infile 'Orders.csv'
into table orders
fields terminated by ',' 
lines terminated by '\n'
ignore 1 rows;

create table orderitems (order_item_id int primary key, order_id varchar(50), product_id varchar(50), quantity int, unit_price decimal(10,2), foreign key (order_id) references orders(order_id), foreign key (product_id) references products(product_id));

load data infile 'OrderItems.csv'
into table orderitems
fields terminated by ',' 
lines terminated by '\n'
ignore 1 rows;

create table reviews (review_id varchar(50) primary key, product_id varchar(50), rating int, foreign key (product_id) references products(product_id));

load data infile 'Reviews.csv'
into table reviews
fields terminated by ',' 
lines terminated by '\n'
ignore 1 rows;

-- Q1. What are the average prices of products by category, filtered to only show categories with an average price greater than $100?
select category, round(avg(price), 2) as avg_price from products
group by category having avg_price > 100;

-- Q2. What are the top 5 best-selling products?
select p.product_id, p.product_name, sum(oi.quantity) as total_sold from orderitems oi
join products p on oi.product_id = p.product_id
group by p.product_id, p.product_name
order by total_sold desc limit 5;

-- Q3. Write a trigger that automatically updates the stock of a product when an order is placed.
DELIMITER //
create trigger update_stock_after_order
after insert on orderitems
for each row
begin
update products
set stock = stock - new.quantity
where product_id = new.product_id;
end//
DELIMITER ;

-- Q4. Which products have received 5-star reviews?
select distinct p.product_id, p.product_name from products p
join reviews r on p.product_id = r.product_id where r.rating = 5;

-- Q5. How much discount has been applied to each order?
select order_id, discount_amount from orders;

-- Q6. How many orders were placed each month?
select 
case order_month
when 1 then 'january'
when 2 then 'february'
when 3 then 'march'
when 4 then 'april'
when 5 then 'may'
when 6 then 'june'
when 7 then 'july'
when 8 then 'august'
when 9 then 'september'
when 10 then 'october'
when 11 then 'november'
when 12 then 'december'
end as month_name,
count(*) as total_orders
from orders
group by order_month
order by order_month;

-- Q7. Create a view that shows all orders along with customer names and order statuses, and how can you query this view to get all 'Shipped' orders?
create view orderswithcustomer as
select o.order_id, c.customer_name, o.order_status from orders o
join customers c on o.customer_id = c.customer_id;
select * from orderswithcustomer where order_status = 'shipped';

-- Q8. Which customers have spent the most?
select c.customer_id, c.customer_name, round(sum(oi.quantity * oi.unit_price), 2) as total_spent
from customers c
join orders o on c.customer_id = o.customer_id
join orderitems oi on o.order_id = oi.order_id
group by c.customer_id, c.customer_name
order by total_spent desc;

-- Q9. What is the average rating and total reviews for each product?
select p.product_id, p.product_name, round(avg(r.rating), 2) as avg_rating, count(r.review_id) as total_reviews from products p
left join reviews r on p.product_id = r.product_id
group by p.product_id, p.product_name;

-- Q10. How many shipments were handled by each carrier?
select shipment_carrier, count(*) as total_shipments from orders
where shipment_carrier is not null
group by shipment_carrier;

-- Q11. Which orders were placed in the year 2024?
select * from orders where year(order_date) = 2024;

-- Q12.  How can you rank customers based on their total spending using a window function?
select customer_id, customer_name, total_spent, rank() over (order by total_spent desc) as spending_rank from (
select c.customer_id, c.customer_name, sum(oi.quantity * oi.unit_price) as total_spent from customers c 
join orders o on c.customer_id = o.customer_id
join orderitems oi on o.order_id = oi.order_id
group by c.customer_id, c.customer_name
) as spending_data;

-- Q13. What is the delivery time for each completed order?
select order_id, delivery_time_days from orders where order_status = 'delivered';

-- Q14. How can products be categorized by price range?
select product_name, price, price_range from products;

-- Q15. How many unique delivered orders were made by each customer?
select customer_id, count(distinct order_id) as delivered_orders from orders
where order_status = 'delivered' group by customer_id;