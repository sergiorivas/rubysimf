require 'rubysimf' 
require 'rubysimf_modules/queue_systems'

class Cliente
end

$sim = RubySimF::Simulator.instance
k=2 

v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 10
v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 12

mundo_exterior = RubySimF::QueueSystems::Source.new( 
  :class => Cliente,
  :interarrival_time_random_variate => v_tiempo_interarribo,
  :until_clock_is => 100)

oficina_banco = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        
  
mundo_exterior.deliver_to oficina_banco
mundo_exterior.generate
$sim.simulate

puts "Promedio de clientes en cola: #{oficina_banco.lq}"
