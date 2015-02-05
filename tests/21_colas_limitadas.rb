require 'rubysimf_with_trace' 
require 'rubysimf_modules/queue_systems'

class Cliente
end

$sim = RubySimF::Simulator.instance
k=1 

v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 10

v_tiempo_servicio_1 = RubySimF::Random::ExponentialVariate.new :lambda => 2
v_tiempo_servicio_2 = RubySimF::Random::ExponentialVariate.new :lambda => 1


mundo_exterior = RubySimF::QueueSystems::Source.new( 
  :class => Cliente,
  :interarrival_time_random_variate => v_tiempo_interarribo,
  :until_clock_is => 10)

oficina_banco_1 = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio_1,
  :number_of_servers => k)        

oficina_banco_2 = RubySimF::QueueSystems::BasicQueueSystem.new(
  :name => "banco2",
  :service_time_random_variate => v_tiempo_servicio_2,
  :number_of_servers => k,
  :queue_capacity => 5)   
mundo_exterior.deliver_to oficina_banco_1
oficina_banco_1.deliver_to oficina_banco_2
oficina_banco_2.declare_output_method{|cliente|
  puts "salio #{cliente}"
  
}
mundo_exterior.generate
$sim.simulate

puts "Promedio de clientes en cola 1: #{oficina_banco_1.ls}"
puts "Promedio de clientes en cola 2: #{oficina_banco_2.ls}"
