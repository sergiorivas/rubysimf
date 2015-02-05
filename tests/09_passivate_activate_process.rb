require 'rubysimf_with_trace'

class Cliente
  
  def initialize(name)
    @name = name
  end
  
  def visitar(a)
    $sim.wait 4
    if @name == "c2"       
      $sim.wait 3
      $sim.reactivate_process_of $gen 
      $sim.wait 7
      puts "fin visitar2"
    end 
    puts "fin visitar #{a}"
  end   
end
     
class Generador
  def generar
    c1 = Cliente.new("c1")
    c1.visitar(1)
    $sim.wait 2 
    c2 = Cliente.new("c2") 
    $sim.passivate_process_of c1
    c2.visitar(22)   
    $sim.passivate_process_of self    
    $sim.wait 2 
  end 
end

#principal
$sim = RubySimF::Simulator.instance
$sim.declare_process Generador, :generar  
$sim.declare_process Cliente, :visitar
$gen = Generador.new
$gen.generar  
$sim.simulate