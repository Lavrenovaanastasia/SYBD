-- Удаление таблиц, если уже существуют
BEGIN EXECUTE IMMEDIATE 'DROP TABLE test_1 CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE test_2 CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Создание таблиц с новыми именами и полями
CREATE TABLE test_1 (
  id NUMBER PRIMARY KEY,
  value_1 VARCHAR2(100) NOT NULL
)
/

CREATE TABLE test_2 (
  id NUMBER PRIMARY KEY,
  value_2 VARCHAR2(100) NOT NULL
)
/

-- Добавление тестовых данных
INSERT INTO test_1 VALUES (1, 'A');
INSERT INTO test_1 VALUES (2, 'B');
INSERT INTO test_2 VALUES (1, 'С');
INSERT INTO test_2 VALUES (2, 'D');
COMMIT;
/

-- Выполнение UNION-запроса с JSON
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "name FROM (
      SELECT value_1 AS name FROM test_1
      UNION
      SELECT value_2 AS name FROM test_2
    )"
  }';

  v_cursor  SYS_REFCURSOR;
  v_name    VARCHAR2(100);

BEGIN
  -- Открытие курсора
  OPEN v_cursor FOR 
    SELECT name FROM (
      SELECT value_1 AS name FROM test_1
      UNION
      SELECT value_2 AS name FROM test_2
    );

  DBMS_OUTPUT.PUT_LINE('Тест: UNION запрос (test_1 + test_2):');

  -- Получение данных
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
