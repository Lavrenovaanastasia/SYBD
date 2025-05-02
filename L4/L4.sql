CREATE OR REPLACE PROCEDURE dynamic_sql_executor (
  p_json    IN  CLOB,
  p_cursor  OUT SYS_REFCURSOR,
  p_rows    OUT NUMBER,
  p_message OUT VARCHAR2
) AS
  /* ЗАДАНИЕ 1-5: Объявление констант для всех типов запросов */
  c_query_type_select CONSTANT VARCHAR2(10) := 'SELECT';
  c_query_type_insert CONSTANT VARCHAR2(10) := 'INSERT';
  c_query_type_update CONSTANT VARCHAR2(10) := 'UPDATE';
  c_query_type_delete CONSTANT VARCHAR2(10) := 'DELETE';
  c_query_type_ddl    CONSTANT VARCHAR2(10) := 'DDL';

  -- Локальные переменные
  v_json_obj          JSON_OBJECT_T;
  v_query_type        VARCHAR2(50);
  v_query             VARCHAR2(32767);
  v_filter_clause     VARCHAR2(32767);

  /* ЗАДАНИЕ 1-2: Парсер условий из JSON */
  PROCEDURE parse_json_conditions(
    p_json_obj IN JSON_OBJECT_T,
    p_join_conditions OUT VARCHAR2,
    p_where_conditions OUT VARCHAR2,
    p_subquery_conditions OUT VARCHAR2,
    p_group_by OUT VARCHAR2
  ) IS
  BEGIN
    -- Извлечение условий соединения, фильтрации и подзапросов
    BEGIN
      p_join_conditions := p_json_obj.get_String('join_conditions');
    EXCEPTION WHEN NO_DATA_FOUND THEN
      p_join_conditions := NULL;
    END;

    BEGIN
      p_where_conditions := p_json_obj.get_String('where_conditions');
    EXCEPTION WHEN NO_DATA_FOUND THEN
      p_where_conditions := NULL;
    END;

    BEGIN
      p_subquery_conditions := p_json_obj.get_String('subquery_conditions');
    EXCEPTION WHEN NO_DATA_FOUND THEN
      p_subquery_conditions := NULL;
    END;

    BEGIN
      p_group_by := p_json_obj.get_String('group_by');
    EXCEPTION WHEN NO_DATA_FOUND THEN
      p_group_by := NULL;
    END;
  END parse_json_conditions;

  /* ЗАДАНИЕ 1-2: Построение условия фильтрации */
  FUNCTION build_filter_clause(
    p_join_conditions IN VARCHAR2,
    p_where_conditions IN VARCHAR2,
    p_subquery_conditions IN VARCHAR2
  ) RETURN VARCHAR2 IS
    v_filter_clause VARCHAR2(32767);
  BEGIN
    -- Комбинирование условий JOIN, WHERE и подзапросов
    v_filter_clause := NULL;
    IF p_join_conditions IS NOT NULL THEN
      v_filter_clause := p_join_conditions;
    END IF;
    
    IF p_where_conditions IS NOT NULL THEN
      v_filter_clause := COALESCE(v_filter_clause || ' AND ', '') || p_where_conditions;
    END IF;
    
    IF p_subquery_conditions IS NOT NULL THEN
      v_filter_clause := COALESCE(v_filter_clause || ' AND ', '') || p_subquery_conditions;
    END IF;
    
    RETURN v_filter_clause;
  END build_filter_clause;

  /* ЗАДАНИЕ 3: Выполнение DML операций */
  PROCEDURE execute_dml(
    p_query_type IN VARCHAR2,
    p_table IN VARCHAR2,
    p_columns IN VARCHAR2,
    p_values IN VARCHAR2,
    p_set_clause IN VARCHAR2,
    p_filter_clause IN VARCHAR2,
    p_rows OUT NUMBER,
    p_message OUT VARCHAR2
  ) IS
    v_query VARCHAR2(32767);
  BEGIN
    -- Генерация запросов INSERT/UPDATE/DELETE
    IF p_query_type = c_query_type_insert THEN
      v_query := 'INSERT INTO ' || p_table || ' (' || p_columns || ') VALUES (' || p_values || ')';
    ELSIF p_query_type = c_query_type_update THEN
      v_query := 'UPDATE ' || p_table || ' SET ' || p_set_clause;
      IF p_filter_clause IS NOT NULL THEN
        v_query := v_query || ' WHERE ' || p_filter_clause;
      END IF;
    ELSIF p_query_type = c_query_type_delete THEN
      v_query := 'DELETE FROM ' || p_table;
      IF p_filter_clause IS NOT NULL THEN
        v_query := v_query || ' WHERE ' || p_filter_clause;
      END IF;
    END IF;

    EXECUTE IMMEDIATE v_query;
    p_rows := SQL%ROWCOUNT;
    p_message := 'DML операция ' || p_query_type || ' выполнена.';
  END execute_dml;

  /* ЗАДАНИЕ 5: Создание триггера для генерации PK */
  PROCEDURE create_trigger(
    p_table IN VARCHAR2,
    p_trigger_name IN VARCHAR2,
    p_pk_field IN VARCHAR2,
    p_sequence_name IN VARCHAR2,
    p_message IN OUT VARCHAR2
  ) IS
    v_trigger_sql VARCHAR2(32767);
  BEGIN
    -- Создание последовательности и триггера
    BEGIN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || p_sequence_name;
    EXCEPTION WHEN OTHERS THEN
      NULL; -- Если последовательность уже существует
    END;

    v_trigger_sql :=
      'CREATE OR REPLACE TRIGGER ' || p_trigger_name || 
      ' BEFORE INSERT ON ' || p_table || 
      ' FOR EACH ROW WHEN (new.' || p_pk_field || ' IS NULL)' ||
      ' BEGIN ' ||
      '   SELECT ' || p_sequence_name || '.NEXTVAL INTO :new.' || p_pk_field || ' FROM dual;' ||
      ' END;';
      
    EXECUTE IMMEDIATE v_trigger_sql;
    p_message := p_message || ' Триггер ' || p_trigger_name || ' создан.';
  END create_trigger;

BEGIN
  /* Основной блок выполнения */
  -- Парсинг JSON
  BEGIN
    v_json_obj := JSON_OBJECT_T.parse(p_json);
    v_query_type := UPPER(v_json_obj.get_String('query_type'));
  EXCEPTION
    WHEN OTHERS THEN
      p_message := 'Ошибка при парсинге JSON: ' || SQLERRM;
      RETURN;
  END;

  /* ЗАДАНИЕ 1-2: Обработка SELECT запросов */
  IF v_query_type = c_query_type_select THEN
    DECLARE
      v_select_columns      VARCHAR2(32767);
      v_tables              VARCHAR2(32767);
      v_join_conditions     VARCHAR2(32767);
      v_where_conditions    VARCHAR2(32767);
      v_subquery_conditions VARCHAR2(32767);
      v_group_by            VARCHAR2(32767);
    BEGIN
      -- Извлечение параметров из JSON
      v_select_columns := v_json_obj.get_String('select_columns');
      v_tables         := v_json_obj.get_String('tables');
      parse_json_conditions(v_json_obj, v_join_conditions, v_where_conditions, v_subquery_conditions, v_group_by);

      -- Построение запроса
      v_filter_clause := build_filter_clause(v_join_conditions, v_where_conditions, v_subquery_conditions);
      v_query := 'SELECT ' || v_select_columns || ' FROM ' || v_tables;
      
      IF v_filter_clause IS NOT NULL THEN
        v_query := v_query || ' WHERE ' || v_filter_clause;
      END IF;
      
      IF v_group_by IS NOT NULL THEN
        v_query := v_query || ' GROUP BY ' || v_group_by;
      END IF;

      -- Выполнение и возврат курсора
      OPEN p_cursor FOR v_query;
      p_message := 'SELECT выполнен успешно';
      p_rows    := 0;
    END;

  /* ЗАДАНИЕ 3: Обработка DML операций */
  ELSIF v_query_type IN (c_query_type_insert, c_query_type_update, c_query_type_delete) THEN
    DECLARE
      v_table      VARCHAR2(100);
      v_columns    VARCHAR2(32767);
      v_values     VARCHAR2(32767);
      v_set_clause VARCHAR2(32767);
      v_join_conditions     VARCHAR2(32767);
      v_where_conditions    VARCHAR2(32767);
      v_subquery_conditions VARCHAR2(32767);
      v_group_by            VARCHAR2(32767);
    BEGIN
      v_table := v_json_obj.get_String('table');
      -- Обработка разных типов DML
      IF v_query_type = c_query_type_insert THEN
        v_columns := v_json_obj.get_String('columns');
        v_values  := v_json_obj.get_String('values');
      ELSIF v_query_type = c_query_type_update THEN
        v_set_clause := v_json_obj.get_String('set_clause');
      END IF;

      parse_json_conditions(v_json_obj, v_join_conditions, v_where_conditions, v_subquery_conditions, v_group_by);
      v_filter_clause := build_filter_clause(v_join_conditions, v_where_conditions, v_subquery_conditions);

      execute_dml(v_query_type, v_table, v_columns, v_values, v_set_clause, v_filter_clause, p_rows, p_message);
    END;

  /* ЗАДАНИЕ 4-5: Обработка DDL операций */
  ELSIF v_query_type = c_query_type_ddl THEN
    DECLARE
      v_ddl_command      VARCHAR2(50);
      v_table           VARCHAR2(100);
      v_fields          VARCHAR2(32767);
      v_generate_trigger VARCHAR2(5);
      v_trigger_name    VARCHAR2(100);
      v_pk_field        VARCHAR2(100);
      v_sequence_name   VARCHAR2(100);
    BEGIN
      v_ddl_command := UPPER(v_json_obj.get_String('ddl_command'));
      v_table := v_json_obj.get_String('table');

      IF v_ddl_command = 'CREATE TABLE' THEN
        -- Создание таблицы
        v_fields := v_json_obj.get_String('fields');
        EXECUTE IMMEDIATE 'CREATE TABLE ' || v_table || ' (' || v_fields || ')';
        p_message := 'Таблица ' || v_table || ' создана.';

        -- Создание триггера (ЗАДАНИЕ 5)
        BEGIN
          v_generate_trigger := v_json_obj.get_String('generate_trigger');
          IF LOWER(v_generate_trigger) = 'true' THEN
            v_trigger_name  := v_json_obj.get_String('trigger_name');
            v_pk_field      := v_json_obj.get_String('pk_field');
            v_sequence_name := v_json_obj.get_String('sequence_name');
            create_trigger(v_table, v_trigger_name, v_pk_field, v_sequence_name, p_message);
          END IF;
        EXCEPTION WHEN NO_DATA_FOUND THEN
          NULL; -- Триггер не требуется
        END;

      ELSIF v_ddl_command = 'DROP TABLE' THEN
        -- Удаление таблицы
        EXECUTE IMMEDIATE 'DROP TABLE ' || v_table;
        p_message := 'Таблица ' || v_table || ' удалена.';
      END IF;
      
      p_rows   := 0;
      p_cursor := NULL;
    END;

  ELSE
    RAISE_APPLICATION_ERROR(-20001, 'Неподдерживаемый тип запроса: ' || v_query_type);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    p_message := 'Ошибка: ' || SQLERRM;
    p_rows    := 0;
    p_cursor  := NULL;
END dynamic_sql_executor;
/



/* ЗАДАНИЕ 4: Удаление таблиц (DDL операция) */
-- Процедура для безопасного удаления таблиц с проверкой блокировок
CREATE OR REPLACE PROCEDURE drop_table_if_exists(table_name IN VARCHAR2) IS
BEGIN
  BEGIN
    -- Попытка заблокировать таблицу для проверки доступности
    EXECUTE IMMEDIATE 'LOCK TABLE ' || table_name || ' IN EXCLUSIVE MODE NOWAIT';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -54 THEN  -- Ошибка "resource busy"
        DBMS_OUTPUT.PUT_LINE('Таблица ' || table_name || ' заблокирована. Пропускаем удаление.');
        RETURN;
      END IF;
  END;

  -- Непосредственное удаление таблицы
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ' || table_name || ' CASCADE CONSTRAINTS';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE != -942 THEN  -- Игнорируем ошибку "table does not exist"
        RAISE;
      END IF;
  END;
END;
/

/* ЗАДАНИЕ 4: Массовое удаление таблиц */
BEGIN
  drop_table_if_exists('student_groups');
  drop_table_if_exists('students');
END;
/


/* ЗАДАНИЕ 4: Создание таблиц (DDL операция) */
-- Таблица групп студентов
CREATE TABLE student_groups (
  group_id   NUMBER PRIMARY KEY,
  group_name VARCHAR2(100) NOT NULL
);

-- Таблица студентов с внешним ключом на группы
CREATE TABLE students (
  student_id   NUMBER PRIMARY KEY,
  student_name VARCHAR2(100) NOT NULL,
  group_id     NUMBER,
  CONSTRAINT fk_student_group FOREIGN KEY (group_id) REFERENCES student_groups(group_id)
)
/

/* ЗАДАНИЕ 3: Вставка начальных данных (DML операция) */
-- Данные для таблицы групп студентов
INSERT INTO student_groups (group_id, group_name) VALUES (1, 'Group A');
INSERT INTO student_groups (group_id, group_name) VALUES (2, 'Group B');
INSERT INTO student_groups (group_id, group_name) VALUES (3, 'Group C');
COMMIT;
/

-- Данные для таблицы студентов
INSERT INTO students (student_id, student_name, group_id) VALUES (1001, 'Ivan Ivanov', 1);
INSERT INTO students (student_id, student_name, group_id) VALUES (1002, 'Maria Petrova', 2);
INSERT INTO students (student_id, student_name, group_id) VALUES (1003, 'Petr Sidorov', 3);
COMMIT;
/



