SELECT * FROM GROUPS; --содержимое
SELECT * FROM STUDENTS;

TRUNCATE TABLE STUDENTS; --очистить таблицу 
TRUNCATE TABLE GROUPS;

DESCRIBE STUDENTS;--просмотр структуры таблицы 
DESCRIBE GROUPS;

DROP TABLE GROUPS;-- удалить 
DROP TABLE STUDENTS;

SELECT table_name FROM user_tables; --Все таблицы
---------------------------------СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ--------------------------------------
SELECT * FROM USER_SYS_PRIVS WHERE PRIVILEGE = 'CREATE TRIGGER';

ALTER SESSION SET "_ORACLE_SCRIPT" = true;
CREATE USER test IDENTIFIED BY 111;
GRANT CREATE SESSION TO test;
grant create table to test;
grant create procedure to test;
grant create trigger to test;
grant create view to test;
grant create sequence to test;
grant alter any table to test;
grant alter any procedure to test;
grant alter any trigger to test;
grant alter profile to test;
grant delete any table to test;
grant drop any table to test;
grant drop any procedure to test;
grant drop any trigger to test;
grant drop any view to test;
grant drop profile to test;

grant select on sys.v_$session to test;
grant select on sys.v_$sesstat to test;
grant select on sys.v_$statname to test;
grant SELECT ANY DICTIONARY to test;
-------------------------------------------------------------------------
