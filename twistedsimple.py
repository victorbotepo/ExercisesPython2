#File: twistedsimple.py
#A simple example of a Twisted app

from twisted.internet import reactor
from twisted.enterprise import adbapi

def printResult(rslt):
   #print rslt[0][0]
   reactor.stop()

if __name__ == "__main__":
   dbpool = adbapi.ConnectionPool('cx_Oracle', user='hr', password ='hr', dsn='127.0.0.1/XE')
   empno = 100
   deferred = dbpool.runQuery("SELECT last_name FROM employees WHERE employee_id = :empno", {'empno':empno})
   deferred.addCallback(printResult)
   reactor.run()