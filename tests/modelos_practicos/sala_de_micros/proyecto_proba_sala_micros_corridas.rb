require "rubysimf"

=begin
Proyecto Probabilidad y Estadistica - Semestre 1-2009 - Fase 1

==ENUNCIADO

Desde hace algun tiempo la sala de micros de la Facultad de Ciencias, ha venido 
presentando el problema de la insuficiencia de equipos para satisfacer las necesidades 
de los estudiantes. Para resolver este problema, lo operadores de la sala han planteado 
limitar el tiempo de estancia de cada estudiante a 30 minutos.

Un estudio estadistico del funcionamiento de la sala fue encomendado a los estudiantes de
computacion para modelar este proceso y arrojo los siguientes resultados:

* El numero de computadores es la sala de micros disponibles para el uso de los 
estudiantes es de 20

* El tiempo de estancia que necesita cada estudiante para terminar las tareas que tiene
planificadas, se asume que sigue una distribucion de probabilidad normal con media 40 
minutos y desviacion estandar de 20 minutos. Si el estudiante es sacado de la sala por 
cumplirse su limite de tiempo, no regresa por ese dia. (Nota: Observe que esta variable 
aleatoria puede arrojar valores negativos, por lo tanto tiempos menores a un minuto 
deben descartarse).

* El numero de estudiantes llegan a la sala por hora, sigue una distribucion de Poisson 
conuna tasa promedio lambda(t) que dependiente del tiempo.

El estudio determino que la tasa de llegadas varia dependiendo de la hora del dia en que 
se hizo la medicion. Sabiendo que la sala abre durante 10 horas al dia, de las 8am a 
la 6pm (10 horas) se obtuvieron los siguientes resultados por hora:

Hora, lambda(t) en llegadas por hora
8am-9am, 20 
9am-10am, 25
10am-11am, 40
11am-12m, 30
12m-1pm, 35
1pm-2pm, 42
2pm-3pm, 50
3pm-4pm, 55
4pm-5pm, 45
5pm-6pm, 10

* A las 6 de la tarde se cierra la entrada de nuevos estudiantes, pero a los presentes 
en la sala se les permite continuar segun la normativa impuesta de tiempo de estancia 
en la misma.

* Los estudiantes que llegan a la sala se les asigna una maquina dependiendo de la
disponibilidad de estas. Si al llegar consiguen la sala llena, entran en una cola, son 
atendidos por orden de llegada, y van entrando conforme se van desocupando los 
computadores.

* Cuando un estudiante llega a la cola y la misma tiene un tamanio muy grande, el 
estudiante se va con probabilidad P que depende del tamanio N de dicha cola. 
Si N>10 entonces P=0.8, Si 4<N<11 entonces P=0.4, Si 1<N<5 entonces P=0.2

* Los estudiantes que estan en la cola, no esperan mas de un cierto tiempo que 
se comporta como una variable aleatoria con distribucion de probabilidad triangular 
con minimo 20, moda 50, y maximo 60 minutos. Una vez transcurrido este tiempo, si no 
ha sido atendido aun, el estudiante se retira de la cola y no regresa por ese dia.

=end

#variables globales
$estudiante_tiempo_estancia_maximo = 50
$nro_computadores_en_sala = 30
$estudiante_distribucion_tiempo_estancia = [40,10]
$tasa_de_llegada_por_hora = [40,50,80,60,70,84,100,110,90,20]
$nro_horas_servicio = $tasa_de_llegada_por_hora.size
$estudiante_tolerancia_de_tamano_cola=[[8,0.1],[20,0.2],[10000,0.4]]
$estudiante_distribucion_tolerancia_de_tiempo=[10,30,60]
$nro_dias_a_simular = 300

#globales de control
$m_nro_estudiantes_totales = RubySimF::Collector.new
$m_nro_estudiantes_atendidos = RubySimF::Collector.new
$m_nro_estudiantes_satisfechos = RubySimF::Collector.new
$m_nro_estudiantes_desertores_tamanio_cola = RubySimF::Collector.new
$m_nro_estudiantes_desertores_tiempo_espera = RubySimF::Collector.new
$m_tamano_maximo_cola = RubySimF::Collector.new
$m_tiempo_promedio_en_cola = RubySimF::Collector.new
$m_hora_de_salida = RubySimF::Collector.new

class Portero

  def initialize(modelo)
    @modelo = modelo
  end

  def cerrar_puerta    
    $sim.wait 60*$nro_horas_servicio    
    @modelo.puerta_abierta = false        
  end
end

class GeneradorDeEstudiantes

  def initialize(modelo)
    @modelo = modelo
  end

  def enviar_estudiantes
    i = 0
    while @modelo.puerta_abierta
      estudiante = Estudiante.new("Estudiante %d"%(i+1),@modelo)
      #puts "Generando: #{estudiante.nombre}"
      estudiante.solicitar_maquina
      indice = ($sim.now/60.0).to_i
      tasa_actual = $tasa_de_llegada_por_hora[indice]/60.0
      tiempo_para_proximo_estudiante = RubySimF::Random.exponential(:lambda => tasa_actual)
      $sim.wait tiempo_para_proximo_estudiante
      i = i+1      
    end    
  end
end 


class Estudiante

  attr_reader :nombre 

  def initialize(nombre,modelo)
    @nombre = nombre
    @modelo = modelo
  end

  def solicitar_maquina
    tiempo_de_llegada = $sim.now
    if @modelo.sala.queue_size <=1 || se_encola()
      
      tiempo_maximo_espera = RubySimF::Random.triangular(
      :min => $estudiante_distribucion_tolerancia_de_tiempo[0],
      :mode => $estudiante_distribucion_tolerancia_de_tiempo[2],
      :max => $estudiante_distribucion_tolerancia_de_tiempo[1])
      
      @modelo.sala.request_until_time tiempo_maximo_espera
      
      if @modelo.sala.acquired?
        @modelo.monitor_tiempo_en_cola.observe($sim.now()-tiempo_de_llegada)
        tiempo_de_estancia = obtener_tiempo_estancia()
        if tiempo_de_estancia > $estudiante_tiempo_estancia_maximo
          $sim.wait $estudiante_tiempo_estancia_maximo
        else
          $sim.wait tiempo_de_estancia
          @modelo.nro_estudiantes_satisfechos += 1
        end
        @modelo.sala.release
        @modelo.nro_estudiantes_atendidos += 1
      else
        @modelo.nro_estudiantes_desertores_tiempo_espera += 1
      end
      
    else
      @modelo.nro_estudiantes_desertores_tamanio_cola += 1
    end
    @modelo.nro_estudiantes_totales += 1
  end

  def se_encola
    $estudiante_tolerancia_de_tamano_cola.each{|i|
      if @modelo.sala.queue_size <= i[0]:
        ran = rand()
        return ran >= i[1]
      end
    }
    return true
  end

  def obtener_tiempo_estancia
    t=RubySimF::Random.normal(
    :mu => $estudiante_distribucion_tiempo_estancia[0],
    :sigma => $estudiante_distribucion_tiempo_estancia[1])
    while t < 1
      t=RubySimF::Random.normal(
      :mu => $estudiante_distribucion_tiempo_estancia[0],
      :sigma => $estudiante_distribucion_tiempo_estancia[1])      
    end
    return t
  end
end

class Modelo

  attr_accessor :puerta_abierta, :nro_estudiantes_totales,:nro_estudiantes_atendidos,
    :nro_estudiantes_satisfechos, :nro_estudiantes_desertores_tamanio_cola,
    :nro_estudiantes_desertores_tiempo_espera, :tamano_maximo_cola, 
    :tiempo_promedio_en_cola, :sala, :monitor_tiempo_en_cola

  def initialize
    @puerta_abierta = true
    @nro_estudiantes_totales = 0
    @nro_estudiantes_atendidos = 0
    @nro_estudiantes_satisfechos = 0
    @nro_estudiantes_desertores_tamanio_cola = 0
    @nro_estudiantes_desertores_tiempo_espera = 0
    @tamano_maximo_cola = 0
    @tiempo_promedio_en_cola = 0
    @sala = RubySimF::Resource.new(:number_of_servers => $nro_computadores_en_sala, :name => "Sala de Micros")
    @monitor_tiempo_en_cola = RubySimF::Collector.new
  end

  def correr
    $sim.init
    generador = GeneradorDeEstudiantes.new(self)
    portero = Portero.new(self)
    generador.enviar_estudiantes
    portero.cerrar_puerta
    $sim.simulate :until => $nro_horas_servicio*60+$estudiante_tiempo_estancia_maximo
    observar_resultados
    #mostrar_resultados_corrida
  end
  
  def observar_resultados
    $m_nro_estudiantes_totales.observe(@nro_estudiantes_totales)
    $m_nro_estudiantes_atendidos.observe(@nro_estudiantes_atendidos)
    $m_nro_estudiantes_satisfechos.observe(@nro_estudiantes_satisfechos)
    $m_nro_estudiantes_desertores_tamanio_cola.\
    observe(@nro_estudiantes_desertores_tamanio_cola)
    $m_nro_estudiantes_desertores_tiempo_espera.\
    observe(@nro_estudiantes_desertores_tiempo_espera)
    $m_tamano_maximo_cola.observe(@sala.waiting_time_collector.max)
    $m_tiempo_promedio_en_cola.observe(@monitor_tiempo_en_cola.mean())
    $m_hora_de_salida.observe($sim.now())
  end

  def mostrar_resultados_corrida
    puts "nro_estudiantes_totales %d" % @nro_estudiantes_totales
    puts "nro_estudiantes_atendidos %d" % @nro_estudiantes_atendidos
    puts "nro_estudiantes_satisfechos %d" % @nro_estudiantes_satisfechos
    puts "nro_estudiantes_desertores_tamanio_cola %d" % \
    @nro_estudiantes_desertores_tamanio_cola
    puts "nro_estudiantes_desertores_tiempo_espera %d" % \
    @nro_estudiantes_desertores_tiempo_espera
    puts "tamano_maximo_cola %d" % @sala.wait_monitor.y_series.max
    puts "tiempo_promedio_en_cola %.2f" % @monitor_tiempo_en_cola.mean
    puts "hora de salida del ultimo estudiante %.2f" % ($sim.now)
  end
end

def mostrar_resumen
  puts "nro_estudiantes_totales %.2f" % $m_nro_estudiantes_totales.mean()
  puts "nro_estudiantes_atendidos %.2f" % $m_nro_estudiantes_atendidos.mean()
  puts "nro_estudiantes_satisfechos %.2f" % $m_nro_estudiantes_satisfechos.mean()
  puts "nro_estudiantes_satisfechos desv %.2f" % $m_nro_estudiantes_satisfechos.standard_desviation()
  puts "nro_estudiantes_desertores_tamanio_cola %.2f" % \
  $m_nro_estudiantes_desertores_tamanio_cola.mean()
  puts "nro_estudiantes_desertores_tiempo_espera %.2f" % \
  $m_nro_estudiantes_desertores_tiempo_espera.mean()
  puts "tamano_maximo_cola %.2f" % $m_tamano_maximo_cola.mean()
  puts "tiempo_promedio_en_cola %.2f" % $m_tiempo_promedio_en_cola.mean()
  puts "hora de salida del ultimo estudiante %.2f" % $m_hora_de_salida.mean()
end

$sim = RubySimF::Simulator.instance   
$sim.declare_process Estudiante, :solicitar_maquina
$sim.declare_process GeneradorDeEstudiantes, :enviar_estudiantes
$sim.declare_process Portero, :cerrar_puerta


$nro_dias_a_simular.times{ |i|
  puts "corrida #{i+1}"
  m = Modelo.new
  m.correr
}
mostrar_resumen
