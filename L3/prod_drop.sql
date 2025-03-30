-- Удаление объектов схемы C##prod_schema
DROP USER c##prod_schema CASCADE;
-- Удаление объектов схемы C##prod_schema

BEGIN
    -- Удаляем ограничения внешних ключей
    EXECUTE IMMEDIATE 'ALTER TABLE C##prod_schema.circle1 DROP CONSTRAINT fk_circle2_id';
    
    -- Удаляем таблицы
    EXECUTE IMMEDIATE 'DROP TABLE C##prod_schema.circle2';
    EXECUTE IMMEDIATE 'DROP TABLE C##prod_schema.circle1';
    EXECUTE IMMEDIATE 'DROP TABLE C##prod_schema.diff_table';
    EXECUTE IMMEDIATE 'DROP TABLE C##prod_schema.foreign_table';
    EXECUTE IMMEDIATE 'DROP TABLE C##prod_schema.common_table';

    -- Удаляем процедуры и функции
    EXECUTE IMMEDIATE 'DROP PROCEDURE C##prod_schema.my_procedure';
    EXECUTE IMMEDIATE 'DROP FUNCTION C##prod_schema.my_function';

    -- Удаляем пользователя
    EXECUTE IMMEDIATE 'DROP USER C##prod_schema CASCADE';
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
END;
/
