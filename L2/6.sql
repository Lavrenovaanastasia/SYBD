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
