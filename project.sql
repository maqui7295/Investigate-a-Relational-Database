Project: Investigate a relational database


/* Query 1 - Question set1,question 1 - What is the rental count of family movies? */
SELECT film_title, category_name, COUNT(*) rental_count
    FROM
    (SELECT f.film_id, f.title film_title, c.name category_name
		FROM film f
		JOIN film_category fc
		ON f.film_id = fc.film_id
		JOIN category c
		ON c.category_id = fc.category_id
		WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')) t1
	JOIN inventory i
	ON t1.film_id = i.film_id
	JOIN rental r
	ON i.inventory_id = r.inventory_id
    GROUP BY 1, 2
    ORDER BY 2, 1;



/* Query 2 -Question set1,question 2 - how does the length of rental duration of these family-friendly movies compares to the duration that all movies are rented for */

WITH all_table AS 
		(SELECT f.title, c.name, f.rental_duration,
			NTILE(4) OVER (ORDER BY f.rental_duration) as quartile
			FROM film f
			JOIN film_category fc
			ON f.film_id = fc.film_id
			JOIN category c
			ON c.category_id = fc.category_id),
	-- made the query below a CTE in case I wanted to perform further aggregations
	-- like in the commented query below the 'select * from grouped_table' query.
	grouped_table AS 
	    (SELECT *,
			CASE WHEN name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') THEN 'family friendly'
			ELSE 'not family friendly' END as family_friendly
			FROM all_table
			ORDER BY name, title)

SELECT * FROM grouped_table;

-- Instead of using a pivot chart in excel or R, using an sql query
-- I could calculate the total rental duration for each of the family-friendly movies 
-- and compare it with the total rental duration for all categories.
-- the 'select * from grouped_table' will be commented out prior to running this query
/* SELECT quartile, family_friendly, SUM(rental_duration) as total_rental_duration
    FROM grouped_table
	GROUP BY 1, 2
	ORDER BY 1; */
	


/* Query 3 Question set1, question 3 - Count of family-friendly movies based on rental_duration  */

SELECT *, COUNT(*) as count 
    FROM	
	(SELECT c.name category,
		NTILE(4) OVER (ORDER BY f.rental_duration) as quartile
		FROM film f
		JOIN film_category fc
		ON f.film_id = fc.film_id
		JOIN category c
		ON c.category_id = fc.category_id
		WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')) sub
	GROUP BY category, quartile
	ORDER BY category, quartile;
	



/* Query 4 - Question set2, Question 2 - who were our top 10 paying customers? */

WITH cust_payments AS 
		(SELECT DATE_TRUNC('month', p.payment_date) pay_month,
			CONCAT(c.first_name, ' ', c.last_name) AS fullname, amount
			FROM customer c
			JOIN payment p
			ON c.customer_id = p.customer_id),
	top_paying AS
	    (SELECT fullname, sum(amount) pay_amount
			FROM cust_payments
			GROUP BY 1
			ORDER BY 2 DESC LIMIT 10) 
	
SELECT pay_month, fullname, COUNT(*) pay_countpermonth, SUM(amount) pay_amount
    FROM cust_payments
	WHERE fullname IN (SELECT fullname FROM top_paying)
	GROUP BY 1, 2
	ORDER BY 2, 1; 