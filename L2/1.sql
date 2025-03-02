CREATE TABLE GROUPS (
    ID NUMBER PRIMARY KEY,                  
    NAME VARCHAR2(100) NOT NULL,          
    C_VAL NUMBER DEFAULT 0                 
);

CREATE TABLE STUDENTS (
    ID NUMBER PRIMARY KEY,                 
    NAME VARCHAR2(100) NOT NULL,          
    GROUP_ID NUMBER,                       
    CONSTRAINT FK_GROUP FOREIGN KEY (GROUP_ID) REFERENCES GROUPS(ID) -- Внешний ключ
);