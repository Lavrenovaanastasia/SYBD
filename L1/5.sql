--------------
CREATE OR REPLACE PROCEDURE InsertIntoMyTable(p_val NUMBER) AS
    v_id NUMBER;
BEGIN   
    SELECT NVL(MAX(id), 0) + 1 INTO v_id FROM MyTable;

    INSERT INTO MyTable (id, val) VALUES (v_id, p_val);
    COMMIT; 
    DBMS_OUTPUT.PUT_LINE('Запись успешно добавлена: ID = ' || v_id || ', VAL = ' || p_val);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка выполнения: ' || SQLERRM);
END InsertIntoMyTable;
-------------
CREATE OR REPLACE PROCEDURE InsertVMyTable(p_id NUMBER, p_val NUMBER) AS
BEGIN
    IF p_id <= 0 OR TRUNC(p_id) != p_id THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ID должен быть положительным целым числом.');
        RETURN;
    END IF;

    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM MyTable WHERE id = p_id;

        IF v_count > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Запись с ID = ' || p_id || ' уже существует.');
            RETURN;
        END IF;
    END;

    -- Вставка записи
    INSERT INTO MyTable (id, val) VALUES (p_id, p_val);
    COMMIT; 

    DBMS_OUTPUT.PUT_LINE('Запись успешно добавлена: ID = ' || p_id || ', VAL = ' || p_val);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка выполнения: ' || SQLERRM);
END InsertVMyTable;

------------------------
CREATE OR REPLACE PROCEDURE UpdateMyTable(p_id NUMBER, p_val NUMBER) AS
    v_count NUMBER;
BEGIN
    IF p_id <= 0 OR TRUNC(p_id) != p_id THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ID должен быть положительным целым числом.');
        RETURN;
    END IF;

    IF p_val < 1 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Значение не должно быть отрицательным или равным нулю.');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_count FROM MyTable WHERE id = p_id;
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Запись с ID = ' || p_id || ' не найдена для обновления.');
        RETURN;
    END IF;

    UPDATE MyTable SET val = p_val WHERE id = p_id;
    COMMIT; 
    DBMS_OUTPUT.PUT_LINE('Запись успешно обновлена: ID = ' || p_id || ', Новый VAL = ' || p_val);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка выполнения: ' || SQLERRM);
END UpdateMyTable;
-------------------------
CREATE OR REPLACE PROCEDURE DeleteFromMyTable(p_id NUMBER) AS
    v_count NUMBER;
BEGIN
    IF p_id <= 0 OR TRUNC(p_id) != p_id THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ID должен быть положительным целым числом.');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_count FROM MyTable WHERE id = p_id;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Запись с ID = ' || p_id || ' не найдена для удаления.');
        RETURN;
    END IF;

    DELETE FROM MyTable WHERE id = p_id;
    COMMIT; 
    DBMS_OUTPUT.PUT_LINE('Запись успешно удалена: ID = ' || p_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка выполнения: ' || SQLERRM);
END DeleteFromMyTable;


SET SERVEROUTPUT ON;

EXEC InsertIntoMyTable(100);

EXEC InsertVMyTable(1, 200); 
EXEC InsertVMyTable(0, 150);  
EXEC InsertVMyTable(-5, 150); 
EXEC InsertVMyTable(100, -50);  

EXEC UpdateMyTable(0, -150);
EXEC UpdateMyTable(-1, -150);
EXEC UpdateMyTable(1, 150);       
EXEC UpdateMyTable(999, 150);   


EXEC DeleteFromMyTable(1);   
EXEC DeleteFromMyTable(999);  
EXEC DeleteFromMyTable(0);    
EXEC DeleteFromMyTable(-5);   
EXEC DeleteFromMyTable(2.5);  
