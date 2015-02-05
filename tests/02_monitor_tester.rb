require 'rubysimf'

$m = RubySimF::Collector.new


class FireworkLauncher 
     
  
  def launch_rocket_a(name_of_rocket)
    puts "Turn on (#{name_of_rocket}): #{$sim.now}"
    $m << 123
    $sim.wait 2  
    puts "Start elevation of (#{name_of_rocket}): #{$sim.now}"     
    $m << 124
    $sim.wait 10
    puts "Boom! (#{name_of_rocket}): #{$sim.now}"
  end
  
end

$sim = RubySimF::Simulator.instance
$sim.declare_process FireworkLauncher, :launch_rocket_a  
l1 = FireworkLauncher.new  
l1.launch_rocket_a("r1")
$sim.simulate                  

#arreglar