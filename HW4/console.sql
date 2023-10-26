create table actor(
	actor_id int(6) primary key,
    first_name varchar(50),
    last_name varchar(50)
);


create table category(
	category_id INT(6) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    CONSTRAINT chk_category_name CHECK (name IN (
        'Animation', 'Comedy', 'Family', 'Foreign', 'Sci-Fi',
        'Travel', 'Children', 'Drama', 'Horror', 'Action',
        'Classics', 'Games', 'New', 'Documentary', 'Sports', 'Music'
    ))
);

create table country(
	country_id int(6) primary key,
    country varchar(50)
);

create table language(
	language_id int(6) primary key,
    name varchar(50)
);

create table city(
	city_id int (6) primary key,
    city varchar (20),
    country_id int(6),
    foreign key(country_id) references country(country_id)
);

create table address(
	address_id int (6) primary key,
    address varchar(255),
    address2 varchar(255),
    district varchar(255),
    city_id int(6),
    postal_code int(10),
    phone int(20),
    foreign key(city_id) references city(city_id)
);

create table store(
	store_id int(6)primary key,
    address_id int(6),
    foreign key(address_id)references address(address_id)
);

create table customer(
	customer_id int(6) primary key,
    store_id int(6),
    first_name varchar(50),
    last_name varchar(50),
    email varchar(50),
    address_id int (6),
    active varchar(50),
    foreign key(store_id) references store(store_id),
    foreign key(address_id) references address(address_id)
);

create table film(
	film_id int(6) primary key,
    tile varchar(50),
    description varchar(255),
    release_year int(6),
    language_id int(6),
    rental_duration int(6) CHECK (rental_duration BETWEEN 2 AND 8),
    rental_rate decimal(4,2)  CHECK (rental_rate BETWEEN 0.99 AND 6.99),
    length int(6) CHECK (length BETWEEN 30 AND 200),
    replacement_cost decimal(5,2) CHECK (replacement_cost BETWEEN 5.00 AND 100.00),
    rating varchar(5)CHECK (rating IN ('PG', 'G', 'NC-17', 'PG-13', 'R')),
    special_features varchar(50),
    foreign key (language_id) references language(language_id),
               CONSTRAINT chk_special_features CHECK (special_features IN (
        'Behind the Scenes', 'Commentaries', 'Deleted Scenes', 'Trailers'
    ))


);
create table film_actor(
	actor_id int(6)primary key,
    film_id int(6)primary key,
    foreign key(actor_id) references actor(actor_id),
    foreign key(film_id) references film(film_id)
);

create table rental(
	rental_id int(6) primary key,
    rental_date DATE,
    inventory_id int(6),
    customer_id int(6),
    return_date DATE,
    staff_id int(6),
    foreign key(inventory_id) references inventory(inventory_id),
    foreign key(customer_id) references customer(customer_id),
    foreign key(staff_id) references staff(staff_id)
);

create table staff(
	staff_id int(6)primary key,
    first_name varchar(10),
    last_name varchar(10),
    address_id int(6),
    email varchar(50),
    store_id int(6),
    active varchar(10),
    username varchar(50),
    passwork varchar(50),
    foreign key(address_id) references address(address_id),
    foreign key(store_id) references store(store_id),
    CONSTRAINT chk_active CHECK (active IN ('0', '1'))
);

create table film_category(
	film_id int(6)primary key,
    category_id int (6)primary key,
    foreign key(film_id) references film(film_id),
    foreign key(category_id) references category(category_id)
);

create table inventory(
	inventory_id int(6)primary key,
    film_id int(6),
    store_id int(6),
    foreign key(film_id) references film(film_id),
    foreign key(store_id) references store(store_id)
);
create table payment(
	payment_id int(6)primary key,
    customer_id int(6),
    staff_id int(6),
    rental_id int(6),
    amount DECIMAL(10, 2) CHECK (amount >= 0),
    payment_date DATE,
    foreign key(customer_id) references customer(customer_id),
    foreign key(staff_id) references staff(staff_id),
    foreign key(rental_id) references rental(rental_id)
);

-- 1.What is the average length of films in each category? List the results in alphabetic order of categories.
SELECT c.name AS category, ROUND(AVG(f.length), 2) AS average_length
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY c.name;

-- 2.Which categories have the longest and shortest average film lengths?
SELECT c.name AS category,
       ROUND(AVG(f.length), 2) AS average_length,
       MIN(f.length) AS shortest_length,
       MAX(f.length) AS longest_length
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY average_length DESC;

-- 3.Which customers have rented action but not comedy or classic movies?

SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
WHERE EXISTS (
    SELECT 1
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    JOIN category cat ON fc.category_id = cat.category_id
    JOIN film f ON i.film_id = f.film_id
    WHERE r.customer_id = c.customer_id
    AND cat.name = 'Action'
)
AND NOT EXISTS (
    SELECT 1
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    JOIN category cat ON fc.category_id = cat.category_id
    WHERE r.customer_id = c.customer_id
    AND cat.name IN ('Comedy', 'Classics')
);

-- 4.Which actor has appeared in the most English-language movies?
SELECT a.actor_id, a.first_name, a.last_name, COUNT(*) AS movie_count
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
JOIN language l ON f.language_id = l.language_id
WHERE l.name = 'English'
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY movie_count DESC
LIMIT 1;

-- 5.How many distinct movies were rented for exactly 10 days from the store where Mike works?
SELECT COUNT(DISTINCT r.inventory_id) AS distinct_movies_rented
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN store s ON i.store_id = s.store_id
JOIN staff st ON s.store_id = st.store_id
WHERE f.rental_duration = 10
AND st.first_name = 'Mike';

-- 6.Alphabetically list actors who appeared in the movie with the largest cast of actors.

SELECT a.first_name, a.last_name
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
WHERE fa.film_id = (
    SELECT fa.film_id
    FROM film_actor fa
    GROUP BY fa.film_id
    ORDER BY COUNT(*) DESC
    LIMIT 1

)
ORDER BY a.first_name, a.last_name;


