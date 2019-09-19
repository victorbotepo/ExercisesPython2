import json
import cx_Oracle
import threading
import ExcelCalidad
from datetime import datetime
from connectionArg import ConnectionArgos

class SaveExcelAsync(threading.Thread):
    def __init__(self, num_gen_cod, codigo_cal, codigo_esc_cal, linea, ruta_grab_archivo, num_token_gen, desc_Validacion, ExcelFile):
        threading.Thread.__init__(self)
        self.codigo_cal = codigo_cal
        self.codigo_esc_cal = codigo_esc_cal
        self.linea = linea
        self.ruta_grab_archivo = ruta_grab_archivo
        self.num_token_gen = num_token_gen
        self.num_gen_cod = num_gen_cod
        self.desc_Validacion = desc_Validacion
        self.list_load_data  =  None

        with open('configuration/configuration.json','r') as f:
            self.config = json.load(f)

        eti_database = 'DATABASECONN_CUSTOMER_CDACOLDESVB'
        #eti_database = 'DATABASECONN_CUSTOMER_CDACOLDE'
        self.con = ConnectionArgos.connectionArgosPortal(self.config[eti_database]["IP"], 
                                                        self.config[eti_database]["PORT"], 
                                                        self.config[eti_database]["USER"], 
                                                        self.config[eti_database]["PASSWORD"], 
                                                        self.config[eti_database]["SERVICENAME"], 
                                                        self.config[eti_database]["SID"])
        
        self.ExcelFile = ExcelFile
        #self.create_excel()


    def create_excel(self):
        ls_fechaactual  = datetime.now().strftime("%d-%m-%Y %H_%M_%S")
        nom_archivo = str(self.codigo_cal)+'_'+str(self.codigo_esc_cal)+'_'+ls_fechaactual
        self.ExcelFile = ExcelCalidad.ExcelCalidadArgos(self.ruta_grab_archivo, nom_archivo)

    def execute_fetch_sentence_DB(self, codigo_cal, codigo_esc_cal, linea, num_token_gen):
        list_exec = self.con.execute_sentence_DB(codigo_cal, codigo_esc_cal, linea, num_token_gen)
        headers = [i[0] for i in list_exec.description]
        self.list_load_data = list(list_exec)
        return headers

    def __convert_clob_to_str_cx_oracle(self, datas):
        converted_data = self.con.convert_clob_to_str_cx_oracle(datas)
        return converted_data

    def generate_excel(self, list_data, code_gen, codigo_cal, codigo_esc_cal, linea, num_token_gen, list_columns, desc_Validacion):
    
        sheet_name = str(codigo_cal)+'_'+str(codigo_esc_cal)+'_'+str(linea)+'_'+str(num_token_gen)

        list_data = self.__convert_clob_to_str_cx_oracle(list_data)
        
        self.ExcelFile.add_sheet(sheet_name, list_columns, list_data, self.config["PARAM_GRABAR_EXCEL"]["STYLE_TITTLE"], desc_Validacion)

        self.ExcelFile.save_workbook()

    def execute_commit(self):
        self.con.connection.commit()

    def run(self):

        headers = self.execute_fetch_sentence_DB(self.codigo_cal, self.codigo_esc_cal, self.linea, self.num_token_gen)

        self.generate_excel(self.list_load_data,self.num_gen_cod, self.codigo_cal, self.codigo_esc_cal,self.linea, self.num_token_gen, headers, self.desc_Validacion)

        self.execute_commit()

        '''
        blobdoc = self.input.read()
        self.cur.execute("INSERT INTO blob_tab (ID, BLOBDOC) VALUES(blob_seq.NEXTVAL, :blobdoc)", {'blobdoc':blobdoc})
        self.input.close()
        self.cur.close()
        '''

'''
th = []
with open('configuration/configuration.json','r') as f:
    config = json.load(f)



l_ExcelFile = ExcelCalidad.ExcelCalidadArgos(config["PARAM_GRABAR_EXCEL"]["RUTA_GRABACION"], 'prueba')

num_tok = 269678
th.append(SaveExcelAsync(2481, 1, 1, 1, config["PARAM_GRABAR_EXCEL"]["RUTA_GRABACION"], num_tok, 'desc_Validacion', l_ExcelFile))
th[0].start()
th.append(SaveExcelAsync(2481, 1, 1, 2, config["PARAM_GRABAR_EXCEL"]["RUTA_GRABACION"], num_tok, 'desc_Validacion', l_ExcelFile))
th[1].start()
th.append(SaveExcelAsync(2481, 1, 1, 3, config["PARAM_GRABAR_EXCEL"]["RUTA_GRABACION"], num_tok, 'desc_Validacion', l_ExcelFile))
th[2].start()
th.append(SaveExcelAsync(2481, 1, 1, 4, config["PARAM_GRABAR_EXCEL"]["RUTA_GRABACION"], num_tok, 'desc_Validacion', l_ExcelFile))
th[3].start()

for t in th:
   t.join()
'''
