DECLARE
    v_count NUMBER;
BEGIN
    -- Используйте SELECT INTO для проверки существования пользователя
    SELECT COUNT(1) INTO v_count 
    FROM all_users 
    WHERE username = 'C##DEV_SCHEMA';

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Пользователь C##dev_schema не существует.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Пользователь C##dev_schema существует.');
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    -- Проверка существующих таблиц
    FOR rec IN (SELECT table_name FROM all_tables WHERE owner = 'C##DEV_SCHEMA') LOOP
        DBMS_OUTPUT.PUT_LINE('Таблица: ' || rec.table_name || ' существует.');
    END LOOP;

    -- Используйте SELECT INTO для проверки существования таблиц
    SELECT COUNT(1) INTO v_count FROM all_tables WHERE owner = 'C##DEV_SCHEMA' AND table_name = 'COMMON_TABLE';
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблица COMMON_TABLE не существует.');
    END IF;

    SELECT COUNT(1) INTO v_count FROM all_tables WHERE owner = 'C##DEV_SCHEMA' AND table_name = 'FOREIGN_TABLE';
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблица FOREIGN_TABLE не существует.');
    END IF;

    SELECT COUNT(1) INTO v_count FROM all_tables WHERE owner = 'C##DEV_SCHEMA' AND table_name = 'DIFF_TABLE';
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблица DIFF_TABLE не существует.');
    END IF;

    SELECT COUNT(1) INTO v_count FROM all_tables WHERE owner = 'C##DEV_SCHEMA' AND table_name = 'NEW_TABLE';
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Таблица NEW_TABLE не существует.');
    END IF;
END;
/
-- Проверка существования процедуры
SELECT object_name, object_type 
FROM all_objects 
WHERE object_name = 'MY_PROCEDURE' AND owner = 'C##DEV_SCHEMA';

-- Проверка процедуры
BEGIN
    EXECUTE IMMEDIATE 'CALL C##DEV_SCHEMA.MY_PROCEDURE';
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
    result := C##dev_schema.my_function;
    DBMS_OUTPUT.PUT_LINE('Результат вызова функции my_function: ' || result);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при вызове функции: ' || SQLERRM);
END;
/