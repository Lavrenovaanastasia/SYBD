
SELECT object_name, status 
FROM user_objects 
WHERE object_name = 'COMPARE_SCHEMAS';

SHOW ERRORS PROCEDURE COMPARE_SCHEMAS;


SHOW ERRORS FUNCTION CREATE_OBJECT;

SHOW ERRORS FUNCTION UPDATE_OBJECT;

SHOW ERRORS PROCEDURE COMPARE_SCHEMAS_OBJECTS;
-----------drop
DROP TABLE STUDENTS;
DROP TABLE GROUPS;-- удалить 

BEGIN--УДАЛИТЬ ВСЕ ТРИГГЕРЫ
    FOR r IN (SELECT trigger_name FROM user_triggers) LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || r.trigger_name;
    END LOOP;
END;
/

DROP SEQUENCE STUDENTS_AUDIT_SEQ;
DROP SEQUENCE seq_student_id;
DROP SEQUENCE seq_group_id;
DROP TABLE Student_logs;
DROP TABLE STUDENTS_AUDIT;

BEGIN -- Удалить все процедуры
    FOR r IN (SELECT object_name FROM user_procedures WHERE object_type = 'PROCEDURE') LOOP
        EXECUTE IMMEDIATE 'DROP PROCEDURE ' || r.object_name;
    END LOOP;
END;
/












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


DROP SEQUENCE seq_student_id;
DROP SEQUENCE seq_group_id;

DROP TABLE STUDENTS_AUDIT;
DROP SEQUENCE STUDENTS_AUDIT_SEQ;

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
-- Проверка привилегий пользователя an
SELECT * FROM USER_SYS_PRIVS WHERE GRANTEE = 'TEST';

SELECT * FROM USER_SYS_PRIVS WHERE PRIVILEGE = 'CREATE TRIGGER';

ALTER SESSION SET "_ORACLE_SCRIPT" = true;
CREATE USER an IDENTIFIED BY 111;
GRANT CREATE SESSION TO an;
grant create table to an;
grant create procedure to an;
grant create trigger to an;
grant create view to an;
grant create sequence to an;
grant alter any table to an;
grant alter any procedure to an;
grant alter any trigger to an;
grant alter profile to an;
grant delete any table to an;
grant drop any table to an;
grant drop any procedure to an;
grant drop any trigger to an;
grant drop any view to an;
grant drop profile to an;
GRANT INSERT ANY TABLE TO an;
GRANT CREATE TRIGGER TO an;
grant alter any table to an;
grant alter any procedure to an;
grant alter any trigger to an;
grant alter profile to an;
grant delete any table to an;
grant drop any table to an;
grant drop any procedure to an;
grant drop any trigger to an;
grant drop any view to an;
grant drop profile to an;


grant select on sys.v_$session to an;
grant select on sys.v_$sesstat to an;
grant select on sys.v_$statname to an;
grant SELECT ANY DICTIONARY to an;
-------------------------------------------------------------------------
ALTER USER TEST QUOTA UNLIMITED ON USERS;

