create database project2;
use project2;

-- Question 1: Find the top 3 customers who have the maximum number of orders

select cust_id,count(ord_id) as total_order from market_fact
group by 1
order by total_order desc
limit 3;

--  Question 2: Create a new column DaysTakenForDelivery that contains the date difference between Order_Date and Ship_Date.


select *,datediff(str_to_date(ship_date,'%d-%m-%Y'),str_to_date(order_date,'%d-%m-%Y')) as daystakenfordelivery 
from orders_dimen od join shipping_dimen sd
on od.order_id=sd.order_id;


-- Question 3: Find the customer whose order took the maximum time to get delivered.

select cust_id,max(datediff(str_to_date(ship_date,'%d-%m-%Y'),
str_to_date(order_date,'%d-%m-%Y'))) as Time_took_to_deliver 
from orders_dimen od join shipping_dimen sd
on od.order_id=sd.order_id
join market_fact mf
on substring(mf.ord_id,5,4)=od.order_id
group by 1
order by Time_took_to_deliver desc
limit 1;


-- q4) : Retrieve total sales made by each product from the data (use Windows function)

select distinct prod_id,round(sum(sales) over(partition by prod_id),2) as total_sales 
from market_fact;

-- 5. Retrieve total profit made by each product from the data (use Windows function)

select distinct Prod_id,round(sum(profit)over(partition by Prod_id),2)
from market_fact;
-- for each distinct productid we are adding profit using windows function , over partition by productid.As we can see 17 products with its product id and its profit 
-- 6: Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
-- here we collecting data for which unique customers come in january and also they come in 


select distinct monthname(str_to_date(order_date, '%d-%m-%Y')) as monthname,
count(cust_id) no_of_returning_customer 
from market_fact mf
join orders_dimen od using (ord_id) 
where year(str_to_date(order_date, '%d-%m-%Y'))=2011 and cust_id in (
select DISTINCT mf.cust_id as cust_id  from market_fact mf
join orders_dimen od
on od.ord_id = mf.ord_id
where month(str_to_date(order_date, '%d-%m-%Y')) = 1 and 
year(str_to_date(order_date, '%d-%m-%Y')) = 2011)
group by 1;




-- In inner query we have collected customer id where they have came in january 2011 , using that in outer query we display monthname and the customer id matching with inner sub query

select distinct month(str_to_date(order_date,'%d-%m-%Y')),count(cust_id) as count 
from market_fact mf join orders_dimen od
on od.ord_id=mf.ord_id
where cust_id in
(select distinct cust_id from market_fact mf join orders_dimen od 
on  od.ord_id=mf.ord_id
where month(str_to_date(order_date,'%d-%m-%Y'))=1 and year(str_to_date(order_date,'%d-%m-%Y'))=2011)
and month(str_to_date(order_date,'%d-%m-%Y'))>1 and year(str_to_date(order_date,'%d-%m-%Y'))=2011
group by 1;

-- restaurant dataset
-- 1.We need to find out the total visits to all restaurants under all alcohol categories available.

select alcohol,count(userid)
from geoplaces2 g join userprofile u
on round(g.latitude)=round(u.latitude)
and round(g.longitude)=round(u.longitude)
group by alcohol;


-- 2.Let's find out the average rating according to alcohol and price so that we can understand the rating in respective price 
--   categories as well.

select alcohol,avg(rating),price
from rating_final r join geoplaces2 g
on r.placeID=g.placeID
group by 1,price;

-- 3.Let’s write a query to quantify that what are the parking availability as well in different alcohol categories along with the 
--   total number of restaurants.

select parking_lot,alcohol,count(g.placeID) No_of_restaurants
from geoplaces2 g join chefmozparking c
on g.placeID=c.placeID
group by 1,2;
-- we have grouped parking_lot , alcohol and then taken the count of no of restaurants , we have joined two tables to get parking lot and alcohol column 
-- so for each category of parking lot and alcohol we have taken count of no of restaurants
-- 4.Also take out the percentage of different cuisine in each alcohol type.

select alcohol,parking_lot,no_of_restaurents,(diff_cuisine/total)*100 as percentage from
 (select alcohol,parking_lot,count(g.placeid) no_of_restaurents,count(distinct rcuisine) as diff_cuisine,count(rcuisine) as total from geoplaces2 g join chefmozparking cp
 on cp.placeid=g.placeid
 join chefmozcuisine cc
 on cc.placeid=cp.placeid
 group by 1,2) as t;

-- 5.let’s take out the average rating of each state.

select state,avg(rating)
from geoplaces2 g join rating_final r
on g.placeID=r.placeID
where state != '?'
group by 1;

-- 6.' Tamaulipas' Is the lowest average rated state. Quantify the reason why it is the lowest rated by providing the summary on the basis 
--   of State, alcohol, and Cuisine.

with t as(
select distinct state as state ,alcohol as alcohol ,rcuisine cuisine from geoplaces2 gp
join chefmozcuisine cc
on cc.placeid = gp.placeid)
select  state,alcohol,count(cuisine) cuisine_available,(select count(distinct rcuisine) from chefmozcuisine) as total_cuisine,
	count(cuisine)/(select count(distinct rcuisine) from chefmozcuisine) *100 percent_available
from t
group by 1,2;


select g.state, g.alcohol,c.rcuisine 
from geoplaces2 g join chefmozcuisine c
on g.placeid = c.placeid 
where g.state ='Tamaulipas';
-- 7.Find the average weight, food rating, and service rating of the customers who have visited KFC and tried Mexican or Italian types of
--   cuisine, and also their budget level is low. We encourage you to give it a try by not using joins.
 
select * from rating_final where placeid =(
select placeid from geoplaces2 where name = 'KFC');
with t as(
select *from rating_final 
where placeid in ( select placeid from chefmozcuisine where rcuisine in ('Mexican','Italian'))
and userid in (select userid from rating_final where placeid =(select placeid from geoplaces2 where name = 'KFC'))
and userid in (select userid from userprofile where budget = 'low'))
select  avg( (select weight from userprofile where userid = t.userid )) as avg_weight ,avg(rating) avg_r,avg(food_rating) avg_f ,avg(service_rating) avg_s
from t ;
