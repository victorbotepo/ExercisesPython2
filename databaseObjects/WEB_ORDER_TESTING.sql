create or replace PACKAGE WEB_ORDER_TESTING AS 
    
    FUNCTION execute_test(test_code NUMBER) RETURN NUMBER;

    FUNCTION execute_test_standard(test_code NUMBER) RETURN NUMBER;
    
    PROCEDURE execute_fetch_sentence(arg_codigo_gen NUMBER, return_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE execute_sentence(arg_codigo_cal NUMBER, arg_codigo_esc_cal NUMBER, arg_linea NUMBER, arg_token NUMBER, return_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE execute_drop_tables(arg_codigo_cal NUMBER, arg_codigo_esc_cal NUMBER);
    
    FUNCTION get_table_name_created(arg_codigo_gen NUMBER, arg_codigo_cal NUMBER, arg_codigo_esc_cal NUMBER, arg_linea NUMBER) RETURN VARCHAR2;
    
    PROCEDURE MockExecuteSentence(arg_codigo_gen NUMBER);
    
    PROCEDURE grabarErrorEjecucion(arg_codigo_gen NUMBER, arg_codigo_cal NUMBER, arg_codigo_esc_cal NUMBER, error_generated VARCHAR2);
    
    PROCEDURE invoke_take(test_code INTEGER, CODIGO_MOCK INTEGER, seq_Cod_gene NUMBER);
    
END WEB_ORDER_TESTING;
/


create or replace PACKAGE BODY WEB_ORDER_TESTING AS 
    
    FUNCTION execute_test(test_code NUMBER) RETURN NUMBER
    AS 
        in_return       NUMBER := 0;
        in_codigo_cal   WEB_TBL_TESTING_FACADE.CODIGO_CAL%TYPE;
        in_descripcion  WEB_TBL_TESTING_FACADE.DESCRIPCION%TYPE;
        in_nom_package  WEB_TBL_TESTING_FACADE.NOM_PACKAGE%TYPE;
        in_nom_proc_func WEB_TBL_TESTING_FACADE.NOM_PROC_FUNC%TYPE;

        v_proc  clob;
        l_termina   VARCHAR2(1) :='0';
        li_cont     NUMBER := 0;
    BEGIN
            v_proc := 'BEGIN ';


            SELECT CODIGO_CAL, DESCRIPCION, NOM_PACKAGE, NOM_PROC_FUNC
                INTO in_codigo_cal, in_descripcion, in_nom_package, in_nom_proc_func
            FROM WEB_TBL_TESTING_FACADE
            WHERE CODIGO_CAL = test_code;

            SELECT COUNT(1) INTO li_cont 
            FROM WEB_TBL_TESTING_FACADE_DET
            WHERE CODIGO_CAL = test_code AND CODIGO_GEN IS NULL;
            
            in_return := execute_test_standard(test_code);

            WHILE l_termina = '0'
            LOOP
                SELECT decode(COUNT(1), li_cont, '1', '0')
                    INTO l_termina
                FROM WEB_TBL_TESTING_FACADE_DET
                WHERE CODIGO_CAL = test_code AND CODIGO_GEN = in_return;
                DBMS_LOCK.SLEEP(20);
                
            END LOOP;

            --EXECUTE IMMEDIATE 'CALL '||in_nom_package||'.'||in_nom_proc_func||'('||test_code||') INTO :in_return ' USING OUT in_return ;
            RETURN in_return;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR( -200001, SQLERRM);
            RETURN in_return;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR( -200002, SQLERRM);   

    END execute_test;

    PROCEDURE invoke_take(test_code INTEGER, CODIGO_MOCK INTEGER, seq_Cod_gene NUMBER)
    IS
        li_token            NUMBER;
        lxml_dato           XMLTYPE;
        v_Return            XMLTYPE;
    BEGIN
    
    
        --lxml_dato := XMLTYPE.CREATEXML(in_take);
        
        SELECT XML_INPUT
            INTO lxml_dato
        FROM WEB_TBL_TESTING_FACADE_DET 
        WHERE CODIGO_CAL = test_code AND CODIGO_ESC_CAL = CODIGO_MOCK  AND CODIGO_GEN IS NULL;
        
        
        v_Return := WEB_ORDER_WS_22.TAKE(lxml_dato);
        
        SELECT ExtractValue(v_Return,'/OUT_WEB_ORDER_OPTIONS/HEADER/TOKEN')
            INTO li_token
        FROM DUAL;
        
        UPDATE WEB_TBL_TESTING_FACADE_DET 
        SET XML_OUT = v_Return, XML_INPUT = lxml_dato, NUM_TOKEN_GEN = li_token, CODIGO_GEN = seq_Cod_gene, DATE_GEN = SYSDATE, err_msg = NULL
        WHERE CODIGO_CAL = test_code AND CODIGO_ESC_CAL = CODIGO_MOCK  AND CODIGO_GEN IS NULL ;
        
        Commit;
        
    END invoke_take;

    FUNCTION execute_test_standard(test_code NUMBER) RETURN NUMBER
    AS 
        CODIGO_MOCK         WEB_TBL_TESTING_FACADE_DET.CODIGO_ESC_CAL%TYPE;
        in_clob_xml_input   WEB_TBL_TESTING_FACADE_DET.CLOB_XML_INPUT%TYPE;
        in_linea            WEB_TBL_TESTING_LOAD_INITIAL.LINEA%TYPE;
        in_sentencia        WEB_TBL_TESTING_LOAD_INITIAL.SENTENCIA%TYPE;

        v_Return    XMLTYPE;
        out_take    CLOB;
        lxml_dato   XMLTYPE;

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
        l_jobno pls_integer;
        l_termina   VARCHAR2(1) := '0';

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
            

            lxml_dato := XMLTYPE.CREATEXML(in_clob_xml_input);


            UPDATE WEB_TBL_TESTING_FACADE_DET 
            SET XML_INPUT = lxml_dato
            WHERE CODIGO_CAL = test_code AND CODIGO_ESC_CAL = CODIGO_MOCK  AND CODIGO_GEN IS NULL ;

            Commit;
            
            --invoke_take(test_code, CODIGO_MOCK, li_seq_Cod_gene);
            
            dbms_job.submit(l_jobno, 'begin WEB_ORDER_TESTING.invoke_take('||to_char(test_code)||', '||
                                                                            to_char(CODIGO_MOCK) ||', '||
                                                                            to_char(li_seq_Cod_gene)||'); end;' );
            --dbms_job.submit(l_jobno, 'begin WEB_ORDER_TESTING.invoke_take(:in_clob_xml_input, :test_code,:CODIGO_MOCK , :li_cont ); end;' );
            li_cont := li_cont + 1;
            
            
            Commit;
            
            /*
            
            v_Return := WEB_ORDER_WS_22.TAKE(lxml_dato);
            --v_Return := WEB_ORDER_WS_A010.TAKE(lxml_dato);

            SELECT ExtractValue(v_Return,'/OUT_WEB_ORDER_OPTIONS/HEADER/TOKEN')
                INTO li_token
            FROM DUAL;

            UPDATE WEB_TBL_TESTING_FACADE_DET 
            SET XML_OUT = v_Return, XML_INPUT = lxml_dato, NUM_TOKEN_GEN = li_token, CODIGO_GEN = li_seq_Cod_gene, DATE_GEN = SYSDATE, err_msg = NULL
            WHERE CODIGO_CAL = test_code AND CODIGO_ESC_CAL = CODIGO_MOCK  AND CODIGO_GEN IS NULL ;

            Commit;*/

       END LOOP;
       CLOSE cursor_sel_mock_test;  
    
    RETURN li_seq_Cod_gene;
    EXCEPTION 
        WHEN OTHERS THEN
            dbms_output.put_line('v_proc: v_proc --> '||v_proc );
            dbms_output.put_line('ERROR: '||SQLERRM );
            RETURN -1;

    END execute_test_standard;

    PROCEDURE execute_fetch_sentence(arg_codigo_gen NUMBER, return_cursor OUT SYS_REFCURSOR)
    AS
    BEGIN
        OPEN return_cursor FOR 
            SELECT val.codigo_cal, val.codigo_esc_cal, val.linea, det.num_token_gen, val.desc_val
            FROM WEB_TBL_TESTING_FAC_VALID val
                    INNER JOIN WEB_TBL_TESTING_FACADE_DET det ON (val.codigo_cal= det.codigo_cal AND val.codigo_esc_cal= det.codigo_esc_cal)
            WHERE det.codigo_gen =  arg_codigo_gen
            ORDER BY val.codigo_cal,val.codigo_esc_cal,val.linea;
            
    END execute_fetch_sentence;

    PROCEDURE execute_sentence(arg_codigo_cal NUMBER, arg_codigo_esc_cal NUMBER, arg_linea NUMBER, arg_token NUMBER, return_cursor OUT SYS_REFCURSOR)
    AS 
        name_created_table  VARCHAR2(30);
        ls_Sentence1        CLOB;
        --------------------------------------------
        PROCEDURE exec_create_table
        IS
            ls_Anonym_sentence  CLOB;
            ls_Sentence         CLOB;
            
        BEGIN
            SELECT sentence
                INTO ls_Sentence
            FROM WEB_TBL_TESTING_FAC_VALID
            WHERE codigo_cal = arg_codigo_cal AND codigo_esc_cal = arg_codigo_esc_cal AND linea = arg_linea;
            
            name_created_table := 'TAB_TEST_'||arg_codigo_cal||'_'||arg_codigo_esc_cal||'_'||arg_linea;
            
            execute_drop_tables(arg_codigo_cal, arg_codigo_esc_cal);
            
            ls_Sentence:= REPLACE(ls_Sentence,':NUM_TOKEN',TO_CHAR(arg_token));
            
            dbms_output.put_line('ls_Sentence --> '||ls_Sentence );
            
            ls_Anonym_sentence := ' CREATE TABLE '||name_created_table||' AS ('||ls_Sentence||')';
            
            dbms_output.put_line('ls_Anonym_sentence --> '||ls_Anonym_sentence );
            
            EXECUTE IMMEDIATE ls_Anonym_sentence;
            
            UPDATE WEB_TBL_TESTING_FAC_VALID 
                SET TABLE_CREATED= name_created_table, ERR_MSG = NULL
            WHERE CODIGO_CAL = arg_codigo_cal AND CODIGO_ESC_CAL = arg_codigo_esc_cal AND LINEA = arg_linea ;
            
        END exec_create_table;
        --------------------------------------------
    BEGIN
    
        SELECT REPLACE(sentence,':NUM_TOKEN',TO_CHAR(arg_token))
            INTO ls_Sentence1
        FROM WEB_TBL_TESTING_FAC_VALID
        WHERE codigo_cal = arg_codigo_cal AND codigo_esc_cal = arg_codigo_esc_cal AND linea = arg_linea;
    
        --ls_Sentence:= REPLACE(ls_Sentence,':NUM_TOKEN',TO_CHAR(arg_token));
        
        --exec_create_table;
        OPEN return_cursor 
            FOR 'SELECT * FROM ('||ls_Sentence1||')'
            ;
        
    END execute_sentence;
    
    PROCEDURE execute_drop_tables(arg_codigo_cal NUMBER, arg_codigo_esc_cal NUMBER)
    AS
        sentence_drop  CLOB;
        drop_table      VARCHAR2(30);
        
        CURSOR cur_tables_drop IS 
        SELECT TABLE_CREATED FROM WEB_TBL_TESTING_FAC_VALID
                WHERE codigo_cal = arg_codigo_cal AND codigo_esc_cal = arg_codigo_esc_cal AND table_created IS NOT NULL AND
                        TABLE_CREATED IN (SELECT table_name FROM all_tables WHERE owner = user and  table_name like 'TAB_TEST_%');
    BEGIN
        sentence_drop:= 'DROP TABLE ';
        OPEN cur_tables_drop;
        LOOP
              FETCH cur_tables_drop INTO drop_table;
                EXIT WHEN cur_tables_drop%NOTFOUND;
                    sentence_drop := sentence_drop||' '||drop_table;
                    EXECUTE IMMEDIATE sentence_drop;
                    sentence_drop:= 'DROP TABLE ';
                    
                    UPDATE WEB_TBL_TESTING_FAC_VALID SET table_created = NULL 
                    WHERE codigo_cal = arg_codigo_cal AND codigo_esc_cal = arg_codigo_esc_cal AND table_created = drop_table;
                    
        END LOOP;
        CLOSE cur_tables_drop;
        
    END execute_drop_tables ;

    FUNCTION get_table_name_created(arg_codigo_gen NUMBER, arg_codigo_cal NUMBER, arg_codigo_esc_cal NUMBER, arg_linea NUMBER) RETURN VARCHAR2
    AS
        ls_table_created    VARCHAR2(50);
    BEGIN
        SELECT table_created
        INTO ls_table_created
            FROM WEB_TBL_TESTING_FAC_VALID val
                    INNER JOIN WEB_TBL_TESTING_FACADE_DET det ON (val.codigo_cal= det.codigo_cal AND val.codigo_esc_cal= det.codigo_esc_cal)
            WHERE det.codigo_gen =  arg_codigo_gen AND val.codigo_cal= arg_codigo_cal AND val.codigo_esc_cal= arg_codigo_esc_cal AND
                    val.linea = arg_linea;
        RETURN NVL(ls_table_created,'');
    END get_table_name_created;

    PROCEDURE MockExecuteSentence(arg_codigo_gen NUMBER)
    AS
        cursor l_cur 
        IS 
            SELECT val.codigo_cal, val.codigo_esc_cal, val.linea, det.num_token_gen
                FROM WEB_TBL_TESTING_FAC_VALID val
                        INNER JOIN WEB_TBL_TESTING_FACADE_DET det ON (val.codigo_cal= det.codigo_cal AND val.codigo_esc_cal= det.codigo_esc_cal)
                WHERE det.codigo_gen =  arg_codigo_gen
                ORDER BY val.linea;
        li_codigo_cal       NUMBER;
        li_codigo_esc_cal   NUMBER;
        li_linea            NUMBER;
        li_num_token_gen    NUMBER;
        
        l_cur1               sys_refcursor;
        
    BEGIN
        OPEN l_cur;
        LOOP 
            FETCH l_cur INTO li_codigo_cal, li_codigo_esc_cal, li_linea, li_num_token_gen;
            EXIT WHEN l_cur%NOTFOUND;
                execute_sentence(li_codigo_cal, li_codigo_esc_cal, li_linea, li_num_token_gen, l_cur1);
        END LOOP;
    END MockExecuteSentence;
    
    PROCEDURE grabarErrorEjecucion(arg_codigo_gen NUMBER, arg_codigo_cal NUMBER, arg_codigo_esc_cal NUMBER, error_generated VARCHAR2)
    AS
    BEGIN 
        UPDATE WEB_TBL_TESTING_FACADE_DET SET err_msg = error_generated
        WHERE arg_codigo_gen = codigo_gen AND arg_codigo_cal = codigo_cal AND  
              codigo_esc_cal = arg_codigo_esc_cal;
    END grabarErrorEjecucion;
END WEB_ORDER_TESTING;
/