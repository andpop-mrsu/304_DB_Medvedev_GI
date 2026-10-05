-- Отключаем внешние ключи для ускорения импорта
PRAGMA foreign_keys = OFF;

-- Удаляем существующие таблицы, если они есть
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS temp_movies;
DROP TABLE IF EXISTS temp_ratings;
DROP TABLE IF EXISTS temp_tags;
DROP TABLE IF EXISTS temp_users;

-- 1. Создаём временные таблицы для сырого импорта
CREATE TABLE temp_movies (movieId TEXT, title TEXT, genres TEXT);
CREATE TABLE temp_ratings (userId TEXT, movieId TEXT, rating TEXT, timestamp TEXT);
CREATE TABLE temp_tags (userId TEXT, movieId TEXT, tag TEXT, timestamp TEXT);
CREATE TABLE temp_users (userId TEXT, name TEXT, email TEXT, gender TEXT, register_date TEXT, occupation TEXT);

-- 2. Импорт данных из исходных файлов
.mode csv
.import dataset/movies.csv temp_movies
.import dataset/ratings.csv temp_ratings
.import dataset/tags.csv temp_tags

.separator "|"
.import dataset/users.txt temp_users

-- 3. Удаляем строки заголовков, которые попали при импорте
DELETE FROM temp_movies WHERE movieId = 'movieId';
DELETE FROM temp_ratings WHERE userId = 'userId';
DELETE FROM temp_tags WHERE userId = 'userId';
DELETE FROM temp_users WHERE userId = 'userId';

-- 4. Создаём итоговые таблицы с AUTOINCREMENT id
CREATE TABLE movies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    year INTEGER,
    genres TEXT
);

CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    movie_id INTEGER,
    rating REAL,
    timestamp INTEGER
);

CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    movie_id INTEGER,
    tag TEXT,
    timestamp INTEGER
);

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);

-- 5. Трансформация и перенос данных в итоговые таблицы
-- Для movies: извлекаем год из строки вида "Title (YYYY)"
INSERT INTO movies (title, year, genres)
SELECT 
    CASE 
        WHEN title LIKE '%(%)' THEN trim(substr(title, 1, length(title) - 6))
        ELSE title 
    END,
    CASE 
        WHEN title LIKE '%(%)' THEN CAST(substr(title, length(title) - 4, 4) AS INTEGER)
        ELSE NULL 
    END,
    genres
FROM temp_movies;

-- Для остальных таблиц приводим типы данных
INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT CAST(userId AS INTEGER), CAST(movieId AS INTEGER), CAST(rating AS REAL), CAST(timestamp AS INTEGER)
FROM temp_ratings;

INSERT INTO tags (user_id, movie_id, tag, timestamp)
SELECT CAST(userId AS INTEGER), CAST(movieId AS INTEGER), tag, CAST(timestamp AS INTEGER)
FROM temp_tags;

INSERT INTO users (name, email, gender, register_date, occupation)
SELECT name, email, gender, register_date, occupation
FROM temp_users;

-- 6. Очистка временных таблиц
DROP TABLE temp_movies;
DROP TABLE temp_ratings;
DROP TABLE temp_tags;
DROP TABLE temp_users;

-- Включаем внешние ключи обратно
PRAGMA foreign_keys = ON;
