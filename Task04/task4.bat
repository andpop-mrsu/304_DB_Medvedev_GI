#!/bin/bash

# Создаём базу данных
sqlite3 movies_rating.db < db_init.sql

echo " "
echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма. В списке оставить первые 100 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT u1.name AS user1, u2.name AS user2, m.title AS movie
FROM ratings r1
JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id
JOIN users u1 ON r1.user_id = u1.id
JOIN users u2 ON r2.user_id = u2.id
JOIN movies m ON r1.movie_id = m.id
LIMIT 100;"

echo " "
echo "2. Найти 10 самых старых оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT m.title, u.name, r.rating, strftime('%Y-%m-%d', r.timestamp, 'unixepoch') AS review_date
FROM ratings r
JOIN users u ON r.user_id = u.id
JOIN movies m ON r.movie_id = m.id
WHERE r.timestamp = (SELECT MIN(r2.timestamp) FROM ratings r2 WHERE r2.user_id = r.user_id)
ORDER BY r.timestamp ASC
LIMIT 10;"

echo " "
echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В колонке 'Рекомендуем' для фильмов должно быть написано 'Да' или 'Нет'."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH avg_ratings AS (
    SELECT movie_id, AVG(rating) AS avg_rating
    FROM ratings
    GROUP BY movie_id
),
max_min AS (
    SELECT MAX(avg_rating) AS max_rating, MIN(avg_rating) AS min_rating
    FROM avg_ratings
)
SELECT m.title, m.year,
       CASE WHEN ar.avg_rating = (SELECT max_rating FROM max_min) THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем'
FROM movies m
JOIN avg_ratings ar ON m.id = ar.movie_id
JOIN max_min mm ON 1=1
WHERE ar.avg_rating = mm.max_rating OR ar.avg_rating = mm.min_rating
ORDER BY m.year, m.title;"

echo " "
echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-мужчины в период с 2011 по 2014 год."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT COUNT(*) AS rating_count, ROUND(AVG(r.rating), 2) AS avg_rating
FROM ratings r
JOIN users u ON r.user_id = u.id
WHERE u.gender = 'male'
  AND CAST(strftime('%Y', datetime(r.timestamp, 'unixepoch')) AS INTEGER) BETWEEN 2011 AND 2014;"

echo " "
echo "5. Составить список фильмов с указанием средней оценки и количества пользователей, которые их оценили. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT m.title, m.year, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(DISTINCT r.user_id) AS user_count
FROM movies m
JOIN ratings r ON m.id = r.movie_id
GROUP BY m.id, m.title, m.year
ORDER BY m.year, m.title
LIMIT 20;"

echo " "
echo "6. Определить самый распространенный жанр фильма и количество фильмов в этом жанре. Отдельную таблицу для жанров не использовать, жанры нужно извлекать из таблицы movies."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE split_genres(movie_id, genre, rest) AS (
    SELECT id,
           CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, 1, INSTR(genres, '|') - 1) ELSE genres END,
           CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, INSTR(genres, '|') + 1) ELSE '' END
    FROM movies
    WHERE genres IS NOT NULL AND genres != ''
    UNION ALL
    SELECT movie_id,
           CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, 1, INSTR(rest, '|') - 1) ELSE rest END,
           CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, INSTR(rest, '|') + 1) ELSE '' END
    FROM split_genres
    WHERE rest != ''
),
genre_counts AS (
    SELECT genre, COUNT(DISTINCT movie_id) AS movie_count
    FROM split_genres
    GROUP BY genre
)
SELECT genre, movie_count
FROM genre_counts
ORDER BY movie_count DESC
LIMIT 1;"

echo " "
echo "7. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации' (сначала фамилия, потом имя)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT SUBSTR(name, INSTR(name, ' ') + 1) || ' ' || SUBSTR(name, 1, INSTR(name, ' ') - 1) || '|' || register_date AS user_info
FROM users
ORDER BY register_date DESC
LIMIT 10;"

echo " "
echo "8. С помощью рекурсивного CTE определить, на какие дни недели приходился день рождения (15 января 1990) в каждом году с 1990 по 2024."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE years(y) AS (
    SELECT 1990
    UNION ALL
    SELECT y + 1 FROM years WHERE y < 2024
)
SELECT y AS year,
       CASE CAST(strftime('%w', printf('%04d-01-15', y)) AS INTEGER)
           WHEN 0 THEN 'Sunday'
           WHEN 1 THEN 'Monday'
           WHEN 2 THEN 'Tuesday'
           WHEN 3 THEN 'Wednesday'
           WHEN 4 THEN 'Thursday'
           WHEN 5 THEN 'Friday'
           WHEN 6 THEN 'Saturday'
       END AS day_of_week
FROM years;"
