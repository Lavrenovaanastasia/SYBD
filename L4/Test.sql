--------------------------------------------------
--  SELECT запросы
--------------------------------------------------

--  Простой SELECT запрос (выборка студентов и их групп)
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "s.student_name, g.group_name",
    "tables": "students s, student_groups g",
    "join_conditions": "s.group_id = g.group_id"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_student_name VARCHAR2(100);
  v_group_name   VARCHAR2(100);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE(' Простой SELECT запрос (выборка студентов и их групп)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_student_name, v_group_name;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Student: ' || v_student_name || ', Group: ' || v_group_name);
  END LOOP;

  CLOSE v_cursor;
END;
/

--  SELECT запрос с GROUP BY (подсчет количества студентов в каждой группе)
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "g.group_name, COUNT(s.student_id) AS student_count",
    "tables": "students s, student_groups g",
    "join_conditions": "s.group_id = g.group_id",
    "group_by": "g.group_name"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_group_name   VARCHAR2(100);
  v_student_count NUMBER;

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('SELECT запрос с GROUP BY (подсчет количества студентов в каждой группе)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_group_name, v_student_count;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Group: ' || v_group_name || ', Student Count: ' || v_student_count);
  END LOOP;

  CLOSE v_cursor;
END;
/

--  SELECT запрос с GROUP BY и WHERE (подсчет студентов в группах с определенными условиями)
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "g.group_name, COUNT(s.student_id) AS student_count",
    "tables": "students s, student_groups g",
    "join_conditions": "s.group_id = g.group_id",
    "where_conditions": "g.group_name LIKE ''Group %''",
    "group_by": "g.group_name"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_group_name   VARCHAR2(100);
  v_student_count NUMBER;

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('SELECT запрос с GROUP BY и WHERE (подсчет студентов в группах)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_group_name, v_student_count;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Group: ' || v_group_name || ', Student Count: ' || v_student_count);
  END LOOP;

  CLOSE v_cursor;
END;
/

--  SELECT запрос с MAX (выборка максимального ID студента)
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "MAX(student_id) AS max_student_id",
    "tables": "students"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_max_student_id NUMBER;

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE(' SELECT запрос с MAX (выборка максимального ID студента)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_max_student_id;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Max Student ID: ' || v_max_student_id);
  END LOOP;

  CLOSE v_cursor;
END;
/

--------------------------------------------------
--  Вложенные запросы
--------------------------------------------------

--  SELECT запрос с подзапросом (IN) (выборка студентов из определенных групп)
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "s.student_name, g.group_name",
    "tables": "students s, student_groups g",
    "join_conditions": "s.group_id = g.group_id",
    "where_conditions": "s.student_id IN (SELECT student_id FROM students WHERE group_id IS NOT NULL)"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_student_name VARCHAR2(100);
  v_group_name   VARCHAR2(100);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('SELECT запрос с подзапросом (IN) (выборка студентов из определенных групп)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_student_name, v_group_name;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Student: ' || v_student_name || ', Group: ' || v_group_name);
  END LOOP;

  CLOSE v_cursor;
END;
/

-- SELECT запрос с подзапросом (NOT IN) (выборка студентов, не принадлежащих к определенным группам)
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "s.student_name, g.group_name",
    "tables": "students s, student_groups g",
    "join_conditions": "s.group_id = g.group_id",
    "where_conditions": "s.student_id NOT IN (SELECT student_id FROM students WHERE group_id IS NULL)"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_student_name VARCHAR2(100);
  v_group_name   VARCHAR2(100);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('SELECT запрос с подзапросом (NOT IN) (выборка студентов, не принадлежащих к определенным группам)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_student_name, v_group_name;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Student: ' || v_student_name || ', Group: ' || v_group_name);
  END LOOP;

  CLOSE v_cursor;
END;
/

--------------------------------------------------
--  DML запросы (INSERT, UPDATE, DELETE)
--------------------------------------------------

--  INSERT запрос (добавление нового студента)
DECLARE
  v_json_input CLOB := '{
    "query_type": "INSERT",
    "table": "students",
    "columns": "student_id, student_name, group_id",
    "values": "1004, ''Alexey Sidorov'', 1"
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

  DBMS_OUTPUT.PUT_LINE('INSERT запрос (добавление нового студента)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
  DBMS_OUTPUT.PUT_LINE('Количество затронутых строк: ' || v_rows);
END;
/


--------------------------------------------------
--  DDL запросы
--------------------------------------------------

-- CREATE TABLE (создание таблицы student_logs)
DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "student_logs",
    "fields": "log_id NUMBER, log_message VARCHAR2(500), log_date DATE"
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

  DBMS_OUTPUT.PUT_LINE(' CREATE TABLE (создание таблицы student_logs)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/

-- Тест 4.2: DROP TABLE (удаление таблицы student_logs)
DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "DROP TABLE",
    "table": "student_logs"
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

  DBMS_OUTPUT.PUT_LINE('DROP TABLE (удаление таблицы student_logs)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/

--------------------------------------------------
--  Создание таблицы с триггером и вставка данных
--------------------------------------------------

-- Создание таблицы с триггером (создание таблицы student_audit с триггером для генерации audit_id)
DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "student_audit",
    "fields": "audit_id NUMBER, student_id NUMBER, action VARCHAR2(50), action_date DATE",
    "generate_trigger": "true",
    "trigger_name": "student_audit_trigger",
    "pk_field": "audit_id",
    "sequence_name": "student_audit_seq"
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

  DBMS_OUTPUT.PUT_LINE(' Создание таблицы с триггером (создание таблицы student_audit с триггером для генерации audit_id)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/

--  Вставка данных в таблицу с триггером
DECLARE
  v_json_input CLOB := '{
    "query_type": "INSERT",
    "table": "student_audit",
    "columns": "student_id, action, action_date",
    "values": "1001, ''INSERT'', SYSDATE"
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

  DBMS_OUTPUT.PUT_LINE('Вставка данных в таблицу с триггером (проверка работы триггера для генерации audit_id)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
  DBMS_OUTPUT.PUT_LINE('Количество затронутых строк: ' || v_rows);
END;
/
-- Проверка данных в таблице student_audit
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "audit_id, student_id, action, action_date",
    "tables": "student_audit"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_audit_id    NUMBER;
  v_student_id   NUMBER;
  v_action      VARCHAR2(50);
  v_action_date DATE;

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE(' Проверка данных в таблице student_audit (проверка корректности вставки данных и работы триггера)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_audit_id, v_student_id, v_action, v_action_date;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Audit ID: ' || v_audit_id || ', Student ID: ' || v_student_id ||
                         ', Action: ' || v_action || ', Action Date: ' || TO_CHAR(v_action_date, 'YYYY-MM-DD HH24:MI:SS'));
  END LOOP;

  CLOSE v_cursor;
END;
/

--------------------------------------------------
--  Вывод данных из всех таблиц
--------------------------------------------------

--  Вывод данных из таблицы student_groups
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "group_id, group_name",
    "tables": "student_groups"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_group_id   NUMBER;
  v_group_name VARCHAR2(100);

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE(' Вывод данных из таблицы student_groups (проверка содержимого таблицы student_groups)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_group_id, v_group_name;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Group ID: ' || v_group_id || ', Group Name: ' || v_group_name);
  END LOOP;

  CLOSE v_cursor;
END;
/

--  Вывод данных из таблицы students
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "student_id, student_name, group_id",
    "tables": "students"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_student_id        NUMBER;
  v_student_name      VARCHAR2(100);
  v_group_id          NUMBER;

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE(' Вывод данных из таблицы students (проверка содержимого таблицы students)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_student_id, v_student_name, v_group_id;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Student ID: ' || v_student_id || ', Student Name: ' || v_student_name ||
                         ', Group ID: ' || v_group_id);
  END LOOP;

  CLOSE v_cursor;
END;
/

--  Вывод данных из таблицы student_audit
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "audit_id, student_id, action, action_date",
    "tables": "student_audit"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_audit_id    NUMBER;
  v_student_id   NUMBER;
  v_action      VARCHAR2(50);
  v_action_date DATE;

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Вывод данных из таблицы student_audit (проверка содержимого таблицы student_audit)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_audit_id, v_student_id, v_action, v_action_date;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Audit ID: ' || v_audit_id || ', Student ID: ' || v_student_id ||
                         ', Action: ' || v_action || ', Action Date: ' || TO_CHAR(v_action_date, 'YYYY-MM-DD HH24:MI:SS'));
  END LOOP;

  CLOSE v_cursor;
END;
/
