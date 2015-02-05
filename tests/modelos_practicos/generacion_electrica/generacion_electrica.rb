=begin
Proyecto de la materia probabilidades y estadistica v15
=end
require "rubysimf"

class SuperMonitor
  def initialize(meses)
    @meses = meses
    @variable = {}
  end
  def declare(var)
    @variable[var] = []
    @meses.times{ @variable[var] << RubySimF::Collector.new }
  end
      
  def observe(var,mes,valor)
    @variable[var][mes] << valor*1.0 
  end
  
  def mean(var,mes)
    @variable[var][mes].mean
  end
  
  def desv(var,mes)
    @variable[var][mes].standard_desviation
  end
    
  def min(var,mes)
    @variable[var][mes].min
  end                  
  
  def max(var,mes)
    @variable[var][mes].max
  end
    
  def percentil(var,mes,perc)
    @variable[var][mes].percentile(perc)
  end
      
  def median(var,mes)
    @variable[var][mes].median
  end             
  
  def p25(var,mes)
    @variable[var][mes].percentile(0.25)  
  end     
  
  def p75(var,mes)
    @variable[var][mes].percentile(0.75)  
  end
end 
     
#============================= CONSTANTES ==========================================================
TEMPORADA_LLUVIA = 'll'
TEMPORADA_SEQUIA = 's'
TEMPORADA_INTERMEDIA = 'i'
MIN = 'min'
MAX = 'max'
MODA = 'moda'
APORTE = 'aporte'
COTAS_EMBALSE = 'cotas'
INICIAL = 'inicial'
CONSUMO = 'consumo'
TURBINAS = 'turbinas'
CANTIDAD = 'cantidad'
POTENCIA = 'potencia'
CRECIMIENTO = 'crecimiento'
EFICIENCIA = 'eficiencia'
NRO_MESES_A_SIMULAR = 'nmas'
NRO_CORRIDAS = 'nc'
CORRIDA = 'corrida'
CAPACIDAD = 'capacidad'
EMBALSE = 'embalse'
OTRAS_FUENTES = 'otras-fuentes'
SUPERFICIE = 'superficie'
FRACCION_UTIL = 'fraccion-util'
PROYECTOS = 'proyectos'
NOMBRE = 'nombre'
INICIO = 'inicio'
MES = 'mes'
ALTURA_ACTUAL = 'altura-actual'
TEMPORADA = 'temporada'
CAUDAL_RIO = 'caudal-rio'
POTENCIA_PROYECTOS = 'potencia-proyectos'
POTENCIA_OTRAS_FUENTES = 'potencia-otras-fuentes'
ENERGIA_OTRAS_FUENTES = 'energia-otras-fuentes'
DEMANDA_NACIONAL = 'demanda-nacional'
DEMANDA_EMBALSE = 'demanda-embalse'
ENERGIA_EMBALSE = 'energia-embalse'
CAUDAL_TURBINADO = 'caudal-turbinado'
CAUDAL_NETO = 'caudal-neto'
DELTA_H = 'delta-h'
DEMANDA_INSATISFECHA = 'demanda-insatisfecha'
POTENCIA_MAXIMA_HIDROELECTRICA = 'potencia-maxima-hidroelectrica'
EFICIENCIA_MINIMA = 'eficiencia-minima'
EFICIENCIA_MAXIMA = 'eficiencia-maxima'
HORAS_GENERADAS_MES = 'horas-generadas-mes'
RETRASO = 'retraso'

#=============================== PARAMETROS ======================================================
TEMPORADA_MESES = [TEMPORADA_INTERMEDIA, TEMPORADA_SEQUIA, TEMPORADA_SEQUIA, TEMPORADA_SEQUIA, 
                  TEMPORADA_SEQUIA, TEMPORADA_LLUVIA, TEMPORADA_LLUVIA, TEMPORADA_LLUVIA,
                  TEMPORADA_LLUVIA, TEMPORADA_INTERMEDIA, TEMPORADA_INTERMEDIA, TEMPORADA_INTERMEDIA]
$parametros = {}
$parametros[COTAS_EMBALSE]={}
$parametros[APORTE] = { TEMPORADA_LLUVIA => {}, TEMPORADA_SEQUIA => {},
 TEMPORADA_INTERMEDIA => {} }
$parametros[CONSUMO] = {}
$parametros[TURBINAS] = {}
$parametros[CORRIDA] = {}
$parametros[EMBALSE] ={}
$parametros[CAPACIDAD] = {}
$proyectos = []

#=============================== VARIABLES GLOBALES ================================================
$cabecera = "Mes (#)\tEpoca del anho (S,L,I)\tNivel de agua en embalse (msnm)\t"+\
"Eficiencia de las turbinas (F)\tCaudal del rio (m3/s)\tPotencia de proyecto(s) del mes (MW)\t"+\
"Potencia disponible de otras fuentes (MW)\tDemanda total de energia (GWh)\t"+\
"Energia generada por otras fuentes (GWh)\tDemanda de energia de la represa (GWh)\t"+\
"Caudal turbinado (m3/s)\tEnergia generada por la represa (GWh)\tDemanda de energia insatisfecha (Gwh)"

$mon = nil

#=============================== FUNCIONES Y RUTINAS ===============================================
def iniciar_corrida()
  $potencia_proyectos = 0
  $altura_actual = $parametros[COTAS_EMBALSE][INICIAL]
  cargar_proyectos()  
end

def recalcular_nivel(mes)
  $mon.observe(ALTURA_ACTUAL,mes,$altura_actual)
  
  temporada = TEMPORADA_MESES[mes%12]

  #demanda GWh
  demanda_nacional = RubySimF::Random.triangular(
    :min => $parametros[CONSUMO][MIN]*((1+$parametros[CONSUMO][CRECIMIENTO])**mes),
    :max => $parametros[CONSUMO][MAX]*((1+$parametros[CONSUMO][CRECIMIENTO])**mes),
    :mode => $parametros[CONSUMO][MODA]*((1+$parametros[CONSUMO][CRECIMIENTO])**mes)
  )
  $mon.observe(DEMANDA_NACIONAL,mes,demanda_nacional)  

  #MW
  potencia_requerida = energia_a_potencia(demanda_nacional)

  #considerando otros proyectos
  proys = proyectos_a_ejecutar(mes)
  potencia_proyectos_mes = 0
  proys.size.times{|i| potencia_proyectos_mes += proys[i][POTENCIA] }
  $potencia_proyectos += potencia_proyectos_mes
  $mon.observe(POTENCIA_PROYECTOS,mes,potencia_proyectos_mes)

  potencia_otras_fuentes = $parametros[CAPACIDAD][OTRAS_FUENTES] + $potencia_proyectos
  $mon.observe(POTENCIA_OTRAS_FUENTES,mes,potencia_otras_fuentes)
  $mon.observe(ENERGIA_OTRAS_FUENTES,mes,potencia_a_energia(potencia_otras_fuentes))
  
  potencia_requerida_embalse = potencia_requerida - potencia_otras_fuentes
  $mon.observe(DEMANDA_EMBALSE,mes,potencia_a_energia(potencia_requerida_embalse))

  potencia_maxima_embalse = $parametros[POTENCIA_MAXIMA_HIDROELECTRICA]
  
  potencia_insatisfecha_por_capacidad = 0
  if potencia_requerida_embalse > potencia_maxima_embalse
    potencia_insatisfecha_por_capacidad = potencia_requerida_embalse - potencia_maxima_embalse
    potencia_requerida_embalse = potencia_maxima_embalse 
  end
  
  eficiencia = nivel_a_eficiencia($altura_actual)
  $mon.observe(EFICIENCIA,mes,eficiencia)
  
  caudal_a_turbinar = potencia_requerida_embalse/eficiencia
  
  #ingreso
  cuadal_ingreso_rio = RubySimF::Random.triangular( #m^3/s
    :min => $parametros[APORTE][temporada][MIN],
    :max => $parametros[APORTE][temporada][MAX],
    :mode => $parametros[APORTE][temporada][MODA]
  )
  $mon.observe(CAUDAL_RIO,mes,cuadal_ingreso_rio)
  
  caudal_neto_a_turbinar = cuadal_ingreso_rio - caudal_a_turbinar
      
  delta_h_hipotetico = caudal_a_nivel(caudal_neto_a_turbinar)
  caudal_embalse = 0
  
  potencia_insatisfecha_por_nivel = 0
  if $altura_actual + delta_h_hipotetico < $parametros[COTAS_EMBALSE][MIN]    
    delta_h_insatisfecho = $altura_actual + delta_h_hipotetico - $parametros[COTAS_EMBALSE][MIN]
    delta_h = $altura_actual - $parametros[COTAS_EMBALSE][MIN]
    caudal_embalse = nivel_a_caudal(delta_h)
    potencia_insatisfecha_por_nivel = (caudal_neto_a_turbinar-caudal_embalse).abs*eficiencia
    $altura_actual = $parametros[COTAS_EMBALSE][MIN]
  elsif $altura_actual + delta_h_hipotetico > $parametros[COTAS_EMBALSE][MAX]
    delta_h = $parametros[COTAS_EMBALSE][MAX] - $altura_actual
    caudal_embalse = nivel_a_caudal(delta_h)
    $altura_actual = $parametros[COTAS_EMBALSE][MAX]
  else
    caudal_embalse = caudal_neto_a_turbinar.abs
    delta_h = delta_h_hipotetico
    $altura_actual += delta_h  
  end
  
  caudal_posible = cuadal_ingreso_rio + caudal_embalse
  caudal_turbinado = 0
  if caudal_a_turbinar > caudal_posible
    caudal_turbinado = caudal_posible
  else
    caudal_turbinado = caudal_a_turbinar  
  end

  $mon.observe(CAUDAL_TURBINADO,mes,caudal_turbinado)
  $mon.observe(ENERGIA_EMBALSE,mes,potencia_a_energia(caudal_turbinado*eficiencia))

  potencia_insatisfecha = potencia_insatisfecha_por_capacidad + potencia_insatisfecha_por_nivel
  energia_insatisfecha = potencia_a_energia(potencia_insatisfecha)
  $mon.observe(DEMANDA_INSATISFECHA,mes,energia_insatisfecha) 
end
    
def energia_a_potencia(energia) #GWh -> MW
  return (energia/($parametros[HORAS_GENERADAS_MES]))*1000.0
end
  
def potencia_a_energia(energia) #MW -> GWh
  return (energia*($parametros[HORAS_GENERADAS_MES]))/1000.0
end

def caudal_a_nivel(caudal)
  return caudal*SEGUNDOS_EN_EL_MES/SUPERFICIE_M2   
end
  
def nivel_a_caudal(nivel)
  return SUPERFICIE_M2*nivel/SEGUNDOS_EN_EL_MES
end


def nivel_a_eficiencia(h)
  return $parametros[EFICIENCIA_MINIMA]  + (
    ($parametros[EFICIENCIA_MAXIMA] - $parametros[EFICIENCIA_MINIMA])* \
    (h - $parametros[COTAS_EMBALSE][MIN]) / \
    ($parametros[COTAS_EMBALSE][MAX] - $parametros[COTAS_EMBALSE][MIN]) ) 
end
  
def simular_corrida()
  $parametros[CORRIDA][NRO_MESES_A_SIMULAR].times{|mes| recalcular_nivel(mes) }
end
   
def cargar_proyectos()
  $proyectos.size.times{|i|
    retraso = RubySimF::Random.exponential(:lambda => 1.0).to_i
    $proyectos[i][RETRASO] = retraso 
  } 
end

def proyectos_a_ejecutar(mes)
  ret = []
  $proyectos.size.times{|i|
    ret << $proyectos[i] if ($proyectos[i][INICIO]+$proyectos[i][RETRASO]) == mes 
  }
  return ret 
end
  
def simular()
  $parametros[CORRIDA][NRO_CORRIDAS].times{|corrida|
    puts "corrida %i"%(corrida+1)
    iniciar_corrida
    simular_corrida
    escribir_salida if corrida == 0
  }   
end
    
def escribir_resultados
  salida1 = File.open(direccion_archivo("promedios.txt"),"w")
  salida2 = File.open(direccion_archivo("minimos.txt"),"w")
  salida3 = File.open(direccion_archivo("maximos.txt"),"w")
  salida4 = File.open(direccion_archivo("medianas.txt"),"w")
  salida5 = File.open(direccion_archivo("percentiles25.txt"),"w")
  salida6 = File.open(direccion_archivo("percentiles75.txt"),"w")
  salida7 = File.open(direccion_archivo("desviaciones.txt"),"w")
  
  salida1.puts($cabecera)
  salida2.puts($cabecera)
  salida3.puts($cabecera)
  salida4.puts($cabecera)
  salida5.puts($cabecera)
  salida6.puts($cabecera)
  salida7.puts($cabecera)
  $parametros[CORRIDA][NRO_MESES_A_SIMULAR].times{|i|
    salida1.printf("%i\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t\n",\
      i,TEMPORADA_MESES[i%12], $mon.mean(ALTURA_ACTUAL,i), \
      $mon.mean(EFICIENCIA,i), $mon.mean(CAUDAL_RIO,i), $mon.mean(POTENCIA_PROYECTOS,i), \
      $mon.mean(POTENCIA_OTRAS_FUENTES,i), $mon.mean(DEMANDA_NACIONAL,i), \
      $mon.mean(ENERGIA_OTRAS_FUENTES,i), $mon.mean(DEMANDA_EMBALSE,i), \
      $mon.mean(CAUDAL_TURBINADO,i), $mon.mean(ENERGIA_EMBALSE,i), $mon.mean(DEMANDA_INSATISFECHA,i)\
      )
    salida2.printf("%i\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t\n",\
      i,TEMPORADA_MESES[i%12], $mon.min(ALTURA_ACTUAL,i), \
      $mon.min(EFICIENCIA,i), $mon.min(CAUDAL_RIO,i), $mon.min(POTENCIA_PROYECTOS,i), \
      $mon.min(POTENCIA_OTRAS_FUENTES,i), $mon.min(DEMANDA_NACIONAL,i), \
      $mon.min(ENERGIA_OTRAS_FUENTES,i), $mon.min(DEMANDA_EMBALSE,i), \
      $mon.min(CAUDAL_TURBINADO,i), $mon.min(ENERGIA_EMBALSE,i), $mon.min(DEMANDA_INSATISFECHA,i)\
      )
    salida3.printf("%i\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t\n",\
      i,TEMPORADA_MESES[i%12], $mon.max(ALTURA_ACTUAL,i), \
      $mon.max(EFICIENCIA,i), $mon.max(CAUDAL_RIO,i), $mon.max(POTENCIA_PROYECTOS,i), \
      $mon.max(POTENCIA_OTRAS_FUENTES,i), $mon.max(DEMANDA_NACIONAL,i), \
      $mon.max(ENERGIA_OTRAS_FUENTES,i), $mon.max(DEMANDA_EMBALSE,i), \
      $mon.max(CAUDAL_TURBINADO,i), $mon.max(ENERGIA_EMBALSE,i), $mon.max(DEMANDA_INSATISFECHA,i)\
      )
    salida4.printf("%i\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t\n",\
      i,TEMPORADA_MESES[i%12], $mon.median(ALTURA_ACTUAL,i), \
      $mon.median(EFICIENCIA,i), $mon.median(CAUDAL_RIO,i), $mon.median(POTENCIA_PROYECTOS,i), \
      $mon.median(POTENCIA_OTRAS_FUENTES,i), $mon.median(DEMANDA_NACIONAL,i), \
      $mon.median(ENERGIA_OTRAS_FUENTES,i), $mon.median(DEMANDA_EMBALSE,i), \
      $mon.median(CAUDAL_TURBINADO,i), $mon.median(ENERGIA_EMBALSE,i), $mon.median(DEMANDA_INSATISFECHA,i)\
      )
    salida5.printf("%i\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t\n",\
      i,TEMPORADA_MESES[i%12], $mon.p25(ALTURA_ACTUAL,i), \
      $mon.p25(EFICIENCIA,i), $mon.p25(CAUDAL_RIO,i), $mon.p25(POTENCIA_PROYECTOS,i), \
      $mon.p25(POTENCIA_OTRAS_FUENTES,i), $mon.p25(DEMANDA_NACIONAL,i), \
      $mon.p25(ENERGIA_OTRAS_FUENTES,i), $mon.p25(DEMANDA_EMBALSE,i), \
      $mon.p25(CAUDAL_TURBINADO,i), $mon.p25(ENERGIA_EMBALSE,i), $mon.p25(DEMANDA_INSATISFECHA,i)\
      )
    salida6.printf("%i\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t\n",\
      i,TEMPORADA_MESES[i%12], $mon.p75(ALTURA_ACTUAL,i), \
      $mon.p75(EFICIENCIA,i), $mon.p75(CAUDAL_RIO,i), $mon.p75(POTENCIA_PROYECTOS,i), \
      $mon.p75(POTENCIA_OTRAS_FUENTES,i), $mon.p75(DEMANDA_NACIONAL,i), \
      $mon.p75(ENERGIA_OTRAS_FUENTES,i), $mon.p75(DEMANDA_EMBALSE,i), \
      $mon.p75(CAUDAL_TURBINADO,i), $mon.p75(ENERGIA_EMBALSE,i), $mon.p75(DEMANDA_INSATISFECHA,i)\
      )
    salida7.printf("%i\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t\n",\
      i,TEMPORADA_MESES[i%12], $mon.desv(ALTURA_ACTUAL,i), \
      $mon.desv(EFICIENCIA,i), $mon.desv(CAUDAL_RIO,i), $mon.desv(POTENCIA_PROYECTOS,i), \
      $mon.desv(POTENCIA_OTRAS_FUENTES,i), $mon.desv(DEMANDA_NACIONAL,i), \
      $mon.desv(ENERGIA_OTRAS_FUENTES,i), $mon.desv(DEMANDA_EMBALSE,i), \
      $mon.desv(CAUDAL_TURBINADO,i), $mon.desv(ENERGIA_EMBALSE,i), $mon.desv(DEMANDA_INSATISFECHA,i)\
      )
  }
  salida1.close()
  salida2.close()
  salida3.close()
  salida4.close()
  salida5.close()
  salida6.close()
  salida7.close()
end

def escribir_salida()
  salida1 = File.open(direccion_archivo("salida.txt"),"w")
  salida1.puts($cabecera)
  $parametros[CORRIDA][NRO_MESES_A_SIMULAR].times{|i|
    salida1.printf("%i\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t\n",\
      i,TEMPORADA_MESES[i%12], $mon.mean(ALTURA_ACTUAL,i), \
      $mon.mean(EFICIENCIA,i), $mon.mean(CAUDAL_RIO,i), $mon.mean(POTENCIA_PROYECTOS,i), \
      $mon.mean(POTENCIA_OTRAS_FUENTES,i), $mon.mean(DEMANDA_NACIONAL,i), \
      $mon.mean(ENERGIA_OTRAS_FUENTES,i), $mon.mean(DEMANDA_EMBALSE,i), \
      $mon.mean(CAUDAL_TURBINADO,i), $mon.mean(ENERGIA_EMBALSE,i), $mon.mean(DEMANDA_INSATISFECHA,i)\
      )         
  }
  salida1.close()  
end
  

def leer_valor(x)
  return x.to_f
end
  
def cargar_entrada
  entrada = open(direccion_archivo("entrada.txt"),"r")
  entrada.readline()
  $parametros[POTENCIA_MAXIMA_HIDROELECTRICA] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[CAPACIDAD][OTRAS_FUENTES] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[EMBALSE][SUPERFICIE] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[EFICIENCIA_MINIMA] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[EFICIENCIA_MAXIMA] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[COTAS_EMBALSE][MIN] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[COTAS_EMBALSE][MAX] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[APORTE][TEMPORADA_SEQUIA][MIN] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[APORTE][TEMPORADA_SEQUIA][MODA] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[APORTE][TEMPORADA_SEQUIA][MAX] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[APORTE][TEMPORADA_LLUVIA][MIN] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[APORTE][TEMPORADA_LLUVIA][MODA] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[APORTE][TEMPORADA_LLUVIA][MAX] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[APORTE][TEMPORADA_INTERMEDIA][MIN] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[APORTE][TEMPORADA_INTERMEDIA][MODA] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[APORTE][TEMPORADA_INTERMEDIA][MAX] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[HORAS_GENERADAS_MES] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[CONSUMO][MIN] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[CONSUMO][MODA] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[CONSUMO][MAX] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[CONSUMO][CRECIMIENTO] = leer_valor(entrada.readline())/100.0
  entrada.readline()
  $parametros[CORRIDA][NRO_MESES_A_SIMULAR] = leer_valor(entrada.readline()).to_i * 12
  entrada.readline()
  $parametros[COTAS_EMBALSE][INICIAL] = leer_valor(entrada.readline())
  entrada.readline()
  $parametros[CORRIDA][NRO_CORRIDAS] = leer_valor(entrada.readline()).to_i
  entrada.readline()
  entrada.readline()
  linea = entrada.readline()
  begin
    while linea != nil and linea != ""
      datos = linea.split()
      nombre = datos[0]
      potencia = datos[1].to_i
      inicio = datos[2].to_i
      proy = { NOMBRE => nombre, POTENCIA => potencia, INICIO => inicio, RETRASO => 0 }
      $proyectos << proy
      linea = entrada.readline()  
    end 
  rescue
  end
  $mon = SuperMonitor.new($parametros[CORRIDA][NRO_MESES_A_SIMULAR])
  $mon.declare(ALTURA_ACTUAL)
  $mon.declare(EFICIENCIA)
  $mon.declare(CAUDAL_RIO)
  $mon.declare(POTENCIA_PROYECTOS)
  $mon.declare(POTENCIA_OTRAS_FUENTES)
  $mon.declare(DEMANDA_NACIONAL)
  $mon.declare(ENERGIA_OTRAS_FUENTES)
  $mon.declare(DEMANDA_EMBALSE)
  $mon.declare(CAUDAL_TURBINADO)
  $mon.declare(ENERGIA_EMBALSE)
  $mon.declare(DEMANDA_INSATISFECHA)
  entrada.close()
end

def direccion_archivo(archivo)
  File.expand_path("./#{archivo}",File.dirname(__FILE__)).to_s
end

#====================================== PROGRAMA PRINCIPAL =========================================
cargar_entrada()
SEGUNDOS_EN_EL_MES = $parametros[HORAS_GENERADAS_MES] * 3600.0
SUPERFICIE_M2 = $parametros[EMBALSE][SUPERFICIE] * 1000000.0 
simular()
escribir_resultados()