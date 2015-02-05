require 'rubysimf'
require 'rubysimf_modules/queue_systems'

class Cliente
end

$sim = RubySimF::Simulator.instance

v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 3.5
v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 4

$servidores = RubySimF::QueueSystems::SerieQueueSystem.new(
  :name => "banco",
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => 1,
  :number_of_servers => 3 
  )        
  
$servidores.declare_output_method{|client| 
  puts "salio el cliente #{client.inspect}"
}

mundo_exterior = RubySimF::QueueSystems::Source.new( 
  :name => "mundo_exterior",
  :class => Cliente,
  :interarrival_time_random_variate => v_tiempo_interarribo,
  :until_clock_is => 200,
  :deliver_to => $servidores
)

mundo_exterior.generate
$sim.simulate
puts $servidores.servers.first.wq
puts $servidores.servers[1].wq
puts $servidores.servers.last.wq
puts
puts $servidores.servers.first.lq
puts $servidores.servers[1].lq
puts $servidores.servers.last.lq