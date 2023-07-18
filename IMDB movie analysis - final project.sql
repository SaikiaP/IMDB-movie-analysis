/*_____________________________________________________________________________________________________________*/
/*Segment 1: Database - Tables, Columns, Relationships*/


/*1.What are the different tables in the database and how are they connected to each other in the database?*/
show tables;                  /*ATTACHED DOCUMENT TO SEE RELATIONSHIP BEWEEN THE TABLES*/

/*2.	Find the total number of rows in each table of the schema.*/
SELECT
    (SELECT COUNT(*) FROM director_mapping) AS director_mapping_count,
    (SELECT COUNT(*) FROM genre) AS genre_count,
    (SELECT COUNT(*) FROM movie) AS movie_count,
    (SELECT COUNT(*) FROM names) AS names_count,
    (SELECT COUNT(*) FROM ratings) AS ratings_count;

/*3.	Identify which columns in the movie table have null values.*/
SELECT
(SELECT COUNT(*) FROM movie WHERE title IS NULL) AS title_nulls,
(SELECT COUNT(*) FROM movie WHERE year IS NULL) AS year_nulls,
(SELECT COUNT(*) FROM movie WHERE date_published IS NULL) AS date_published_nulls,
(SELECT COUNT(*) FROM movie WHERE duration IS NULL) AS duration_nulls,
(SELECT COUNT(*) FROM movie WHERE country IS NULL) AS country_nulls,
(SELECT COUNT(*) FROM movie WHERE worlwide_gross_income IS NULL) AS worlwide_gross_income_nulls,
(SELECT COUNT(*) FROM movie WHERE languages IS NULL) AS languages_nulls,
(SELECT COUNT(*) FROM movie WHERE production_company IS NULL) AS production_company_nulls;

/*____________________________________________________________________________________________________*/

/*Segment 2: Movie Release Trends*/


/*1.	Determine the total number of movies released each year and analyse the month-wise trend.*/

select year(date_published) as year,
month(date_published) as month,
count(*) as total_movie
from movie
group by year(date_published),month(date_published)
order by year desc, total_movie 
desc;

/*2.	Calculate the number of movies produced in the USA or India in the year 2019.*/
select count(*) as movie_count from movie where country in('USA','India') and year = 2019;

/*___________________________________________________________________________________________________________*/
/*Segment 3: Production Statistics and Genre Analysis*/


/*1.	Retrieve the unique list of genres present in the dataset.*/
select distinct genre from genre;

/*2.	Identify the genre with the highest number of movies produced overall.*/
Select genre, count(*) as genre_count 
from genre group by genre 
order by genre_count desc limit 1;

/*3.	Determine the count of movies that belong to only one genre.*/
SELECT COUNT(*) AS movie_count_with_one_genre
	FROM (
	    SELECT movie_id
	    FROM genre
	    GROUP BY movie_id
	    HAVING COUNT(*) = 1
	) subquery;



/*4.	Calculate the average duration of movies in each genre.*/
select avg(movie.duration) as avg_duration , genre.genre 
from movie join genre on movie.id = genre.movie_id 
group by genre.genre;

/*5.	Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced*/
select genre, movie_count,genre_rank
from(
	select genre, count(*) as movie_count,
		dense_rank() over(order by count(*)desc) as genre_rank
	from movie as m
    join genre as g
    on m.id =g.movie_id
    group by genre
) subquery
where genre = 'Thriller';

/*__________________________________________________________________________________________________________*/
/*Segment 4: Ratings Analysis and Crew Members*/

/*1.	Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).*/
SELECT
	MAX(avg_rating) AS max_avg_rating, 
    MAX(total_votes) AS max_total_votes, 
    MAX(median_rating) AS max_median_rating,
	min(avg_rating) AS min_avg_rating, 
    Min(total_votes) AS min_total_votes, 
    Min(median_rating) AS min_median_rating
FROM ratings;


/*2.	Identify the top 10 movies based on average rating.*/
Select 
	movie.title,
    ratings.avg_rating 
from ratings join movie on ratings.movie_id = movie.id 
order by ratings.avg_rating desc limit 10;

/*3.	Summarise the ratings table based on movie counts by median ratings*/
SELECT median_rating, COUNT(*) AS movie_count
FROM ratings
GROUP BY median_rating
ORDER BY movie_count DESC;


/*4.	Identify the production house that has produced the most number of hit movies (average rating > 8).*/
SELECT m.production_company, COUNT(*) AS hit_movie_count
FROM movie m
INNER JOIN ratings r ON m.id = r.movie_id
WHERE r.avg_rating > 8 AND m.production_company IS NOT NULL
GROUP BY m.production_company
ORDER BY hit_movie_count DESC
LIMIT 1;

/*5.	Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.*/
SELECT g.genre, COUNT(*) AS movie_count
FROM genre g
JOIN movie m ON g.movie_id = m.id
JOIN ratings r ON m.id = r.movie_id
WHERE m.year = 2017
  AND m.country = 'USA'
  AND m.date_published >= '2017-03-01' AND m.date_published < '2017-04-01'AND r.total_votes > 1000
GROUP BY g.genre;


/*6.	Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.*/

SELECT g.genre, m.title, r.avg_rating
FROM genre g
JOIN movie m ON g.movie_id = m.id
JOIN ratings r ON m.id = r.movie_id
WHERE m.title LIKE 'The%'
  AND r.avg_rating > 8;

/*__________________________________________________________________________________________________________*/
/*Segment 5: Crew Analysis*/


/*1.	Identify the columns in the names table that have null values.*/
SELECT
(SELECT COUNT(*) FROM names WHERE id IS NULL) AS id_nulls,
(SELECT COUNT(*) FROM  names WHERE name IS NULL) AS name_nulls,
(SELECT COUNT(*) FROM names WHERE height IS NULL) AS height_nulls,
(SELECT COUNT(*) FROM names WHERE date_of_birth IS NULL) AS date_of_birth_nulls,
(SELECT COUNT(*) FROM names WHERE known_for_movies IS NULL) AS known_for_movies_nulls;


/*2.	Determine the top three directors in the top three genres with movies having an average rating > 8.*/
SELECT genre.genre, names.name as director_name, AVG(ratings.avg_rating) AS average_rating
FROM director_mapping
JOIN names ON director_mapping.name_id = names.id
JOIN genre ON director_mapping.movie_id = genre.movie_id
JOIN ratings ON director_mapping.movie_id = ratings.movie_id
WHERE ratings.avg_rating > 8
GROUP BY genre.genre, names.name
ORDER BY AVG(ratings.avg_rating) DESC
LIMIT 3;

/*3.	Find the top two actors whose movies have a median rating >= 8.*/
SELECT names.name, ratings.median_rating
FROM names
JOIN role_mapping ON names.id = role_mapping.name_id
JOIN ratings ON role_mapping.movie_id = ratings.movie_id
WHERE ratings.median_rating >= 8
ORDER BY ratings.median_rating DESC
LIMIT 2;

/*4.	Identify the top three production houses based on the number of votes received by their movies.*/
Select movie.production_company ,ratings.total_votes
from movie join ratings on movie.id =ratings.movie_id 
order by ratings.total_votes desc limit 3;

/*5.	Rank actors based on their average ratings in Indian movies released in India*/
SELECT names.name ,ratings.avg_rating ,role_mapping.name_id
FROM role_mapping
JOIN names ON role_mapping.name_id = names.id
JOIN ratings ON role_mapping.movie_id = ratings.movie_id
JOIN movie ON role_mapping.movie_id = movie.id
WHERE movie.country = 'India' and role_mapping.category ='actor' 
ORDER BY ratings.avg_rating DESC;

/*6.	Identify the top five actresses in Hindi movies released in India based on their average ratings.*/
select names.name 
from 
role_mapping join names on role_mapping.name_id = names.id
join movie on role_mapping.movie_id = movie.id
join ratings on role_mapping.movie_id =ratings.movie_id
where
role_mapping.category ='actress' and movie.country ='India' and movie.languages ='Hindi'
order by ratings.avg_rating desc
limit 5;

/*____________________________________________________________________________________________________________*/
/*Segment 6: Broader Understanding of Data*/


/*1.	Classify thriller movies based on average ratings into different categories.*/
SELECT movie.title, ratings.avg_rating,
    CASE
        WHEN ratings.avg_rating >=9 THEN 'Super hit'
        WHEN ratings.avg_rating >7 AND ratings.avg_rating < 9 THEN 'hit'
        WHEN ratings.avg_rating >6 AND ratings.avg_rating < 8 THEN 'average'
        ELSE 'flop'
    END AS rating_category
FROM movie
JOIN ratings ON movie.id = ratings.movie_id
JOIN genre ON movie.id = genre.movie_id
WHERE genre.genre = 'Thriller'
ORDER BY ratings.avg_rating DESC;


/*2.	analyse the genre-wise running total and moving average of the average movie duration.*/
SELECT genre.genre, 
		movie.title,
       AVG(movie.duration) AS average_duration,
       SUM(AVG(movie.duration)) OVER (PARTITION BY genre.genre ORDER BY genre.genre, movie.id) AS running_total,
       AVG(AVG(movie.duration)) OVER (PARTITION BY genre.genre ORDER BY genre.genre, movie.id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS moving_average
FROM movie
JOIN genre ON movie.id = genre.movie_id
GROUP BY genre.genre, movie.id
ORDER BY genre.genre, movie.id;

/*3.Identify the five highest-grossing movies of each year that belong to the top three genres.*/
WITH top_genres AS
(
SELECT genre,
    COUNT(m.id) AS movie_count,
	RANK () OVER (ORDER BY COUNT(m.id) DESC) AS genre_rank
FROM genre AS g
	LEFT JOIN movie AS m ON g.movie_id = m.id
	GROUP BY genre
)
,
top_grossing AS
(
SELECT g.genre, year, m.title as movie_name,worlwide_gross_income,
    RANK() OVER (PARTITION BY g.genre, year 
    ORDER BY CONVERT(REPLACE(TRIM(worlwide_gross_income), "$ ",""), UNSIGNED INT) DESC) AS movie_rank
FROM
movie AS m INNER JOIN
genre AS g ON g.movie_id = m.id
WHERE g.genre IN (SELECT DISTINCT genre FROM top_genres WHERE genre_rank<=3)
)
SELECT * 
FROM top_grossing
WHERE movie_rank<=5;

/*4.	Determine the top two production houses that have produced the highest number of hits among multilingual movies.*/
/*-	**Considering hits to be >=8*/


SELECT movie.production_company, COUNT(*) AS movie_count
FROM ratings
JOIN movie ON ratings.movie_id = movie.id
WHERE ratings.avg_rating >= 8 AND movie.production_company IS NOT NULL AND movie.languages LIKE '%,%'
GROUP BY movie.production_company
ORDER BY movie_count DESC
LIMIT 2;


/*5.	Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.*/
with actress_ratings as
(
select n.name as actress_name, sum(r.total_votes) as total_votes, count(m.id) as movie_count,
	round(sum(r.avg_rating*r.total_votes)/sum(r.total_votes),2) as actress_avg_rating
from names as n
join role_mapping as a on n.id = a.name_id
join movie as m on a.movie_id = m.id
join ratings as r on m.id=r.movie_id
join genre as g on m.id = g.movie_id
where category ='actress' and lower(g.genre)='drama'
group by actress_name
)
Select *, row_number() over(order by actress_avg_rating desc, total_votes desc) as actresss_rank
from actress_ratings
limit 3;

/*6.	Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.*/
SELECT names.name, COUNT(*) AS movie_count, AVG(movie.duration) AS average_duration, AVG(ratings.avg_rating) AS average_rating
FROM director_mapping
JOIN names ON director_mapping.name_id = names.id
JOIN movie ON director_mapping.movie_id = movie.id
JOIN ratings ON director_mapping.movie_id = ratings.movie_id
GROUP BY names.name
ORDER BY movie_count DESC
LIMIT 9;


/*____________________________________________________________________________________________________________*/
/*Segment 7: Recommendations*/

/*-	Based on the analysis, provide recommendations for the types of content Bolly movies should focus on producing.*/

/*The below questions are not a part of the problem statement but should be included after the their completion to test their understanding:

-	Determine the average duration of movies released by Bolly Movies compared to the industry average.
-	Analyse the correlation between the number of votes and the average rating for movies produced by Bolly Movies.
-	Find the production house that has consistently produced movies with high ratings over the past three years.
-	Identify the top three directors who have successfully delivered commercially successful movies with high ratings.

*/

/* 1.Determine the average duration of movies released by Bolly Movies compared to the industry average.*/
SELECT 
    AVG(CASE WHEN country = 'India' and languages='Hindi' THEN duration END) AS bolly_movies_average_duration,
    AVG(duration) AS industry_average_duration
FROM movie;

/*2. Analyse the correlation between the number of votes and the average rating for movies produced by Bolly Movies.*/
SELECT 
    AVG(ratings.avg_rating) AS average_rating,
    SUM(ratings.total_votes) AS total_votes,
    (
        (
            SUM(ratings.avg_rating * ratings.total_votes)
            - (SUM(ratings.avg_rating) * SUM(ratings.total_votes)) / COUNT(*)
        ) / 
        (
            SQRT(
                (SUM(ratings.avg_rating * ratings.avg_rating) - (SUM(ratings.avg_rating) * SUM(ratings.avg_rating)) / COUNT(*))
                * (SUM(ratings.total_votes * ratings.total_votes) - (SUM(ratings.total_votes) * SUM(ratings.total_votes)) / COUNT(*))
            )
        )
    ) AS correlation
FROM movie
JOIN ratings ON movie.id = ratings.movie_id
WHERE movie.country = 'India' and movie.languages ='Hindi';



/*-	Find the production house that has consistently produced movies with high ratings over the past three years.*/
SELECT  movie.production_company 
FROM movie join ratings on movie.id =ratings.movie_id
WHERE movie.year IN (2017, 2018, 2019) AND ratings.avg_rating> 8 and movie.production_company is not null;


/*Identify the top three directors who have successfully delivered commercially successful movies with high ratings.*/

select names.name, count(*) as movie_count
from
director_mapping join movie on director_mapping.movie_id =movie.id
join ratings on ratings.movie_id =director_mapping.movie_id
join names on names.id =director_mapping.name_id
where ratings.avg_rating >= (select avg(ratings.avg_rating) as average_rating)
	and movie.worlwide_gross_income is not null
group by names.name
order by movie_count desc
limit 3;


