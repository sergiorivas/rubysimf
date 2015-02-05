from SimPy.Simulation import *
from random import *
from math import *
              
def percentil(datos, p):
	datos.sort(key=float)
	perc = 0
	n = len(datos) 
	indice = (n-1)*p 
	if (indice - int(indice)) == 0:
		perc =  datos[int(indice)]
	else:
		perc = (datos[int(indice)]+datos[int(indice+1)])/2.0
	return perc
	                                                            
def traza(): 
	if corrida == 1 and now()<60*8*40+1:
		salida_traza.write("%.2f|%s|%i|%i|%i\n"%(now(),modo,len(cola_control),\
		len(empaque.waitQ)+len(empaque.activeQ),len(almacen)))

def leer_entrada():      
	entrada = open("entrada.txt","r")
	entrada.readline()
	datos["ensamblaje_distribucion_min_a"] = float(entrada.readline())
	entrada.readline()
	datos["ensamblaje_distribucion_moda_a"] = float(entrada.readline())
	entrada.readline()
	datos["ensamblaje_distribucion_max_a"] = float(entrada.readline())         
	entrada.readline()
	datos["ensamblaje_distribucion_min_b"] = float(entrada.readline())
	entrada.readline()
	datos["ensamblaje_distribucion_moda_b"] = float(entrada.readline())
	entrada.readline()
	datos["ensamblaje_distribucion_max_b"] = float(entrada.readline())         
	entrada.readline()
	datos["porcentaje_ir_a_control_calidad"] = float(entrada.readline()) 
	entrada.readline()
	datos["media_demanda_despacho"] = float(entrada.readline())  
	entrada.readline()
	datos["intervalo_despacho"] = float(entrada.readline())
	entrada.readline()
	datos["tamano_lote_control_calidad"] = float(entrada.readline())
	entrada.readline()
	datos["capacidad_cola_control_calidad"] = float(entrada.readline())
	entrada.readline()
	datos["parametro_escala_tiempo_falla"] = float(entrada.readline())
	entrada.readline()
	datos["parametro_forma_tiempo_falla"] = float(entrada.readline())
	entrada.readline()
	datos["tiempo_control_calidad"] = float(entrada.readline()) 
	entrada.readline()
	datos["probabilidad_falla_ensamblaje_a"] = float(entrada.readline())
	entrada.readline()
	datos["probabilidad_falla_ensamblaje_b"] = float(entrada.readline()) 
	entrada.readline()
	datos["umbral_falla_para_cambio_modo"] = float(entrada.readline())	
	entrada.readline()
	datos["cantidad_empacadores"] = float(entrada.readline())       
	entrada.readline()
	datos["minutos_a_simular"] = float(entrada.readline())
	entrada.readline()
	datos["cantidad_corridas"] = float(entrada.readline()) 
	entrada.close()    
  
def bernoulli(p):
	return random() <= p

def generar_tiempo_empaque():
	suma = 0
	for i in range(12):
	  suma += random() 
	return suma/12.0 + 0.5
	
def generar_tiempo_ensamble():
	global modo
	if modo == "a":
		return triangular(datos["ensamblaje_distribucion_min_a"], \
		datos["ensamblaje_distribucion_max_a"], \
		datos["ensamblaje_distribucion_moda_a"])
	return triangular(datos["ensamblaje_distribucion_min_b"], \
	datos["ensamblaje_distribucion_max_b"], \
	datos["ensamblaje_distribucion_moda_b"]) 

def generar_falla_arranque():
	global modo
	if modo == "a":
		return bernoulli(datos["probabilidad_falla_ensamblaje_a"])
	return bernoulli(datos["probabilidad_falla_ensamblaje_b"])
	
def generar_tiempo_falla():
	return weibullvariate(datos["parametro_escala_tiempo_falla"],\
	datos["parametro_forma_tiempo_falla"])*60.0
	
def generar_cantidad_despachar():
	contador = -1
	acum = 0.0
	while acum < 1:
		contador += 1
		acum += expovariate(datos["media_demanda_despacho"])   
	return contador

class Maquina(Process):  
	def __init__(self,name):
		Process.__init__(self)   
		self.name = name
		self.tiempo_falla_componentes = generar_tiempo_falla()  
		self.falla_arranque = generar_falla_arranque()
		self.creada_en = now()
		
	def procesar(self): 
		global empacadas,probador_esperando,ensamblaje_parado, ensamblador 
		global tiempo_servicio,monitor_control
		if bernoulli(datos["porcentaje_ir_a_control_calidad"]): 
			cola_control.append(self)   
			largo_cola = 0       
			if len(cola_control) > datos["tamano_lote_control_calidad"]:
				largo_cola = (len(cola_control) - datos["tamano_lote_control_calidad"]) 
			monitor_control.observe(largo_cola)
			if probador_esperando:
				probador_esperando = False
				reactivate(probador)
			yield passivate, self 
		traza()
		yield request, self, empaque
		traza() 
		tiempo_empaque = generar_tiempo_empaque()
		yield hold, self, tiempo_empaque
		yield release, self, empaque    
		traza()
		tiempo_servicio +=  tiempo_empaque 
		monitor_tiempo.observe(now()-self.creada_en) 
		empacadas += 1
		almacen.append(self) 
		traza()
		
class Probador(Process):
	def probar(self): 
		global fallan_en_prueba,probadas,probador_esperando,ensamblaje_parado, modo
		while True:
			if len(cola_control) >= datos["tamano_lote_control_calidad"]:
				yield hold, self, datos["tiempo_control_calidad"]
				traza()
				for i in range(int(datos["tamano_lote_control_calidad"])):
					probadas += 1
					maquina = cola_control.pop(0)       
					if maquina.falla_arranque:  
						fallan_en_prueba += 1 
						del(maquina) 
					else:
						if maquina.tiempo_falla_componentes<datos["tiempo_control_calidad"]:
							fallan_en_prueba += 1 
							del(maquina)  
						else:         
							reactivate(maquina)
				if (datos["umbral_falla_para_cambio_modo"] < fallan_en_prueba*1.0/probadas) \
				and modo == "a":
					modo = "b"   
				if ensamblaje_parado:
					ensamblaje_parado = False
					reactivate(ensamblador)
			else:   
				probador_esperando = True
				yield passivate, self
						
class Ensamblador(Process):
	def ensamblar(self): 
		global contador_maquinas, ensambladas, ensamblaje_parado
		while True:   
			if len(cola_control) >= (datos["capacidad_cola_control_calidad"] +\
			 datos["tamano_lote_control_calidad"]):
				ensamblaje_parado = True
				yield passivate, self
			else:
				m = Maquina(name="Maquina %i"%contador_maquinas)  
				contador_maquinas += 1
				yield hold, self, generar_tiempo_ensamble()
				ensambladas += 1
				activate(m,m.procesar()) 
				traza() 

class Despachador(Process):
	def despachar(self): 
		global demanda_insatisfecha, despachadas, modo
		while True:
			yield hold, self, datos["intervalo_despacho"] 
			monitor_almacen.observe(len(almacen))
			demanda = generar_cantidad_despachar()   
			a_sacar = demanda
			if demanda > len(almacen):
				a_sacar = len(almacen) 
		 		demanda_insatisfecha += (demanda - len(almacen))        
#				if modo == "b": 
#					modo = "a"      
			for i in range(a_sacar):
				maquina = almacen.pop(0) 
			despachadas += a_sacar   
			traza()
				
def simular_corrida():
	initialize() 
	activate(ensamblador,ensamblador.ensamblar())
	activate(probador,probador.probar())
	activate(despachador,despachador.despachar())
	simulate(until=datos["minutos_a_simular"])   

def inicializar_corrida():
	global empaque, almacen, probador_esperando, ensamblaje_parado
	global ensambladas,despachadas,probadas,fallan_en_prueba, empacadas
	global contador_maquinas, demanda_insatisfecha
	global cola_control, modo
	global ensamblador, probador, despachador    
	global monitor_control,tiempo_servicio,monitor_tiempo,monitor_almacen
	monitor_control = Monitor()  
	monitor_tiempo = Monitor()
	monitor_almacen = Monitor()
	empaque = Resource(capacity=datos["cantidad_empacadores"],\
	name="empaque",monitored=True)
	almacen = []                       
	ensambladas = 0    
	despachadas = 0
	probadas = 0
	fallan_en_prueba = 0
	contador_maquinas = 1
	empacadas = 0
	demanda_insatisfecha = 0
	cola_control = []     
	probador_esperando = False  
	ensamblaje_parado = False
	ensamblador = Ensamblador(name="ensamblador")
	probador = Probador(name="probador")
	despachador = Despachador(name="despachador")     
	modo = "a"
	tiempo_servicio = 0
	
def mostrar_resultados_corrida():      
	global salida  
	p1 = 0
	p2 = 0
	if empaque.waitMon.count() > 0:
		p1 = max(empaque.waitMon.yseries())    
		p2 = empaque.waitMon.timeAverage()
	salida.write("%i|%i|%i|%i|%i|%i|%.2f|%i|%.2f|%i|%i|%.2f|%.2f|%.2f|%.2f|%.2f\n"%(
	ensambladas,probadas,fallan_en_prueba, empacadas,
	despachadas,demanda_insatisfecha,monitor_control.timeAverage(),
	max(monitor_control.yseries()), p2, p1, 
	max(monitor_almacen.yseries()),monitor_tiempo.mean(), 
	max(monitor_tiempo.yseries()),
	min(monitor_tiempo.yseries()),percentil(monitor_tiempo.yseries(),0.5),
	100.0*tiempo_servicio/(datos["cantidad_empacadores"]*now())
	))   

datos = {}       
leer_entrada()      
salida = open("salida.txt", "w")  
salida_traza = open("traza.txt", "w")  
salida.write("ensambladas|probadas|desechadas|empacadas|")
salida.write("despachadas|demanda_instatisfecha|promedio_cola_control_calidad|")
salida.write("max_cola_control_calidad|promedio_cola_empaque|max_cola_empaque|")
salida.write("max_almacen|promedio_tiempo_produccion|max_tiempo_produccion|")
salida.write("min_tiempo_produccion|p50_tiempo_produccion|")
salida.write("promedio_porcentaje_ocupacion\n")
salida_traza.write("hora|modo_produccion|cantidad_area_control_calidad|cantidad_area_empaque|cantidad_almacen\n")
for i in range(int(datos["cantidad_corridas"])):
	corrida = i+1
	print "corrida %i"%(corrida)
	inicializar_corrida()
	simular_corrida()
	mostrar_resultados_corrida()  
salida.close()
salida_traza.close() 

 