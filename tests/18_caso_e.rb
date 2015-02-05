require 'rubysimf' 
require 'rubysimf_modules/queue_systems'

class Cliente
end

$sim = RubySimF::Simulator.instance
k=1
p=0.8

v_tiempo_interarribo = RubySimF::Random::ExponentialVariate.new :lambda => 10
v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 12

mundo_exterior = RubySimF::QueueSystems::Source.new( 
  :class => Cliente,
  :interarrival_time_random_variate => v_tiempo_interarribo,
  :until_clock_is => 30)

oficina_banco = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        

mundo_exterior.deliver_to oficina_banco

oficina_banco.declare_output_method{|cliente|
  u = rand()  
  if u <= p                     
    puts "volvio a entrar"
    oficina_banco.admit cliente
  else
    puts "salio"
  end  
} 
mundo_exterior.generate
$sim.simulate

puts "Promedio de clientes en cola 1: #{oficina_banco.lq}" 

#ojo deberiamos probar el stop simulation

