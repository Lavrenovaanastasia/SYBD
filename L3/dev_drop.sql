-- Удаление объектов схемы C##dev_schema
DROP USER c##dev_schema CASCADE;

BEGIN
    -- Удаляем ограничения внешних ключей
    EXECUTE IMMEDIATE 'ALTER TABLE C##dev_schema.foreign_table DROP CONSTRAINT foreign_table_common_id_fkey';
    
    -- Удаляем таблицы
    EXECUTE IMMEDIATE 'DROP TABLE C##dev_schema.new_table';
    EXECUTE IMMEDIATE 'DROP TABLE C##dev_schema.diff_table';
    EXECUTE IMMEDIATE 'DROP TABLE C##dev_schema.foreign_table';
    EXECUTE IMMEDIATE 'DROP TABLE C##dev_schema.common_table';

    -- Удаляем процедуры и функции
    EXECUTE IMMEDIATE 'DROP PROCEDURE C##dev_schema.my_procedure';
    EXECUTE IMMEDIATE 'DROP FUNCTION C##dev_schema.my_function';

    -- Удаляем пользователя
    EXECUTE IMMEDIATE 'DROP USER C##dev_schema CASCADE';
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
END;
/