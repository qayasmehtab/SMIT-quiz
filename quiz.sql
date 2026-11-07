use bikestores

---Chapter 1: Querying & Filtering
--Q1. (LIKE, IN, ORDER BY with multiple columns) Return the first_name, last_name and city
-- of customers who live in the state NY or CA, whose email ends in .com and whose last_name starts
-- with the letter M. Sort by city ascending, then last_name ascending.


SELECT 
	first_name,
	last_name,
	city
FROM
	sales.customers
WHERE 
	state IN ('NY', 'CA')
AND email LIKE '%.com'
AND last_name LIKE 'M%'
ORDER BY 
	city ASC, last_name ASC;


--Q2. (Aliases, calculated column, ORDER BY, pagination) Show product_name, 
--list_price and a calculated column called discounted_price (10% off) for products 
--with a list_price above 500. Skip the 10 most expensive products and return the 
--next 10 (the 11th to 20th most expensive).


SELECT 
	product_name,
	list_price,
	list_price * 0.9 AS discounted_price
FROM 
	production.products
WHERE
	list_price > 500
ORDER BY 
	list_price DESC;

--Q3. (NULL, BETWEEN, AND/OR precedence) Find all orders that are either Pending or Processing, 
--have not shipped yet, and were placed between 2018-01-01 and 2018-06-30. Return 
--order_id, order_date, required_date and order_status. Your AND/OR logic must be explicitly grouped.



SELECT 
	product_name, 
	list_price, 
	list_price * 0.9 AS discounted
FROM 
	production.products
WHERE
	list_price > 500
ORDER BY 
	list_price DESC
	OFFSET 10 ROWS 
	FETCH NEXT 10 ROWS ONLY;

--Chapter 2: Joins
--Q4. (Multi-table INNER JOIN, 5 tables) For all Completed orders placed in 2018,
--- return the customer's full name, order_id, order_date, store_name, 
--product_name and quantity. Sort by order_date, newest first.

SELECT 
	p.product_name,
	c.category_name,
	b.brand_name
FROM
	production.products AS p
INNER JOIN 
	production.categories AS c 
	ON p.category_id = c.category_id
INNER JOIN
	production.brands As b
	ON p.brand_id = b.brand_id
LEFT JOIN
	sales.order_items AS oi 
	ON p.product_id = oi.product_id
WHERE
	oi.product_id IS NULL;


---Q5. (LEFT JOIN + NULL check, 4 tables) List every product that has never been sold, 
---showing product_name, category_name and brand_name.

SELECT 
	p.product_name,
	c.category_name,
	b.brand_name
FROM
	production.products AS p
INNER JOIN 
	production.categories c 
	ON p.category_id = c.category_id
INNER JOIN 
	production.brands AS b
	ON p.brand_id = b.brand_id
LEFT JOIN
	sales.order_items AS oi 
	ON p.product_id = oi.product_id
WHERE 
	oi.product_id IS NULL;


--Q6. (Self join + extra join) Show every staff member's full name, 
--their manager's full name (NULL for the top-level person) and the name of the store they work in

SELECT 
    CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    st.store_name
FROM 
	sales.staffs s
LEFT JOIN 
	sales.staffs AS m 
ON s.manager_id = m.staff_id
INNER JOIN
	sales.stores AS st 
ON s.store_id = st.store_id;


--Chapter 3: Views
--Q7. (CREATE VIEW + query the view)
--(a) Create a view sales.vw_order_details that joins orders, customers, 
--order_items and products and exposes: order_id, order_date, order_status, customer_id, 
--first_name, last_name, product_name, quantity and a calculated line_total 
--(quantity × list_price × (1 − discount)).
--(b) Using only that view, return each customer's total spend on Completed orders, 
--and keep only customers who spent more than 10,000. Sort by total spend, highest first.

CREATE VIEW sales.vw_order_details AS
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    c.customer_id,
    c.first_name,
    c.last_name,
    p.product_name,
    oi.quantity,
    (oi.quantity * oi.list_price * (1 - oi.discount)) AS line_total
FROM 
	sales.orders AS o
INNER JOIN 
	sales.customers c 
ON o.customer_id = c.customer_id
INNER JOIN 
	sales.order_items AS oi 
ON o.order_id = oi.order_id
INNER JOIN
	production.products AS p
ON oi.product_id = p.product_id;


SELECT 
    customer_id,
    first_name,
    last_name,
    SUM(line_total) AS total_spend
FROM 
	sales.vw_order_details
WHERE
	order_status = 4
GROUP BY
	customer_id, first_name, last_name
HAVING
	SUM(line_total) > 10000
ORDER BY 
	total_spend DESC;



--Chapter 4: Aggregation
--Q8. (GROUP BY on multiple columns, HAVING, COUNT DISTINCT, joins, 
--top N) For each combination of category_name and brand_name,
-- return the number of distinct orders and the total revenue. Keep only combinations 
--that appear in at least 20 distinct orders, and return the top 5 by revenue.

SELECT TOP 5
    c.category_name,
    b.brand_name,
    COUNT(DISTINCT oi.order_id) AS distinct_orders,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
FROM 
	production.categories AS c
INNER JOIN
	production.products AS p 
ON c.category_id = p.category_id
INNER JOIN
	production.brands AS b
ON p.brand_id = b.brand_id
INNER JOIN 
	sales.order_items oi 
ON p.product_id = oi.product_id
GROUP BY 
	c.category_name, b.brand_name
HAVING COUNT(DISTINCT oi.order_id) >= 20
ORDER BY 
	total_revenue DESC;




--Q9. (Aggregation across joins, YEAR(), COUNT DISTINCT) For each store and each order year,
-- return store_name, order_year, the number of distinct orders and total revenue. 
--Sort by store_name, then order_year.

.
SELECT 
    s.store_name,
    YEAR(o.order_date) AS order_year,
    COUNT(DISTINCT o.order_id) AS distinct_orders,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
FROM 
	sales.stores s
INNER JOIN 
	sales.orders o ON s.store_id = o.store_id
INNER JOIN
	sales.order_items oi ON o.order_id = oi.order_id
GROUP BY 
	s.store_name, YEAR(o.order_date)
ORDER BY 
	s.store_name, order_year;


--Chapter 5: Subqueries
---Q10. (Nested subqueries, 4 levels of IN, no joins) Return the first and last names 
--of customers who have ordered at least one product from the brand 'Electra'.
-- Use only nested IN subqueries.




---Q11. (NOT IN, NULL-safe) Find customers who have never placed an order.
-- Make the query safe against NULL values in the subquery.


SELECT 
	customer_id, 
	first_name, 
	last_name, 
	phone, email, 
	street,
	city,
	state, 
	zip_code
FROM 
	sales.customers
WHERE 
	customer_id NOT IN( 
SELECT 
	customer_id 
FROM 
    sales.orders 
WHERE 
	customer_id IS NOT NULL
);