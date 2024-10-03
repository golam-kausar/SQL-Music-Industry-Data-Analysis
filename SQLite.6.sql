--Q1. Who is the senior most employee based on job title?
SELECT title, last_name, first_name
from employee
ORDER by levels DESC
limit 1;

--Q2: Which countries have the most Invoices?
SELECT count (*) as c, billing_country
FROM invoice
GROUP by billing_country
ORDER by c DESC
LIMIT 10;

-- Q3: What are top 3 values of total invoice?
SELECT total from invoice
order by total desc;

-- Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that 
--has the highest sum of invoice totals. Return both the city name & sum of all invoice totals.
SELECT billing_city, sum (total) as invoice_total
from invoice
GROUP by billing_city
ORDER by invoice_total desc
limit 1;

--Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money.
SELECT customer.customer_id, first_name, last_name, SUM(total) as total_spending
FROM customer
join invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id
ORDER by total_spending DESC
limit 1;

--Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A.album2
select distinct email, first_name, last_name
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in (
  SELECT track_id from track
  JOIN genre on track.genre_id = genre.genre_id
  where genre.name LIKE 'Rock'
  )
  ORDER by email;

--Alternatively 
select DISTINCT email as Email, first_name as FirstName, last_name as LastName, genre.name as Name
from customer
join invoice on invoice.customer_id = customer.customer_id
JOIN invoice_line on invoice_line.invoice_id = invoice.invoice_id
join track on track.track_id = invoice_line.track_id
join genre on genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER by email;

--Q7: Let's invite the artists who have written the most rock music in our dataset. 
--Write a query that returns the Artist name and total track count of the top 10 rock bands.
SELECT artist.artist_id, artist.name, count(artist.artist_id) as number_of_songs
from track
JOIN album2 on album2.album_id = track.album_id
JOIN artist on artist.artist_id = album2.artist_id
JOIN genre on genre.genre_id = track.genre_id
where genre.name like 'Rock'
GROUP by artist.artist_id
order by number_of_songs DESC
LIMIT 10;

--Alternatively  
SELECT artist.artist_id, artist.name, COUNT(track.track_id) AS number_of_songs
FROM track
JOIN album2 ON album2.album_id = track.album_id
JOIN artist ON artist.artist_id = album2.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

--Q8: Return all the track names that have a song length longer than the average song length. 
--Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.
SELECT name, milliseconds
from track
WHERE milliseconds > (
  SELECT avg(milliseconds) as avg_track_length
  from track)
 ORDER by milliseconds DESC;

--Q9: Find how much amount spent by each customer on artists? 
--Write a query to return customer name, artist name and total spent?

--Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
--which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
--Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
--so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
--for each artist.

with best_selling_artist as (
  select artist.artist_id, artist.name as artist_name, sum (invoice_line.unit_price*invoice_line.quantity) as total_sales
  from invoice_line
  JOIN track on track.track_id = invoice_line.track_id
  join album2 on album2.album_id = track.album_id
  join artist on artist.artist_id = album2.album_id
  GROUP by 1
  ORDER by 3 DESC
  LIMIT 1
  )
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, sum (il.unit_price*il.quantity) as amount_spent
from invoice i
JOIN customer c on c.customer_id = i.invoice_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album2 alb on alb.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = alb.artist_id
GROUP by 1,2,3,4
order by 5 DESC;


--Q10: We want to find the most popular music genre for each country. 
--The most popular genre is the one with the highest number of purchases. 
--For countries where there is a tie (equal number of purchases), we want to return all the genres.

--Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level.

--Method 1: Using CTE
WITH popular_genre AS
(
  -- Count purchases for each genre in each country
  SELECT COUNT (invoice_line.quantity) as purchases, customer.country, genre.name, genre.genre_id, 
  ROW_NUMBER() OVER (PARTITION by customer.country ORDER by COUNT(invoice_line.quantity) DESC) as RowNo
  from invoice_line
  JOIN invoice on invoice.invoice_id = invoice_line.invoice_id
  JOIN customer on customer.customer_id = invoice.customer_id
  join track on track.track_id = invoice_line.track_id
  JOIN genre on genre.genre_id = track.genre_id
  GROUP by 2,3,4
  order by 2 ASC, 1 DESC
)
SELECT * from popular_genre WHERE RowNo <= 1;
  
--Method 2: : Using Recursive
with RECURSIVE
sales_per_country as (
  SELECT COUNT (*) as purchases_per_genre, customer.country, genre.name, genre.genre_id
  from invoice_line
  JOIN invoice on invoice.invoice_id = invoice_line.invoice_id
  join customer on customer.customer_id = invoice.customer_id
  join track on track.track_id = invoice_line.track_id
  join genre on genre.genre_id = track.genre_id
  GROUP by 2,3,4
  ORDER by 2
  ),
  max_genre_per_country as (SELECT MAX(purchases_per_genre) as max_genre_number, country
                            from sales_per_country
                            group by 2
                            ORDER by 2)
   SELECT sales_per_country.* from sales_per_country
   JOIN max_genre_per_country on sales_per_country.country = max_genre_per_country.country
   WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

--Q12: Write a query that determines the customer that has spent the most on music for each country. 
--Write a query that returns the country along with the top customer and how much they spent. 
--For countries where the top amount spent is shared, provide all customers who spent this amount.

--Steps to Solve:  Similar to the above question. There are two parts in question- 
--first find the most spent on music for each country and second filter the data for respective customers. */

-- Method 1: using CTE
WITH Customter_with_country AS (
		SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC, 5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1;
  
--Method 2: Using Recursive
WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country, MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;