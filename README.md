# Investigate a Relational Database

Structured query language (SQL) is often used to analyse data. This project sought to gain business insights from the **Sakila Movie database**, an SQL database of online DVD rentals. For more information on the database, please check [here](https://www.postgresqltutorial.com/postgresql-getting-started/postgresql-sample-database/)

## Installation

You will need to have postgreSQL database server installed. Afterwards, follow this [article](https://www.postgresqltutorial.com/postgresql-getting-started/load-postgresql-sample-database/) to load the dataset into the database.

The Entity Relationship Diagram (ERD) is provided in this repository.

## Questions

### Question 1: What is the rental count of family movies?

In order to extract film and their categories, I joined the film and film_category tables within a subquery. Then joined the result of the subquery to the **inventory** and **rental** tables.

```sql
SELECT film_title, category_name, COUNT(*) rental_count
  FROM
 -- subquery
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
```

### Question 2: How does the length of rental duration of these family-friendly movies compare to the rental duration of all movies

Here I used **common table expressions (CTE)** to name two subqueries. `NTILE(4)` was used to group the rental_duration based on quartiles while `CASE WHEN` was used to create a column *family_friendly* that grouped the movies as *family-friendly* or *not-family-friendly*.

```sql
WITH all_table AS 
  (SELECT f.title, c.name, f.rental_duration,
    NTILE(4) OVER (ORDER BY f.rental_duration) as quartile
    FROM film f
    JOIN film_category fc
    ON f.film_id = fc.film_id
    JOIN category c
    ON c.category_id = fc.category_id),
 -- made the query below a CTE in case I wanted to perform further aggregations
 -- like in the query below the 'select * from grouped_table' query.
 grouped_table AS 
  (SELECT *,
    CASE WHEN name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') THEN 'family friendly'
    ELSE 'not family friendly' END as family_friendly
    FROM all_table
    ORDER BY name, title)

SELECT * FROM grouped_table;
```

Instead of using a pivot chart in excel or R, using an sql query, I could calculate the total rental duration for each of the family-friendly movies and compare it with the total rental duration for all categories. The `select * from grouped_table` would be replaced with the query below.

```sql
SELECT quartile, family_friendly, SUM(rental_duration) as total_rental_duration
  FROM grouped_table
  GROUP BY 1, 2
  ORDER BY 1;
```

### Question 3: Count of family-friendly movies based on rental_duration

```sql
SELECT *, COUNT(*) as count 
  FROM 
  (SELECT c.name category, NTILE(4) OVER (ORDER BY f.rental_duration) as quartile
    FROM film f
    JOIN film_category fc
    ON f.film_id = fc.film_id
    JOIN category c
    ON c.category_id = fc.category_id
    WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')) sub
  GROUP BY category, quartile
  ORDER BY category, quartile;
```

### Question 4: Who were the top-10 paying customers?

The new thing here is the `DATE_TRUNC` function used to truncate a date string and the `CONCAT` function used to combine strings.

```sql
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
```

## Conclusion

Check **report.pdf** to view the generated insights and visualizations.
