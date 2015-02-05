require 'rubysimf_with_trace' 
require 'rubysimf_modules/queue_systems'

class Cliente
end

$sim = RubySimF::Simulator.instance

v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 10
v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 12
v_tamano_lote = RubySimF::Random::GeometricVariate.new :probability_of_success => 0.5


mundo_exterior = RubySimF::QueueSystems::Source.new( 
  :class => Cliente,
  :interarrival_time_random_variate => v_tiempo_interarribo,
  :bulk_size_variate => v_tamano_lote)

oficina_banco = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => 1)        
  
mundo_exterior.deliver_to oficina_banco   
 
mundo_exterior.generate
$sim.simulate :until => 1

puts "Promedio de clientes en cola: #{oficina_banco.lq}"
