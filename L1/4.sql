CREATE OR REPLACE FUNCTION ID_Task4(p_id VARCHAR2) 
RETURN VARCHAR2 AS
    v_val NUMBER;
    v_sql VARCHAR2(4000);
BEGIN
    IF p_id IS NULL THEN
        RETURN 'Ошибка: ID не может быть NULL.';
    END IF;

    IF NOT REGEXP_LIKE(p_id, '^\d+$') THEN
        RETURN 'Ошибка: ID должен содержать только целые положительные числа.';
    END IF;

    -- Преобразование p_id в число
    DECLARE
        n_id NUMBER := TO_NUMBER(p_id);
    BEGIN
        
        IF n_id < 0 THEN
            RETURN 'Ошибка: ID не может быть отрицательным.';
        END IF;

        SELECT val INTO v_val FROM MyTable WHERE id = n_id;

        v_sql := 'INSERT INTO MyTable (id, val) VALUES (' || n_id || ', ' || v_val || ');';
        DBMS_OUTPUT.PUT_LINE(v_sql);
        RETURN v_sql;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Ошибка: ID ' || n_id || ' не найден в MyTable.';
        WHEN OTHERS THEN
            RETURN 'Ошибка выполнения: ' || SQLERRM;
    END;
END;


SET SERVEROUTPUT ON;

SELECT ID_Task4('-8') FROM dual; 
SELECT ID_Task4('abc') FROM dual; 
SELECT ID_Task4('5.5') FROM dual; 
SELECT ID_Task4('!') FROM dual; 
SELECT ID_Task4('10') FROM dual; 
SELECT ID_Task4('100000') FROM dual;