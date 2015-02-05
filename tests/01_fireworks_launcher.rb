require 'rubysimf'

class FireworkLauncher 
  
  def launch_rocket_a(name_of_rocket)
    puts "Turn on (#{name_of_rocket}): #{$sim.now}"
    $sim.wait 2  
    puts "Start elevation of (#{name_of_rocket}): #{$sim.now}"
    $sim.wait 10
    puts "Boom! (#{name_of_rocket}): #{$sim.now}"
  end

  def launch_rocket_b
    puts "Turn on (rocket2): #{$sim.now}"
    $sim.wait 3  
    puts "Start elevation (rocket2): #{$sim.now}"
    $sim.wait 5
    puts "Exploits (rocket2) YELLOW: #{$sim.now}"
    $sim.wait 3
    puts "Exploits (rocket2) BLUE: #{$sim.now}"
    $sim.wait 3
    puts "Exploits (rocket2) RED: #{$sim.now}"
  end 
  
end

$sim = RubySimF::Simulator.instance
$sim.declare_process FireworkLauncher, :launch_rocket_a  
$sim.declare_process FireworkLauncher, :launch_rocket_b

l1 = FireworkLauncher.new
l2 = FireworkLauncher.new
l1.launch_rocket_a("rocket1")
l2.launch_rocket_b

$sim.simulate