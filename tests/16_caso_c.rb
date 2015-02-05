require 'rubysimf' 
require 'rubysimf_modules/queue_systems'

class Cliente
end

$sim = RubySimF::Simulator.instance
k=2 

v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 11
v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 12

mundo_exterior = RubySimF::QueueSystems::Source.new( 
  :class => Cliente,
  :interarrival_time_random_variate => v_tiempo_interarribo,
  :until_clock_is => 100)

oficina_banco_1 = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        

oficina_banco_2 = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        

oficina_banco_3 = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        
  
mundo_exterior.deliver_to oficina_banco_1
oficina_banco_1.deliver_to oficina_banco_2
oficina_banco_2.deliver_to oficina_banco_3
mundo_exterior.generate
$sim.simulate

puts "Promedio de clientes en cola 1: #{oficina_banco_1.lq}"
puts "Promedio de clientes en cola 2: #{oficina_banco_2.lq}"
puts "Promedio de clientes en cola 3: #{oficina_banco_3.lq}"

