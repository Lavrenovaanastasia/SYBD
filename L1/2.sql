BEGIN
    FOR i IN 1..10000 LOOP
        INSERT INTO MyTable (id, val) 
        VALUES (i, TRUNC(DBMS_RANDOM.VALUE(1, 1000000)));
    END LOOP;
    COMMIT;
END;