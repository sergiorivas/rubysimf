=begin
Proyecto Proba 02-2009
=end
require "rubysimf"  


class MultiMonitor
  def initialize
    @mon = {} 
  end
  
  def append(nombre)
    @mon[nombre] = RubySimF::Collector.new
  end
  
  def observe(nombre,valor)
    @mon[nombre] << valor
  end 
  
  def get(nombre)
    return @mon[nombre]
  end
end

$minutos_a_simular = 8*60 #8 horas
$minutos_a_ignorar = 6*60 #6 horas
$theta = 0.177 #tiempo promedio interarribo (minutos)
$c = 10 #cantidad de cajas en el supermercado
$r = 2  #cantidad de cajas rapidas en el supermercado
$cajas = [] #arreglo de cajas
$cantidad_articulos_limite = 10 #cantidad de articulos para las cajas rapidas
$valor_grande = 300000
$nro_corridas = 100
$mostrar_resultados_por_corrida = false
$mostrar_resultados_globales = true
    
$monitor_corrida = MultiMonitor.new
$monitor_global = MultiMonitor.new
$monitor_clientes = MultiMonitor.new
$monitor_clientes_prom = RubySimF::Collector.new

$cantidad_clientes_no_hacen_cola = 0
$cantidad_clientes_en_el_supermercado = 0
$max_clientes_en_el_supermercado = 0

$z975 = 1.96 

$cantidad_clientes_sin_cola = 0
$cantidad_clientes_servidos = 0


def generar_cantidad_articulos()
  p = [0.0235,0.0242,0.0251,0.0257,0.0265,0.0271,0.0277,0.0283,0.0287,0.029,
  0.0295,0.0297,0.0298,0.03,0.03,0.03,0.0298,0.0297,0.0295,0.029,
  0.0287,0.0283,0.0277,0.0271,0.0265,0.0257,0.0251,0.0242,0.0235,0.0227,
  0.0218,0.0209,0.02,0.0191,0.0182,0.0173,0.0164,0.0155,0.0146,0.0139]
  return RubySimF::Random.empirical(:probabilities => p) + 1
end
  
def generar_mu_de_pago(n) #segundos
  p = [0.1, 0.25, 0.15, 0.5]
  vals = [60, 30*Math.sqrt(n), 180, 120]
  return vals[RubySimF::Random.empirical(:probabilities => p)]
end

class Generador
  def generar
    i = 1
    while true
      t = RubySimF::Random.exponential :lambda => (1.0/$theta)
      $sim.wait t
      nombre = "cliente %i"%i
      c = Cliente.new(nombre)
      c.ir_a_caja()
      i += 1  
    end
  end
end                

class Cliente
  
  def initialize(nombre)
    @nombre = nombre
  end
  
  def ir_a_caja
    $cantidad_clientes_en_el_supermercado += 1
    if $max_clientes_en_el_supermercado < $cantidad_clientes_en_el_supermercado
      $max_clientes_en_el_supermercado = $cantidad_clientes_en_el_supermercado  
    end

    tiempo_inicio = $sim.now
    n = generar_cantidad_articulos()    

    #viendo si hay una caja rapida libre
    caja_rapida_libre = false
    i = 0
    i_min = 0

    while i < $r && !caja_rapida_libre
      caja_rapida_libre == ($cajas[i].busy_servers+$cajas[i].queue_size == 0)
      i += 1          
    end  

    if caja_rapida_libre
      i_min = i
    else
      #buscando la caja con menos cola
      min = $valor_grande
      $c.times{|i|
        if i >= $r || n < $cantidad_articulos_limite
          largo_caja_i=($cajas[i].queue_size+$cajas[i].busy_servers)
          if largo_caja_i < min
            min = largo_caja_i
            i_min = i 
          end
        end
      }
    end 
    
            
    if tiempo_inicio > $minutos_a_ignorar
      $cantidad_clientes_sin_cola += 1 if $cajas[i_min].busy_servers == 0
      $cantidad_clientes_servidos += 1   
    end

    
    $cajas[i_min].request
        
    if tiempo_inicio > $minutos_a_ignorar
      $monitor_corrida.get("tpo_cola") << ($sim.now()-tiempo_inicio)
    end
    #calculando el tiempo de servicios
    mu = generar_mu_de_pago(n)/60.0
    tiempo_servicio = ((5.0*Math.sqrt(n))/60.0) + RubySimF::Random.normal(:mu => mu,:sigma => mu/6.0) #minutos
    
    $sim.wait tiempo_servicio
    $cajas[i_min].release
  
    if tiempo_inicio > $minutos_a_ignorar
      if i_min < $r
        $monitor_corrida.get("tpo_servicio_rapido") << tiempo_servicio
        $monitor_global.get("todos_tpo_servicio_rapido") << tiempo_servicio
      else
        $monitor_corrida.get("tpo_servicio_normal") << tiempo_servicio
        $monitor_global.get("todos_tpo_servicio_normal") << tiempo_servicio
      end
    end   
    
    begin
      $monitor_clientes.get(@nombre) << $sim.now()-tiempo_inicio
    rescue
      $monitor_clientes.append @nombre
      $monitor_clientes.get(@nombre) << $sim.now-tiempo_inicio
    end
    
    $monitor_corrida.get("tpo_sis") << $sim.now-tiempo_inicio if $sim.now > $minutos_a_ignorar
    $cantidad_clientes_en_el_supermercado -= 1
  end  
                                                  
end

def modelo()
  
  $monitor_corrida = MultiMonitor.new
  $monitor_corrida.append("tpo_sis")
  $monitor_corrida.append("tpo_cola")
  $monitor_corrida.append("tpo_servicio_rapido")
  $monitor_corrida.append("tpo_servicio_normal")
  
  #iniciar cajas
  $cajas = []
  $c.times{|i|
    nombre_caja = "caja %i"%(i+1)
    $cajas << RubySimF::Resource.new(:capacity => 1, :name => nombre_caja)
  }
  
  $cantidad_clientes_no_hacen_cola = 0
  $cantidad_clientes_en_el_supermercado = 0
  $max_clientes_en_el_supermercado = 0
  
  $sim.init
  $g = Generador.new
  $g.generar()
  $sim.simulate(:until => $minutos_a_simular)
  procesar_resultados()  
end   

  
def procesar_resultado_tiempo(nombre)
  if $monitor_corrida.get(nombre).count() > 0
    $monitor_global.get("min_%s"%nombre) << $monitor_corrida.get(nombre).min 
    $monitor_global.get("max_%s"%nombre) << $monitor_corrida.get(nombre).max 
    $monitor_global.get("prom_%s"%nombre) << $monitor_corrida.get(nombre).mean
    $monitor_global.get("med_%s"%nombre) << $monitor_corrida.get(nombre).median 
    $monitor_global.get("desv_%s"%nombre) << $monitor_corrida.get(nombre).standard_desviation
  end
end
  
def procesar_resultados()
  procesar_resultado_tiempo("tpo_sis")
  procesar_resultado_tiempo("tpo_cola")
  procesar_resultado_tiempo("tpo_servicio_normal")
  procesar_resultado_tiempo("tpo_servicio_rapido")
  $monitor_global.get("todos_promedios_tpo_sis") << $monitor_global.get("prom_tpo_sis").mean
  $monitor_global.get("todos_maximo_numero_clientes_supermercado") << $max_clientes_en_el_supermercado
end
  
def imprimir_resultados_tiempo(monitor,titulo)
  if monitor.count()>0
   printf "%s: min => %.2f, max => %.2f, promedio => %.2f, mediana => %.2f, desviacion => %.2f\n",
    titulo,monitor.min,monitor.max,monitor.mean,monitor.median,monitor.standard_desviation
  else
   printf "%s: -- no hay observaciones --\n",titulo 
  end 
end   

def imprimir_resultados_tiempo_globales(minimo=0.0,maximo=0.0,promedio=0.0,median=0.0,desviacion=0.0,titulo="")
  printf "%s: min => %.2f, max => %.2f, promedio => %.2f, mediana => %.2f, desviacion => %.2f \n", \
    titulo,minimo,maximo,promedio,median,desviacion
end   


def imprimir_resultados_cajas()
  $c.times{ |i|
    if $cajas[i].wait_collector.count > 0
      printf "Longitud cola caja %i: min => %i, max => %i\n", \
      i+1, $cajas[i].wait_collector.min , $cajas[i].wait_collector.max
    else
      printf "Longitud cola caja %i: min => 0, max => 0\n" , (i+1) 
    end
  }
end  
    
def imprimir_resultados_ociosidad(monitor,n_servidores,tiempo,titulo)
  if monitor.count()>0
    printf "Porcentaje de ociosidad %s: %.2f%%\n", \
      titulo,(100-(100*monitor.sum/(n_servidores*tiempo)))
  else
    printf "Porcentaje de ociosidad %s: -- no hay observaciones --\n",titulo 
  end
end  

def imprimir_intervalo_confianza(mon,titulo)
  med = mon.mean() || 0
  lado = $z975*Math.sqrt(mon.variance()/$nro_corridas) rescue 0
  printf "%s: estimador_media => %.2f, intervalo (%.2f , %.2f)\n",titulo,med,med-lado,med+lado  
end   

def imprimir_resultados_corrida
  imprimir_resultados_tiempo($monitor_corrida.get("tpo_sis"),"Tiempo en el sistema")
  imprimir_resultados_tiempo($monitor_corrida.get("tpo_cola"),"Tiempo en cola")
  imprimir_resultados_tiempo($monitor_corrida.get("tpo_servicio_normal"),"Tiempo en servicio (normales)")
  imprimir_resultados_tiempo($monitor_corrida.get("tpo_servicio_rapido"),"Tiempo en servicio (rapidas)")
  imprimir_resultados_cajas()
  imprimir_resultados_ociosidad($monitor_corrida.get("tpo_servicio_normal"),$c-$r,
    $minutos_a_simular-$minutos_a_ignorar,"de cajas normales")
  imprimir_resultados_ociosidad($monitor_corrida.get("tpo_servicio_rapido"),$r,
    $minutos_a_simular-$minutos_a_ignorar,"de cajas rapidas")   
end  
 
def imprimir_medidas_tiempo_globales(nombre,titulo)
  imprimir_resultados_tiempo_globales(
    $monitor_global.get("min_%s"%nombre).mean(), $monitor_global.get("max_%s"%nombre).mean(),
    $monitor_global.get("prom_%s"%nombre).mean(),$monitor_global.get("med_%s"%nombre).mean(),
    $monitor_global.get("desv_%s"%nombre).mean(),titulo)    
end   
  
def imprimir_resultados_globales()
  imprimir_medidas_tiempo_globales("tpo_sis","Promedios de tiempo en el sistema")
  imprimir_medidas_tiempo_globales("tpo_cola","Promedios de tiempo en cola")
  imprimir_medidas_tiempo_globales("tpo_servicio_normal","Promedios de tiempo de servicio (normales)")
  imprimir_medidas_tiempo_globales("tpo_servicio_rapido","Promedios de tiempo de servicio (rapidas)")
  imprimir_resultados_ociosidad($monitor_global.get("todos_tpo_servicio_normal"),$c-$r,
    ($minutos_a_simular-$minutos_a_ignorar)*$nro_corridas,"de cajas normales")
  imprimir_resultados_ociosidad($monitor_global.get("todos_tpo_servicio_rapido"),$r,
    ($minutos_a_simular-$minutos_a_ignorar)*$nro_corridas,"de cajas rapidas")
  imprimir_intervalo_confianza($monitor_global.get("todos_maximo_numero_clientes_supermercado"),
    "Maximo clientes en el supermercado")
  imprimir_intervalo_confianza($monitor_global.get("todos_clientes_no_hacen_cola"),
    "Proporcion de clientes que no hacen cola")
end 
  
  
def comparar_arreglo(a, b)
  return cmp(a[0], b[0])  
end

def iniciar_monitores_tiempo(nombre)
  $monitor_global.append("min_%s"%nombre)
  $monitor_global.append("max_%s"%nombre)
  $monitor_global.append("prom_%s"%nombre)
  $monitor_global.append("med_%s"%nombre)
  $monitor_global.append("desv_%s"%nombre) 
end

def iniciar_monitores()
  iniciar_monitores_tiempo("tpo_sis")
  iniciar_monitores_tiempo("tpo_cola")
  iniciar_monitores_tiempo("tpo_servicio_normal")
  iniciar_monitores_tiempo("tpo_servicio_rapido")  
  $monitor_global.append("todos_tpo_servicio_normal")
  $monitor_global.append("todos_tpo_servicio_rapido")
  $monitor_global.append("todos_promedios_tpo_sis")
  $monitor_global.append("todos_clientes_no_hacen_cola")
  $monitor_global.append("todos_maximo_numero_clientes_supermercado") 
end
  
#programa principal 
$sim = RubySimF::Simulator.instance
$sim.declare_process Generador, :generar
$sim.declare_process Cliente, :ir_a_caja

iniciar_monitores()
$nro_corridas.times{|i|
  puts "------ CORRIDA %i ------"%(i+1)
  modelo()
  imprimir_resultados_corrida() if $mostrar_resultados_por_corrida
}
if $mostrar_resultados_globales
  puts "------ RESULTADOS GLOBALES ------"
  imprimir_resultados_globales() 
end



