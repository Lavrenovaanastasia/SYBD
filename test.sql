-- Вставка тестовых данных (без указания ID)
BEGIN
    -- Добавляем авторов в таблицу Students (ID генерируются автоматически)
    INSERT INTO Students (full_name, birth_date) VALUES ('Иван Иванов', TO_DATE('2005-09-09', 'YYYY-MM-DD'));
    INSERT INTO Students (full_name, birth_date) VALUES ('Мария Сидорова', TO_DATE('2006-11-11', 'YYYY-MM-DD'));
    COMMIT; -- Подтверждаем изменения в базе данных

    -- Добавляем группы в таблицу Groups (используем подзапросы для получения student_id)
    INSERT INTO Groups (student_id, group_name, specialization, start_date)
    VALUES (
        (SELECT student_id FROM Students WHERE full_name = 'Иван Иванов'),
        'Группа 1 ',
        'Информатика ',
        TO_DATE('2022-09-01', 'YYYY-MM-DD')
    );

    INSERT INTO Groups (student_id, group_name, specialization, start_date)
    VALUES (
        (SELECT student_id FROM Students WHERE full_name = 'Мария Сидорова'),
        'Группа 2',
        'Высшая Математика',
        TO_DATE('2023-08-01', 'YYYY-MM-DD')
    );
    COMMIT; 

    INSERT INTO Documents (student_id, copy_number, condition)
    VALUES (
        (SELECT student_id FROM Students WHERE full_name = 'Иван Иванов'),
        '25350071',
        'Готово'
    );

    INSERT INTO Documents (student_id, copy_number, condition)
    VALUES (
        (SELECT student_id FROM Students WHERE full_name = 'Мария Сидорова'),
        '25350072',
        'В процессе'
    );
    COMMIT; 
END;
/



-- Обновление данных (используем подзапросы вместо явных ID)
BEGIN
    
    UPDATE Students
    SET full_name = 'Иван иванович Иванов'
    WHERE full_name = 'Иван Иванов';
    COMMIT; 
   
    UPDATE Groups
    SET group_name = 'Группа 3'
    WHERE Groups.SPECIALIZATION = 'Высшая Математика';
    COMMIT; 

    UPDATE Documents
    SET condition = 'Завершение'
    WHERE copy_number = '25350072';
    COMMIT; 
END;
/

-- последняя
BEGIN
    -- Удаляем экземпляр студента по номеру копии
    DELETE FROM Documents
    WHERE copy_number = '25350071';
    COMMIT; 
END;
/

-- Восстановление данных на указанное время
BEGIN
    StudentTimeTravel_PKG.RESTORE(TIMESTAMP '2025-05-04 21:47:00.203000');
END;
/

-- Восстановление данных за указанный интервал времени (в миллисекундах)
BEGIN
    StudentTimeTravel_PKG.RESTORE(120000); --  = 3 минуты(+2 нуля)
END;
/


SELECT * FROM Groups;
SELECT * FROM Students;
SELECT * FROM Documents;
SELECT * FROM Audit_Log;
SELECT * FROM Reports_Logs;


-- с указанного времени
BEGIN
    StudentReport_PKG.Create_Report(TO_TIMESTAMP('2025-05-05 12:00:00.163000', 'YYYY-MM-DD HH24:MI:SS.FF'));
END;
/

-- с момента последнего отчета
BEGIN
    StudentReport_PKG.Create_Report;
END;
/


SELECT report_content FROM Reports_Logs ORDER BY report_date DESC;
EXEC Generate_Otchet_HTML;