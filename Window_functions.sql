select customer_id,payment_date,prior_date,(x.payment_date-x.prior_date) as interval, date_part('hours',x.payment_date-x.prior_date) as hours_since
from (
select customer_id,
payment_date,
lag(payment_date) over() as prior_date ,
row_number() over(partition by customer_id order by payment_date)  from payment) x;


﻿
with random_numbers as (
	select random() * 100 as val
	FROM generate_series(1,100)
)

SELECT rn.*, 
   CASE 
     WHEN rn.val < 50 THEN 'lt_50'
     WHEN rn.val >=50 THEN 'gte_50'
     ELSE 'some_other_condition'
     END as rand_outcome

FROM random_numbers rn

-- Get order nbr
WITH order_nbrs AS (
	SELECT p.*, row_number() over(partition by p.customer_id ORDER BY p.payment_date)
	FROM payment p
)

SELECT ons.* , 
CASE 
 WHEN ons.row_number = 1 THEN 'first_order'
 WHEN ons.row_number > 1 THEN 'repeat_order'
 ELSE 'checkme' END as order_outocme
FROM order_nbrs ons

﻿-- buyerid, email, first order, recent order, total spend
WITH base_table AS (
 SELECT p.customer_id, p.payment_date, 
 row_number() over(partition by p.customer_id order by p.payment_date asc) as early_order,
 row_number() over(partition by p.customer_id order by p.payment_date desc) as late_order	
 FROM payment p
), second_table AS (

	SELECT * FROM base_table bt 
	WHERE bt.early_order = 1 OR bt.late_order = 1
)

SELECT st.customer_id, max(st.payment_date) as rec_order, min(st.payment_date) as first_order,
(
	SELECT SUM(p2.amount) FROM payment p2 WHERE p2.customer_id = st.customer_id
) as ltv_spend
FROM second_table st 
GROUP BY 1 ORDER BY 1

-- Preferred Rating need to figure out  how to get their ratings
SELECT * FROM (
	SELECT t.customer_id, t.rating, count(*) , 
	row_number() over(partition by t.customer_id ORDER BY COUNT(*) DESC)
	FROM (
		SELECT r.customer_id, r.inventory_id, i.film_id, f.rating
		FROM rental r
		 JOIN inventory i on r.inventory_id = i.inventory_id
		 JOIN film f ON f.film_id = i.film_id
	) t GROUP BY 1, 2 ORDER BY 1, 3 DESC
) t2 WHERE t2.row_number = 1


SELECT t.customer_id, count(*) ,  array_agg(distinct t.rating),
row_number() over(partition by t.customer_id ORDER BY COUNT(*) DESC)
FROM (
	SELECT r.customer_id, r.inventory_id, i.film_id, f.rating
	FROM rental r
	 JOIN inventory i on r.inventory_id = i.inventory_id
	 JOIN film f ON f.film_id = i.film_id
) t GROUP BY 1
ORDER BY 1, 3 DESC

﻿-- FINDING all data about a customer's first order
-- Should have 1 row for each customer
-- the min is determined by the payment_date

SELECT * FROM (
	SELECT p.* FROM payment p
	JOIN (
	  SELECT p2.customer_id, min(p2.payment_date) as fo_date
	  FROM payment p2 
	  GROUP BY 1 
	)zebra ON zebra.fo_date = p.payment_date
	ORDER BY 2
)t WHERE t.staff_id = 2



-- row_number
-- can you get a list of orders by staff member, in reverse order?
-- get customer's most recent orders?

WITH first_orders AS (
SELECT * FROM (
	SELECT p.*, 
	       ROW_NUMBER() OVER(PARTITION BY p.customer_id ORDER BY p.payment_date )
	       FROM payment p
	       ORDER BY 2
	)t WHERE t.row_number = 1
)

SELECT * FROM first_orders








-- CASE
with rando_nbrs AS (
	select random() * 100 as val
	from generate_series(1,100)
)
SELECT rn.* ,
CASE
 WHEN rn.val < 50 THEN 'lt_50'
 WHEN rn.val < 90 THEN 'lt_90'
 WHEN rn.val < 101 THEN 'gt_90'
 ELSE 'oops' -- filter on that later...
END as outcome 
FROM rando_nbrs rn





WITH ranked_orders AS (
SELECT p.*, 
ROW_NUMBER() OVER(PARTITION BY p.customer_id ORDER BY p.payment_date )
FROM payment p
ORDER BY 2
)

SELECT ro.*,
CASE 
 WHEN ro.row_number = 1 THEN 'new_order'
 WHEN ro.row_number > 1 THEN 'rept_order'
  ELSE 'oops' END as outcome
FROM ranked_orders ro
