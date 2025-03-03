------------------------------------------ЗАДАНИЕ 1------------------------------------------------------------------------------------
CREATE TABLE GROUPS (
    ID NUMBER PRIMARY KEY,                  
    NAME VARCHAR2(100) NOT NULL,          
    C_VAL NUMBER DEFAULT 0                 
);

CREATE TABLE STUDENTS (
    ID NUMBER PRIMARY KEY,                 
    NAME VARCHAR2(100) NOT NULL,          
    GROUP_ID NUMBER,                       
    CONSTRAINT FK_GROUP FOREIGN KEY (GROUP_ID) REFERENCES GROUPS(ID) -- Внешний ключ
);

------------------------------------------ЗАДАНИЕ 2------------------------------------------------------------------------------------
-----------------------------------------------------1 для проверки уникальности полей ID 
CREATE OR REPLACE TRIGGER GROUPS_ID_UK
BEFORE INSERT ON GROUPS
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM GROUPS
    WHERE ID = :NEW.ID;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Ошибка: ID группы должен быть уникальным.');
    END IF;
END;

CREATE OR REPLACE TRIGGER STUDENTS_ID_UK
BEFORE INSERT ON STUDENTS
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM STUDENTS
    WHERE ID = :NEW.ID;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Ошибка: ID студента должен быть уникальным.');
    END IF;
END;


-------------------------------------------------------ПРОВЕРКА----------------------------------------------------------
SELECT trigger_name--сПИСОК ВСЕХ ТРИГЕЕРОВ
FROM user_triggers;

BEGIN--УДАЛИТЬ ВСЕ ТРИГГЕРЫ
    FOR r IN (SELECT trigger_name FROM user_triggers) LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || r.trigger_name;
    END LOOP;
END;

INSERT INTO GROUPS (ID, NAME) VALUES (2, 'Группа A');
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (1, 'Иван', 1);

INSERT INTO STUDENTS (ID, NAME, GROUP_ID)  VALUES (1, 'Jane Smith', 1);
INSERT INTO GROUPS (ID, NAME) VALUES (3, 'Group B'); 

SELECT * FROM GROUPS; --содержимое
SELECT * FROM STUDENTS;
-------------------------------------------------2для генерации автоинкрементного ключа

DROP SEQUENCE seq_student_id;
DROP SEQUENCE seq_group_id;

-- Создание последовательности для студентов
CREATE SEQUENCE seq_student_id start with 1 increment by 1 nocache;

CREATE or replace trigger auto_increment_student_id
before insert on students
for each row
declare
    v_count number;
begin
    if :new.id is null then
        loop
            select seq_student_id.nextval into :new.id from dual;
            select count(*) into v_count
            from students
            where id = :new.id;
            exit when v_count = 0;
        end loop;
    end if;
end auto_increment_student_id;

-- Создание последовательности для групп
CREATE SEQUENCE seq_group_id start with 1 increment by 1 nocache;

CREATE or replace trigger auto_increment_group_id
before insert on groups
for each row
declare
    v_count number;
begin
    if :new.id is null then
        loop
            select seq_group_id.nextval into :new.id from dual;
            select count(*) into v_count
            from groups
            where id = :new.id;
            exit when v_count = 0;
        end loop;
    end if;
end auto_increment_group_id;
---------------------------------------------------ПРОВЕРКА
-- Вставка в таблицу STUDENTS
INSERT INTO STUDENTS (NAME, GROUP_ID) VALUES ('Иван', 1);
INSERT INTO STUDENTS (NAME, GROUP_ID) VALUES ('Мария', 2);

-- Вставка в таблицу GROUPS
INSERT INTO GROUPS (NAME) VALUES ('Группа Б');
INSERT INTO GROUPS (NAME) VALUES ('Группа B');

SELECT * FROM STUDENTS;
SELECT * FROM GROUPS;


DROP TABLE STUDENTS;
DROP TABLE GROUPS;-- удалить 
-------------------------------------------------для проверки уникальности поля GROUP.NAME
CREATE OR REPLACE TRIGGER trg_check_group_name
BEFORE INSERT ON GROUPS
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM GROUPS
    WHERE NAME = :NEW.NAME;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Group name must be unique.');
    END IF;
END;

-----------------ПРОВЕРКА

INSERT INTO GROUPS (NAME) VALUES ('Группа A');
------------------------------------------ЗАДАНИЕ 3------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER cascade_delete_students
AFTER DELETE ON GROUPS
FOR EACH ROW
BEGIN
    -- Удаляем студентов, относящихся к удаляемой группе
    DELETE FROM STUDENTS WHERE GROUP_ID = :OLD.ID;
END cascade_delete_students;


CREATE OR REPLACE PROCEDURE delete_group_and_students(p_group_id IN NUMBER) AS
BEGIN
    -- Удаляем студентов, относящихся к группе
    DELETE FROM STUDENTS WHERE GROUP_ID = p_group_id;

    -- Удаляем группу
    DELETE FROM GROUPS WHERE ID = p_group_id;
END delete_group_and_students;

SHOW ERRORS TRIGGER cascade_delete_students;

DELETE FROM GROUPS WHERE ID = 1;

EXEC delete_group_and_students(1);
SELECT * FROM STUDENTS;
SELECT * FROM GROUPS;

DROP TRIGGER cascade_delete_students;
------------------------------------------ЗАДАНИЕ 4------------------------------------------------------------------------------------
-- Создание таблицы
CREATE TABLE STUDENTS_AUDIT
(
    AUDIT_ID NUMBER PRIMARY KEY,
    ACTION_TYPE VARCHAR2(10),
    ACTION_TIME TIMESTAMP,
    USER_NAME VARCHAR2(255),
    STUDENT_ID NUMBER,
    STUDENT_NAME VARCHAR2(255),
    GROUP_ID NUMBER,
    OLD_VALUE VARCHAR2(255),
    NEW_VALUE VARCHAR2(255)
);

-- Создание последовательности
CREATE SEQUENCE STUDENTS_AUDIT_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;

-- Создание триггера для вставки
CREATE OR REPLACE TRIGGER AUDIT_INSERT_STUDENTS
AFTER INSERT ON STUDENTS
FOR EACH ROW
BEGIN
    INSERT INTO STUDENTS_AUDIT (AUDIT_ID, ACTION_TYPE, ACTION_TIME, USER_NAME, STUDENT_ID, STUDENT_NAME, GROUP_ID, NEW_VALUE)
    VALUES (STUDENTS_AUDIT_SEQ.NEXTVAL, 'INSERT', SYSDATE, USER, :NEW.ID, :NEW.NAME, :NEW.GROUP_ID, 'New student added');
END AUDIT_INSERT_STUDENTS;
/

-- Создание триггера для обновления
CREATE OR REPLACE TRIGGER AUDIT_UPDATE_STUDENTS
AFTER UPDATE ON STUDENTS
FOR EACH ROW
BEGIN
    INSERT INTO STUDENTS_AUDIT (AUDIT_ID, ACTION_TYPE, ACTION_TIME, USER_NAME, STUDENT_ID, STUDENT_NAME, GROUP_ID, OLD_VALUE, NEW_VALUE)
    VALUES (STUDENTS_AUDIT_SEQ.NEXTVAL, 'UPDATE', SYSDATE, USER, :NEW.ID, :NEW.NAME, :NEW.GROUP_ID, :OLD.NAME, :NEW.NAME);
END AUDIT_UPDATE_STUDENTS;
/

-- Создание триггера для удаления
CREATE OR REPLACE TRIGGER AUDIT_DELETE_STUDENTS
AFTER DELETE ON STUDENTS
FOR EACH ROW
BEGIN
    INSERT INTO STUDENTS_AUDIT (AUDIT_ID, ACTION_TYPE, ACTION_TIME, USER_NAME, STUDENT_ID, STUDENT_NAME, GROUP_ID, OLD_VALUE)
    VALUES (STUDENTS_AUDIT_SEQ.NEXTVAL, 'DELETE', SYSDATE, USER, :OLD.ID, :OLD.NAME, :OLD.GROUP_ID, 'Student deleted');
END AUDIT_DELETE_STUDENTS;
/


SELECT * FROM GROUPS;

INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (5, 'ПАша', 1);
SELECT * FROM STUDENTS_AUDIT;

DELETE FROM STUDENTS WHERE ID = 1;
SELECT * FROM STUDENTS_AUDIT;



SELECT TRIGGER_NAME, STATUS FROM USER_TRIGGERS WHERE TRIGGER_NAME IN 
('AUDIT_INSERT_STUDENTS', 'AUDIT_UPDATE_STUDENTS', 'AUDIT_DELETE_STUDENTS');



DROP TABLE STUDENTS_AUDIT;
DROP SEQUENCE STUDENTS_AUDIT_SEQ;
DROP TRIGGER AUDIT_INSERT_STUDENTS;
DROP TRIGGER AUDIT_UPDATE_STUDENTS;
DROP TRIGGER AUDIT_DELETE_STUDENTS;
------------------------------------------ЗАДАНИЕ 5------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE RESTORE_STUDENTS_AT_TIME(
    p_time TIMESTAMP
) AS
BEGIN
    -- Восстановление на указанный момент времени
    FOR rec IN (
        SELECT * FROM STUDENTS_AUDIT
        WHERE ACTION_TIME <= p_time
        ORDER BY ACTION_TIME DESC
    ) LOOP
        IF rec.ACTION_TYPE = 'INSERT' THEN
            INSERT INTO STUDENTS (ID, NAME, GROUP_ID)
            VALUES (rec.STUDENT_ID, rec.STUDENT_NAME, rec.GROUP_ID);
        ELSIF rec.ACTION_TYPE = 'UPDATE' THEN
            UPDATE STUDENTS
            SET NAME = rec.NEW_VALUE,
                GROUP_ID = rec.GROUP_ID
            WHERE ID = rec.STUDENT_ID;
        ELSIF rec.ACTION_TYPE = 'DELETE' THEN
            DELETE FROM STUDENTS
            WHERE ID = rec.STUDENT_ID;
        END IF;
    END LOOP;

    COMMIT; -- Зафиксировать изменения
END RESTORE_STUDENTS_AT_TIME;
/


CREATE OR REPLACE PROCEDURE RESTORE_STUDENTS_WITH_OFFSET(
    p_time TIMESTAMP,
    p_offset INTERVAL DAY TO SECOND
) AS
    v_corrected_time TIMESTAMP; -- Новая переменная для скорректированного времени
BEGIN
    -- Корректировка времени
    v_corrected_time := p_time + p_offset;

    -- Восстановление на скорректированный момент времени
    FOR rec IN (
        SELECT * FROM STUDENTS_AUDIT
        WHERE ACTION_TIME <= v_corrected_time
        ORDER BY ACTION_TIME DESC
    ) LOOP
        IF rec.ACTION_TYPE = 'INSERT' THEN
            INSERT INTO STUDENTS (ID, NAME, GROUP_ID)
            VALUES (rec.STUDENT_ID, rec.STUDENT_NAME, rec.GROUP_ID);
        ELSIF rec.ACTION_TYPE = 'UPDATE' THEN
            UPDATE STUDENTS
            SET NAME = rec.NEW_VALUE,
                GROUP_ID = rec.GROUP_ID
            WHERE ID = rec.STUDENT_ID;
        ELSIF rec.ACTION_TYPE = 'DELETE' THEN
            DELETE FROM STUDENTS
            WHERE ID = rec.STUDENT_ID;
        END IF;
    END LOOP;

    COMMIT; -- Зафиксировать изменения
END RESTORE_STUDENTS_WITH_OFFSET;
/

DECLARE
    v_time TIMESTAMP := TO_TIMESTAMP('2025-03-03 12:00:00', 'YYYY-MM-DD HH24:MI:SS'); 
BEGIN
    RESTORE_STUDENTS_AT_TIME(v_time);
END;
/


DECLARE
    v_time TIMESTAMP := TO_TIMESTAMP('2025-03-03 12:00:00', 'YYYY-MM-DD HH24:MI:SS');
BEGIN
    RESTORE_STUDENTS_WITH_OFFSET(v_time, INTERVAL '-1' HOUR); -- Восстановление на 1 час назад
END;
/

SELECT * FROM GROUPS;

SELECT * FROM STUDENTS;


DROP PROCEDURE RESTORE_STUDENTS_AT_TIME;
DROP PROCEDURE RESTORE_STUDENTS_WITH_OFFSET;
DROP TRIGGER AUDIT_INSERT_STUDENTS;
DROP TRIGGER AUDIT_UPDATE_STUDENTS;
DROP TRIGGER AUDIT_DELETE_STUDENTS;
------------------------------------------ЗАДАНИЕ 6------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_update_group_cval
AFTER INSERT OR DELETE ON STUDENTS
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        -- Увеличиваем C_VAL группы при добавлении студента
        UPDATE GROUPS
        SET C_VAL = C_VAL + 1
        WHERE ID = :NEW.GROUP_ID;
    ELSIF DELETING THEN
        -- Уменьшаем C_VAL группы при удалении студента
        UPDATE GROUPS
        SET C_VAL = C_VAL - 1
        WHERE ID = :OLD.GROUP_ID;
    END IF;
END;
/



INSERT INTO GROUPS (ID, NAME) VALUES (1, 'Group A');
INSERT INTO GROUPS (ID, NAME) VALUES (2, 'Group B');

SELECT * FROM GROUPS;


INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (1, 'Student 1', 1);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (2, 'Student 2', 1);

SELECT * FROM GROUPS;

DELETE FROM STUDENTS WHERE ID = 1;

SELECT * FROM GROUPS;

SELECT * FROM STUDENTS;


------------------------------------------------------------------------------------------------------------------

INSERT INTO GROUPS (ID, NAME) VALUES (1, 'Группа A');

INSERT INTO GROUPS (ID, NAME) VALUES (2, 'Группа Б');

INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (1, 'Иван', 1);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (2, 'Мария', 1);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (3, 'Паша', 2);

DELETE FROM GROUPS WHERE ID = 1; 

EXEC delete_group_and_students(1);

CREATE OR REPLACE PROCEDURE RESTORE_STUDENT (
    p_student_id NUMBER
) AS
    v_group_id NUMBER;
    v_student_name VARCHAR2(100);
    v_group_name VARCHAR2(100);
BEGIN
    -- Получаем информацию о удаленном студенте
    SELECT GROUP_ID, STUDENT_NAME INTO v_group_id, v_student_name
    FROM STUDENTS_AUDIT
    WHERE STUDENT_ID = p_student_id AND ACTION_TYPE = 'DELETE'
    ORDER BY ACTION_TIME DESC
    FETCH FIRST ROW ONLY;

    -- Проверяем, существует ли группа
    BEGIN
        SELECT NAME INTO v_group_name
        FROM GROUPS
        WHERE ID = v_group_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Группа не найдена, создаем новую
            INSERT INTO GROUPS (ID, NAME) VALUES (v_group_id, 'Группа A');
    END;

    -- Восстанавливаем студента
    INSERT INTO STUDENTS (ID, NAME, GROUP_ID)
    VALUES (p_student_id, v_student_name, v_group_id);
    
    COMMIT;
END RESTORE_STUDENT;


BEGIN
    RESTORE_STUDENT(1); -- Восстановление студента с ID 1
END;


SELECT * FROM GROUPS;
SELECT * FROM STUDENTS;