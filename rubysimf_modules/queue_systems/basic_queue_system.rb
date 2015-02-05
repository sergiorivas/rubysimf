class RubySimF::QueueSystems::BasicQueueSystem   
  
  def deliver_to(target)
    @deliver_to = target
  end
       
  def add_dependient(object)
    sim = RubySimF::Simulator.instance  
    log = RubySimF::Logger.instance   
    log.info("Basic queue system <#{@name}> has a dependient to wakeup <#{object}>", sim.now)
    @dependients << object
  end
  
  def release_dependients    
    sim = RubySimF::Simulator.instance
    log = RubySimF::Logger.instance   
     
    @dependients.each{|x| 
      log.info("Basic queue system <#{@name}> has a unblocked <#{x}>", sim.now) 
      sim.reactivate_process_of(x)
    }           
    @dependients = []
  end
  
  def initialize(params={})
    begin 
      @@id += 1 
    rescue
      @@id = 0
    end
   
    defaults = {  
      :name => "basic_queue_system_#{@@id}",
      :service_time_random_variate => nil,             
      :number_of_servers => 1,
      :deliver_to => nil,
      :queue_capacity => nil,
    }                        
    
    params = defaults.merge params
    @name = params[:name]
    @number_of_servers = params[:number_of_servers]
    @queue_capacity = params[:queue_capacity]
    @service_time_random_variate = params[:service_time_random_variate]    
    @server = RubySimF::Resource.new(:number_of_servers => @number_of_servers, 
      :name => "#{@name}_resource",
      :queue_capacity => @queue_capacity) 
    @output_block = nil
    @deliver_to = params[:deliver_to]    
    @dependients = []  
    
  end
  
  def can_admit?
    @server.can_request?
  end                                         
  
  def admit(client, params = {})
    params = {} unless params
    defaults = {
      :priority => RubySimF::Constants::DEFAULT_PRIORITY,
      :preemptive => false
    }  
    params = defaults.merge(params)
    priority = params[:priority]  
    preemptive = params[:preemptive] 

    sim = RubySimF::Simulator.instance 
    log = RubySimF::Logger.instance   
    log.info("Basic queue system <#{@name}> is admitting to <#{client}>", sim.now) 
    @server.request :priority => priority, :preemptive => preemptive
    sim.wait(@service_time_random_variate.generate_value)
    release_dependients     
    @server.release
    if @deliver_to    
      delivered = false
      while !delivered do
        if @deliver_to.can_admit?
          @deliver_to.admit(client, 
            :priority => priority, 
            :preemptive => preemptive)
          delivered = true
        else     
          log.info("Basic queue system <#{@name}> is blocked because the system <#{@deliver_to}> is full", sim.now) 
          @deliver_to.add_dependient self
          sim.passivate_process_of self
          Thread.stop  
        end
      end
    else
      @output_block.call client if @output_block 
    end
    log.info("Basic queue system <#{@name}> is release the <#{client}>", sim.now) 
  end           
  
  def declare_output_method &block  
    sim = RubySimF::Simulator.instance 
    RubySimF::Logger.instance.info("Declaring output method on basic queue system <#{@name}>", sim.now) 
    @output_block = block
  end  
  
  auto_methods = %w{wq lq ws ls mean_queue_length mean_system_length mean_waiting_time mean_system_time}   
  auto_methods.each{|m|
    define_method(m.to_sym){
      @server.send m.to_sym
    }
  }

end  

RubySimF::Simulator.instance.declare_process RubySimF::QueueSystems::BasicQueueSystem, :admit   
