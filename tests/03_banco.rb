require 'rubysimf_with_debug_trace'

$client_id = 1
$queue = []
$busy_office = false

class Exterior
  def generate
    while $sim.now < 20    
      c = Client.new
      c.request_service($client_id)
      $client_id += 1
      interarrival_time = generate_interarrival_time() 
      puts "interarrival_time: #{interarrival_time}"
      $sim.wait(interarrival_time)
    end
  end 
end
   
class Client
  def request_service(client)
    puts "#{$sim.now()}: Attend the client: #{client}"
    if $busy_office
      $queue << client
    else
      $busy_office = true  
      consume_service(client)
    end
  end 
  
  def consume_service(client)  
    service_time = generate_service_time()   
    puts "service_time: #{service_time}"
    $sim.wait(service_time)
    puts "#{$sim.now()}: Client left: #{client}"
    if $queue.empty?
      $busy_office = false
    else
      next_client = $queue.delete_at(0) #saca el primero y lo borra    
      consume_service(next_client)
    end
  end
  
end

def generate_interarrival_time
  rand(5)+1 #aleatorio uniforme 1 a 6
end

def generate_service_time
  rand(3)+1 #aleatorio uniforme 1 a 4
end

$sim = RubySimF::Simulator.instance
$sim.declare_process Exterior, :generate   
$sim.declare_process Client, :request_service       
universe = Exterior.new
universe.generate  
$sim.simulate
