-- Добавление 5 новых пользователей (включая себя и 4 соседей по группе)
-- Дата регистрации определяется по системному времени

INSERT INTO users (name, email, gender, register_date, occupation_id)
VALUES ('Иванов Иван', 'ivanov@example.com', 'male', date('now'), (SELECT id FROM occupations WHERE name = 'student' LIMIT 1));

INSERT INTO users (name, email, gender, register_date, occupation_id)
VALUES ('Петров Петр', 'petrov@example.com', 'male', date('now'), (SELECT id FROM occupations WHERE name = 'student' LIMIT 1));

INSERT INTO users (name, email, gender, register_date, occupation_id)
VALUES ('Сидорова Анна', 'sidorova@example.com', 'female', date('now'), (SELECT id FROM occupations WHERE name = 'student' LIMIT 1));

INSERT INTO users (name, email, gender, register_date, occupation_id)
VALUES ('Козлов Дмитрий', 'kozlov@example.com', 'male', date('now'), (SELECT id FROM occupations WHERE name = 'student' LIMIT 1));

INSERT INTO users (name, email, gender, register_date, occupation_id)
VALUES ('Новикова Мария', 'novikova@example.com', 'female', date('now'), (SELECT id FROM occupations WHERE name = 'student' LIMIT 1));

-- Добавление 3 новых фильмов разных жанров

INSERT INTO movies (title, year) VALUES ('Матрица', 1999);
INSERT INTO movies (title, year) VALUES ('Начало', 2010);
INSERT INTO movies (title, year) VALUES ('Интерстеллар', 2014);

-- Добавление жанров для новых фильмов (если их еще нет)
INSERT OR IGNORE INTO genres (name) VALUES ('Sci-Fi');
INSERT OR IGNORE INTO genres (name) VALUES ('Action');
INSERT OR IGNORE INTO genres (name) VALUES ('Drama');
INSERT OR IGNORE INTO genres (name) VALUES ('Thriller');
INSERT OR IGNORE INTO genres (name) VALUES ('Adventure');

-- Связываем фильмы с жанрами
INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g 
WHERE m.title = 'Матрица' AND g.name = 'Sci-Fi';

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g 
WHERE m.title = 'Матрица' AND g.name = 'Action';

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g 
WHERE m.title = 'Начало' AND g.name = 'Sci-Fi';

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g 
WHERE m.title = 'Начало' AND g.name = 'Thriller';

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g 
WHERE m.title = 'Интерстеллар' AND g.name = 'Sci-Fi';

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g 
WHERE m.title = 'Интерстеллар' AND g.name = 'Drama';

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g 
WHERE m.title = 'Интерстеллар' AND g.name = 'Adventure';

-- Добавление 3 новых отзывов от себя (Иванов Иван)
INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 5.0, strftime('%s', 'now')
FROM users u, movies m
WHERE u.name = 'Иванов Иван' AND m.title = 'Матрица';

INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 4.5, strftime('%s', 'now')
FROM users u, movies m
WHERE u.name = 'Иванов Иван' AND m.title = 'Начало';

INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 5.0, strftime('%s', 'now')
FROM users u, movies m
WHERE u.name = 'Иванов Иван' AND m.title = 'Интерстеллар';
