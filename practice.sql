-- START Q1 
-- Northwind has a policy where after the 1st late order for a customer, 
-- it gives a 20% refund for all subsequent late orders per customer. 
-- The 20% refund is applied to the total order value (quantity x unitprice). 
-- Calculate amount of refunds Northwind has paid per product name in total as a result of late orders. Disregard discounts.
WITH late_o AS(
	SELECT o.customerid, p.productname, o.orderid, o.requireddate, o.shippeddate, od.*,
			rank() OVER(
				PARTITION BY o.customerid ORDER BY o.orderdate) AS row_num 
				-- use rank NOT order since customer can order different products on same day
	FROM public.orders o
	JOIN public.order_details od ON od.orderid=o.orderid
	JOIN public.products p ON p.productid=od.productid
	WHERE o.requireddate < o.shippeddate)
SELECT productname, 
	   SUM(quantity*unitprice)::INT AS total_value_of_late_orders, 
	   SUM((quantity*unitprice)*0.2)::INT AS total_refunded_value
FROM late_o
WHERE row_num >1
GROUP BY productname
ORDER BY SUM(quantity*unitprice) DESC;

-- END Q1
-- START Q2
-- Northwind’s HR team is performing an analysis of managers at Northwind, to see if there are wide disparities between 
-- the responsibilities of different managers. List each manager at Northwind, along with the number of employees they manage,
-- the number of regions and territories they oversee, the number of orders their reports have processed,
-- and the number of customers associated with these orders.

SELECT DISTINCT em.firstname ||' '|| em.lastname AS manager_name,
       COUNT(DISTINCT t.regionid) AS regions,
	   COUNT(DISTINCT e.employeeid) AS employees,
	   COUNT(DISTINCT et.territoryid) AS territories,
	   COUNT(DISTINCT o.orderid) AS orders,
	   COUNT(DISTINCT o.customerid) AS customers
FROM employees e
JOIN employees em ON em.employeeid = e.reportsto
JOIN employeeterritories et ON et.employeeid = e.employeeid
JOIN orders o ON o.employeeid = e.employeeid
JOIN territories t ON t.territoryid = et.territoryid
GROUP BY 1;

-- END Q2
-- START Q3
--  For orders by German customers, list in chronoogical order their order IDs, order dates, 
-- order totals (quantity x unitprice with discount applied), running order total, and average order total.
WITH german AS(
SELECT o.orderid, 
		o.orderdate, 
		SUM(((1-od.discount)*od.unitprice)*od.quantity) AS order_total
FROM customers c
JOIN orders o ON o.customerid = c.customerid
JOIN public.order_details od ON od.orderid = o.orderid
WHERE c.country = 'Germany'
GROUP BY 1,2
ORDER BY 1)

SELECT orderid,
		orderdate,
		order_total,
		SUM(order_total) OVER(ORDER BY orderid) AS running_total,
		AVG(order_total) OVER(ORDER BY orderid) AS average_order_total
FROM german;

-- END Q3
-- START Q4
--We need to cut back on unpopular product lines. List all products that have had a total markdown value of over $3,000. 
-- The markdown value is the difference between the unitprice of the product and the unit price of the order x quantity. 
-- Do not list Meat/Poultry category products.

SELECT p.productid, p.productname, SUM((p.unitprice-od.unitprice)*od.quantity) mark_price
FROM public.order_details od
JOIN public.products p ON p.productid = od.productid
JOIN public.categories c ON c.categoryid = p.categoryid
WHERE c.categoryname NOT IN ('Meat/Poultry') 
GROUP BY 1,2
HAVING SUM((od.unitprice*od.quantity)-p.unitprice)> 3000
ORDER BY SUM((od.unitprice*od.quantity)-p.unitprice) DESC;

-- END Q4
-- START Q5
-- List out each employee, the number of orders they have processed, the percentage of total order volume that employee 
-- has contributed to, and also the difference between their order number and the average orders per employee. 
-- Categorize employees with under 50 orders as Associates, 51-100 orders as Senior Associates, and 101+ as Principals. 
-- Order by the number of orders processed per employee.

WITH e_orders AS(
SELECT e.employeeid, e.firstname ||' '|| e.lastname AS fullname, COUNT(o.orderid) orders
FROM employees e
JOIN orders o ON o.employeeid = e.employeeid
GROUP BY 1,2)
--SELECT SUM(orders)
--FROM e_orders

SELECT*,
		ROUND(orders/(SELECT SUM(orders) FROM e_orders)::NUMERIC,2) AS pct_of_order,
		ROUND(orders-(SELECT AVG(orders) FROM e_orders):: NUMERIC,2) AS order_differential,
		CASE 
		WHEN orders < 50 THEN 'Associate'
		WHEN orders >=50 AND orders <=100 THEN 'Senior Associate'
		ELSE 'Principal' END AS title
FROM e_orders
ORDER BY orders DESC;

-- END Q5
-- START Q6
-- Produce the query for a dashboard that will display in the C-Suite monitors, 
-- that shows the number of employees, customers, orders, and territories.

SELECT 'Number of Orders' AS category, COUNT(orderid) AS count
FROM orders o
UNION 
SELECT 'Number of Customers' AS category, COUNT(customerid) AS count
FROM customers c
UNION 
SELECT 'Number of Territories' AS category, COUNT(territoryid) AS count
FROM territories
UNION
SELECT 'Number of Employees' AS category, COUNT(employeeid) AS count
FROM employees

ORDER BY count DESC;

-- or: 
SELECT*
FROM(
SELECT 'Number of Orders' AS category, COUNT(orderid)
FROM orders o
UNION 
SELECT 'Number of Customers' AS category, COUNT(customerid) 
FROM customers c
UNION 
SELECT 'Number of Territories' AS category, COUNT(territoryid) 
FROM territories
UNION
SELECT 'Number of Employees' AS category, COUNT(employeeid) 
FROM employees) t1
ORDER BY 2 DESC;

-- END Q6


