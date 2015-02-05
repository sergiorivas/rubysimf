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

v_tiempo_interarribo_1 = RubySimF::Random::ExponentialVariate.new :lambda => 10
v_tiempo_interarribo_2 = RubySimF::Random::ExponentialVariate.new :lambda => 5
v_tiempo_interarribo_3 = RubySimF::Random::ExponentialVariate.new :lambda => 2

v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 12

oficina_banco = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        


mundo_exterior_1 = RubySimF::QueueSystems::Source.new( 
  :class => Cliente1,
  :interarrival_time_random_variate => v_tiempo_interarribo_1,
  :until_clock_is => 10,
  :deliver_to => oficina_banco)

mundo_exterior_2 = RubySimF::QueueSystems::Source.new( 
  :class => Cliente2,
  :interarrival_time_random_variate => v_tiempo_interarribo_2,
  :until_clock_is => 10,
  :deliver_to => oficina_banco)

mundo_exterior_3 = RubySimF::QueueSystems::Source.new( 
  :class => Cliente3,
  :interarrival_time_random_variate => v_tiempo_interarribo_3,
  :until_clock_is => 10,
  :deliver_to => oficina_banco)

oficina_banco.declare_output_method{|cliente|
  puts cliente.class 
} 
mundo_exterior_1.generate  
mundo_exterior_2.generate
mundo_exterior_3.generate

$sim.simulate

puts "Promedio de clientes en cola 1: #{oficina_banco.lq}" 

#ojo deberiamos probar el stop simulation

