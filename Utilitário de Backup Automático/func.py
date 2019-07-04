import psycopg2, time, schedule, datetime, os
from subprocess import Popen, PIPE

global data_dir
global reconnect
reconnect = True

class Time:
    def time_opt(self):
        freq = input("O backup deverá ser feito diariamente ou em dias determinados?\n   1- Diario\n   2- Em intervalos determinados(Horas ou Minutos)\n")
        if (freq == '1'):
            hora = input("Em qual horário?\n")
            print("Backup será realizado todos os dias às " + hora + "\n")
            self.day(hora)
        elif (freq == '2'):
            opt2 = input("Em horas ou minutos?\n m - minutos\n h - horas\n")
            if (opt2 in ('h','H','hora','HORA','hour', 'Hour','HORAS','horas')):
                opt3 = input("Qual intervalo de horas?\n")
                print("Backup será realizado a cada " + opt3 + " horas\n")
                self.timer_hour(opt3)
            elif (opt2 in ('m','M','minuto','MINUTO','minute', 'MINUTE','minutos','MINUTOS')):
                opt4 = input("Qual intervalo de minutos?\n")
                print("Backup será realizado a cada " + opt4 + " minutos\n")
                self.timer_minutes(opt4)
            else:
                print("Opção Inválida\n")
        else:
            print("Opção Inválida\n")

    def timer_hour(self,hr):
        hour = int(hr)
        schedule.every(hour).hours.do(db.backup)
        while True:
            schedule.run_pending()
            time.sleep(1)

    def timer_minutes(self, min):
        minutes = int(min)
        schedule.every(minutes).minutes.do(db.backup)
        while True:
            schedule.run_pending()
            time.sleep(1)

    def day(self,hora):
        schedule.every().day.at(hora).do(db.backup)
        while True:
            schedule.run_pending()
            time.sleep(1)

    def get_today(self):
        today = (datetime.datetime.now()).strftime('%d/%m/%y_%H:%M').replace("/", "").replace(":", "")
        return today

tm = Time()

class Database:
    def Condb(self,retry):
            try:
                print("\nInsira os dados de conexão PostgreSQL abaixo:\n\n")
                host = input("IP do Servidor:\n")
                print("")
                db = input("Nome da Base de Dados:\n")
                print("")
                usr = input("Usuário para conexão com a base " + db + ":\n")
                print("")
                psw = input("Senha para usuário '" + usr + "': \n")
                print("")
                pt = input("Porta para conexão com PostgreSQL:\n")

                global db_name
                db_name = db

                self.conn = psycopg2.connect = psycopg2.connect\
                (
                    host=host,
                    database=db,
                    user=usr,
                    password=psw,
                    port=pt
                )

                self.conn.autocommit = False
                self.cur = self.conn.cursor()
                return self.conn
            except psycopg2.OperationalError as error:
                if not reconnect or retry >= 5:
                    raise error
                    print("\nNão foi possível conectar. Verifique suas configurações de banco e reinicie o utilitário\n")
                    time.sleep(5)
                else:
                    retry += 1
                    print("Erro ao conectar:\n {}. \n\nInsira os dados novamente... {}".format(str(error).strip(), retry),"\n")
                    time.sleep(5)
                    self.Condb(retry)
            except (Exception, psycopg2.Error) as error:
                raise error
                print("\nNão foi possível conectar. Verifique suas configurações de banco e reinicie o utilitário\n")
                time.sleep(5)

    def query(self, cod):
        self.cur.execute(cod)
        fetch = self.cur.fetchone()
        return fetch

    def get_data(self):
        self.cur.execute('''select setting from pg_settings where name = 'hba_file''')
        data_dir = self.cur.fetchone()
        if (data_dir != 'Null' and data_dir != None):
            return True
        else:
            return False

    def backup(self):
        hr_atual = tm.get_today()
        print("Iniciando o backup programado - " + str(datetime.datetime.now()))
        dir = os.path.dirname(os.path.abspath(__file__))
        print(r''' "''' + dir + """\psql_x64\pg_dump.exe" -h localhost -p 5432 -d """ + db_name + r""" -U postgres -Fc -E UTF-8 -x -O --no-tablespaces -f C:\Users\lucasserra.NASAJON\Documents\nsj_""" + db_name + """_""" + hr_atual + """.backup""")
        bkp = (r''' "''' + dir + """\psql_x64\pg_dump.exe" -h localhost -p 5432 -d """ + db_name + r""" -U postgres -Fc -E UTF-8 -x -O --no-tablespaces -f C:\Users\lucasserra.NASAJON\Documents\nsj_""" + db_name + """_""" + hr_atual + """.backup""")
        bkp_process = Popen(bkp, shell=True,stdout=PIPE, stderr=PIPE)
        bkp_process.wait()
        print("Processo de backup finalizado às " + str(datetime.datetime.now())+ "\n")

db = Database()