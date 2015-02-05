require 'rubysimf'
$taquillas = RubySimF::Resource.new(:number_of_servers => 1, :name => "banco") 

class Cliente
  def visitar()
    $taquillas.request   
    tiempo_servicio = RubySimF::Random.exponential(:lambda =>4)  
    $sim.wait(tiempo_servicio)
    $taquillas.release
  end   
end
     
class Generador
  def generar
    while $sim.now() < 2000 
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

puts $taquillas.wq   #mean_waiting_time 
puts $taquillas.ws #mean_system_time
puts $taquillas.lq #mean_queue_length
puts $taquillas.ls #mean_system_length