require 'rubysimf' 
require 'rubysimf_modules/queue_systems'

class Cliente
  attr_accessor :hora_llegada, :hora_salida1, :hora_final
end

def simular(nro_corrida, lambda, mu1, mu2, mu3, p)
  puts "Corrida #{nro_corrida}" 
  $nro_clientes = 0

  $recolectoru_wst = RubySimF::Collector.new
  $recolectoru_wss = RubySimF::Collector.new


  $sim = RubySimF::Simulator.instance
  $sim.init

  $v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => lambda
  $v_tiempo_servicio1 = RubySimF::Random::ExponentialVariate.new :lambda => mu1
  $v_tiempo_servicio2 = RubySimF::Random::ExponentialVariate.new :lambda => mu2
  $v_tiempo_servicio3 = RubySimF::Random::ExponentialVariate.new :lambda => mu3

  $fuente = RubySimF::QueueSystems::Source.new( 
    :class => Cliente,
    :interarrival_time_random_variate => $v_tiempo_interarribo)

  $sistema1 = RubySimF::QueueSystems::BasicQueueSystem.new(
    :service_time_random_variate => $v_tiempo_servicio1,
    :number_of_servers => 2)
    
  $sistema2 = RubySimF::QueueSystems::BasicQueueSystem.new(
    :service_time_random_variate => $v_tiempo_servicio2,
    :number_of_servers => 2)
      
  $sistema3 = RubySimF::QueueSystems::BasicQueueSystem.new(
    :service_time_random_variate => $v_tiempo_servicio3,
    :number_of_servers => 1)        

  $fuente.declare_output_method{|cliente|   
    cliente.hora_llegada=$sim.now
    $sistema1.admit cliente
  }
  
  $sistema1.declare_output_method{|cliente|   
    cliente.hora_salida1=$sim.now
    if RubySimF::Random.bernoulli(p) == 1
      $sistema2.admit cliente
    else
      $sistema3.admit cliente   
    end
  }

  $sistema2.declare_output_method{|cliente|
    cliente.hora_final=$sim.now
    #puts "Cliente #{$nro_clientes} servido"
    $nro_clientes +=1
    $nro_clientes_global +=1
    
    $sim.statistics_on if $nro_clientes == $clientes_a_descartar  
    $sim.stop if $nro_clientes == $clientes_por_corrida  
    
    if $nro_clientes >= $clientes_a_descartar
      $recolectoru_wst << (cliente.hora_final - cliente.hora_llegada) 
      $recolectoru_wss << (cliente.hora_salida1 - cliente.hora_llegada)  
    end
  }
  
  $sistema3.declare_output_method{|cliente|
    cliente.hora_final=$sim.now
    #puts "Cliente #{$nro_clientes} servido"
    $nro_clientes +=1
    $nro_clientes_global +=1
    
    $sim.statistics_on if $nro_clientes == $clientes_a_descartar  
    $sim.stop if $nro_clientes == $clientes_por_corrida

    if $nro_clientes >= $clientes_a_descartar
      $recolectoru_wst << (cliente.hora_final - cliente.hora_llegada) 
      $recolectoru_wss << (cliente.hora_salida1 - cliente.hora_llegada)  
    end
  } 

  $fuente.generate               
  $sim.simulate :statistics_on => false

  $recolector_ls1 << $sistema1.ls
  $recolector_lq1 << $sistema1.lq
  $recolector_wq1 << $sistema1.wq
  $recolector_ws1 << $sistema1.ws
  $recolector_ls2 << $sistema2.ls
  $recolector_lq2 << $sistema2.lq
  $recolector_wq2 << $sistema2.wq
  $recolector_ws2 << $sistema2.ws
  $recolector_ls3 << $sistema3.ls
  $recolector_lq3 << $sistema3.lq
  $recolector_wq3 << $sistema3.wq
  $recolector_ws3 << $sistema3.ws 
  $recolector_wst << $recolectoru_wst.mean()
  $recolector_wss << $recolectoru_wss.mean()
  
end             


#principal
$clientes_por_corrida = 21000
$clientes_a_descartar = 1000  
$parametros = []  
$parametros << { :archivo => "salidac_01.txt",
    :lambda => 100, :mu1 => 111, :mu2 => 53, :mu3 => 150, :p => 0.7}
$parametros << { :archivo => "salidac_02.txt",
    :lambda => 100, :mu1 => 55, :mu2 => 23, :mu3 => 700, :p => 0.3}

$nro_clientes_global = 1  

$parametros.each{|para|
  $recolector_lq1 = RubySimF::Collector.new
  $recolector_ls1 = RubySimF::Collector.new
  $recolector_wq1 = RubySimF::Collector.new
  $recolector_ws1 = RubySimF::Collector.new     
  $recolector_lq2 = RubySimF::Collector.new
  $recolector_ls2 = RubySimF::Collector.new
  $recolector_wq2 = RubySimF::Collector.new
  $recolector_ws2 = RubySimF::Collector.new
  $recolector_lq3 = RubySimF::Collector.new
  $recolector_ls3 = RubySimF::Collector.new
  $recolector_wq3 = RubySimF::Collector.new
  $recolector_ws3 = RubySimF::Collector.new 
  $recolector_wst = RubySimF::Collector.new #sistema total
  $recolector_wss = RubySimF::Collector.new #subsistema
  
  $corrida = 1     
  while $corrida <=100    
    simular($corrida, para[:lambda], para[:mu1], para[:mu2], para[:mu3], para[:p])   
    File.open(para[:archivo], "a") { |archivo| 
      archivo.puts "nro_corridas|lq1|ls1|wq1|ws1|lq2|ls2|wq2|ws2|lq3|ls3|wq3|ws3|wss|wst" if $corrida == 1
      archivo.puts "#{$corrida}|#{$recolector_lq1.mean}|#{$recolector_ls1.mean}|#{$recolector_wq1.mean}|#{$recolector_ws1.mean}||#{$recolector_lq2.mean}|#{$recolector_ls2.mean}|#{$recolector_wq2.mean}|#{$recolector_ws2.mean}|#{$recolector_lq3.mean}|#{$recolector_ls3.mean}|#{$recolector_wq3.mean}|#{$recolector_ws3.mean}|#{$recolector_wss.mean}|#{$recolector_wst.mean}"      
    }
    $corrida += 1
  end                                      
}    

  
