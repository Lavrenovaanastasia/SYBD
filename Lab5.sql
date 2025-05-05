CREATE OR REPLACE PACKAGE StudentReport_PKG IS
    PROCEDURE Create_Report(p_start_time IN TIMESTAMP);
    PROCEDURE Create_Report;
END StudentReport_PKG;
/

CREATE OR REPLACE PACKAGE BODY StudentReport_PKG IS
    last_report_time TIMESTAMP := TO_TIMESTAMP('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

    PROCEDURE Create_Report(p_start_time IN TIMESTAMP) IS
        v_ins_students    NUMBER;
        v_upd_students    NUMBER;
        v_del_students    NUMBER;
        v_ins_groups      NUMBER;
        v_upd_groups      NUMBER;
        v_del_groups      NUMBER;
        v_ins_copies      NUMBER;
        v_upd_copies      NUMBER;
        v_del_copies      NUMBER;
        v_report          VARCHAR2(4000);
    BEGIN
        -- Подсчет изменений для Students
        SELECT COUNT(*) INTO v_ins_students FROM Audit_Log WHERE table_name = 'STUDENTS' AND operation_type = 'I' AND change_time >= p_start_time;
        SELECT COUNT(*) INTO v_upd_students FROM Audit_Log WHERE table_name = 'STUDENTS' AND operation_type = 'U' AND change_time >= p_start_time;
        SELECT COUNT(*) INTO v_del_students FROM Audit_Log WHERE table_name = 'STUDENTS' AND operation_type = 'D' AND change_time >= p_start_time;

        -- Подсчет изменений для Groups
        SELECT COUNT(*) INTO v_ins_groups FROM Audit_Log WHERE table_name = 'GROUPS' AND operation_type = 'I' AND change_time >= p_start_time;
        SELECT COUNT(*) INTO v_upd_groups FROM Audit_Log WHERE table_name = 'GROUPS' AND operation_type = 'U' AND change_time >= p_start_time;
        SELECT COUNT(*) INTO v_del_groups FROM Audit_Log WHERE table_name = 'GROUPS' AND operation_type = 'D' AND change_time >= p_start_time;

        -- Подсчет изменений для Documents
        SELECT COUNT(*) INTO v_ins_copies FROM Audit_Log WHERE table_name = 'Documents' AND operation_type = 'I' AND change_time >= p_start_time;
        SELECT COUNT(*) INTO v_upd_copies FROM Audit_Log WHERE table_name = 'Documents' AND operation_type = 'U' AND change_time >= p_start_time;
        SELECT COUNT(*) INTO v_del_copies FROM Audit_Log WHERE table_name = 'Documents' AND operation_type = 'D' AND change_time >= p_start_time;

        -- Формирование отчета
      -- Формирование отчета
    v_report := '<html><head><title>Report on changes</title></head><body>';
    v_report := v_report || '<h1>Report on changes from ' || TO_CHAR(p_start_time, 'YYYY-MM-DD HH24:MI:SS') || '</h1>';
    v_report := v_report || '<table border="1" cellspacing="0" cellpadding="4">';
    v_report := v_report || '<tr><th>Table</th><th>INSERT</th><th>UPDATE</th><th>DELETE</th></tr>';
    v_report := v_report || '<tr><td>STUDENTS</td><td>' || v_ins_students || '</td><td>' || v_upd_students || '</td><td>' || v_del_students || '</td></tr>';
    v_report := v_report || '<tr><td>GROUPS</td><td>' || v_ins_groups || '</td><td>' || v_upd_groups || '</td><td>' || v_del_groups || '</td></tr>';
    v_report := v_report || '<tr><td>Documents</td><td>' || v_ins_copies || '</td><td>' || v_upd_copies || '</td><td>' || v_del_copies || '</td></tr>';
    v_report := v_report || '</table><br></body></html>';

        -- Сохранение отчета
        INSERT INTO Reports_Logs (report_date, report_content) VALUES (SYSTIMESTAMP, v_report);
        COMMIT;

        DBMS_OUTPUT.PUT_LINE(v_report);
        last_report_time := SYSTIMESTAMP;
    END Create_Report;

    PROCEDURE Create_Report IS
    BEGIN
        Create_Report(last_report_time);
    END Create_Report;
END StudentReport_PKG;
/
------------------------------------------------------
CREATE OR REPLACE PACKAGE StudentTimeTravel_PKG AS
    -- Процедура для восстановления данных на основе указанного времени
    PROCEDURE Restore(p_target_time IN TIMESTAMP);
    -- Процедура для восстановления данных на основе указанного интервала времени в миллисекундах
    PROCEDURE Restore(p_interval IN NUMBER);
END StudentTimeTravel_PKG;
/

CREATE OR REPLACE PACKAGE BODY StudentTimeTravel_PKG IS
    -- Процедура для восстановления данных на основе указанного времени
    PROCEDURE Restore(p_target_time IN TIMESTAMP) IS
    BEGIN
        -- 1. Восстановление DELETE операций (в обратном порядке)
        -- Обрабатываем операции удаления (DELETE) для таблицы Documents
        FOR rec IN (
            SELECT * FROM Audit_Log
            WHERE table_name = 'Documents' -- Указываем таблицу
            AND operation_type = 'D' -- Указываем тип операции DELETE
            AND change_time > p_target_time -- Условие по времени
            ORDER BY change_time DESC -- Сортируем по времени изменений (последние изменения первыми)
        ) LOOP
            -- Восстанавливаем удаленные записи в таблице Documents
            INSERT INTO Documents (copy_id, student_id, copy_number, condition)
            VALUES (
                TO_NUMBER(rec.pk_value), -- Получаем первичный ключ
                TO_NUMBER(REGEXP_SUBSTR(rec.changed_data, 'student_id=([^,]+)', 1, 1, NULL, 1)), -- Извлекаем student_id
                REGEXP_SUBSTR(rec.changed_data, 'copy_number=([^,]+)', 1, 1, NULL, 1), -- Извлекаем copy_number
                REGEXP_SUBSTR(rec.changed_data, 'condition=([^,]+)', 1, 1, NULL, 1) -- Извлекаем состояние экземпляра
            );
        END LOOP;

        -- Обрабатываем операции удаления (DELETE) для таблицы Groups
        FOR rec IN (
            SELECT * FROM Audit_Log
            WHERE table_name = 'GROUPS' -- Указываем таблицу
            AND operation_type = 'D' -- Указываем тип операции DELETE
            AND change_time > p_target_time -- Условие по времени
            ORDER BY change_time DESC -- Сортируем по времени изменений (последние изменения первыми)
        ) LOOP
            -- Восстанавливаем удаленные группы
            INSERT INTO Groups (group_id, student_id, group_name, specialization, start_date)
            VALUES (
                TO_NUMBER(rec.pk_value), -- Получаем первичный ключ
                TO_NUMBER(REGEXP_SUBSTR(rec.changed_data, 'student_id=([^,]+)', 1, 1, NULL, 1)), -- Извлекаем student_id
                REGEXP_SUBSTR(rec.changed_data, 'group_name=([^,]+)', 1, 1, NULL, 1), -- Извлекаем название группы
                REGEXP_SUBSTR(rec.changed_data, 'specialization=([^,]+)', 1, 1, NULL, 1), -- Извлекаем специализацию
                TO_DATE(REGEXP_SUBSTR(rec.changed_data, 'start_date=([^,]+)', 1, 1, NULL, 1), 'YYYY-MM-DD') -- Извлекаем дату начала
            );
        END LOOP;

        -- Обрабатываем операции удаления (DELETE) для таблицы Students
        FOR rec IN (
            SELECT * FROM Audit_Log
            WHERE table_name = 'STUDENTS' -- Указываем таблицу
            AND operation_type = 'D' -- Указываем тип операции DELETE
            AND change_time > p_target_time -- Условие по времени
            ORDER BY change_time DESC -- Сортируем по времени изменений (последние изменения первыми)
        ) LOOP
            -- Восстанавливаем удаленных студентов
            INSERT INTO Students (student_id, full_name, birth_date)
            VALUES (
                TO_NUMBER(rec.pk_value), -- Получаем первичный ключ
                REGEXP_SUBSTR(rec.changed_data, 'full_name=([^,]+)', 1, 1, NULL, 1), -- Извлекаем полное имя
                TO_DATE(REGEXP_SUBSTR(rec.changed_data, 'birth_date=([^,]+)', 1, 1, NULL, 1), 'YYYY-MM-DD') -- Извлекаем дату рождения
            );
        END LOOP;

        -- 2. Восстановление UPDATE операций
        -- Обрабатываем операции обновления (UPDATE) для таблицы Students
        FOR rec IN (
            SELECT * FROM Audit_Log
            WHERE table_name = 'STUDENTS' -- Указываем таблицу
            AND operation_type = 'U' -- Указываем тип операции UPDATE
            AND change_time > p_target_time -- Условие по времени
            ORDER BY change_time DESC -- Сортируем по времени изменений (последние изменения первыми)
        ) LOOP
            -- Обновляем существующие записи в таблице Students
            UPDATE Students
            SET full_name = REGEXP_SUBSTR(rec.changed_data, 'full_name=([^,]+)', 1, 1, NULL, 1), -- Обновляем полное имя
                birth_date = TO_DATE(REGEXP_SUBSTR(rec.changed_data, 'birth_date=([^,]+)', 1, 1, NULL, 1), 'YYYY-MM-DD') -- Обновляем дату рождения
            WHERE student_id = TO_NUMBER(rec.pk_value); -- Условие для обновления по первичному ключу
        END LOOP;

        -- Обрабатываем операции обновления (UPDATE) для таблицы Groups
        FOR rec IN (
            SELECT * FROM Audit_Log
            WHERE table_name = 'GROUPS' -- Указываем таблицу
            AND operation_type = 'U' -- Указываем тип операции UPDATE
            AND change_time > p_target_time -- Условие по времени
            ORDER BY change_time DESC -- Сортируем по времени изменений (последние изменения первыми)
        ) LOOP
            -- Обновляем существующие записи в таблице Groups
            UPDATE Groups
            SET student_id = TO_NUMBER(REGEXP_SUBSTR(rec.changed_data, 'student_id=([^,]+)', 1, 1, NULL, 1)), -- Обновляем student_id
                group_name = REGEXP_SUBSTR(rec.changed_data, 'group_name=([^,]+)', 1, 1, NULL, 1), -- Обновляем название группы
                specialization = REGEXP_SUBSTR(rec.changed_data, 'specialization=([^,]+)', 1, 1, NULL, 1), -- Обновляем специализацию
                start_date = TO_DATE(REGEXP_SUBSTR(rec.changed_data, 'start_date=([^,]+)', 1, 1, NULL, 1), 'YYYY-MM-DD') -- Обновляем дату начала
            WHERE group_id = TO_NUMBER(rec.pk_value); -- Условие для обновления по первичному ключу
        END LOOP;

        -- Обрабатываем операции обновления (UPDATE) для таблицы Documents
        FOR rec IN (
            SELECT * FROM Audit_Log
            WHERE table_name = 'Documents' -- Указываем таблицу
            AND operation_type = 'U' -- Указываем тип операции UPDATE
            AND change_time > p_target_time -- Условие по времени
            ORDER BY change_time DESC -- Сортируем по времени изменений (последние изменения первыми)
        ) LOOP
            -- Обновляем существующие записи в таблице Documents
            UPDATE Documents
            SET student_id = TO_NUMBER(REGEXP_SUBSTR(rec.changed_data, 'student_id=([^,]+)', 1, 1, NULL, 1)), -- Обновляем student_id
                copy_number = REGEXP_SUBSTR(rec.changed_data, 'copy_number=([^,]+)', 1, 1, NULL, 1), -- Обновляем номер экземпляра
                condition = REGEXP_SUBSTR(rec.changed_data, 'condition=([^,]+)', 1, 1, NULL, 1) -- Обновляем состояние экземпляра
            WHERE copy_id = TO_NUMBER(rec.pk_value); -- Условие для обновления по первичному ключу
        END LOOP;

        -- 3. Восстановление INSERT операций (в обратном порядке)
        -- Обрабатываем операции вставки (INSERT) для таблицы Documents
        FOR rec IN (
            SELECT * FROM Audit_Log
            WHERE table_name = 'Documents' -- Указываем таблицу
            AND operation_type = 'I' -- Указываем тип операции INSERT
            AND change_time > p_target_time -- Условие по времени
            ORDER BY change_time DESC -- Сортируем по времени изменений (последние изменения первыми)
        ) LOOP
            -- Удаляем вставленные записи в таблице Documents
            DELETE FROM Documents WHERE copy_id = TO_NUMBER(rec.pk_value); -- Условие для удаления по первичному ключу
        END LOOP;

        -- Обрабатываем операции вставки (INSERT) для таблицы Groups
        FOR rec IN (
            SELECT * FROM Audit_Log
            WHERE table_name = 'GROUPS' -- Указываем таблицу
            AND operation_type = 'I' -- Указываем тип операции INSERT
            AND change_time > p_target_time -- Условие по времени
            ORDER BY change_time DESC -- Сортируем по времени изменений (последние изменения первыми)
        ) LOOP
            -- Удаляем вставленные группы
            DELETE FROM Groups WHERE group_id = TO_NUMBER(rec.pk_value); -- Условие для удаления по первичному ключу
        END LOOP;

        -- Обрабатываем операции вставки (INSERT) для таблицы Students
        FOR rec IN (
            SELECT * FROM Audit_Log
            WHERE table_name = 'STUDENTS' -- Указываем таблицу
            AND operation_type = 'I' -- Указываем тип операции INSERT
            AND change_time > p_target_time -- Условие по времени
            ORDER BY change_time DESC -- Сортируем по времени изменений (последние изменения первыми)
        ) LOOP
            -- Удаляем вставленных студентов
            DELETE FROM Students WHERE student_id = TO_NUMBER(rec.pk_value); -- Условие для удаления по первичному ключу
        END LOOP;

        -- Удаление записей из журнала изменений после восстановления
        DELETE FROM Audit_Log WHERE change_time > p_target_time; -- Удаляем записи в журнале, которые были созданы после указанного времени
        COMMIT; -- Подтверждаем изменения
    END Restore;

    -- Процедура для восстановления данных на основе указанного интервала времени
    PROCEDURE Restore(p_interval IN NUMBER) IS
        v_target_time TIMESTAMP; -- Объявляем переменную для хранения целевого времени
    BEGIN
        -- Вычисляем целевое время, вычитая интервал из текущего времени
        v_target_time := SYSTIMESTAMP - (p_interval / (24 * 60 * 60 * 1000)); -- Преобразуем миллисекунды в TIMESTAMP
        Restore(v_target_time); -- Вызываем процедуру Restore с рассчитанным временем
    END Restore;
END StudentTimeTravel_PKG;
/
---------------------------------------------------------------------
-- Триггер для таблицы Students
CREATE OR REPLACE TRIGGER trg_students_audit
BEFORE INSERT OR UPDATE OR DELETE ON Students
FOR EACH ROW
BEGIN
    -- Проверяем, происходит ли вставка новой записи
    IF INSERTING THEN
        INSERT INTO Audit_Log (table_name, pk_value, changed_data, operation_type)
        VALUES (
            'STUDENTS', -- Имя таблицы
            TO_CHAR(:NEW.student_id), -- Новый уникальный идентификатор студента
            'full_name=' || :NEW.full_name || ', birth_date=' || TO_CHAR(:NEW.birth_date, 'YYYY-MM-DD'), -- Изменённые данные
            'I' -- Тип операции: вставка
        );
    -- Проверяем, происходит ли обновление существующей записи
    ELSIF UPDATING THEN
        INSERT INTO Audit_Log (table_name, pk_value, changed_data, operation_type)
        VALUES (
            'STUDENTS', -- Имя таблицы
            TO_CHAR(:OLD.student_id), -- Старый уникальный идентификатор студента
            'full_name=' || :OLD.full_name || ', birth_date=' || TO_CHAR(:OLD.birth_date, 'YYYY-MM-DD'), -- Изменённые данные
            'U' -- Тип операции: обновление
        );
    -- Проверяем, происходит ли удаление записи
    ELSIF DELETING THEN
        INSERT INTO Audit_Log (table_name, pk_value, changed_data, operation_type)
        VALUES (
            'STUDENTS', -- Имя таблицы
            TO_CHAR(:OLD.student_id), -- Уникальный идентификатор удаляемого студента
            'full_name=' || :OLD.full_name || ', birth_date=' || TO_CHAR(:OLD.birth_date, 'YYYY-MM-DD'), -- Изменённые данные
            'D' -- Тип операции: удаление
        );
    END IF;
END;
/

-- Триггер для таблицы Groups
CREATE OR REPLACE TRIGGER trg_groups_audit
BEFORE INSERT OR UPDATE OR DELETE ON Groups
FOR EACH ROW
BEGIN
    -- Проверяем, происходит ли вставка новой группы
    IF INSERTING THEN
        INSERT INTO Audit_Log (table_name, pk_value, changed_data, operation_type)
        VALUES (
            'GROUPS', -- Имя таблицы
            TO_CHAR(:NEW.group_id), -- Новый уникальный идентификатор группы
            'student_id=' || :NEW.student_id || ', group_name=' || :NEW.group_name || ', specialization=' || :NEW.specialization ||
                ', start_date=' || TO_CHAR(:NEW.start_date, 'YYYY-MM-DD'), -- Изменённые данные
            'I' -- Тип операции: вставка
        );
    -- Проверяем, происходит ли обновление группы
    ELSIF UPDATING THEN
        INSERT INTO Audit_Log (table_name, pk_value, changed_data, operation_type)
        VALUES (
            'GROUPS', -- Имя таблицы
            TO_CHAR(:OLD.group_id), -- Старый уникальный идентификатор группы
            'student_id=' || :OLD.student_id || ', group_name=' || :OLD.group_name || ', specialization=' || :OLD.specialization ||
                ', start_date=' || TO_CHAR(:OLD.start_date, 'YYYY-MM-DD'), -- Изменённые данные
            'U' -- Тип операции: обновление
        );
    -- Проверяем, происходит ли удаление группы
    ELSIF DELETING THEN
        INSERT INTO Audit_Log (table_name, pk_value, changed_data, operation_type)
        VALUES (
            'GROUPS', -- Имя таблицы
            TO_CHAR(:OLD.group_id), -- Уникальный идентификатор удаляемой группы
            'student_id=' || :OLD.student_id || ', group_name=' || :OLD.group_name || ', specialization=' || :OLD.specialization ||
                ', start_date=' || TO_CHAR(:OLD.start_date, 'YYYY-MM-DD'), -- Изменённые данные
            'D' -- Тип операции: удаление
        );
    END IF;
END;
/

-- Триггер для таблицы Documents
CREATE OR REPLACE TRIGGER trg_Documents_audit
BEFORE INSERT OR UPDATE OR DELETE ON Documents
FOR EACH ROW
BEGIN
    -- Проверяем, происходит ли вставка нового экземпляра студента
    IF INSERTING THEN
        INSERT INTO Audit_Log (table_name, pk_value, changed_data, operation_type)
        VALUES (
            'Documents', -- Имя таблицы
            TO_CHAR(:NEW.copy_id), -- Новый уникальный идентификатор экземпляра
            'student_id=' || :NEW.student_id || ', copy_number=' || :NEW.copy_number || ', condition=' || :NEW.condition, -- Изменённые данные
            'I' -- Тип операции: вставка
        );
    -- Проверяем, происходит ли обновление экземпляра
    ELSIF UPDATING THEN
        INSERT INTO Audit_Log (table_name, pk_value, changed_data, operation_type)
        VALUES (
            'Documents', -- Имя таблицы
            TO_CHAR(:OLD.copy_id), -- Старый уникальный идентификатор экземпляра
            'student_id=' || :OLD.student_id || ', copy_number=' || :OLD.copy_number || ', condition=' || :OLD.condition, -- Изменённые данные
            'U' -- Тип операции: обновление
        );
    -- Проверяем, происходит ли удаление экземпляра
    ELSIF DELETING THEN
        INSERT INTO Audit_Log (table_name, pk_value, changed_data, operation_type)
        VALUES (
            'Documents', -- Имя таблицы
            TO_CHAR(:OLD.copy_id), -- Уникальный идентификатор удаляемого экземпляра
            'student_id=' || :OLD.student_id || ', copy_number=' || :OLD.copy_number || ', condition=' || :OLD.condition, -- Изменённые данные
            'D' -- Тип операции: удаление
        );
    END IF;
END;
/