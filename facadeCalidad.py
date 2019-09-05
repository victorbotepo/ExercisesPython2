import json
#import connectionArg
from connectionArg import ConnectionArgos
#import connectionArg.ConnectionArgos.ConnectionArgos

class facadeCalidad:

    def __init__(self):
        '''self.ip = ip
        self.port = port
        self.user = user
        self.password = password
        self.serviceName = serviceName'''
        with open('configuration/configuration.json','r') as f:
            self.config = json.load(f)
        print("despues de Open configuration")
        #eti_database = 'DATABASECONN_CUSTOMER_CDAUSADESVB'
        eti_database = 'DATABASECONN_CUSTOMER_CDACOLDESVB'
        #eti_database = 'DATABASECONN_CUSTOMER_CDACOLDE'
        self.con = ConnectionArgos.connectionArgosPortal(self.config[eti_database]["IP"], 
                                                        self.config[eti_database]["PORT"], 
                                                        self.config[eti_database]["USER"], 
                                                        self.config[eti_database]["PASSWORD"], 
                                                        self.config[eti_database]["SERVICENAME"], 
                                                        self.config[eti_database]["SID"])
        print("despues de connect to portal")
        self.cur = self.con.get_cursor
        #self.cur = None       
        
    def execute_test_take(self, test_code):
        num_generated_token = self.con.execute_test( test_code)
        print(num_generated_token)
        return num_generated_token

    def execute_val_calidad(self,num_gen_code):
        self.con.execute_cal_fetch_load_ini(num_gen_code)
        l_cur_load_ini = self.con.l_resultVal1
        #l_cur_load_ini = list(l_cur_load_ini)
        for row in l_cur_load_ini:
                #row_c = list(row)
            print( row)
            print(row[0]) #codigo_cal
            codigo_cal = int(row[0])
            print(row[1]) #codigo_esc_cal
            codigo_esc_cal = int(row[1])
            print(row[2]) #linea
            linea = int(row[2])
            print(row[3]) #num_token_gen
            num_token_gen = int(row[3])
            self.list_load_ini  = self.execute_fetch_sentence_DB(codigo_cal, codigo_esc_cal, linea, num_token_gen)
            
            table_created = self.con.exec_get_table_name_created(num_gen_code,codigo_cal, codigo_esc_cal, linea)

            self.generate_excel(self.list_load_ini, num_gen_code, codigo_cal, codigo_esc_cal, linea, num_token_gen, table_created)

            self.con.execute_sentence_drop_table_DB(codigo_cal, codigo_esc_cal)

            self.execute_commit()

        #return self.con.execute_fetch(num_gen_code)

    def execute_fetch_sentence_DB(self, codigo_cal, codigo_esc_cal, linea, num_token_gen):
            list_exec = self.con.execute_sentence_DB(codigo_cal, codigo_esc_cal, linea, num_token_gen)
            list_exec = list(list_exec)
            return list_exec

    def generate_excel(self, list_data, code_gen, codigo_cal, codigo_esc_cal, linea, num_token_gen, table_created):

            for row1 in list_data:
                table_created = self.con.exec_get_table_name_created(code_gen,codigo_cal, codigo_esc_cal, linea)
                l_cur_columns_table =  self.con.get_columns_table_DB(table_created)
                l_cur_columns_table = list(l_cur_columns_table)
                print(row1)
          
    def execute_commit(self):
        self.con.connection.commit()

    def close(self):
        self.con.close

class saveToExcel():
    def __init__(self,ruta):
        self.ruta = ruta


#ip, port, user, password, db, servicename
'''connection = cx_Oracle.connect('CDAUSADESVB/CDAUSADESVB@10.110.7.25/cmddev')
ver = connection.version.split(".")
print(ver)
connection.close'''
#cx_Oracle.connect('CONSESBXM', 'Esb_rdrp$412', 'INTEGRACION_ESB')
try:


    insInvoke = facadeCalidad()
    #GeneradeCode = insInvoke.execute_test_take(1)
    #listResult = insInvoke.execute_val_calidad(GeneradeCode)
    #insInvoke.execute_val_calidad(GeneradeCode)
    insInvoke.execute_val_calidad(601)
    


except Exception as other:
    print(str(other) )
    raise other
