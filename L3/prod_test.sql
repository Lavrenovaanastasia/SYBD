-- Проверка существования пользователя
DECLARE
    v_count NUMBER;
BEGIN
    -- Используйте SELECT INTO для проверки существования пользователя
    SELECT COUNT(1) INTO v_count 
    FROM all_users 
    WHERE username = 'C##PROD_SCHEMA';

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Пользователь C##prod_schema не существует.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Пользователь C##prod_schema существует.');
    END IF;
END;
/

-- Проверка существующих таблиц
DECLARE
    v_count NUMBER;
BEGIN
    FOR rec IN (SELECT table_name FROM all_tables WHERE owner = 'C##PROD_SCHEMA') LOOP
        DBMS_OUTPUT.PUT_LINE('Таблица: ' || rec.table_name || ' существует.');
    END LOOP;

    SELECT COUNT(1) INTO v_count FROM all_tables WHERE owner = 'C##PROD_SCHEMA' AND table_name = 'COMMON_TABLE';
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблица COMMON_TABLE не существует.');
    END IF;

    SELECT COUNT(1) INTO v_count FROM all_tables WHERE owner = 'C##PROD_SCHEMA' AND table_name = 'FOREIGN_TABLE';
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблица FOREIGN_TABLE не существует.');
    END IF;

    SELECT COUNT(1) INTO v_count FROM all_tables WHERE owner = 'C##PROD_SCHEMA' AND table_name = 'DIFF_TABLE';
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблица DIFF_TABLE не существует.');
    END IF;

    SELECT COUNT(1) INTO v_count FROM all_tables WHERE owner = 'C##PROD_SCHEMA' AND table_name = 'CIRCLE1';
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблица CIRCLE1 не существует.');
    END IF;

    SELECT COUNT(1) INTO v_count FROM all_tables WHERE owner = 'C##PROD_SCHEMA' AND table_name = 'CIRCLE2';
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблица CIRCLE2 не существует.');
    END IF;
END;
/

-- Проверка существования процедуры
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(1) INTO v_count 
    FROM all_objects 
    WHERE object_name = 'MY_PROCEDURE' AND owner = 'C##PROD_SCHEMA';

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Процедура my_procedure не существует.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Процедура my_procedure существует.');
    END IF;
END;
/

-- Проверка процедуры
BEGIN
    C##PROD_SCHEMA.my_procedure;  
    DBMS_OUTPUT.PUT_LINE('Процедура my_procedure выполнена успешно.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры: ' || SQLERRM);
END;
/

-- Проверка функции
DECLARE
    result NUMBER;
BEGIN
    result := C##PROD_SCHEMA.my_function;
    DBMS_OUTPUT.PUT_LINE('Результат вызова функции my_function: ' || result);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при вызове функции: ' || SQLERRM);
END;
/