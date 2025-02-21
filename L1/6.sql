CREATE OR REPLACE FUNCTION TASK6(
    p_monthl NUMBER,
    p_percentag NUMBER
) RETURN NUMBER AS
    v_total_reward NUMBER;
BEGIN
    IF p_monthl < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Ошибка: Месячная зарплата не может быть отрицательной.');
    ELSIF p_percentag < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Ошибка: Процент годовых премиальных не может быть отрицательным.');
    ELSIF p_percentag > 100 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Ошибка: Процент годовых премиальных не может быть больше 100.');
    END IF;

    v_total_reward := (1 + p_percentag / 100) * 12 * p_monthl;

    RETURN v_total_reward;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка выполнения: ' || SQLERRM);
        RETURN NULL; 
END TASK6;



DECLARE
    v_result NUMBER;  
BEGIN
  
    SELECT TASK6(1000, 10) INTO v_result FROM dual;
    DBMS_OUTPUT.PUT_LINE('Total Compensation (1000, 10): ' || v_result);

    SELECT TASK6(1000, 150) INTO v_result FROM dual;  
    DBMS_OUTPUT.PUT_LINE('Total Compensation (1000, 150): ' || v_result);

    SELECT TASK6(-1000, 10) INTO v_result FROM dual; 
    DBMS_OUTPUT.PUT_LINE('Total Compensation (-1000, 10): ' || v_result);

    SELECT TASK6(1000, -10) INTO v_result FROM dual;
    DBMS_OUTPUT.PUT_LINE('Total Compensation (1000, -10): ' || v_result);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
END;
