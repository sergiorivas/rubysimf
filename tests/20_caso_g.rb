require 'rubysimf' 
require 'rubysimf_modules/queue_systems'

class Cliente1
end

class Cliente2
end

$sim = RubySimF::Simulator.instance
k=1
p=0.8
r=0.3   

v_tiempo_interarribo_1 = RubySimF::Random::ExponentialVariate.new :lambda => 10
v_tiempo_interarribo_2 = RubySimF::Random::ExponentialVariate.new :lambda => 5
v_tiempo_interarribo_3 = RubySimF::Random::ExponentialVariate.new :lambda => 2

v_tiempo_servicio = RubySimF::Random::ExponentialVariate.new :lambda => 12

oficina_banco_a = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        

oficina_banco_b = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        

oficina_banco_c = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        

oficina_banco_d = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        

oficina_banco_e = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        

oficina_banco_f = RubySimF::QueueSystems::BasicQueueSystem.new(
  :service_time_random_variate => v_tiempo_servicio,
  :number_of_servers => k)        

mundo_exterior_1 = RubySimF::QueueSystems::Source.new( 
  :class => Cliente1,
  :interarrival_time_random_variate => v_tiempo_interarribo_1,
  :deliver_to => oficina_banco_a)

mundo_exterior_2 = RubySimF::QueueSystems::Source.new( 
  :class => Cliente2,
  :interarrival_time_random_variate => v_tiempo_interarribo_2,
  :deliver_to => oficina_banco_b)

mundo_exterior_3 = RubySimF::QueueSystems::Source.new( 
  :class => Cliente1,
  :interarrival_time_random_variate => v_tiempo_interarribo_3,
  :deliver_to => oficina_banco_c)

oficina_banco_a.deliver_to oficina_banco_c
oficina_banco_b.deliver_to oficina_banco_c
oficina_banco_c.declare_output_method{ |cliente|
  u = rand()
  if u <= r
    oficina_banco_d.admit cliente
  else
    oficina_banco_f.admit cliente
  end
}
oficina_banco_d.deliver_to oficina_banco_e
oficina_banco_f.declare_output_method{ |cliente|
  u = rand()
  if u <= p
    oficina_banco_b.admit cliente  
  else
    puts "salio por f"
  end
} 

oficina_banco_e.declare_output_method{ |cliente|
  puts "salio por e"
}

mundo_exterior_1.generate  
mundo_exterior_2.generate
mundo_exterior_3.generate

$sim.simulate :until => 50

puts "Promedio de clientes en cola a: #{oficina_banco_a.lq}" 
puts "Promedio de clientes en cola b: #{oficina_banco_b.lq}" 
puts "Promedio de clientes en cola c: #{oficina_banco_c.lq}" 
puts "Promedio de clientes en cola d: #{oficina_banco_d.lq}" 
puts "Promedio de clientes en cola e: #{oficina_banco_e.lq}" 
puts "Promedio de clientes en cola f: #{oficina_banco_f.lq}" 
