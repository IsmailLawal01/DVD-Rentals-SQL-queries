--retrieving information on top 10 customers.
SELECT 
		rental.customer_id,
		first_name,
		last_name,
		COUNT(rental.customer_id) AS number_of_rents
FROM
	rental
INNER JOIN customer ON rental.customer_id = customer.customer_id
GROUP BY rental.customer_id, first_name, last_name
ORDER BY number_of_rents DESC LIMIT 10;


--top 5 most rented movies
SELECT 
		inventory.film_id, 
		title,
		count(rental_id) AS rental_count
FROM 
	inventory
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
INNER JOIN film ON inventory.film_id = film.film_id
GROUP BY inventory.film_id, title
ORDER BY rental_count DESC LIMIT 5;


--rental frequency
SELECT
		COUNT(rental_id)/COUNT(DISTINCT customer_id) AS "avg (movies/customer)"
FROM 
	rental;


--top 10 popular movie genres
SELECT 
		category.name AS genres,
		count(rental_id) AS rental_count
FROM 
	category
INNER JOIN film_category ON category.category_id = film_category.category_id
INNER JOIN inventory ON film_category.film_id = inventory.film_id
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
GROUP BY category.name, film_category.category_id
ORDER BY rental_count DESC LIMIT 10;


--peak rental times
		--day
SELECT
		EXTRACT('DOW' FROM rental_date) AS day,
		COUNT(rental_id) AS nor
FROM 
	rental
GROUP BY day
ORDER BY nor DESC;
		--hour
SELECT
		EXTRACT(HOUR FROM rental_date) AS time,
		COUNT(rental_id) AS nor
FROM 
	rental
GROUP BY time
ORDER BY nor DESC;


--customers with history of returning movies late
SELECT
	rental.customer_id,
	first_name,
	last_name,
	COUNT(rental.customer_id) AS nolr
FROM 
	rental
INNER JOIN customer ON rental.customer_id = customer.customer_id
INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
INNER JOIN film ON inventory.film_id = film.film_id
WHERE EXTRACT(DAY FROM (return_date - rental_date)) > rental_duration
GROUP BY rental.customer_id, first_name, last_name
ORDER BY nolr DESC;

--customer loyalty
	-- customers of more than 1 year
SELECT 
      customer_id, 
      MAX(return_date),
      MIN(rental_date),
	  MAX(return_date) - MIN(rental_date) AS active_period
FROM rental
GROUP BY customer_id
HAVING EXTRACT('YEAR' FROM(MAX(return_date) - MIN(rental_date))) > 1
ORDER BY customer_id ASC;
	
	-- since no data was returned so we look at the active period (rental history)
SELECT 
      customer_id, 
      MAX(return_date),
      MIN(rental_date),
	  MAX(return_date) - MIN(rental_date) AS active_period
FROM rental
GROUP BY customer_id
ORDER BY active_period DESC;

	-- cutomers of more than 98 days (highest active_period)
SELECT 
		rental.customer_id,
		first_name ||' '|| last_name AS customer_name,
		email,
		address,
		phone,
		MAX(return_date)-MIN(rental_date) AS active_period,
		CASE WHEN EXTRACT(DAY FROM (MAX(return_date)-MIN(rental_date))) > 98 THEN 'LOYAL CUSTOMER' ELSE ' ' END AS status
FROM
	rental
INNER JOIN customer ON rental.customer_id = customer.customer_id
INNER JOIN address ON customer.address_id = address.address_id
GROUP BY rental.customer_id, customer_name, email, address, phone
HAVING EXTRACT(DAY FROM (MAX(return_date)-MIN(rental_date))) > 97
ORDER BY rental.customer_id ASC;