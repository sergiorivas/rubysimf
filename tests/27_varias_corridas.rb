require 'rubysimf' 
require 'rubysimf_modules/queue_systems'

class Cliente
end

$sim = RubySimF::Simulator.instance
$nro_clientes = 1

$v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 10
$v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 12

$recolector = RubySimF::Collector.new

def simular
  $sim.init

  $mundo_exterior = RubySimF::QueueSystems::Source.new( 
    :class => Cliente,
    :interarrival_time_random_variate => $v_tiempo_interarribo,
    :population_limit => 10)

  $oficina_banco = RubySimF::QueueSystems::BasicQueueSystem.new(
    :service_time_random_variate => $v_tiempo_servicio,
    :number_of_servers => 1)        

  $mundo_exterior.deliver_to $oficina_banco   

  $oficina_banco.declare_output_method{|cliente|
    puts $nro_clientes
    $nro_clientes +=1
  } 

  $mundo_exterior.generate               
  $sim.simulate :until => 10
  puts "Promedio de clientes en cola: #{$oficina_banco.lq}"
  $recolector << $oficina_banco.lq
end
 
30.times{|x|
  simular 
} 
puts "Promedio de clientes en cola (TODAS corridas): #{$recolector.mean}"

  
