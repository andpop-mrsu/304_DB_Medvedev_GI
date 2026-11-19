PRAGMA foreign_keys = OFF;

-- Удаляем существующие таблицы
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS movie_genres;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS occupations;
DROP TABLE IF EXISTS temp_movies;
DROP TABLE IF EXISTS temp_ratings;
DROP TABLE IF EXISTS temp_tags;
DROP TABLE IF EXISTS temp_users;

-- Таблица профессий
CREATE TABLE occupations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

-- Таблица пользователей (сохраняем оригинальные ID)
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    gender TEXT NOT NULL CHECK(gender IN ('male', 'female')),
    register_date TEXT DEFAULT (date('now')),
    occupation_id INTEGER
);

-- Таблица фильмов (сохраняем оригинальные ID)
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER CHECK(year >= 1800 AND year <= 2100)
);

-- Таблица жанров
CREATE TABLE genres (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

-- Таблица связи фильмов и жанров
CREATE TABLE movie_genres (
    movie_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE
);

-- Таблица оценок (сохраняем оригинальные ID пользователей и фильмов)
CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating REAL NOT NULL CHECK(rating >= 0 AND rating <= 5),
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE
);

-- Таблица тегов
CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE
);

-- Индексы
CREATE INDEX idx_users_name ON users(name);
CREATE INDEX idx_movies_title ON movies(title);
CREATE INDEX idx_movies_year ON movies(year);
CREATE INDEX idx_ratings_user_id ON ratings(user_id);
CREATE INDEX idx_ratings_movie_id ON ratings(movie_id);
CREATE INDEX idx_tags_user_id ON tags(user_id);
CREATE INDEX idx_tags_movie_id ON tags(movie_id);

-- Временные таблицы для импорта
CREATE TABLE temp_movies (movieId INTEGER, title TEXT, genres TEXT);
CREATE TABLE temp_ratings (userId INTEGER, movieId INTEGER, rating REAL, timestamp INTEGER);
CREATE TABLE temp_tags (userId INTEGER, movieId INTEGER, tag TEXT, timestamp INTEGER);
CREATE TABLE temp_users (userId INTEGER, name TEXT, email TEXT, gender TEXT, register_date TEXT, occupation TEXT);

-- Импорт данных
.mode csv
.import ../dataset/movies.csv temp_movies
.import ../dataset/ratings.csv temp_ratings
.import ../dataset/tags.csv temp_tags

.separator "|"
.import ../dataset/users.txt temp_users

-- Удаляем заголовки
DELETE FROM temp_movies WHERE typeof(movieId) = 'text';
DELETE FROM temp_ratings WHERE typeof(userId) = 'text';
DELETE FROM temp_tags WHERE typeof(userId) = 'text';
DELETE FROM temp_users WHERE typeof(userId) = 'text';

-- Заполняем справочник профессий
INSERT OR IGNORE INTO occupations (name)
SELECT DISTINCT occupation FROM temp_users WHERE occupation != '' AND occupation IS NOT NULL;

-- Заполняем пользователей с ОРИГИНАЛЬНЫМИ ID (берем первого при дубликатах email)
INSERT INTO users (id, name, email, gender, register_date, occupation_id)
SELECT 
    tu.userId,
    tu.name,
    tu.email,
    CASE WHEN UPPER(tu.gender) = 'M' THEN 'male' 
         WHEN UPPER(tu.gender) = 'F' THEN 'female' 
         ELSE 'male' END,
    tu.register_date,
    o.id
FROM (
    SELECT userId, name, email, gender, register_date, occupation,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY userId) as rn
    FROM temp_users
    WHERE email != '' AND email IS NOT NULL
) tu
LEFT JOIN occupations o ON o.name = tu.occupation
WHERE tu.rn = 1;

-- Заполняем фильмы с ОРИГИНАЛЬНЫМИ ID
INSERT INTO movies (id, title, year)
SELECT 
    movieId,
    CASE 
        WHEN title LIKE '%(%)' THEN trim(substr(title, 1, length(title) - 6))
        ELSE title 
    END,
    CASE 
        WHEN title LIKE '%(%)' THEN CAST(substr(title, length(title) - 4, 4) AS INTEGER)
        ELSE NULL 
    END
FROM temp_movies;

-- Заполняем жанры
INSERT OR IGNORE INTO genres (name)
SELECT DISTINCT genre FROM (
    WITH RECURSIVE split(movieId, genre, rest) AS (
        SELECT movieId,
               CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, 1, INSTR(genres, '|') - 1) ELSE genres END,
               CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, INSTR(genres, '|') + 1) ELSE '' END
        FROM temp_movies
        WHERE genres IS NOT NULL AND genres != '' AND genres != '(no genres listed)'
        UNION ALL
        SELECT movieId,
               CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, 1, INSTR(rest, '|') - 1) ELSE rest END,
               CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, INSTR(rest, '|') + 1) ELSE '' END
        FROM split
        WHERE rest != ''
    )
    SELECT genre FROM split
);

-- Заполняем связи фильмов и жанров
INSERT OR IGNORE INTO movie_genres (movie_id, genre_id)
SELECT DISTINCT tm.movieId, g.id
FROM temp_movies tm
JOIN genres g ON g.name IN (
    SELECT genre FROM (
        WITH RECURSIVE split(movieId, genre, rest) AS (
            SELECT tm2.movieId,
                   CASE WHEN INSTR(tm2.genres, '|') > 0 THEN SUBSTR(tm2.genres, 1, INSTR(tm2.genres, '|') - 1) ELSE tm2.genres END,
                   CASE WHEN INSTR(tm2.genres, '|') > 0 THEN SUBSTR(tm2.genres, INSTR(tm2.genres, '|') + 1) ELSE '' END
            FROM temp_movies tm2
            WHERE tm2.movieId = tm.movieId
              AND tm2.genres IS NOT NULL AND tm2.genres != '' AND tm2.genres != '(no genres listed)'
            UNION ALL
            SELECT movieId,
                   CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, 1, INSTR(rest, '|') - 1) ELSE rest END,
                   CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, INSTR(rest, '|') + 1) ELSE '' END
            FROM split
            WHERE rest != ''
        )
        SELECT genre FROM split
    )
);

-- Заполняем ratings (теперь ID совпадают!)
INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT userId, movieId, rating, timestamp
FROM temp_ratings
WHERE userId IS NOT NULL AND movieId IS NOT NULL AND rating IS NOT NULL AND timestamp IS NOT NULL;

-- Заполняем tags
INSERT INTO tags (user_id, movie_id, tag, timestamp)
SELECT userId, movieId, tag, timestamp
FROM temp_tags
WHERE userId IS NOT NULL AND movieId IS NOT NULL AND tag IS NOT NULL AND timestamp IS NOT NULL;

-- Удаляем временные таблицы
DROP TABLE temp_movies;
DROP TABLE temp_ratings;
DROP TABLE temp_tags;
DROP TABLE temp_users;

-- Включаем проверки
PRAGMA foreign_keys = ON;
