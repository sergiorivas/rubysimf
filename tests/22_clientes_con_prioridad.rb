#require 'rubysimf_with_trace' 
require 'rubysimf' 
require 'rubysimf_modules/queue_systems'

class Cliente1
end

class Cliente2
end

class Cliente3
end

$sim = RubySimF::Simulator.instance
k=1
p=0.8

v_tiempo_interarribo_1 = RubySimF::Random::ExponentialVariate.new :lambda => 3
v_tiempo_interarribo_2 = RubySimF::Random::ExponentialVariate.new :lambda => 3
v_tiempo_interarribo_3 = RubySimF::Random::ExponentialVariate.new :lambda => 3

v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 4

oficina_banco = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        

mundo_exterior_1 = RubySimF::QueueSystems::Source.new( 
  :class => Cliente1, 
  :priority => 1,
  :interarrival_time_random_variate => v_tiempo_interarribo_1,
  :deliver_to => oficina_banco)

mundo_exterior_2 = RubySimF::QueueSystems::Source.new( 
  :class => Cliente2, 
  :priority => 2,
  :interarrival_time_random_variate => v_tiempo_interarribo_2,
  :deliver_to => oficina_banco)

mundo_exterior_3 = RubySimF::QueueSystems::Source.new( 
  :class => Cliente3,
  :interarrival_time_random_variate => v_tiempo_interarribo_3)
  
mundo_exterior_3.declare_output_method{|cliente|
  oficina_banco.admit cliente, :priority => 3
}

oficina_banco.declare_output_method{|cliente|
  puts cliente.class 
} 
mundo_exterior_1.generate 
mundo_exterior_2.generate
mundo_exterior_3.generate

$sim.simulate :until => 20

puts "Promedio de clientes en cola 2: #{oficina_banco.lq}" 

