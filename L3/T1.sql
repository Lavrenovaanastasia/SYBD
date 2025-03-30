SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 1000;

-- Выдаем необходимые привилегии системе для выполнения процедур и доступа к таблицам
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('-------------------------НАСТРОЙКА ПРИВИЛЕГИЙ СИСТЕМЫ -------------------------');
END;
/

GRANT EXECUTE ANY PROCEDURE TO SYSTEM;  
GRANT EXECUTE ANY PROCEDURE ON SCHEMA C##DEV_SCHEMA TO SYSTEM;  
GRANT EXECUTE ANY PROCEDURE ON SCHEMA C##PROD_SCHEMA TO SYSTEM; 
GRANT SELECT ANY TABLE TO SYSTEM;  -- Разрешаем выборку данных из любых таблиц
GRANT SELECT ANY TABLE ON SCHEMA C##DEV_SCHEMA TO SYSTEM; 
GRANT SELECT ANY TABLE ON SCHEMA C##PROD_SCHEMA TO SYSTEM;  
GRANT SELECT ANY DICTIONARY TO SYSTEM;  
GRANT SELECT_CATALOG_ROLE TO SYSTEM;  -- для доступа к каталогам
GRANT EXECUTE_CATALOG_ROLE TO SYSTEM;  -- для выполнения операций над каталогами

-- Создаем таблицу для хранения результатов сравнения
BEGIN
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('------------------------------------ СОЗДАНИЕ ВСПОМОГАТЕЛЬНЫХ ТАБЛИЦ------------------------------------');
    
END;
/

CREATE TABLE comparison_result (
    table_name VARCHAR2(100),  -- Имя таблицы
    is_different NUMBER(1) DEFAULT 0,  -- Флаг, указывающий на различия (1 - есть различия, 0 - нет)
    is_only_in_dev_schema NUMBER(1) DEFAULT 0,  -- Флаг для таблиц, которые только в схеме разработки
    is_only_in_prod_schema NUMBER(1) DEFAULT 0  -- Флаг для таблиц, которые только в производственной схеме
);

-- Создаем таблицу для хранения отсортированных таблиц
CREATE TABLE sorted_tables (
    table_name VARCHAR2(100)  -- Имя таблицы
);

-- Процедура для сортировки таблиц по внешним ключам
CREATE OR REPLACE PROCEDURE sort_tables_in_schema(schema_name IN VARCHAR2) 
AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('----------------------------------- СОРТИРОВКА ТАБЛИЦ ПО ВНЕШНИМ КЛЮЧАМ------------------------------------------------');
   
    DBMS_OUTPUT.PUT_LINE('Схема: ' || schema_name);
    
    -- Цикл по всем таблицам, начиная с тех, у которых нет зависимостей
    FOR rec IN (
        WITH DEPENDENCYTREE(table_name, lvl) AS (
            -- Начинаем с таблиц без внешних ключей
            SELECT table_name, 1 AS lvl
            FROM all_tables
            WHERE owner = schema_name
            AND NOT EXISTS (
                SELECT 1
                FROM all_constraints
                WHERE constraint_type = 'R'
                AND r_constraint_name = constraint_name
            )
            UNION ALL
            -- Рекурсивно добавляем таблицы с внешними ключами
            SELECT a.table_name, b.lvl + 1
            FROM all_constraints a
            JOIN DEPENDENCYTREE b ON a.r_constraint_name = b.table_name
            WHERE a.owner = schema_name
            AND a.constraint_type = 'R'
        )
        SELECT table_name
        FROM DEPENDENCYTREE
        ORDER BY lvl  -- Сортируем по уровню вложенности
    ) LOOP
        BEGIN
            -- Вставляем имя таблицы в таблицу sorted_tables
            INSERT INTO sorted_tables (table_name) VALUES (rec.table_name);
            DBMS_OUTPUT.PUT_LINE('Добавлена таблица: ' || rec.table_name);
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('===========Сортировка таблиц завершена============');
END sort_tables_in_schema;
/

-- Создаем таблицу для хранения зависимостей между таблицами
CREATE TABLE schema_dependencies (
    child_obj VARCHAR2(100),  -- Имя дочернего объекта
    parent_obj VARCHAR2(100)   -- Имя родительского объекта
);

-- Процедура для поиска циклических зависимостей в схемах
CREATE OR REPLACE PROCEDURE check_cyclic_dependencies(schema_name IN VARCHAR2) 
AS
    result VARCHAR2(100);  -- Переменная для хранения результата
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('------------------------------ ПРОВЕРКА ЦИКЛИЧЕСКИХ ЗАВИСИМОСТЕЙ В СХЕМЕ------------------------------------------------');
 
    DBMS_OUTPUT.PUT_LINE('Схема: ' || schema_name);

    -- Цикл по всем таблицам в схеме
    FOR schema_table IN (SELECT schema_tables.table_name name FROM all_tables schema_tables WHERE owner = schema_name) 
    LOOP
        -- Вставляем уникальные пары родитель-ребенок в таблицу schema_dependencies
        INSERT INTO schema_dependencies (child_obj, parent_obj)
            SELECT DISTINCT a.table_name, c_pk.table_name r_table_name 
            FROM all_cons_columns a
            JOIN all_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN all_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
        WHERE c.constraint_type = 'R' AND a.table_name = schema_table.name;
    END LOOP;

    -- Проверка на циклические зависимости
    WITH Paths AS (
        SELECT child_obj, parent_obj, SYS_CONNECT_BY_PATH(child_obj, ',') AS path
        FROM schema_dependencies
        START WITH child_obj IN (SELECT DISTINCT child_obj FROM schema_dependencies)
        CONNECT BY NOCYCLE PRIOR parent_obj = child_obj
        AND LEVEL > 1
    )
    SELECT CASE 
             WHEN EXISTS (
               SELECT 1 
               FROM Paths 
               WHERE REGEXP_COUNT(path, ',') > 1
             ) THEN 'В схеме есть циклические зависимости' 
             ELSE 'В схеме нету циклических зависимостей' 
           END
    INTO result
    FROM dual;

    -- Выводим результат на экран
    DBMS_OUTPUT.PUT_LINE('Результат: ' || result);
    
    -- Очищаем таблицу зависимостей
    EXECUTE IMMEDIATE 'DELETE FROM schema_dependencies';
    DBMS_OUTPUT.PUT_LINE('========== Проверка завершена===========================');
END check_cyclic_dependencies;
/

-- Процедура для сравнения схем
CREATE OR REPLACE PROCEDURE compare_schemas(dev_schema IN VARCHAR2, prod_schema IN VARCHAR2, ddl_output IN NUMBER) 
AS
    diff NUMBER := 0;  -- Переменная для хранения количества различий
    query_string VARCHAR2(4000) := '';  -- Строка для хранения DDL-запросов
    temp_string VARCHAR2(4000) := '';  -- Временная строка для хранения результатов
BEGIN     
    
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('------------------------------ НАЧАЛО СРАВНЕНИЯ СХЕМ ------------------------');
    -- DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('================ DEV схема: ' || dev_schema || '               ============');
    DBMS_OUTPUT.PUT_LINE('================ PROD схема: ' || prod_schema || '             ============');
  
    DBMS_OUTPUT.PUT_LINE('');

    -- Цикл по всем таблицам, которые есть в обеих схемах
    FOR same_table IN 
        (SELECT table_name FROM all_tables dev_tables WHERE OWNER = dev_schema
        INTERSECT
        SELECT prod_tables.table_name FROM all_tables prod_tables WHERE OWNER = prod_schema) 
    LOOP
        -- Сравниваем структуру столбцов
        SELECT COUNT(*) INTO diff FROM
        (SELECT dev_table.COLUMN_NAME name, dev_table.DATA_TYPE FROM all_tab_columns dev_table 
        WHERE OWNER = dev_schema AND TABLE_NAME = same_table.table_name) dev_columns
        FULL JOIN
        (SELECT prod_table.COLUMN_NAME name, prod_table.DATA_TYPE FROM all_tab_columns prod_table
        WHERE OWNER = prod_schema AND TABLE_NAME = same_table.table_name) prod_columns
        ON dev_columns.name = prod_columns.name
        WHERE dev_columns.name IS NULL OR prod_columns.name IS NULL;

        -- Если есть различия, добавляем запись в результат
        IF diff > 0 THEN
            INSERT INTO comparison_result (table_name, is_different) VALUES (same_table.table_name, 1);
            DBMS_OUTPUT.PUT_LINE('Обнаружены различия в таблице: ' || same_table.table_name || ' (' || diff || ' различий)');
        ELSE
            INSERT INTO comparison_result (table_name) VALUES (same_table.table_name);
            DBMS_OUTPUT.PUT_LINE('Таблица ' || same_table.table_name || ' идентична в обеих схемах');
        END IF;
    END LOOP;

    -- Цикл по таблицам, которые есть только в схеме разработки
    FOR other_table IN 
        (SELECT dev_tables.table_name name FROM all_tables dev_tables WHERE dev_tables.OWNER = dev_schema
        MINUS 
        SELECT prod_tables.table_name FROM all_tables prod_tables WHERE prod_tables.OWNER = prod_schema) 
    LOOP
        INSERT INTO comparison_result (table_name, is_only_in_dev_schema) VALUES (other_table.name, 1);
        DBMS_OUTPUT.PUT_LINE('Таблица существует только в DEV: ' || other_table.name);
    END LOOP;

    -- Цикл по таблицам, которые есть только в производственной схеме
    FOR other_table IN 
        (SELECT prod_tables.table_name name FROM all_tables prod_tables WHERE prod_tables.OWNER = prod_schema
        MINUS
        SELECT dev_tables.table_name FROM all_tables dev_tables WHERE dev_tables.OWNER = dev_schema) 
    LOOP
        INSERT INTO comparison_result (table_name, is_only_in_prod_schema) VALUES (other_table.name, 1);
        DBMS_OUTPUT.PUT_LINE('Таблица существует только в PROD: ' || other_table.name);
    END LOOP;
    
    -- Выводим информацию о таблицах схемы разработки
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('-------------------------------АНАЛИЗ СХЕМЫ ' || dev_schema || '----------------------------------------------------------');
    
    check_cyclic_dependencies(dev_schema);  -- Проверяем на циклические зависимости
    sort_tables_in_schema(dev_schema);  -- Сортируем таблицы по внешнему ключу

    -- Цикл по результатам сравнения
    FOR rec IN (
        SELECT comparison_result.*
        FROM sorted_tables 
        JOIN comparison_result 
        ON sorted_tables.table_name = comparison_result.table_name
    ) LOOP
        IF rec.is_different = 1 THEN
            DBMS_OUTPUT.PUT_LINE(' Таблица ' || rec.table_name || ' имеет различия между схемами');
        ELSIF rec.is_only_in_dev_schema = 1 THEN
            DBMS_OUTPUT.PUT_LINE(' Таблица ' || rec.table_name || ' существует только в ' || dev_schema);
            SELECT create_object('TABLE', rec.table_name, prod_schema, dev_schema) INTO temp_string;
            query_string := query_string || CHR(10) || temp_string;  -- Добавляем запрос на создание таблицы в строку
        ELSE
            DBMS_OUTPUT.PUT_LINE(' Таблица ' || rec.table_name || ' идентична в обеих схемах');
        END IF;            
    END LOOP; 

    -- Очищаем временные таблицы
    EXECUTE IMMEDIATE 'DELETE FROM sorted_tables';
    
    -- Выводим информацию о таблицах схемы производства
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------АНАЛИЗ СХЕМЫ ' || prod_schema || ' ----------------------------------------------');
   
    check_cyclic_dependencies(prod_schema);  -- Проверяем на циклические зависимости
    sort_tables_in_schema(prod_schema);  -- Сортируем таблицы по внешнему ключу

    -- Цикл по результатам сравнения для производственной схемы
    FOR rec IN (
        SELECT comparison_result.*
        FROM sorted_tables 
        JOIN comparison_result 
        ON sorted_tables.table_name = comparison_result.table_name
    ) LOOP
        IF rec.is_different = 1 THEN
            DBMS_OUTPUT.PUT_LINE(' Таблица ' || rec.table_name || ' имеет различия между схемами');
            SELECT update_object('TABLE', rec.table_name, prod_schema, dev_schema) INTO temp_string;
            query_string := query_string || CHR(10) || temp_string;  -- Добавляем запрос на обновление таблицы в строку
        ELSIF rec.is_only_in_prod_schema = 1 THEN
            DBMS_OUTPUT.PUT_LINE(' Таблица ' || rec.table_name || ' существует только в ' || prod_schema);
            SELECT delete_object('TABLE', rec.table_name, prod_schema) INTO temp_string;
            query_string := query_string || CHR(10) || temp_string;  -- Добавляем запрос на удаление таблицы в строку
        ELSE
            DBMS_OUTPUT.PUT_LINE(' Таблица ' || rec.table_name || ' идентична в обеих схемах');
        END IF;            
    END LOOP; 

    -- Очищаем временные таблицы
    EXECUTE IMMEDIATE 'DELETE FROM sorted_tables';
    EXECUTE IMMEDIATE 'DELETE FROM comparison_result';

    -- Если нужно, выводим DDL скрипты
    IF ddl_output = 1 THEN
        DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------- DDL СКРИПТЫ ДЛЯ СИНХРОНИЗАЦИИ -----------------------------------');
   
        DBMS_OUTPUT.PUT_LINE(query_string);
    END IF;

    query_string := '';  -- Очищаем строку для следующего использования

    -- Сравниваем объекты схем
    compare_schemas_objects(dev_schema, prod_schema, query_string);

    -- Если нужно, выводим DDL скрипты для объектов
    IF ddl_output = 1 THEN
        DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('-------------------------------------DL СКРИПТЫ ДЛЯ ОБЪЕКТОВ СХЕМЫ -----------------------------------------------');
   
        DBMS_OUTPUT.PUT_LINE(query_string);
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------СРАВНЕНИЕ СХЕМ УСПЕШНО ЗАВЕРШЕНО-----------------------------------------');
   
END compare_schemas;
/

-------------------------------------------------------------------------------
-- Процедура для сравнения объектов схем
CREATE OR REPLACE PROCEDURE compare_schemas_objects(
    dev_schema IN VARCHAR2,  -- Имя схемы 
    prod_schema IN VARCHAR2,  -- Имя  схемы
    query_string OUT VARCHAR2  -- Строка для хранения результатов
)
AS
    dev_text VARCHAR2(32767);  -- Текст объекта в схеме
    prod_text VARCHAR2(32767);  -- Текст объекта в  схеме
    TYPE objarray IS VARRAY(4) OF VARCHAR2(10);  -- Массив для хранения типов объектов
    objects_arr objarray;  -- Переменная для массива объектов
    total INTEGER;  -- Общее количество объектов
    temp_string VARCHAR2(4000) := '';  -- Временная строка для хранения запросов
BEGIN
    -- Инициализируем массив с типами объектов для сравнения
    objects_arr := OBJARRAY('PROCEDURE', 'FUNCTION', 'INDEX', 'PACKAGE');
    total := objects_arr.count;  -- Получаем количество объектов

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------СРАВНЕНИЕ ОБЪЕКТОВ СХЕМ-----------------------------------------------------');
   
    -- Цикл по всем типам объектов
    FOR i IN 1 .. total LOOP
        DBMS_OUTPUT.PUT_LINE('Тип объекта: ' || objects_arr(i));
        
        -- Смотрим общие объекты между схемами
        FOR same_object IN 
            (SELECT dev_objects.object_name 
            FROM all_objects dev_objects 
            WHERE owner = dev_schema AND object_type = objects_arr(i)
            INTERSECT
            SELECT prod_objects.object_name 
            FROM all_objects prod_objects 
            WHERE owner = prod_schema AND object_type = objects_arr(i)) 
        LOOP    
            -- Убираем лишние пробелы и объединяем строки объекта в одну
            SELECT REGEXP_REPLACE(LISTAGG(text, ' ') WITHIN GROUP (ORDER BY line), ' {2,}', ' ') 
            INTO dev_text
            FROM all_source
            WHERE owner = dev_schema AND name = same_object.object_name;
    
            SELECT REGEXP_REPLACE(LISTAGG(text, ' ') WITHIN GROUP (ORDER BY line), ' {2,}', ' ') 
            INTO prod_text
            FROM all_source
            WHERE owner = prod_schema AND name = same_object.object_name;
            
            -- Сравниваем тексты объектов
            IF dev_text != prod_text THEN
                DBMS_OUTPUT.PUT_LINE('➤ ' || objects_arr(i) || ' ' || same_object.object_name || ' имеют различную структуру');
                SELECT update_object(objects_arr(i), same_object.object_name, prod_schema, dev_schema) INTO temp_string;
                query_string := query_string || CHR(10) || temp_string;  -- Добавляем запрос на обновление в строку
            ELSE
                DBMS_OUTPUT.PUT_LINE('✓ ' || objects_arr(i) || ' ' || same_object.object_name || ' идентичны');
            END IF;
        END LOOP;

        -- Цикл по объектам dev
        FOR other_object IN 
            (SELECT dev_objects.object_name 
            FROM all_objects dev_objects 
            WHERE owner = dev_schema AND object_type = objects_arr(i)
            MINUS
            SELECT prod_objects.object_name 
            FROM all_objects prod_objects 
            WHERE owner = prod_schema AND object_type = objects_arr(i)) 
        LOOP
            DBMS_OUTPUT.PUT_LINE('➤ ' || objects_arr(i) || ' ' || other_object.object_name || ' существует только в ' || dev_schema);
            SELECT create_object(objects_arr(i), other_object.object_name, prod_schema, dev_schema) INTO temp_string;
            query_string := query_string || CHR(10) || temp_string;  -- Добавляем запрос на создание в строку
        END LOOP;

        -- Цикл по объектам prod
        FOR other_object IN 
            (SELECT prod_objects.object_name 
            FROM all_objects prod_objects 
            WHERE owner = prod_schema AND object_type = objects_arr(i)
            MINUS
            SELECT dev_objects.object_name 
            FROM all_objects dev_objects 
            WHERE owner = dev_schema AND object_type = objects_arr(i)) 
        LOOP
            DBMS_OUTPUT.PUT_LINE('➤ ' || objects_arr(i) || ' ' || other_object.object_name || ' существует только в ' || prod_schema);
            SELECT delete_object(objects_arr(i), other_object.object_name, prod_schema) INTO temp_string;
            query_string := query_string || CHR(10) || temp_string;  -- Добавляем запрос на удаление в строку
        END LOOP;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('==========Сравнение объектов завершено===========================');
END compare_schemas_objects;
/

-- Создает строку для создания объекта
CREATE OR REPLACE FUNCTION create_object(object_type IN VARCHAR2, object_name IN VARCHAR2, main_schema IN VARCHAR2, aux_schema IN VARCHAR2) 
RETURN VARCHAR2 IS
    result VARCHAR(4000);  -- Переменная для хранения результата
BEGIN
    -- Настраиваем параметры для получения DDL
    IF object_type = 'TABLE' THEN
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
    END IF;

    -- Получаем DDL для объекта
    result := DBMS_METADATA.GET_DDL(object_type, object_name, aux_schema);
    result := REPLACE(result, aux_schema, main_schema);  -- Заменяем схему

    RETURN result;  -- Возвращаем результат
END create_object;
/

-- Создает строку для изменения объекта
CREATE OR REPLACE FUNCTION update_object(object_type IN VARCHAR2, object_name IN VARCHAR2, main_schema IN VARCHAR2, aux_schema IN VARCHAR2) 
RETURN VARCHAR2 IS
    result VARCHAR(4000);  -- Переменная для хранения результата
BEGIN
    -- Настраиваем параметры для получения DDL
    IF object_type = 'TABLE' THEN
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
        DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
    END IF;

    -- Получаем DDL для изменения объекта
    result := DBMS_METADATA.GET_DDL(object_type, object_name, aux_schema);
    result := REPLACE(result, aux_schema, main_schema);  -- Заменяем схему

    IF object_type = 'TABLE' THEN
        result := 'DROP ' || object_type || ' ' || main_schema || '.' || object_name || ';' || CHR(10) || result;
    END IF;
    
    RETURN result;
END update_object;
/

-- Создает строку для удаления
CREATE OR REPLACE FUNCTION delete_object(object_type IN VARCHAR2, object_name IN VARCHAR2, main_schema IN VARCHAR2) 
RETURN VARCHAR2 IS
BEGIN
    RETURN 'DROP ' || main_schema || '.' || object_type || ' ' || object_name || ';';
END delete_object;
/

-- Запуск процедуры сравнения схем с красивым выводом
BEGIN
    DBMS_OUTPUT.PUT_LINE('==========================================================================================');
    DBMS_OUTPUT.PUT_LINE('============= ЗАПУСК СРАВНЕНИЯ СХЕМ =============');
   
    DBMS_OUTPUT.PUT_LINE('');
    
    compare_schemas('C##DEV_SCHEMA', 'C##PROD_SCHEMA', 1);
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('============= ПРОЦЕДУРА ЗАВЕРШЕНА УСПЕШНО=============');
END;
/
