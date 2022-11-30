######## CASE STUDY 1: DANNY'S DINNER
### Creating database
CREATE DATABASE danny_dinner;
USE danny_dinner;


#### CREATING TABLES
# creating sales table
CREATE TABLE sales (
	customer_id VARCHAR(1), 
    order_date DATE, 
    product_id tinyint);

# insert values into sales table
INSERT INTO sales
 (customer_id, order_date, product_id)
VALUES 
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
  # creating menu table
  CREATE TABLE menu (
	 product_id tinyint, 
     product_name VARCHAR(5), 
     price INT);

# inserting values
INSERT INTO menu (
	product_id, 
    product_name, 
    price)
VALUES 
	('1', 'sushi', '10'),
	('2', 'curry', '15'),
	('3', 'ramen', '12');
  
# creating members table
CREATE TABLE members 
   (customer_id VARCHAR(1), 
   join_date DATE);

## inserting values
INSERT INTO members
 (customer_id, 
 join_date)
VALUES 
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


######################################################### CASE STUDY QUESTIONS ###############################################


### Q1. What is the total amount each customer spent at the restaurant?
SELECT 
	s.customer_id, 
	SUM(m.price) AS Total_Amount
FROM sales s
INNER JOIN menu m
USING (product_id)
GROUP BY s.customer_id;
## Customer A spent the highest amount of 76, closely followed by Customer who spent 74.
## Customer C spent the least amount of 36



### Q2. How many days has each customer visited the restaurant?
SELECT 
	customer_id, 
    COUNT(DISTINCT(order_date)) AS Number_of_days_Visited
FROM sales
GROUP BY customer_id;
## Customer B visited at 6 different dates, followed by Customer A at 4 distinct dates. Last is Customer C at 2 dates
## However, even though Customers A and B visited different distinct dates, the overall number of times they visited is the same
## Both visited 6 times. Customer C visited 3 times at two different dates



### Q3. What was the first item from the menu purchased by each customer?
WITH customer_purchase AS (
	SELECT 
		s.customer_id, 
        m.product_name, 
        s.order_date, 
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS customer_purchase_ranking
FROM sales s
INNER JOIN menu m
USING(product_id))
	SELECT customer_id, product_name
	FROM customer_purchase
	WHERE customer_purchase_ranking = 1
    GROUP BY customer_id, product_name;
## For Customer A, the first items purchased were sushi and curry. For Customer B, first item bought was curry
## For customer C, the first purchased item was ramen




### Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH count_purchase AS (
  SELECT 
    m.product_name, 
    COUNT(s.product_id) AS number_of_times_purchased,
    RANK() OVER(ORDER BY COUNT(s.product_id) DESC) AS purchase_ranking
FROM sales s
INNER JOIN menu m
USING (product_id)
GROUP BY m.product_name)
  SELECT product_name, number_of_times_purchased
  FROM count_purchase
  WHERE purchase_ranking = 1;
## The most purchased item was ramen which was purchased 8 times by all customers




### Q5. Which item was the most popular for each customer?  
WITH popular_ranking AS (
	SELECT 
    s.customer_id,
    m.product_name, 
    COUNT(s.product_id) AS number_of_purchases,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rank_number
FROM sales s
INNER JOIN menu m
USING (product_id)
GROUP BY m.product_name, s.customer_id)
	SELECT customer_id, product_name, number_of_purchases
	FROM popular_ranking
	WHERE rank_number = 1;
## For customer A, the most popular item purchased was ramen which was bought three times.
## For Customer B, the most popular purchase were curry, sushi, and ramen which were purchased twice each
## For customer C, the most purchased item was ramen, purchased 3 times 




### Q6. Which item was purchased first by the customer after they became a member?
WITH first_purchase AS (
	SELECT 
    s.customer_id, 
    s.order_date,
    m.product_name, 
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC) AS purchase_number
FROM sales s
INNER JOIN members ms
USING (customer_id)
INNER JOIN menu m
USING (product_id)
WHERE s.order_date >= ms.join_date)
	SELECT customer_id, order_date, product_name
	FROM first_purchase
	WHERE purchase_number = 1;
## For Customer A, the first item purchased after membership was curry. 
## For Customer B, it was sushi. 



### Q7.  Which item was purchased just before they customer became a member?
WITH last_purchase AS (
SELECT 
	s.customer_id,
    s.order_date,
    s.product_id, 
    m.product_name,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS customer_purchase_number
FROM sales s
INNER JOIN menu m
USING (product_id)
INNER JOIN members ms
USING (customer_id)
WHERE s.order_date < ms.join_date
ORDER BY s.customer_id)
	SELECT customer_id, order_date, product_name
    FROM last_purchase
    WHERE customer_purchase_number = 1;
## For customer A, the last purchase before membership were sushi and curry, both purchase on 2021-01-01
## For customer B, the last purchase before membership was sushi purchased on 2021-01-04



### Q8.  What is the total items and amount spent for each member before they became a member?
SELECT 
    s.customer_id,
    COUNT(*) AS Total_items,
    SUM(m.price) AS Amount_spent
FROM sales s
INNER JOIN menu m
USING (product_id)
INNER JOIN members ms 
USING (customer_id)
WHERE s.order_date < ms.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;
## Customer A spent a total of 25 before membership
## Customer B spent 40 before membership



### Q9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH customer_spending AS (
SELECT s.customer_id, s.product_id,
CASE 
	WHEN m.product_name = "sushi" THEN m.price * 20
	ELSE m.price*10 
END AS "Points"
FROM sales s
INNER JOIN menu m
USING (product_id))
	SELECT customer_id, SUM(Points) AS Customer_Points
    FROM customer_spending
	GROUP BY customer_id;
## Customer A has a total point of 860
## Customer B has a total point of 940, the highest of all customers
## Customer C has a total of 360

-- ALTERNATIVE AND BETTER SOLUTION
SELECT s.customer_id,
SUM(CASE 
	WHEN m.product_name = "sushi" THEN m.price * 20
	ELSE m.price*10 
	END) AS Customer_Points
FROM sales s
INNER JOIN menu m
USING (product_id)
GROUP BY customer_id;


### Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
### how many points do customer A and B have at the end of January?
WITH date_table AS (
SELECT s.customer_id, 
		s.product_id, 
        m.product_name,
        s.order_date, 
        ms.join_date, 
        m.price,
		DATE_ADD(ms.join_date, INTERVAL 6 DAY) AS first_week  
FROM sales s
INNER JOIN menu m
USING (product_id)
INNER JOIN members ms
USING (customer_id)
WHERE EXTRACT(MONTH FROM s.order_date) = 1)
	SELECT customer_id,
    SUM(CASE WHEN order_date BETWEEN join_date AND first_week THEN price*2*10
		WHEN product_name = 'sushi' THEN price*2*10
		ELSE price*10
		END) AS Customer_Points
		FROM date_table
    WHERE order_date < first_week
    GROUP BY customer_id
    ORDER BY customer_id;



#########################################################  BONUS QUESTIONS	#############################################################
###### QUESTION 1: JOIN ALL THE THINGS
SELECT 
	s.customer_id, 
    s.order_date, 
    m.product_name, 
    m.price,
    CASE 
		WHEN ms.join_date > s.order_date THEN 'N'
        WHEN ms.join_date <= s.order_date THEN 'Y'
        ELSE 'N'
		END AS member
	FROM sales s
    LEFT JOIN menu m
    USING (product_id)
    LEFT JOIN members ms
    USING (customer_id)
    ORDER BY 
		s.customer_id, 
		s.order_date, 
        m.product_name;
    

###### QUESTION 2: RANK ALL THE THINGS
WITH member_table AS (
SELECT 
	s.customer_id, 
    s.order_date, 
    m.product_name, 
    m.price,
    CASE 
		WHEN ms.join_date > s.order_date THEN 'N'
        WHEN ms.join_date <= s.order_date THEN 'Y'
        ELSE 'N'
		END AS member
    FROM sales s
    LEFT JOIN menu m
    USING (product_id)
    LEFT JOIN members ms
    USING (customer_id)
    ORDER BY 
		s.customer_id, 
		s.order_date, 
        m.product_name)
SELECT *, 
	CASE
		WHEN member = 'Y' 
        THEN RANK() OVER(PARTITION BY s.customer_id, member ORDER BY s.order_date)
		WHEN member = 'N' 
        THEN 'null'
        END AS ranking
FROM member_table;


###################################################### END ######################################################






