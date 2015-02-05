require "rubysimf"
                                                                         
def traza() 
	if corrida == 1 && $sim.now()<60*8*40+1
		salida_traza.printf("%.2f|%s|%i|%i|%i\n",
		$sim.now,$modo,$cola_control.size,\
		$empaque.queue_size+$empaque.busy_servers,$almacen.size) 
	end
end

def leer_entrada()     
	entrada = File.open("entrada.txt","r")
	entrada.readline()
	$datos["ensamblaje_distribucion_min_a"] = entrada.readline().to_f
	entrada.readline()
	$datos["ensamblaje_distribucion_moda_a"] = entrada.readline().to_f
	entrada.readline()
	$datos["ensamblaje_distribucion_max_a"] = entrada.readline().to_f         
	entrada.readline()
	$datos["ensamblaje_distribucion_min_b"] = entrada.readline().to_f
	entrada.readline()
	$datos["ensamblaje_distribucion_moda_b"] = entrada.readline().to_f
	entrada.readline()
	$datos["ensamblaje_distribucion_max_b"] = entrada.readline().to_f         
	entrada.readline()
	$datos["porcentaje_ir_a_control_calidad"] = entrada.readline().to_f 
	entrada.readline()
	$datos["media_demanda_despacho"] = entrada.readline().to_f  
	entrada.readline()
	$datos["intervalo_despacho"] = entrada.readline().to_f
	entrada.readline()
	$datos["tamano_lote_control_calidad"] = entrada.readline().to_f
	entrada.readline()
	$datos["capacidad_$cola_control_calidad"] = entrada.readline().to_f
	entrada.readline()
	$datos["parametro_escala_tiempo_falla"] = entrada.readline().to_f
	entrada.readline()
	$datos["parametro_forma_tiempo_falla"] = entrada.readline().to_f
	entrada.readline()
	$datos["tiempo_control_calidad"] = entrada.readline().to_f 
	entrada.readline()
	$datos["probabilidad_falla_ensamblaje_a"] = entrada.readline().to_f
	entrada.readline()
	$datos["probabilidad_falla_ensamblaje_b"] = entrada.readline().to_f 
	entrada.readline()
	$datos["umbral_falla_para_cambio_$modo"] = entrada.readline().to_f	
	entrada.readline()
	$datos["cantidad_empacadores"] = entrada.readline().to_f       
	entrada.readline()
	$datos["minutos_a_simular"] = entrada.readline().to_f
	entrada.readline()
	$datos["cantidad_corridas"] = entrada.readline().to_f 
	entrada.close()
end    

def generar_tiempo_empaque()
	suma = 0
	12.times{ suma += rand() }
	return suma/12.0 + 0.5 
end
	
def generar_tiempo_ensamble():
	if $modo == "a"
		return RubySimF::Random.triangular(:min => $datos["ensamblaje_distribucion_min_a"], \
		:max => $datos["ensamblaje_distribucion_max_a"], \
		:mode => $datos["ensamblaje_distribucion_moda_a"]) 
	end
	return RubySimF::Random.triangular(:min => $datos["ensamblaje_distribucion_min_b"], \
	:max => $datos["ensamblaje_distribucion_max_b"], \
	:mode => $datos["ensamblaje_distribucion_moda_b"]) 
end

def generar_falla_arranque()
	return RubySimF::Random.bernoulli(:probability_of_success => $datos["probabilidad_falla_ensamblaje_a"]) if $modo == "a"
	return RubySimF::Random.bernoulli(:probability_of_success =>$datos["probabilidad_falla_ensamblaje_b"])         
end
	
def generar_tiempo_falla()
	return weibullvariate($datos["parametro_escala_tiempo_falla"],\
	$datos["parametro_forma_tiempo_falla"])*60.0   
end
	
def generar_cantidad_despachar():
	contador = -1
	acum = 0.0
	while acum < 1
		contador += 1
		acum += RubySimF::Random.exponential(:lambda => $datos["media_demanda_despacho"]) 
	end  
	return contador
end

class Maquina
  
  attr_reader :falla_arranque, :tiempo_falla_componentes
    
	def initialize(name):
		@name = name
		@tiempo_falla_componentes = generar_tiempo_falla()  
		@falla_arranque = generar_falla_arranque()
		@creada_en = $sim.now
	end
		
	def procesar() 
		if RubySimF::Random.bernoulli(
		  :probability_of_success => $datos["porcentaje_ir_a_control_calidad"]) 
			$cola_control << self  
			largo_cola = 0       
			if $cola_control.size > $datos["tamano_lote_control_calidad"]
				largo_cola = ($cola_control.size - $datos["tamano_lote_control_calidad"])
			end 
			$monitor_contro << largo_cola
			if $probador_esperando
				$probador_esperando = false
				$sim.reactivate_process_of($probador)
			end
			$sim.passivate_process_of(self) 
		traza()
		$empaque.request()
		traza() 
		tiempo_empaque = generar_tiempo_empaque()
		$sim.wait tiempo_empaque
		$empaque.release    
		traza()
		$tiempo_servicio +=  tiempo_empaque 
		$monitor_tiempo << ($sim.now-@creada_en) 
		$empacadas += 1
		$almacen << self 
		traza()  
	end
end

$sim.declare_process Maquina, :procesar
		
class Probador
	def probar 
		while true
			if $cola_control.size >= $datos["tamano_lote_control_calidad"]
				$sim.wait $datos["tiempo_control_calidad"]
				traza()
				$datos["tamano_lote_control_calidad"].to_i.times{
					$probadas += 1
					maquina = $cola_control.delete_at(0)       
					if maquina.falla_arranque  
						$fallan_en_prueba += 1 
						maquina.dispose
					else
						if maquina.tiempo_falla_componentes<$datos["tiempo_control_calidad"]
							$fallan_en_prueba += 1 
							maquina.dispose  
						else        
							reactivate(maquina)  
						end
				  end  
				}
				if ($datos["umbral_falla_para_cambio_$modo"] < $fallan_en_prueba*1.0/$probadas) \
				&& $modo == "a"
					$modo = "b"   
				if $ensamblaje_parado
					$ensamblaje_parado = false
					$sim.reactivate_process_of($ensamblador)     
				end
			else   
				$probador_esperando = true
  			$sim.passivate_process_of(self) 
			end 
		end
	end
end

$sim.declare_process Probador, :probar
						
class Ensamblador
	def ensamblar 
		while true   
			if $cola_control.size >= ($datos["capacidad_$cola_control_calidad"] +\
			 $datos["tamano_lote_control_calidad"])
				$ensamblaje_parado = true
				$sim.passivate_process_of(self) 
			else
				m = Maquina.new("Maquina %i" % $contador_maquinas)  
				$contador_maquinas += 1
				$sim.wait generar_tiempo_ensamble()
				$ensambladas += 1
				m.procesar 
				traza()
			end  
		end
	end
end 

$sim.declare_process Emsamblador, :ensamblar

class Despachador
	def despachar
		while true
			$sim.wait $datos["intervalo_despacho"] 
			$monitor_almacen << $almacen.size
			demanda = generar_cantidad_despachar()   
			a_sacar = demanda
			if demanda > $almacen.size
				a_sacar = $almacen.size 
		 		$demanda_insatisfecha += (demanda - $almacen.size) 
		 	end       
			a_sacar.times{ maquina = $almacen.delete_at(0) }
			$despachadas += a_sacar   
			traza() 
		end
	end
end  

$sim.declare_process Despachador, :despachar

				
def simular_corrida
	$sim.init 
	$ensamblador.ensamblar
	$probador.probar
	$despachador.despachar
	$sim.simulate(:until =>$datos["minutos_a_simular"])  
end 

def inicializar_corrida
	$monitor_control = RubySimF::Collector.new  
	$monitor_tiempo = RubySimF::Collector.new
	$monitor_almacen = RubySimF::Collector.new
	$empaque = RubySimF::Resource.new(:number_of_servers => $datos["cantidad_empacadores"],\
	name => "empaque")
	$almacen = []                       
	$ensambladas = 0    
	$despachadas = 0
	$probadas = 0
	$fallan_en_prueba = 0
	$contador_maquinas = 1
	$empacadas = 0
	$demanda_insatisfecha = 0
	$cola_control = []     
	$probador_esperando = False  
	$ensamblaje_parado = False
	$ensamblador = Ensamblador(name="$ensamblador")
	$probador = Probador(name="$probador")
	$despachador = Despachador(name="$despachador")     
	$modo = "a"
	$tiempo_servicio = 0
	
def mostrar_resultados_corrida():      
	global salida  
	p1 = 0
	p2 = 0
	if $empaque.waitMon.count() > 0:
		p1 = max($empaque.waitMon.yseries())    
		p2 = $empaque.waitMon.timeAverage()
	salida.write("%i|%i|%i|%i|%i|%i|%.2f|%i|%.2f|%i|%i|%.2f|%.2f|%.2f|%.2f|%.2f\n"%(
	$ensambladas,$probadas,$fallan_en_prueba, $empacadas,
	$despachadas,$demanda_insatisfecha,$monitor_control.timeAverage(),
	max($monitor_control.yseries()), p2, p1, 
	max($monitor_almacen.yseries()),$monitor_tiempo.mean(), 
	max($monitor_tiempo.yseries()),
	min($monitor_tiempo.yseries()),percentil($monitor_tiempo.yseries(),0.5),
	100.0*$tiempo_servicio/($datos["cantidad_empacadores"]*$sim.now)
	))   

$datos = {}       
leer_entrada()      
salida = open("salida.txt", "w")  
salida_traza = open("traza.txt", "w")  
salida.write("$ensambladas|$probadas|desechadas|$empacadas|")
salida.write("$despachadas|demanda_instatisfecha|promedio_$cola_control_calidad|")
salida.write("max_$cola_control_calidad|promedio_cola_$empaque|max_cola_$empaque|")
salida.write("max_$almacen|promedio_tiempo_produccion|max_tiempo_produccion|")
salida.write("min_tiempo_produccion|p50_tiempo_produccion|")
salida.write("promedio_porcentaje_ocupacion\n")
salida_traza.write("hora|$modo_produccion|cantidad_area_control_calidad|cantidad_area_$empaque|cantidad_$almacen\n")
for i in range(int($datos["cantidad_corridas"])):
	corrida = i+1
	print "corrida %i"%(corrida)
	inicializar_corrida()
	simular_corrida()
	mostrar_resultados_corrida()  
salida.close()
salida_traza.close() 

 