require 'rubysimf' 
require 'rubysimf_modules/queue_systems'

class Cliente
end

sim = RubySimF::Simulator.instance
contador_clientes = 1

v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 10
v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 12

mundo_exterior = RubySimF::QueueSystems::Source.new( 
  :class => Cliente,
  :interarrival_time_random_variate => v_tiempo_interarribo)

oficina_banco = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => 1)        
  
mundo_exterior.deliver_to oficina_banco   

oficina_banco.declare_output_method{|cliente|
  puts contador_clientes
  contador_clientes += 1
  sim.stop if contador_clientes > 3
}
 
mundo_exterior.generate
sim.simulate :until => 1

puts "Promedio de clientes en cola: #{oficina_banco.lq}"
