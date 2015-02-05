require 'rubysimf'
require 'rubysimf_modules/queue_systems'

class Cliente
end

$sim = RubySimF::Simulator.instance

v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 3
v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 4

servidor = RubySimF::QueueSystems::BasicQueueSystem.new(
  :name => "banco",
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => 2
  )   

mundo_exterior = RubySimF::QueueSystems::Source.new( 
  :name => "mundo_exterior",
  :class => Cliente,
  :interarrival_time_random_variate => v_tiempo_interarribo,
  :until_clock_is => 20,
  :deliver_to => servidor
)

mundo_exterior.generate
$sim.simulate
puts servidor.wq
puts servidor.ws
puts servidor.lq
puts servidor.ls