SELECT * FROM GROUPS; --содержимое
SELECT * FROM STUDENTS;

TRUNCATE TABLE STUDENTS; --очистить таблицу 
TRUNCATE TABLE GROUPS;

DESCRIBE STUDENTS;--просмотр структуры таблицы 
DESCRIBE GROUPS;


DROP TABLE STUDENTS;
DROP TABLE GROUPS;-- удалить 

SELECT trigger_name--сПИСОК ВСЕХ ТРИГЕЕРОВ
FROM user_triggers;

BEGIN--УДАЛИТЬ ВСЕ ТРИГГЕРЫ
    FOR r IN (SELECT trigger_name FROM user_triggers) LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || r.trigger_name;
    END LOOP;
END;


SELECT object_name -- Список всех процедур
FROM user_procedures
WHERE object_type = 'PROCEDURE';

BEGIN -- Удалить все процедуры
    FOR r IN (SELECT object_name FROM user_procedures WHERE object_type = 'PROCEDURE') LOOP
        EXECUTE IMMEDIATE 'DROP PROCEDURE ' || r.object_name;
    END LOOP;
END;
/

--включение триггеров 
CREATE OR REPLACE PROCEDURE ENABLE_ALL_TRIGGERS AS
BEGIN
    FOR r IN (SELECT trigger_name FROM user_triggers WHERE trigger_type = 'BEFORE' OR trigger_type = 'AFTER') LOOP
        EXECUTE IMMEDIATE 'ALTER TRIGGER ' || r.trigger_name || ' ENABLE';
    END LOOP;
END ENABLE_ALL_TRIGGERS;
/

BEGIN
    ENABLE_ALL_TRIGGERS; -- Включаем все триггеры
END;
/

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
GRANT INSERT ANY TABLE TO test;
GRANT CREATE TRIGGER TO test;
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
ALTER USER TEST QUOTA UNLIMITED ON USERS;

