import json
import cx_Oracle
import itertools
from operator import itemgetter

class connectionArgosPortal():
    def __init__(self,ip, port, user, password, servicename, sid):
        try:

            self.ip = ip
            self.port = port
            self.user = user
            self.password = password
            self.servicename = servicename
            self.sid = sid
            self.connection = None
            self.dsn_tns = None
            if self.servicename != '':
                self.connection = cx_Oracle.connect(user+'/'+password+'@'+ip+'/'+servicename)
            else:
                self.dsn_tns = cx_Oracle.makedsn(ip, 1521, sid)
                print(self.dsn_tns)
                self.connection = cx_Oracle.connect(user, password, self.dsn_tns) 
            self.cur = self.connection.cursor()
            self.l_cur_load_ini = None
        except Exception as other:
            raise other

    def close(self):
        self.connection.close

    def get_cursor(self):
        self.cur

    def execute_test(self, test_code):
        #self.cur.callproc("WEB_ORDER_TESTING.execute_test",test_code)
        consec_exec = self.cur.callfunc('WEB_ORDER_TESTING.execute_test',int,[test_code]) 
        self.connection.commit()
        return consec_exec

    def execute_cal_fetch_load_ini(self, code_gen):
        self.l_cur_load_ini = self.cur.var(cx_Oracle.CURSOR)
        code_gen, self.l_resultVal1 = self.cur.callproc("WEB_ORDER_TESTING.execute_fetch_sentence", [code_gen, self.l_cur_load_ini]) 

    def execute_sentence_DB(self, codigo_cal, codigo_esc_cal, linea, num_token_gen):
        l_cur1 = self.connection.cursor()
        self.cur.callproc("WEB_ORDER_TESTING.execute_sentence", [codigo_cal, codigo_esc_cal, linea, num_token_gen, l_cur1]) 
        return l_cur1

    def execute_sentence_drop_table_DB(self, codigo_cal, codigo_esc_cal):
        self.cur.callproc("WEB_ORDER_TESTING.execute_drop_tables", [codigo_cal, codigo_esc_cal])

    def exec_get_table_name_created(self, code_gen, codigo_cal, codigo_esc_cal, linea):
        table_created = self.cur.callfunc('WEB_ORDER_TESTING.get_table_name_created',str,[code_gen,codigo_cal, codigo_esc_cal, linea ])
        return table_created
    

