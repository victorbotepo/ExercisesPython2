import json
import xlwt 
from xlwt import Workbook 

class ExcelCalidadArgos():
    def __init__(self,ruta, nombreArchivo):
        self.ruta = ruta
        self.nombreArchivo = nombreArchivo
        self.wb = Workbook()
        self.save_workbook
        self.sheet = None

    def save_workbook(self):
        self.wb.save(self.ruta+'//'+self.nombreArchivo+'.xls') 

    def add_sheet(self,sheet_name, list_columns, list_data, style_tittle, desc_Validacion):
        self.sheet = self.wb.add_sheet(sheet_name)

        self.add_write(0, round(len(list_columns)/2), desc_Validacion, style_tittle)
        self.add_write(0, round(len(list_columns)/2)+1, desc_Validacion, style_tittle)
        desc_Validacion
        li_Row = 1 
        li_Column = 0
        for col  in list_columns:
            self.add_write(li_Row, li_Column, col, style_tittle)
            li_Column += 1

        li_Row += 1
        for row in list_data:
            print(row)
            print(type(row))
            li_Column = 0
            for data in row:
                self.add_write(li_Row, li_Column, data)
                li_Column += 1
            li_Row += 1

        return self.sheet

    def add_write(self,row, column, content, style=''):


        if len(style) > 0:
            xlwt.add_palette_colour("custom_colour", 0x21)
            self.wb.set_colour_RGB(0x21, 0, 103, 132)
            l_style = xlwt.easyxf(style) 
            self.sheet.write(row, column, content, l_style) 
        else:
            self.sheet.write(row, column, content) 

    def add_write_all_row(self, content,row=0, column=0, style=''):
    
        for column, heading in enumerate(content, column):
            self.sheet.write(row, column, heading)

