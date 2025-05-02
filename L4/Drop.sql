-- Процедура для безопасного удаления триггеров
CREATE OR REPLACE PROCEDURE drop_trigger_if_exists(trigger_name IN VARCHAR2) IS
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER ' || trigger_name;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -4080 THEN -- Игнорируем ошибку "trigger does not exist"
      RAISE;
    END IF;
END;
/

-- Процедура для безопасного удаления последовательностей
CREATE OR REPLACE PROCEDURE drop_sequence_if_exists(sequence_name IN VARCHAR2) IS
BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE ' || sequence_name;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -2289 THEN -- Игнорируем ошибку "sequence does not exist"
      RAISE;
    END IF;
END;
/

-- Процедура для удаления таблиц
CREATE OR REPLACE PROCEDURE drop_table_if_exists(table_name IN VARCHAR2) IS
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ' || table_name || ' CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN -- Игнорируем ошибку "table does not exist"
      RAISE;
    END IF;
END;
/

BEGIN

  -- Удаление таблиц
  drop_table_if_exists('students');
  drop_table_if_exists('student_groups');
  DBMS_OUTPUT.PUT_LINE('Все объекты успешно удалены.');
END;
/






