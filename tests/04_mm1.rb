require 'rubysimf'

$bank_office = RubySimF::Resource.new(:number_of_servers => 2, :name => "bank") #Prebuilt entity provided by RubySimF
$customer_observer = RubySimF::Collector.new #Collector provided by RubySimF
$queue_time_customer_observer = RubySimF::Collector.new #Collector provided by RubySimF

class Customer
  def visit()
    arrival_time = $sim.now # Gives the simulation clock
    $bank_office.request   
    
    $queue_time_customer_observer << ($sim.now - arrival_time)
    t = RubySimF::Random.exponential(:lambda =>4)  #is provided by RubySimF
    $sim.wait(t)
    
    
    $bank_office.release
    total_time = $sim.now()-arrival_time
    $customer_observer << total_time 
  end   
end
     
class Generator
  def generate
    while $sim.now() < 50
      t = RubySimF::Random.exponential(:lambda =>3) 
      $sim.wait(t)
      c = Customer.new
      c.visit
    end
  end 
end

$sim = RubySimF::Simulator.instance
$sim.declare_process Generator, :generate   
$sim.declare_process Customer, :visit       

gen = Generator.new
gen.generate  
$sim.simulate           

puts "Average of customer queue time in system: #{$queue_time_customer_observer.mean}"
puts "Average of customer time in system: #{$customer_observer.mean}"