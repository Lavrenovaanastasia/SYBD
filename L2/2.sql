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

INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (1, 'Группа A', 10);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (1, 'Иван', 1);

INSERT INTO STUDENTS (ID, NAME, GROUP_ID)  VALUES (1, 'Jane Smith', 1);
INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (1, 'Group B', 10); 
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
INSERT INTO GROUPS (NAME, C_VAL) VALUES ('Группа Б', 20);
INSERT INTO GROUPS (NAME, C_VAL) VALUES ('Группа B', 5);

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
