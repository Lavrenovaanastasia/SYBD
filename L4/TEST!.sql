-- Создание таблицы t1 с автоинкрементом для первичного ключа
DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "t1",
    "fields": "id NUMBER PRIMARY KEY, name VARCHAR2(100)",
    "generate_trigger": "true",
    "trigger_name": "t1_trigger",
    "pk_field": "id",
    "sequence_name": "t1_seq"
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

  DBMS_OUTPUT.PUT_LINE('Создание таблицы t1 с триггером для генерации id');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/

-- Создание таблицы t2 с внешним ключом, ссылающимся на таблицу t1
DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "t2",
    "fields": "id NUMBER PRIMARY KEY, t1_id NUMBER, description VARCHAR2(200), CONSTRAINT fk_t1 FOREIGN KEY (t1_id) REFERENCES t1(id)",
    "generate_trigger": "true",
    "trigger_name": "t2_trigger",
    "pk_field": "id",
    "sequence_name": "t2_seq"
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

  DBMS_OUTPUT.PUT_LINE('Создание таблицы t2 с триггером для генерации id и внешним ключом на t1');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/

-- Вставка данных в таблицу t1
DECLARE
  v_json_input CLOB := '{
    "query_type": "INSERT",
    "table": "t1",
    "columns": "name",
    "values": "''Test Name 1''"
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

  DBMS_OUTPUT.PUT_LINE('Вставка данных в таблицу t1');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/

-- Вставка данных в таблицу t2
DECLARE
  v_json_input CLOB := '{
    "query_type": "INSERT",
    "table": "t2",
    "columns": "t1_id, description",
    "values": "1, ''Test Description 1''"
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

  DBMS_OUTPUT.PUT_LINE('Вставка данных в таблицу t2');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/

-- Проверка данных в таблице t1
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "id, name",
    "tables": "t1"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_id        NUMBER;
  v_name      VARCHAR2(100);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Проверка данных в таблице t1');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_id, v_name;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ', Name: ' || v_name);
  END LOOP;

  CLOSE v_cursor;
END;
/

-- Проверка данных в таблице t2
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "id, t1_id, description",
    "tables": "t2"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_id        NUMBER;
  v_t1_id     NUMBER;
  v_description VARCHAR2(200);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Проверка данных в таблице t2');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_id, v_t1_id, v_description;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ', t1_id: ' || v_t1_id || ', Description: ' || v_description);
  END LOOP;

  CLOSE v_cursor;
END;
/
