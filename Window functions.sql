/*Question 1: Determine the top 3 films with the highest rental rates, assigning a rank to each film based on its rental rate.
Question 2: Rank customers based on the total amount they spent on rentals, and display only those with a rank less than or equal to 5.
Question 3: Calculate the rank of each actor based on the number of films they have appeared in.
Question 4: Find the dense rank of each film category based on the number of films in that category.
Question 5: Determine the dense rank of customers based on the total number of films they have rented, displaying only those with a dense rank less than or equal to 5.
Question 6: Rank films based on their release years within each category using DENSE_RANK().
Question 7: Assign a unique number to each rental of each customer, from oldest rentage to newest. Show this information for our customers called “Aaron Selby” and “Mary Smith”.
Question 8: Retrieve the top 5 most rented films and include a column indicating the rental_id in which they were rented.
Question 9: Find the three most active customers by the number of rentals, assigning a sequential number to each using ROW_NUMBER().
Question 10: Calculate the average rental rate for each film, considering a window that includes the two preceding and two following films based on their rental rate.
Question 11: Compute the cumulative total rental revenue over time, ordering the results by the rental date, and reset the total for each new month.
Question 12: Determine the maximum and minimum rental rates for each film category, considering a window that includes the three preceding and three following categories.
*/

--top 3 films with the highest rental rates, assigning a rank to each film based on its rental rate.
SELECT 	
	inventory.film_id, 
	title,
	count(rental_id) AS rental_count,
	ROW_NUMBER() OVER(ORDER BY count(rental_id) DESC) rank
FROM 
	inventory
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
INNER JOIN film ON inventory.film_id = film.film_id
GROUP BY inventory.film_id, title
LIMIT 3;


--customers based on the total amount they spent on rentals,ranked less than or equal to 5
WITH net_spend AS
(SELECT payment.customer_id,
	first_name,
	last_name,
	SUM(AMOUNT) AS total_spend,
	RANK() OVER(ORDER BY SUM(AMOUNT) DESC) rank
FROM
	payment
INNER JOIN customer ON payment.customer_id = customer.customer_id
GROUP BY payment.customer_id, first_name, last_name)

SELECT *
FROM net_spend
WHERE rank <= 5;


--rank of each actor based on the number of films they have appeared in.
SELECT 
	first_name,
	last_name,
	COUNT(film_id) AS no_of_movies,
	RANK() OVER(ORDER BY COUNT(film_id) DESC) rank
FROM 
	film_actor
INNER JOIN actor ON film_actor.actor_id = actor.actor_id
GROUP BY first_name, last_name;


--dense rank of each film category based on the number of films in that category
SELECT
	name,
	COUNT(film_id) no_of_movies,
	DENSE_RANK() OVER(ORDER BY COUNT(film_id) DESC) rank
FROM 
	film_category
INNER JOIN category ON film_category.category_id = category.category_id
GROUP BY name;


--dense rank of customers based on the total number of films they have rented,rank less than or equal to 5.
WITH customer_rank 
AS( SELECT
	first_name,
	last_name,
	COUNT(rental.customer_id) AS number_of_rents,
	DENSE_RANK() OVER(ORDER BY COUNT(rental.customer_id) DESC) rank
FROM
	rental
INNER JOIN customer ON rental.customer_id = customer.customer_id
GROUP BY first_name, last_name)

SELECT *
FROM customer_rank
WHERE rank <= 5;


--films based on their release years within each category using DENSE_RANK()
SELECT 
	film.title,
	release_year,
	category.name,
	DENSE_RANK() OVER(PARTITION BY category.name ORDER BY release_year DESC) rank
FROM 
	film
INNER JOIN film_category ON film.film_id = film_category.film_id
INNER JOIN category ON film_category.category_id = category.category_id
GROUP BY film.title, release_year, category.name;


--Assign a unique number to each rental of each customer, from oldest rentage to newest. Show this information for our customers called “Aaron Selby” and “Mary Smith”.
WITH rent_rank AS (
	SELECT 
		*,
		RANK() OVER(PARTITION BY customer_id ORDER BY rental_date ASC) rank
	FROM rental)
	
SELECT 
	*
FROM rent_rank 
INNER JOIN customer ON rent_rank.customer_id = customer.customer_id
WHERE (first_name ILIKE 'Aaron' AND last_name ILIKE 'Selby') 
	OR (first_name ILIKE 'Mary' AND last_name ILIKE 'Smith');
	
	
--Retrieve the top 5 most rented films and include a column indicating the rental_id in which they were rented.
WITH f_rent AS(
	SELECT 
		film.film_id,
		title,
		COUNT(rental_id),
		RANK() OVER(ORDER BY COUNT(rental.inventory_id) DESC) rank
FROM 
	film
INNER JOIN inventory ON film.film_id = inventory.film_id
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
GROUP BY film.film_id)

SELECT
	f_rent.film_id,
	title,
	rank
	--rental_id
FROM 
	f_rent
INNER JOIN inventory ON f_rent.film_id = inventory.film_id
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
WHERE rank <= 5
ORDER BY film_id;


--Find the three most active customers by the number of rentals, assigning a sequential number to each using ROW_NUMBER().
WITH c_rent AS(
	SELECT 
		rental.customer_id,
		first_name,
		last_name,
		COUNT(rental.customer_id) AS number_of_rents,
		ROW_NUMBER() OVER(ORDER BY COUNT(rental.customer_id) DESC)
FROM
	rental
INNER JOIN customer ON rental.customer_id = customer.customer_id
GROUP BY rental.customer_id, first_name, last_name)

SELECT *
FROM c_rent
WHERE row_number <= 3;


--average rental rate for each film, considering a window that includes the two preceding and two following films based on their rental rate
SELECT 
	film_id,
	title,
	release_year,
	AVG(rental_rate),
	AVG(rental_rate) OVER(ORDER BY film_id ASC ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS avg_rental_rate
FROM film
GROUP BY film_id


--Cumulative total rental revenue over time, ordering the results by the rental date, and reset the total for each new month.
SELECT
    	payment_date,
   	EXTRACT(MONTH FROM payment_date) AS month,
	amount,
   	SUM(amount) OVER (PARTITION BY EXTRACT(MONTH FROM payment_date) ORDER BY payment_date) AS cumulative_total
FROM
   payment
ORDER BY
    payment_date ASC;
	
	
--maximum and minimum rental rates for each film category, considering a window that includes the three preceding and three following categories.
WITH minmax AS (
	SELECT
		category.category_id,
		category.name,
		MAX(film.rental_rate) AS maxi,
		MIN(film.rental_rate) AS mini
FROM 
	category
INNER JOIN film_category ON category.category_id = film_category.category_id
INNER JOIN film ON film_category.film_id = film.film_id
GROUP BY category.category_id, category.name--, film.rental_rate
ORDER BY category.category_id)

SELECT  name,
	maxi,
	MAX(maxi) OVER(ORDER BY category_id ASC ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING) AS rolling_max,
	mini,
	MAX(mini) OVER(ORDER BY category_id ASC ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING) AS rolling_min
FROM minmax;
