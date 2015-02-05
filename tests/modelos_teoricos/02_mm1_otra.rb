require 'rubysimf' 
require 'rubysimf_modules/queue_systems'

class Cliente
end

def simular(nro_corrida, lambda, mu1, mu2, mu3, p)
  puts "Corrida #{nro_corrida}" 
  $nro_clientes = 0

  $sim = RubySimF::Simulator.instance
  $sim.init

  $v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => lambda
  $v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => mu

  $mundo_exterior = RubySimF::QueueSystems::Source.new( 
    :class => Cliente,
    :interarrival_time_random_variate => $v_tiempo_interarribo)

  $oficina_banco = RubySimF::QueueSystems::BasicQueueSystem.new(
    :service_time_random_variate => $v_tiempo_servicio,
    :number_of_servers => k)        

  $mundo_exterior.deliver_to $oficina_banco   

  $oficina_banco.declare_output_method{|cliente|
    #puts "Cliente #{$nro_clientes} servido"
    $nro_clientes +=1
    $nro_clientes_global +=1
    
    $sim.statistics_on if $nro_clientes == $clientes_a_descartar  
    $sim.stop if $nro_clientes == $clientes_por_corrida
  } 

  $mundo_exterior.generate               
  $sim.simulate :statistics_on => false

  $recolector_ls << $oficina_banco.ls
  $recolector_lq << $oficina_banco.lq
  $recolector_wq << $oficina_banco.wq
  $recolector_ws << $oficina_banco.ws
end             


def converge(ls_real)
  return false if $corrida < 3
  $porcentaje_tope = 1
  if $recolector_ls.mean && $recolector_ls.standard_desviation
    $diferencia = ($recolector_ls.mean-ls_real).abs
    $epsilon = $porcentaje_tope/100.0 * ls_real
    $desv = $recolector_ls.standard_desviation
    return $desv <= $diferencia && $diferencia <= $epsilon
  else
    return false
  end
end

#principal
$clientes_por_corrida = 21000
$clientes_a_descartar = 1000  
$parametros = []  
$parametros << { :archivo => "salida_201.txt",
    :lambda => 2, :mu => 3, :k => 1, :ls_real => 2}
$parametros << { :archivo => "salida_202.txt",
    :lambda => 100, :mu => 101, :k => 1, :ls_real => 100}
$parametros << { :archivo => "salida_203.txt",
    :lambda => 10, :mu => 100, :k => 1, :ls_real => 0.1111}

=begin
$parametros << { :lambda => 100, :mu => 101, :k => 1}
$parametros << { :lambda => 10, :mu => 100, :k => 1}
$parametros << { :lambda => 2, :mu => 3, :k => 2}
$parametros << { :lambda => 100, :mu => 101, :k => 2}
$parametros << { :lambda => 10, :mu => 100, :k => 2}
$parametros << { :lambda => 2, :mu => 3, :k => 4}
$parametros << { :lambda => 100, :mu => 101, :k => 4}
$parametros << { :lambda => 10, :mu => 100, :k => 4}
$parametros << { :lambda => 2, :mu => 3, :k => 8}
$parametros << { :lambda => 100, :mu => 101, :k => 8}
$parametros << { :lambda => 10, :mu => 100, :k => 8}
=end

$nro_clientes_global = 1  
$diferencia = 1000000
$epsilon = 1000
$desv = 1000000000

$parametros.each{|para|
  $recolector_lq = RubySimF::Collector.new
  $recolector_ls = RubySimF::Collector.new
  $recolector_wq = RubySimF::Collector.new
  $recolector_ws = RubySimF::Collector.new
  $corrida = 1     
  while $corrida <=100#!converge para[:ls_real]
    simular($corrida, para[:lambda], para[:mu], para[:k])   
    File.open(para[:archivo], "a") { |archivo| 
      archivo.puts "nro_corridas|desviacion|diferencia|epsilon|lambda|mu|k|lq|ls|wq|ws" if $corrida == 1
      archivo.puts "#{$corrida}|#{$desv}|#{$diferencia}|#{$epsilon}|#{para[:lambda]}|#{para[:mu]}|#{para[:k]}|#{$recolector_lq.mean}|#{$recolector_ls.mean}|#{$recolector_wq.mean}|#{$recolector_ws.mean}"      
    }
    $corrida += 1
  end                                      
}    

  
