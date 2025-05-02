--------------------------------------------------
-- Тест на создание таблицы с FOREIGN KEY
--------------------------------------------------

DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "course_enrollments",
    "fields": "enrollment_id NUMBER PRIMARY KEY, student_id NUMBER, course_id NUMBER, CONSTRAINT fk_student FOREIGN KEY (student_id) REFERENCES students(student_id), CONSTRAINT fk_course FOREIGN KEY (course_id) REFERENCES courses(course_id)"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

BEGIN
  -- Попробуем удалить таблицу, если она существует, чтобы избежать конфликта
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE course_enrollments CASCADE CONSTRAINTS';
  EXCEPTION
    WHEN OTHERS THEN
      NULL; -- Игнорируем ошибку, если таблица не существует
  END;

  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('Тест: Создание таблицы course_enrollments с FOREIGN KEY');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/
SELECT * FROM  course_enrollments;
--------------------------------------------------
-- Тесты на JOIN и GROUP BY
--------------------------------------------------

-- Тест 1 Простой JOIN запрос (выборка студентов и их групп)
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "s.student_name, g.group_name",
    "tables": "students s JOIN student_groups g ON s.group_id = g.group_id"
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

  DBMS_OUTPUT.PUT_LINE('Тест 1.1: Простой JOIN запрос (выборка студентов и их групп)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_student_name, v_group_name;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Student: ' || v_student_name || ', Group: ' || v_group_name);
  END LOOP;

  CLOSE v_cursor;
END;
/

-- Тест 2 SELECT запрос с GROUP BY (подсчет количества студентов в каждой группе)
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "g.group_name, COUNT(s.student_id) AS student_count",
    "tables": "students s JOIN student_groups g ON s.group_id = g.group_id",
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

  DBMS_OUTPUT.PUT_LINE(' SELECT запрос с GROUP BY (подсчет количества студентов в каждой группе)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_group_name, v_student_count;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Group: ' || v_group_name || ', Student Count: ' || v_student_count);
  END LOOP;

  CLOSE v_cursor;
END;
/
SELECT * FROM students;
/
--------------------------------------------------
-- Тест на UNION запрос (выборка студентов )
--------------------------------------------------
SELECT * FROM courses;



DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "name FROM (
      SELECT student_name AS name FROM students
      UNION
      SELECT course_name AS name FROM courses
    )"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);
  v_name VARCHAR2(100);

BEGIN
  -- Открытие курсора
  OPEN v_cursor FOR 
    SELECT name FROM (
      SELECT student_name AS name FROM students
      UNION
      SELECT course_name AS name FROM courses
    );

  DBMS_OUTPUT.PUT_LINE('Тест: UNION запрос (выборка студентов )');

  -- Проверка на успешное открытие курсора
  LOOP
    FETCH v_cursor INTO v_name;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Name: ' || v_name);
  END LOOP;

  CLOSE v_cursor;

  DBMS_OUTPUT.PUT_LINE('Запрос выполнен успешно.');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
    IF v_cursor%ISOPEN THEN
      CLOSE v_cursor;
    END IF;
END;
/


--------------------------------------------------
--  автоинкрементом
--------------------------------------------------

DECLARE
    v_cursor SYS_REFCURSOR;
    v_id NUMBER;
    v_name VARCHAR2(100);
BEGIN
    OPEN v_cursor FOR SELECT student_id, student_name FROM students;

    DBMS_OUTPUT.PUT_LINE('Тест: Автоинкремент');
    LOOP
        FETCH v_cursor INTO v_id, v_name;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ', Name: ' || v_name);
    END LOOP;

    CLOSE v_cursor;
END;
/

-------ТЕСТЫ НА ОШИБКИ
--Проверка обработки UPDATE запроса с некорректными данными.
DECLARE
  v_json_input CLOB := '{
    "query_type": "UPDATE",
    "table": "students",
    "set_clause": "student_name = ''Nonexistent Name''",
    "where_conditions": "student_id = 9999" -- Не существующий ID
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

  DBMS_OUTPUT.PUT_LINE('UPDATE запрос с некорректными данными');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/

-- Проверка обработки попытки создания таблицы с уже существующим именем.
DECLARE
  v_json_input CLOB := '{
    "query_type": "DDL",
    "ddl_command": "CREATE TABLE",
    "table": "student_groups",
    "fields": "group_id NUMBER PRIMARY KEY, group_name VARCHAR2(100) NOT NULL"
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

  DBMS_OUTPUT.PUT_LINE('Тест на создание таблицы с существующим именем');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/


-- Проверка выполнения DELETE запроса без условий (должен удалить все записи).
DECLARE
  v_json_input CLOB := '{
    "query_type": "DELETE",
    "table": "students"
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

  DBMS_OUTPUT.PUT_LINE('DELETE запрос без условий');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);
END;
/

SELECT *FROM   students;
/





-- Простой SELECT запрос с JOIN
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "s.student_name, g.group_name",
    "tables": "students s INNER JOIN student_groups g ON s.group_id = g.group_id"
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

  DBMS_OUTPUT.PUT_LINE('Простой SELECT запрос (выборка студентов и их групп)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_student_name, v_group_name;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Student: ' || v_student_name || ', Group: ' || v_group_name);
  END LOOP;

  CLOSE v_cursor;
END;
/




-- SELECT запрос с GROUP BY
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "g.group_name, COUNT(s.student_id) AS student_count",
    "tables": "students s INNER JOIN student_groups g ON s.group_id = g.group_id",
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

