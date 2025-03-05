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

--------t2
CREATE OR REPLACE TRIGGER GROUP_ID_UK
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
/
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
/
-----------------
CREATE SEQUENCE seq_student_id start with 1 increment by 1 nocache;
/
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
/
CREATE SEQUENCE seq_group_id start with 1 increment by 1 nocache;
/
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
/

-----------
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
/
-------------t3

------------------------------------- Создадим пакет, который будет использовать флаг для блокировки выполнения триггера
CREATE OR REPLACE PACKAGE trigger_control AS
    g_disable_trigger BOOLEAN := FALSE;
END trigger_control;
/

CREATE OR REPLACE PACKAGE BODY trigger_control AS
END trigger_control;
/

CREATE OR REPLACE TRIGGER cascade_delete_students
BEFORE DELETE ON GROUPS
FOR EACH ROW
BEGIN
    trigger_control.g_disable_trigger := TRUE;

    DELETE FROM STUDENTS
    WHERE GROUP_ID = :OLD.id;

    trigger_control.g_disable_trigger := FALSE;
END;
/


CREATE OR REPLACE PROCEDURE delete_group_and_students(p_group_id IN NUMBER) AS
BEGIN
    -- Удаляем студентов, относящихся к группе
    DELETE FROM STUDENTS WHERE GROUP_ID = p_group_id;

    -- Удаляем группу
    DELETE FROM GROUPS WHERE ID = p_group_id;
END delete_group_and_students;
/
------------------t4



-----------------t5

-- Журналирование изменений
CREATE TABLE Student_logs (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
    table_name VARCHAR2(50),    
    operation VARCHAR2(10),      
    record_id NUMBER,         
    old_values CLOB,
    new_values CLOB,
    changed_by VARCHAR2(100),
    changed_at TIMESTAMP DEFAULT SYSTIMESTAMP
)
/

CREATE OR REPLACE TRIGGER audit_Groups
AFTER INSERT OR UPDATE OR DELETE ON GROUPS
FOR EACH ROW
DECLARE
    v_old_values CLOB;
    v_new_values CLOB;
    v_operation VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
    ELSIF DELETING THEN
        v_operation := 'DELETE';
    END IF;

    IF UPDATING OR DELETING THEN
        v_old_values := 'id=' || :OLD.id || ', NAME=' || :OLD.NAME || ', C_VAL=' || :OLD.C_VAL;
    ELSE
        v_old_values := NULL;
    END IF;

    IF INSERTING OR UPDATING THEN
        v_new_values := 'id=' || :NEW.id || ', NAME=' || :NEW.NAME || ', C_VAL=' || :NEW.C_VAL;
    ELSE
        v_new_values := NULL;
    END IF;

    INSERT INTO Student_logs (
        table_name, 
        operation, 
        record_id, 
        old_values, 
        new_values, 
        changed_by, 
        changed_at
    )
    VALUES (
        'Groups', 
        v_operation, 
        COALESCE(:NEW.id, :OLD.id), 
        v_old_values, 
        v_new_values, 
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        SYSTIMESTAMP
    );
END;
/

-- Триггер для логирования изменений в Students
CREATE OR REPLACE TRIGGER audit_Students
AFTER INSERT OR UPDATE OR DELETE ON STUDENTS
FOR EACH ROW
DECLARE
    v_old_values CLOB;
    v_new_values CLOB;
    v_operation VARCHAR2(10);
BEGIN
    -- Определяем операцию (INSERT, UPDATE, DELETE)
    IF INSERTING THEN
        v_operation := 'INSERT';
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
    ELSIF DELETING THEN
        v_operation := 'DELETE';
    END IF;

    -- Формируем строковое представление старых значений (если UPDATE/DELETE)
    IF UPDATING OR DELETING THEN
        v_old_values := 'id=' || :OLD.id || ', NAME=' || :OLD.NAME || ', GROUP_ID=' || :OLD.GROUP_ID;
    ELSE
        v_old_values := NULL;
    END IF;

    -- Формируем строковое представление новых значений (если INSERT/UPDATE)
    IF INSERTING OR UPDATING THEN
        v_new_values := 'id=' || :NEW.id || ', NAME=' || :NEW.NAME || ', GROUP_ID=' || :NEW.GROUP_ID;
    ELSE
        v_new_values := NULL;
    END IF;

    -- Записываем изменения в журнал
    INSERT INTO Student_logs (
        table_name, 
        operation, 
        record_id, 
        old_values, 
        new_values, 
        changed_by, 
        changed_at
    )
    VALUES (
        'Students', 
        v_operation, 
        COALESCE(:NEW.id, :OLD.id), 
        v_old_values, 
        v_new_values, 
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        SYSTIMESTAMP
    );
END;
/
CREATE OR REPLACE PROCEDURE restore_data_from_audit(
    p_record_id IN NUMBER,       -- ID студента (0 = восстановить всех)
    p_restore_time IN TIMESTAMP  -- Время, до которого восстанавливать
)
IS
    CURSOR deleted_students IS
        SELECT record_id, old_values
        FROM Student_logs
        WHERE changed_at <= p_restore_time
              AND operation = 'DELETE'
              AND table_name = 'Students'
        ORDER BY changed_at DESC;

    CURSOR deleted_groups IS
        SELECT record_id, old_values
        FROM Student_logs
        WHERE changed_at <= p_restore_time
              AND operation = 'DELETE'
              AND table_name = 'Groups'
        ORDER BY changed_at DESC;

    v_old_values CLOB;
    v_name VARCHAR2(100);
    v_group_id NUMBER;
    v_group_name VARCHAR2(100);
    v_group_exists NUMBER;
BEGIN
    -- Восстанавливаем группы, если p_record_id = 0
    IF p_record_id = 0 THEN
        FOR grp IN deleted_groups LOOP
            v_old_values := grp.old_values;
            v_group_name := REGEXP_SUBSTR(v_old_values, 'NAME=([^,]+)', 1, 1, NULL, 1);
            
            -- Проверяем, существует ли группа
            SELECT COUNT(*) INTO v_group_exists FROM GROUPS WHERE ID = grp.record_id;
            
            -- Если группы нет, восстанавливаем её
            IF v_group_exists = 0 THEN
                INSERT INTO GROUPS (ID, NAME) VALUES (grp.record_id, v_group_name);
                DBMS_OUTPUT.PUT_LINE('Группа ID ' || grp.record_id || ' восстановлена.');
            END IF;
        END LOOP;

        -- Восстанавливаем всех студентов
        FOR stu IN deleted_students LOOP
            v_old_values := stu.old_values;
            v_name := REGEXP_SUBSTR(v_old_values, 'NAME=([^,]+)', 1, 1, NULL, 1);
            v_group_id := TO_NUMBER(REGEXP_SUBSTR(v_old_values, 'GROUP_ID=([^,]+)', 1, 1, NULL, 1));

            -- Проверяем, существует ли студент
            SELECT COUNT(*) INTO v_group_exists FROM STUDENTS WHERE ID = stu.record_id;

            -- Восстанавливаем студента, если его нет
            IF v_group_exists = 0 THEN
                INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (stu.record_id, v_name, v_group_id);
                DBMS_OUTPUT.PUT_LINE('Студент ID ' || stu.record_id || ' восстановлен.');
            END IF;
        END LOOP;
    ELSE
        -- Восстанавливаем одного студента
        BEGIN
            SELECT old_values
            INTO v_old_values
            FROM Student_logs
            WHERE record_id = p_record_id 
                  AND changed_at <= p_restore_time
                  AND operation = 'DELETE'
                  AND table_name = 'Students'
            ORDER BY changed_at DESC
            FETCH FIRST 1 ROW ONLY;

            v_name := REGEXP_SUBSTR(v_old_values, 'NAME=([^,]+)', 1, 1, NULL, 1);
            v_group_id := TO_NUMBER(REGEXP_SUBSTR(v_old_values, 'GROUP_ID=([^,]+)', 1, 1, NULL, 1));

            -- Проверяем, есть ли его группа
            SELECT COUNT(*) INTO v_group_exists FROM GROUPS WHERE ID = v_group_id;

            -- Если группа удалена, восстанавливаем её
            IF v_group_exists = 0 THEN
                BEGIN
                    SELECT old_values
                    INTO v_old_values
                    FROM Student_logs
                    WHERE record_id = v_group_id 
                          AND changed_at <= p_restore_time
                          AND operation = 'DELETE'
                          AND table_name = 'Groups'
                    ORDER BY changed_at DESC
                    FETCH FIRST 1 ROW ONLY;

                    v_group_name := REGEXP_SUBSTR(v_old_values, 'NAME=([^,]+)', 1, 1, NULL, 1);

                    INSERT INTO GROUPS (ID, NAME) VALUES (v_group_id, v_group_name);
                    DBMS_OUTPUT.PUT_LINE('Группа ID ' || v_group_id || ' восстановлена.');
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        DBMS_OUTPUT.PUT_LINE('Не найдено данных для группы ID ' || v_group_id);
                        RETURN;
                END;
            END IF;

            -- Восстанавливаем студента
            INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (p_record_id, v_name, v_group_id);
            DBMS_OUTPUT.PUT_LINE('Студент ID ' || p_record_id || ' восстановлен.');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Нет данных для восстановления студента с ID ' || p_record_id);
        END;
    END IF;
END;
/


----------------------t6

CREATE OR REPLACE TRIGGER trg_update_group_cval
FOR INSERT OR UPDATE OR DELETE ON STUDENTS
COMPOUND TRIGGER
    TYPE num_set IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
    old_group_ids num_set;
    new_group_ids num_set;

    BEFORE EACH ROW IS
    BEGIN
        IF trigger_control.g_disable_trigger THEN
            NULL; 
        ELSE
            IF (UPDATING OR DELETING) AND :OLD.GROUP_ID IS NOT NULL THEN
                old_group_ids(TRUNC(:OLD.GROUP_ID)) := TRUE;
            END IF;

            IF (INSERTING OR UPDATING) AND :NEW.GROUP_ID IS NOT NULL THEN
                new_group_ids(TRUNC(:NEW.GROUP_ID)) := TRUE;
            END IF;
        END IF;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        key PLS_INTEGER;
    BEGIN
        IF trigger_control.g_disable_trigger THEN
            NULL; 
        ELSE
            key := old_group_ids.FIRST;
            WHILE key IS NOT NULL LOOP
                UPDATE GROUPS
                SET C_VAL = C_VAL - 1
                WHERE id = key
                  AND C_VAL > 0;
                key := old_group_ids.NEXT(key);
            END LOOP;

            key := new_group_ids.FIRST;
            WHILE key IS NOT NULL LOOP
                UPDATE GROUPS
                SET C_VAL = C_VAL + 1
                WHERE id = key;
                key := new_group_ids.NEXT(key);
            END LOOP;

            UPDATE GROUPS
            SET C_VAL = 0
            WHERE id NOT IN (SELECT DISTINCT GROUP_ID FROM STUDENTS WHERE GROUP_ID IS NOT NULL);
        END IF;
    END AFTER STATEMENT;

END trg_update_group_cval;
/

-------------dop
