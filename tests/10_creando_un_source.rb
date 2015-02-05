require 'rubysimf'
require  'rubysimf_modules/queue_systems'

class Cliente
end

$sim = RubySimF::Simulator.instance

v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 10

mundo_exterior = RubySimF::QueueSystems::Source.new( 
  :name => "mundo_exterior",
  :class => Cliente,
  :interarrival_time_random_variate => v_tiempo_interarribo,
  :until_clock_is => 5
)

mundo_exterior.declare_output_method{|generado|
  puts $sim.now, generado.inspect
}

mundo_exterior.generate
$sim.simulate
