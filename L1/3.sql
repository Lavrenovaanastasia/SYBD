CREATE OR REPLACE FUNCTION Chetnost
RETURN VARCHAR2
IS
    chet NUMBER := 0;   
    nechet NUMBER := 0; 
BEGIN
 
    SELECT COUNT(*)
    INTO chet
    FROM MyTable
    WHERE MOD(val, 2) = 0 AND val IS NOT NULL;
   
    SELECT COUNT(*)
    INTO nechet
    FROM MyTable
    WHERE MOD(val, 2) = 1 AND val IS NOT NULL;

    RETURN 'Result: ' || CASE 
               WHEN chet > nechet THEN 'TRUE'
               WHEN nechet > chet THEN 'FALSE'
               ELSE 'EQUAL'
           END || ', Even Count: ' || chet || ', Odd Count: ' || nechet;

END Chetnost;

SELECT val, MOD(val, 2) AS mod_value 
FROM MyTable 
WHERE val IS NOT NULL;



SELECT Chetnost() FROM dual;