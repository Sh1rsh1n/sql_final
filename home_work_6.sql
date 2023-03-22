/*
1. Создайте таблицу users_old, аналогичную таблице users. 
Создайте процедуру, с помощью которой можно переместить любого (одного) пользователя из таблицы users в таблицу users_old. 
(использование транзакции с выбором commit или rollback – обязательно).

2. Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток. 
С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", 
с 12:00 до 18:00 функция должна возвращать фразу "Добрый день", 
с 18:00 до 00:00 -- "Добрый вечер", 
с 00:00 до 6:00 -- "Доброй ночи".

3. (по желанию)* Создайте таблицу logs типа Archive. 
Пусть при каждом создании записи в таблицах users, communities и messages
в таблицу logs помещается время и дата создания записи, название таблицы, идентификатор первичного ключа.
*/



-- Задание 1.
DROP TABLE IF EXISTS users_old;
-- копируем таблицу с атрибутами, но без данных.
CREATE TABLE users_old LIKE users;

DROP PROCEDURE IF EXISTS prc_moveing_user;
DELIMITER //
CREATE PROCEDURE prc_moveing_user(user_id INT, OUT tran_result varchar(100))
BEGIN
	
	DECLARE moving_check BIT DEFAULT FALSE;

	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
	BEGIN
 		SET moving_check = TRUE;
	END;

	START TRANSACTION;
	    INSERT INTO users_old(id, firstname, lastname, email)
	    SELECT id, firstname, lastname, email FROM users
	    WHERE id = user_id;
	   
	    DELETE FROM users
	    WHERE id = user_id;
	   
	IF moving_check THEN
		SET tran_result = 'Ошибка. Что-то пошло не так.';
		ROLLBACK;
	ELSE
		SET tran_result = 'Успешное перемещение пользователя.';
		COMMIT;
	END IF;
END//
DELIMITER ;

CALL prc_moveing_user(3, @tran_result);

SELECT @tran_result;


-- Задание 2.
DROP FUNCTION IF EXISTS hello;

DELIMITER //
CREATE FUNCTION hello() 
RETURNS varchar(100) READS SQL DATA
BEGIN 
	DECLARE time_now time DEFAULT time(now());
	-- проверка других значений
	-- SET time_now = '15:35:00';
	-- SET time_now = '10:30:00';
	-- SET time_now = '00:30:00';

	IF time_now > time('06:00:00') AND time_now < time('12:00:00') THEN 
		RETURN 'Доброе утро';
	END IF;
	IF time_now >= time('12:00:00') AND time_now < time('18:00:00') THEN 
		RETURN 'Доброе день';
	END IF;
	IF time_now >= time('18:00:00') THEN 
		RETURN 'Доброе вечер';
	END IF;
	IF time_now > time('00:00:00') AND time_now <= time('06:00:00') THEN 
		RETURN 'Доброе ночи';
	END IF;

RETURN 'Что-то пошло не так.';
END//
delimiter ;

SELECT hello();


-- Задание 3.
DROP TABLE IF EXISTS logs;
-- таблица logs с атрибутами как в задании
CREATE TABLE logs (table_name varchar(55), time_created timestamp, primary_key_id int) ENGINE = Archive;

-- триггер для таблицы users 
DROP TRIGGER IF EXISTS users_insert;
delimiter |
CREATE TRIGGER users_insert BEFORE INSERT ON users 
	FOR EACH ROW 
	BEGIN 
		INSERT INTO logs (logs.table_name, logs.time_created, logs.primary_key_id) 
		VALUES ('users', curtime(), (SELECT id FROM users ORDER BY id DESC LIMIT 1));
	END;
|

delimiter ;

-- триггер для таблицы messages 
DROP TRIGGER IF EXISTS messages_insert;
delimiter |
CREATE TRIGGER messages_insert BEFORE INSERT ON messages  
	FOR EACH ROW 
	BEGIN 
		INSERT INTO logs (logs.table_name, logs.time_created, logs.primary_key_id) 
		VALUES ('messages', curtime(), (SELECT m.id FROM messages m ORDER BY id DESC LIMIT 1));
	END;
|

delimiter ;

-- триггер для таблицы communities 
DROP TRIGGER IF EXISTS communities_insert;
delimiter |
CREATE TRIGGER communities_insert BEFORE INSERT ON communities  
	FOR EACH ROW 
	BEGIN 
		INSERT INTO logs (logs.table_name, logs.time_created, logs.primary_key_id) 
		VALUES ('communities', curtime(), (SELECT c.id FROM communities c ORDER BY id DESC LIMIT 1));
	END;
|

delimiter ;

/*
INSERT INTO users (firstname, lastname, email) VALUES 
('sadfasdf', 'asdfasd', 'alex@ya.ru');

INSERT INTO communities (name) VALUES ('football');

INSERT INTO messages (from_user_id, to_user_id, body) VALUES 
(1, 5, 'Hello my oldest friend');
*/


