CREATE OR REPLACE DIRECTORY REPORT_DIR AS 'D:/REPORT_DIR';


GRANT READ, WRITE ON DIRECTORY REPORT_DIR TO TEST;

GRANT ALL PRIVILEGES TO TEST;

SELECT 
  report_content
  FROM (SELECT report_id, report_content  FROM Reports_Logs   ORDER BY report_date DESC)
  WHERE report_id = (SELECT COUNT(report_id)FROM Reports_Logs) ;

CREATE OR REPLACE PROCEDURE Generate_Otchet_HTML IS
  v_content Reports_Logs.report_content%TYPE;
  v_file    UTL_FILE.FILE_TYPE;
BEGIN
  -- Получаем первую запись с id = 1
  SELECT 
      report_content
  INTO v_content
  FROM (SELECT report_id, report_content  FROM Reports_Logs   ORDER BY report_date DESC)
  WHERE report_id = (SELECT COUNT(report_id)FROM Reports_Logs) ;

  -- Открываем файл для перезаписи
  v_file := UTL_FILE.FOPEN('REPORT_DIR', 'otchet.html', 'w');

  -- Записываем содержимое в файл
  UTL_FILE.PUT_LINE(v_file, v_content);

  -- Закрываем файл
  UTL_FILE.FCLOSE(v_file);

  DBMS_OUTPUT.PUT_LINE('Файл otchet.html успешно обновлен.');

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка: Запись с id = 1 не найдена.');
  WHEN OTHERS THEN
    IF UTL_FILE.IS_OPEN(v_file) THEN
      UTL_FILE.FCLOSE(v_file);
    END IF;
    DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
    RAISE;
END Generate_Otchet_HTML;
/


EXEC Generate_Otchet_HTML;