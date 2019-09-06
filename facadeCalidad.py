import json
import ExcelCalidad
from datetime import date
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
        self.ExcelFile = None   

    def get_parametrosGenerales(self):
        return self.config

    def execute_test_take(self, test_code):
        num_generated_token = self.con.execute_test( test_code)
        print(num_generated_token)
        return num_generated_token

    def execute_val_calidad(self,num_gen_code):
        table_created = ''
        codigo_cal = 0
        codigo_esc_cal =0
        try:

            self.con.execute_cal_fetch_load_ini(num_gen_code)
            l_cur_load_ini = self.con.l_resultVal1

            graboExcel = False

            #l_cur_load_ini = list(l_cur_load_ini)
            for row in l_cur_load_ini:
                    #row_c = list(row)
                print( row)
                print(row[0]) #codigo_cal
                codigo_cal = int(row[0])
                if graboExcel == False:
                    self.create_excel(codigo_cal)
                    graboExcel = True

                print(row[1]) #codigo_esc_cal
                codigo_esc_cal = int(row[1])
                print(row[2]) #linea
                linea = int(row[2])
                print(row[3]) #num_token_gen
                num_token_gen = int(row[3])
                
                print(row[4]) #desc_val
                desc_Validacion = row[4]

                cursorSentences = self.execute_fetch_sentence_DB(codigo_cal, codigo_esc_cal, linea, num_token_gen)
                headers = [i[0] for i in cursorSentences.description]
                self.list_load_ini = list(cursorSentences)
                
                table_created = self.con.exec_get_table_name_created(num_gen_code,codigo_cal, codigo_esc_cal, linea)

                self.generate_excel(self.list_load_ini, num_gen_code, codigo_cal, codigo_esc_cal, linea, num_token_gen, table_created, headers, desc_Validacion)

                self.con.execute_sentence_drop_table_DB(codigo_cal, codigo_esc_cal)

                self.execute_commit()

        except Exception as e:
            print(e)
            if len(table_created) > 0 and codigo_cal > 0 and codigo_esc_cal >0:
                codigo_cal
                self.con.execute_sentence_drop_table_DB(codigo_cal, codigo_esc_cal)

        #return self.con.execute_fetch(num_gen_code)

    def execute_fetch_sentence_DB(self, codigo_cal, codigo_esc_cal, linea, num_token_gen):
            list_exec = self.con.execute_sentence_DB(codigo_cal, codigo_esc_cal, linea, num_token_gen)
            return list_exec

    def generate_excel(self, list_data, code_gen, codigo_cal, codigo_esc_cal, linea, num_token_gen, table_created, list_columns, desc_Validacion):

        sheet_name = str(codigo_cal)+'_'+str(codigo_esc_cal)+'_'+str(linea)+'_'+str(num_token_gen)

        self.ExcelFile.add_sheet(sheet_name, list_columns, list_data, self.config["PARAM_GRABAR_EXCEL"]["STYLE_TITTLE"], desc_Validacion)

        print(type(list_data))
        print(len(list_data))

        self.ExcelFile.save_workbook()



    def create_excel(self, codigo_cal):
        today = date.today()
        d1 = today.strftime("%d_%m_%Y")
        nom_archivo = str(codigo_cal)+'_'+str(d1)
        self.ExcelFile = ExcelCalidad.ExcelCalidadArgos(self.config["PARAM_GRABAR_EXCEL"]["RUTA_GRABACION"], nom_archivo)

    def execute_commit(self):
        self.con.connection.commit()

    def close(self):
        self.con.close


#ip, port, user, password, db, servicename
'''connection = cx_Oracle.connect('CDAUSADESVB/CDAUSADESVB@10.110.7.25/cmddev')
ver = connection.version.split(".")
print(ver)
connection.close'''
#cx_Oracle.connect('CONSESBXM', 'Esb_rdrp$412', 'INTEGRACION_ESB')
try:


    insInvoke = facadeCalidad()
    GeneradeCode = insInvoke.execute_test_take(1)
    #listResult = insInvoke.execute_val_calidad(GeneradeCode)
    insInvoke.execute_val_calidad(GeneradeCode)
    #insInvoke.execute_val_calidad(601)
    li_="END"
    print(li_)


except Exception as other:
    print(str(other) )
    raise other
