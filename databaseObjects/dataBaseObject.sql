
CREATE TABLE WEB_TBL_TESTING_FACADE
(
    CODIGO_CAL  NUMBER,
    DESCRIPCION VARCHAR2(100),
    NOM_PACKAGE VARCHAR2(30),
    NOM_PROC_FUNC VARCHAR2(30)
)
;

CREATE TABLE WEB_TBL_TESTING_FACADE_DET
(
    CODIGO_GEN      NUMBER,
    CODIGO_CAL      NUMBER,
    CODIGO_ESC_CAL  NUMBER,
	DATE_GEN		DATE,
    DESCRIPCION VARCHAR2(1000),
    CLOB_XML_INPUT CLOB,
    XML_INPUT       XMLTYPE,
    NUM_TOKEN_GEN   NUMBER,
    XML_OUT         XMLTYPE
)
;
CREATE UNIQUE INDEX WEB_TBL_TESTING_FACADE_DET_I1 ON WEB_TBL_TESTING_FACADE_DET (CODIGO_CAL, CODIGO_ESC_CAL, CODIGO_GEN);

CREATE SEQUENCE  WEB_SEQ_ORDER_TESTING  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1;


CREATE TABLE WEB_TBL_TESTING_LOAD_INITIAL
(
    CODIGO_CAL      NUMBER,
    CODIGO_ESC_CAL  NUMBER,
    LINEA           SMALLINT,
    SENTENCIA       CLOB
);

CREATE TABLE WEB_TBL_TESTING_FAC_VALID 
(
    CODIGO_CAL      NUMBER,
    CODIGO_ESC_CAL  NUMBER,
	DESC_VAL		VARCHAR2(4000),
    LINEA           SMALLINT,
    SENTENCE        CLOB,
	TABLE_CREATED	VARCHAR2(30)
);
ALTER TABLE WEB_TBL_TESTING_FAC_VALID ADD CONSTRAINT WEB_TBL_TESTING_FAC_VALID_P1 PRIMARY KEY(CODIGO_CAL,CODIGO_ESC_CAL,LINEA );


-- Insert de cada funcionalidad a probar
INSERT INTO WEB_TBL_TESTING_FACADE
VALUES(1,'OPTIMIZADOR', 'WEB_ORDER_TESTING_OPTI','EXECUTE_TEST');

INSERT INTO WEB_TBL_TESTING_LOAD_INITIAL
VALUES(1, 1, 1,'UPDATE WEB_TBL_SETTING_OPTIMIZATION SET PLANTS_PERCENTAGE_DEPTH = 0 WHERE CITY = ''RICHARDSON''');
INSERT INTO WEB_TBL_TESTING_LOAD_INITIAL
VALUES(1, 1, 2,'UPDATE WEB_TBL_SETTING_OPTIMIZATION SET PLANTS_NUMBER_DEPTH = 6 WHERE CITY = ''RICHARDSON''');