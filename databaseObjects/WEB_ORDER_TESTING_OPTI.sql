CREATE OR REPLACE PACKAGE WEB_ORDER_TESTING_OPTI IS

  -- Author  : vbotero
  -- Created : 27/08/2019 08:22:32 p.m.
  -- Purpose : Testing_package_optimizer

  FUNCTION execute_test(test_code NUMBER) RETURN NUMBER;

END WEB_ORDER_TESTING_OPTI;
/


CREATE OR REPLACE PACKAGE BODY WEB_ORDER_TESTING_OPTI AS 
    
    FUNCTION execute_test(test_code NUMBER) RETURN NUMBER
    AS 
        CODIGO_MOCK         WEB_TBL_TESTING_FACADE_DET.CODIGO_ESC_CAL%TYPE;
        in_clob_xml_input   WEB_TBL_TESTING_FACADE_DET.CLOB_XML_INPUT%TYPE;
        in_linea            WEB_TBL_TESTING_LOAD_INITIAL.LINEA%TYPE;
        in_sentencia        WEB_TBL_TESTING_LOAD_INITIAL.SENTENCIA%TYPE;
        
        v_Return    XMLTYPE;
        out_take    CLOB;
        lxml_dato   XMLTYPE;
        li_token    NUMBER;

        CURSOR cursor_initial_load
            IS
            SELECT loadini.LINEA, loadini.SENTENCIA
            FROM WEB_TBL_TESTING_FACADE_DET det
                    INNER JOIN WEB_TBL_TESTING_LOAD_INITIAL loadini ON (det.CODIGO_CAL = loadini.CODIGO_CAL AND 
                                                                        det.CODIGO_ESC_CAL = loadini.CODIGO_ESC_CAL)
            WHERE det.CODIGO_CAL = test_code AND CODIGO_GEN IS NULL;

        CURSOR cursor_sel_mock_test
            IS
            SELECT det.CODIGO_ESC_CAL, det.CLOB_XML_INPUT
            FROM WEB_TBL_TESTING_FACADE_DET det
            WHERE det.CODIGO_CAL = test_code AND CODIGO_GEN IS NULL;
        v_proc  CLOB;
        li_seq_Cod_gene NUMBER := 0;
        li_cont SMALLINT := 0 ;
BEGIN
        v_proc :='BEGIN ';
        OPEN cursor_initial_load;
		LOOP FETCH cursor_initial_load INTO in_linea, in_sentencia;
		EXIT WHEN cursor_initial_load%NOTFOUND;
            v_proc := v_proc ||NVL(in_sentencia,' ')||';';
            IF NVL(in_sentencia,' ') != ' ' THEN
                li_cont := li_cont + 1;
            END IF;
        END LOOP;

        v_proc := v_proc||' END;';
        IF  li_cont >   1   THEN
            EXECUTE IMMEDIATE v_proc;
        END IF;
        CLOSE cursor_initial_load;
        
        
        li_cont := 0;
        
        OPEN cursor_sel_mock_test;
		LOOP FETCH cursor_sel_mock_test INTO CODIGO_MOCK, in_clob_xml_input;
		EXIT WHEN cursor_sel_mock_test%NOTFOUND;
            
            IF li_cont = 0 THEN
                SELECT WEB_SEQ_ORDER_TESTING.NextVal 
                    INTO li_seq_Cod_gene
                FROM DUAL;
            END IF;
            li_cont := li_cont + 1;
            
            lxml_dato := XMLTYPE.CREATEXML(in_clob_xml_input);
            
            v_Return := WEB_ORDER_WS_A010.TAKE(lxml_dato);
            
            SELECT ExtractValue(v_Return,'/OUT_WEB_ORDER_OPTIONS/HEADER/TOKEN')
                INTO li_token
            FROM DUAL;
            
            UPDATE WEB_TBL_TESTING_FACADE_DET 
            SET XML_OUT = v_Return, XML_INPUT = lxml_dato, NOM_TOKEN_GEN = li_token, CODIGO_GEN = li_seq_Cod_gene
            WHERE CODIGO_CAL = test_code AND CODIGO_ESC_CAL = CODIGO_MOCK;
            
            Commit;
              
       END LOOP;
       CLOSE cursor_sel_mock_test;  
 
    RETURN li_seq_Cod_gene;
    EXCEPTION 
        WHEN OTHERS THEN
            dbms_output.put_line('v_proc: v_proc --> '||v_proc );
            dbms_output.put_line('ERROR: '||SQLERRM );
            RETURN -1;
        
    END execute_test;
END WEB_ORDER_TESTING_OPTI;
/
