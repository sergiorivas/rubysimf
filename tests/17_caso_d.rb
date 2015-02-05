require 'rubysimf' 
require 'rubysimf_modules/queue_systems'

class Cliente
end

$sim = RubySimF::Simulator.instance
k=2
p=0.5
q=0.7 

v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 10
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
  
mundo_exterior.declare_output_method{|cliente|
  u = rand()  
  if u <= p
    oficina_banco_1.admit cliente
  elsif u <= q
    oficina_banco_2.admit cliente
  else
    oficina_banco_3.admit cliente
  end  
} 
mundo_exterior.generate
$sim.simulate

puts "Promedio de clientes en cola 1: #{oficina_banco_1.lq}"
puts "Promedio de clientes en cola 2: #{oficina_banco_2.lq}"
puts "Promedio de clientes en cola 3: #{oficina_banco_3.lq}"

