-- SELECT запрос с GROUP BY и WHERE (подсчет студентов в группах с использованием BETWEEN)
DECLARE
  v_json_input CLOB := '{
    "query_type": "SELECT",
    "select_columns": "g.group_name, COUNT(s.student_id) AS student_count",
    "tables": "students s, student_groups g",
    "join_conditions": "s.group_id = g.group_id",
    "where_conditions": "g.group_id BETWEEN 1 AND 3",
    "group_by": "g.group_name"
  }';

  v_cursor  SYS_REFCURSOR;
  v_rows    NUMBER;
  v_message VARCHAR2(4000);

  v_group_name    VARCHAR2(100);
  v_student_count NUMBER;

BEGIN
  dynamic_sql_executor(
    p_json    => v_json_input,
    p_cursor  => v_cursor,
    p_rows    => v_rows,
    p_message => v_message
  );

  DBMS_OUTPUT.PUT_LINE('SELECT запрос с GROUP BY и WHERE (подсчет студентов в группах с использованием BETWEEN)');
  DBMS_OUTPUT.PUT_LINE('Результат операции: ' || v_message);

  LOOP
    FETCH v_cursor INTO v_group_name, v_student_count;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Group: ' || v_group_name || ', Student Count: ' || v_student_count);
  END LOOP;

  CLOSE v_cursor;
END;
