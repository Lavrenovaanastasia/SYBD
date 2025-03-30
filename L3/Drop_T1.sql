BEGIN
    -- Удаление всех объектов в схеме C##DEV_SCHEMA
    EXECUTE IMMEDIATE 'DROP TABLE comparison_result CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE sorted_tables CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE schema_dependencies CASCADE CONSTRAINTS';
    
    EXECUTE IMMEDIATE 'DROP PROCEDURE check_cyclic_dependencies';
    EXECUTE IMMEDIATE 'DROP PROCEDURE sort_tables_in_schema';
    EXECUTE IMMEDIATE 'DROP PROCEDURE compare_schemas';
    EXECUTE IMMEDIATE 'DROP PROCEDURE compare_schemas_objects';
    
    EXECUTE IMMEDIATE 'DROP FUNCTION create_object';
    EXECUTE IMMEDIATE 'DROP FUNCTION update_object';
    EXECUTE IMMEDIATE 'DROP FUNCTION delete_object';

   
    -- Удаление всех объектов в схеме C##PROD_SCHEMA
    EXECUTE IMMEDIATE 'DROP TABLE comparison_result CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE sorted_tables CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE schema_dependencies CASCADE CONSTRAINTS';
    
    EXECUTE IMMEDIATE 'DROP PROCEDURE check_cyclic_dependencies';
    EXECUTE IMMEDIATE 'DROP PROCEDURE sort_tables_in_schema';
    EXECUTE IMMEDIATE 'DROP PROCEDURE compare_schemas';
    EXECUTE IMMEDIATE 'DROP PROCEDURE compare_schemas_objects';
    
    EXECUTE IMMEDIATE 'DROP FUNCTION create_object';
    EXECUTE IMMEDIATE 'DROP FUNCTION update_object';
    EXECUTE IMMEDIATE 'DROP FUNCTION delete_object';

   
    
    -- Удаление привилегий
    EXECUTE IMMEDIATE 'REVOKE EXECUTE ANY PROCEDURE FROM SYSTEM';
    EXECUTE IMMEDIATE 'REVOKE EXECUTE ANY PROCEDURE ON SCHEMA C##DEV_SCHEMA FROM SYSTEM';
    EXECUTE IMMEDIATE 'REVOKE EXECUTE ANY PROCEDURE ON SCHEMA C##PROD_SCHEMA FROM SYSTEM';
    EXECUTE IMMEDIATE 'REVOKE SELECT ANY TABLE FROM SYSTEM';
    EXECUTE IMMEDIATE 'REVOKE SELECT ANY TABLE ON SCHEMA C##DEV_SCHEMA FROM SYSTEM';
    EXECUTE IMMEDIATE 'REVOKE SELECT ANY TABLE ON SCHEMA C##PROD_SCHEMA FROM SYSTEM';
    EXECUTE IMMEDIATE 'REVOKE SELECT ANY DICTIONARY FROM SYSTEM';
    EXECUTE IMMEDIATE 'REVOKE SELECT_CATALOG_ROLE FROM SYSTEM';
    EXECUTE IMMEDIATE 'REVOKE EXECUTE_CATALOG_ROLE FROM SYSTEM';

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при удалении объектов: ' || SQLERRM);
END;
/

BEGIN--УДАЛИТЬ ВСЕ ТРИГГЕРЫ
    FOR r IN (SELECT trigger_name FROM user_triggers) LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || r.trigger_name;
    END LOOP;
END;
/

BEGIN -- Удалить все процедуры
    FOR r IN (SELECT object_name FROM user_procedures WHERE object_type = 'PROCEDURE') LOOP
        EXECUTE IMMEDIATE 'DROP PROCEDURE ' || r.object_name;
    END LOOP;
END;
/
