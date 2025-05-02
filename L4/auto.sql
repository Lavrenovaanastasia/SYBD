CREATE USER MYUSER IDENTIFIED BY 1111;
GRANT CONNECT, RESOURCE TO MYUSER;
SELECT USER FROM dual;
SELECT trigger_name FROM user_triggers WHERE table_name = 'STUDENT_AUDIT';

--------------------------------------------------
-- 0. Подготовка: Удаление объектов если существуют
--------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER employees_autoinc_trigger';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE employees_seq';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE employees';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

--------------------------------------------------
-- 1. Создание таблицы с отладочным выводом
--------------------------------------------------
DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "employees",
    "fields": "employee_id NUMBER, name VARCHAR2(100), position VARCHAR2(100)",
    "generate_trigger": "true",
    "trigger_name": "employees_autoinc_trigger",
    "pk_field": "employee_id",
    "sequence_name": "employees_seq"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);
BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );
  
  -- Диагностика после создания
  DBMS_OUTPUT.PUT_LINE('1. Создание таблицы: ' || v_message);
  DBMS_OUTPUT.PUT_LINE('Проверка объектов:');
  BEGIN
    EXECUTE IMMEDIATE 'SELECT 1 FROM employees WHERE 1=0';
    DBMS_OUTPUT.PUT_LINE('Таблица employees существует');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка доступа к таблице: ' || SQLERRM);
  END;
END;
/

--------------------------------------------------
-- 2. Проверка создания триггера и последовательности
--------------------------------------------------
DECLARE
  v_count NUMBER;
BEGIN
  -- Проверка триггера
  SELECT COUNT(*) INTO v_count 
  FROM user_triggers 
  WHERE trigger_name = 'EMPLOYEES_AUTOINC_TRIGGER';
  
  DBMS_OUTPUT.PUT_LINE('2. Триггер существует: ' || CASE WHEN v_count > 0 THEN 'Да' ELSE 'Нет' END);

  -- Проверка последовательности
  SELECT COUNT(*) INTO v_count 
  FROM user_sequences 
  WHERE sequence_name = 'EMPLOYEES_SEQ';
  
  DBMS_OUTPUT.PUT_LINE('3. Последовательность существует: ' || CASE WHEN v_count > 0 THEN 'Да' ELSE 'Нет' END);
END;
/

--------------------------------------------------
-- 4. Вставка данных с проверкой триггера
--------------------------------------------------
-- Первая вставка
DECLARE
  v_json_input CLOB := '{
    "query_type": "INSERT",
    "table": "employees",
    "columns": "name, position",
    "values": "''Иван Петров'', ''Менеджер''"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);
BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );
  DBMS_OUTPUT.PUT_LINE('4. Первая вставка: ' || v_message);
  
  -- Прямая проверка через SQL
  DECLARE
    v_id NUMBER;
  BEGIN
    SELECT employee_id INTO v_id 
    FROM employees 
    WHERE name = 'Иван Петров';
    
    DBMS_OUTPUT.PUT_LINE('5. Проверка ID первого сотрудника: ' || v_id);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('5. Данные не найдены');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('5. Ошибка проверки: ' || SQLERRM);
  END;
END;
/

--------------------------------------------------
-- 6. Итоговый вывод
--------------------------------------------------
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "employee_id, name, position",
    "tables": "employees"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_employee_id NUMBER;
  v_name        VARCHAR2(100);
  v_position    VARCHAR2(100);
BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('6. Итоговый результат:');
  LOOP
    FETCH v_cursor INTO v_employee_id, v_name, v_position;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(
      'ID: ' || NVL(TO_CHAR(v_employee_id), 'NULL') || 
      ', Name: ' || v_name || 
      ', Position: ' || v_position
    );
  END LOOP;
  CLOSE v_cursor;
END;
/