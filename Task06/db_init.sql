PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS works;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS cars;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS master_services;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS car_categories;

PRAGMA foreign_keys = ON;

CREATE TABLE car_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE employees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    position TEXT NOT NULL DEFAULT 'Мастер',
    hire_date TEXT NOT NULL DEFAULT (date('now')),
    termination_date TEXT,
    salary_percent REAL NOT NULL DEFAULT 50.0 CHECK(salary_percent >= 0 AND salary_percent <= 100),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
    phone TEXT,
    email TEXT UNIQUE
);

CREATE TABLE services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    duration_minutes INTEGER NOT NULL CHECK(duration_minutes > 0),
    price REAL NOT NULL CHECK(price >= 0),
    category_id INTEGER,
    FOREIGN KEY (category_id) REFERENCES car_categories(id) ON DELETE SET NULL
);

CREATE TABLE master_services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    UNIQUE(employee_id, service_id),
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
);

CREATE TABLE clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT UNIQUE
);

CREATE TABLE cars (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id INTEGER NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    year INTEGER CHECK(year >= 1900 AND year <= 2100),
    category_id INTEGER,
    license_plate TEXT UNIQUE,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES car_categories(id) ON DELETE SET NULL
);

CREATE TABLE appointments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    car_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    appointment_date TEXT NOT NULL,
    appointment_time TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Запланирована' CHECK(status IN ('Запланирована', 'Подтверждена', 'Отменена', 'Выполнена')),
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT
);

CREATE TABLE works (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id INTEGER,
    employee_id INTEGER NOT NULL,
    car_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    work_date TEXT NOT NULL DEFAULT (date('now')),
    start_time TEXT,
    end_time TEXT,
    actual_price REAL NOT NULL CHECK(actual_price >= 0),
    is_paid INTEGER NOT NULL DEFAULT 0 CHECK(is_paid IN (0, 1)),
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE RESTRICT,
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE RESTRICT,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT
);

INSERT INTO car_categories (name) VALUES
('Легковые'),
('Грузовые'),
('Мотоциклы'),
('Внедорожники');

INSERT INTO employees (full_name, position, hire_date, salary_percent, is_active, phone, email) VALUES
('Иванов Иван Иванович', 'Старший мастер', '2020-03-15', 60.0, 1, '+79001112233', 'ivanov@sto.ru'),
('Петров Петр Петрович', 'Мастер', '2021-06-01', 50.0, 1, '+79002223344', 'petrov@sto.ru'),
('Сидорова Анна Сергеевна', 'Мастер', '2019-01-10', 55.0, 1, '+79003334455', 'sidorova@sto.ru'),
('Козлов Дмитрий Алексеевич', 'Мастер', '2018-05-20', 45.0, 0, '+79004445566', 'kozlov@sto.ru'),
('Новикова Мария Ивановна', 'Мастер', '2022-09-01', 50.0, 1, '+79005556677', 'novikova@sto.ru');

UPDATE employees SET termination_date = '2023-12-31' WHERE full_name = 'Козлов Дмитрий Алексеевич';

INSERT INTO services (name, duration_minutes, price, category_id) VALUES
('Замена масла', 30, 1500.0, 1),
('Диагностика двигателя', 60, 3000.0, 1),
('Замена тормозных колодок', 90, 4500.0, 1),
('Шиномонтаж', 45, 2000.0, 1),
('Ремонт двигателя', 480, 25000.0, 1),
('Замена масла (грузовое)', 60, 3500.0, 2),
('Диагностика грузового', 90, 5000.0, 2),
('Ремонт мотоцикла', 120, 6000.0, 3),
('Замена цепи мотоцикла', 60, 3000.0, 3),
('Ремонт внедорожника', 240, 15000.0, 4);

INSERT INTO master_services (employee_id, service_id) VALUES
(1, 1), (1, 2), (1, 3), (1, 5),
(2, 1), (2, 4), (2, 6),
(3, 2), (3, 3), (3, 7), (3, 8),
(4, 1), (4, 2), (4, 9),
(5, 4), (5, 10);

INSERT INTO clients (full_name, phone, email) VALUES
('Смирнов Алексей', '+79011111111', 'smirnov@mail.ru'),
('Кузнецова Ольга', '+79022222222', 'kuznetsova@mail.ru'),
('Попов Владимир', '+79033333333', 'popov@mail.ru'),
('Васильева Екатерина', '+79044444444', 'vasileva@mail.ru'),
('Соколов Михаил', '+79055555555', 'sokolov@mail.ru');

INSERT INTO cars (client_id, brand, model, year, category_id, license_plate) VALUES
(1, 'Toyota', 'Camry', 2020, 1, 'А123БВ77'),
(1, 'BMW', 'X5', 2019, 4, 'А456ГД77'),
(2, 'Volkswagen', 'Golf', 2018, 1, 'В789ЕЖ77'),
(3, 'KAMAZ', '5490', 2021, 2, 'С012ИК77'),
(4, 'Honda', 'CBR600', 2022, 3, 'М345ЛМ77'),
(5, 'Lada', 'Vesta', 2021, 1, 'Н678НО77');

INSERT INTO appointments (car_id, employee_id, service_id, appointment_date, appointment_time, status) VALUES
(1, 1, 1, '2024-11-25', '10:00', 'Подтверждена'),
(2, 3, 2, '2024-11-26', '14:00', 'Запланирована'),
(3, 2, 4, '2024-11-27', '11:00', 'Запланирована'),
(4, 2, 6, '2024-11-28', '09:00', 'Отменена'),
(5, 3, 8, '2024-11-29', '15:00', 'Подтверждена'),
(6, 1, 3, '2024-11-30', '12:00', 'Запланирована');

INSERT INTO works (appointment_id, employee_id, car_id, service_id, work_date, start_time, end_time, actual_price, is_paid) VALUES
(1, 1, 1, 1, '2024-11-25', '10:00', '10:30', 1500.0, 1),
(NULL, 1, 1, 2, '2024-11-20', '11:00', '12:00', 3000.0, 1),
(NULL, 3, 2, 2, '2024-11-21', '14:00', '15:00', 3000.0, 0),
(NULL, 2, 3, 4, '2024-11-22', '11:00', '11:45', 2000.0, 1),
(NULL, 4, 5, 9, '2024-10-15', '10:00', '11:00', 3000.0, 1);
