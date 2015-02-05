require 'rubysimf'

$taquilla = RubySimF::Resource.new(:number_of_servers => 1, :name => "banco") 

class Cliente
  def visitar()
    $taquilla.request_until_time(0.25)
    puts $taquilla.acquired? 
    tiempo_servicio = RubySimF::Random.exponential(:lambda =>4)  
    $sim.wait(tiempo_servicio)
    $taquilla.release
  end   
end
     
class Generador
  def generar
    while $sim.now() < 20
      c = Cliente.new
      c.visitar
      tiempo_interarribo = RubySimF::Random.exponential(:lambda =>3) 
      $sim.wait(tiempo_interarribo)
    end
  end 
end

#principal
$sim = RubySimF::Simulator.instance
$sim.declare_process Generador, :generar   
$sim.declare_process Cliente, :visitar       
gen = Generador.new
gen.generar  
$sim.simulate                       

puts $taquilla.mean_waiting_time 
puts $taquilla.mean_system_time
puts $taquilla.mean_queue_length
puts $taquilla.mean_system_length