CREATE OR REPLACE PROCEDURE RESTORE_STUDENTS_AT_TIME(
    p_time TIMESTAMP
) AS
BEGIN
    -- Восстановление на указанный момент времени
    FOR rec IN (
        SELECT * FROM STUDENTS_AUDIT
        WHERE ACTION_TIME <= p_time
        ORDER BY ACTION_TIME DESC
    ) LOOP
        IF rec.ACTION_TYPE = 'INSERT' THEN
            INSERT INTO STUDENTS (ID, NAME, GROUP_ID)
            VALUES (rec.STUDENT_ID, rec.STUDENT_NAME, rec.GROUP_ID);
        ELSIF rec.ACTION_TYPE = 'UPDATE' THEN
            UPDATE STUDENTS
            SET NAME = rec.NEW_VALUE,
                GROUP_ID = rec.GROUP_ID
            WHERE ID = rec.STUDENT_ID;
        ELSIF rec.ACTION_TYPE = 'DELETE' THEN
            DELETE FROM STUDENTS
            WHERE ID = rec.STUDENT_ID;
        END IF;
    END LOOP;

    COMMIT; -- Зафиксировать изменения
END RESTORE_STUDENTS_AT_TIME;
/


CREATE OR REPLACE PROCEDURE RESTORE_STUDENTS_WITH_OFFSET(
    p_time TIMESTAMP,
    p_offset INTERVAL DAY TO SECOND
) AS
    v_corrected_time TIMESTAMP; -- Новая переменная для скорректированного времени
BEGIN
    -- Корректировка времени
    v_corrected_time := p_time + p_offset;

    -- Восстановление на скорректированный момент времени
    FOR rec IN (
        SELECT * FROM STUDENTS_AUDIT
        WHERE ACTION_TIME <= v_corrected_time
        ORDER BY ACTION_TIME DESC
    ) LOOP
        IF rec.ACTION_TYPE = 'INSERT' THEN
            INSERT INTO STUDENTS (ID, NAME, GROUP_ID)
            VALUES (rec.STUDENT_ID, rec.STUDENT_NAME, rec.GROUP_ID);
        ELSIF rec.ACTION_TYPE = 'UPDATE' THEN
            UPDATE STUDENTS
            SET NAME = rec.NEW_VALUE,
                GROUP_ID = rec.GROUP_ID
            WHERE ID = rec.STUDENT_ID;
        ELSIF rec.ACTION_TYPE = 'DELETE' THEN
            DELETE FROM STUDENTS
            WHERE ID = rec.STUDENT_ID;
        END IF;
    END LOOP;

    COMMIT; -- Зафиксировать изменения
END RESTORE_STUDENTS_WITH_OFFSET;
/

DECLARE
    v_time TIMESTAMP := TO_TIMESTAMP('2025-03-03 12:00:00', 'YYYY-MM-DD HH24:MI:SS'); 
BEGIN
    RESTORE_STUDENTS_AT_TIME(v_time);
END;
/


DECLARE
    v_time TIMESTAMP := TO_TIMESTAMP('2025-03-03 12:00:00', 'YYYY-MM-DD HH24:MI:SS');
BEGIN
    RESTORE_STUDENTS_WITH_OFFSET(v_time, INTERVAL '-1' HOUR); -- Восстановление на 1 час назад
END;
/



DROP PROCEDURE RESTORE_STUDENTS_AT_TIME;
DROP PROCEDURE RESTORE_STUDENTS_WITH_OFFSET;
DROP TABLE STUDENTS_AUDIT;
DROP SEQUENCE STUDENTS_AUDIT_SEQ;
DROP TRIGGER AUDIT_INSERT_STUDENTS;
DROP TRIGGER AUDIT_UPDATE_STUDENTS;
DROP TRIGGER AUDIT_DELETE_STUDENTS;
