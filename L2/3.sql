CREATE OR REPLACE TRIGGER cascade_delete_students
BEFORE DELETE ON GROUPS
FOR EACH ROW
BEGIN
    DELETE FROM STUDENTS
    WHERE GROUP_ID = :old.id;
END cascade_delete_students;



DELETE FROM GROUPS WHERE ID = 1; 


SELECT * FROM STUDENTS;
SELECT * FROM GROUPS;

DROP TRIGGER cascade_delete_students;
