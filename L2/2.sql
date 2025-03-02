--для проверки уникальности полей ID 
CREATE OR REPLACE TRIGGER trg_check_student_id
BEFORE INSERT ON STUDENTS
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM STUDENTS WHERE ID = :NEW.ID) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Student ID must be unique.');
    END IF;
END;

CREATE OR REPLACE TRIGGER trg_check_group_id
BEFORE INSERT ON GROUPS
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM GROUPS WHERE ID = :NEW.ID) THEN
        RAISE_APPLICATION_ERROR(-20002, 'Group ID must be unique.');
    END IF;
END;

--для генерации автоинкрементного ключа
-- Создаем последовательность для студентов
CREATE SEQUENCE student_seq START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_auto_increment_student
BEFORE INSERT ON STUDENTS
FOR EACH ROW
BEGIN
    IF :NEW.ID IS NULL THEN
        SELECT student_seq.NEXTVAL INTO :NEW.ID FROM dual;
    END IF;
END;
/

-- Создаем последовательность для групп
CREATE SEQUENCE group_seq START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_auto_increment_group
BEFORE INSERT ON GROUPS
FOR EACH ROW
BEGIN
    IF :NEW.ID IS NULL THEN
        SELECT group_seq.NEXTVAL INTO :NEW.ID FROM dual;
    END IF;
END;



--для проверки уникальности поля GROUP.NAME