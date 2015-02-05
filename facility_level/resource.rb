class RubySimF::Resource
  
  attr_reader :wait_queue,:active_list,:wait_collector,:waiting_time_collector
  
  def busy_servers
    @active_list.size
  end                
  
  def queue_size
    @wait_queue.size
  end
  
  def mean_queue_length
    @wait_collector.time_weighted_mean
  end
  
  def mean_system_length
    @active_collector.time_weighted_mean
  end
  
  def mean_waiting_time
    @waiting_time_collector.mean
  end
  
  def mean_system_time
    @system_time_collector.mean
  end 
  
  alias :lq :mean_queue_length
  alias :ls :mean_system_length
  alias :wq :mean_waiting_time
  alias :ws :mean_system_time
  
  def acquired?
    @acquired
  end
  
  def initialize(params={})
    defaults = { :number_of_servers => 1, :name => "Resource", :queue_capacity => nil }
    params = defaults.merge params
    @name = params[:name]
    @active_list = []
    @wait_queue = []
    #@priority_queue = []

    @number_of_servers = params[:number_of_servers] 
    @queue_capacity = params[:queue_capacity]    
    
    @adquired = false
    @wait_collector = RubySimF::Collector.new      
    @active_collector = RubySimF::Collector.new 
    @waiting_time_collector = RubySimF::Collector.new 
    @system_time_collector = RubySimF::Collector.new 
    @arrival_time_list = {}   
  end  
  
  def can_request?  
    if @queue_capacity
      return @wait_queue.size < @queue_capacity
    end
    return true
  end
  
  def request(params={})
    defaults = {
      :priority => RubySimF::Constants::DEFAULT_PRIORITY,
      :preemptive => false
    }  
    params = defaults.merge(params)
    priority = params[:priority]   
    priority ||= RubySimF::Constants::DEFAULT_PRIORITY  
    preemptive = false #preemptive = params[:preemptive]   
    if @queue_capacity
      if @wait_queue.size >= @queue_capacity
        raise RubySimF::Exception::FullQueue.new "Wait queue of resource <#{@name}> is full"
      end 
    end
           
    @acquired = false
    caller = RubySimF::Simulator.instance.current_process
    arrival_time = RubySimF::Simulator.instance.now
    @arrival_time_list[caller.name] = arrival_time
    
    RubySimF::Logger.instance.info(
    "Request of resource <#{@name}> from process: <#{caller.name}>",
    RubySimF::Simulator.instance.now)
    
    RubySimF::Logger.instance.info(
    "Status of <#{@name}> active_list:\nSize: #{@active_list.size}\n[#{@active_list.each{|x| "#{x}"}.join", "}]\n",
    RubySimF::Simulator.instance.now)
    
    RubySimF::Logger.instance.info(
    "Status of <#{@name}> wait_queue:\nSize: #{@wait_queue.size}\n[#{@wait_queue.each{|x| "#{x}"}.join", "}]\n",
    RubySimF::Simulator.instance.now)
    
    if RubySimF::Simulator.instance.save_statistics?
      @wait_collector << @wait_queue.size
      @active_collector << (@wait_queue.size + @active_list.size)
    end

    if (@active_list.size >= @number_of_servers) && 
       (!preemptive || !can_interrupt_process?(priority))
      
      add_to_wait_queue caller, priority   

      RubySimF::Logger.instance.info(
      "<#{caller.name}> has been insert into queue of resource <#{@name}> and bloqued",
      RubySimF::Simulator.instance.now)          
      
      Thread.stop
    else 
      interrupt_served_process(priority) if @active_list.size >= @number_of_servers
      
      @acquired = true
   
      RubySimF::Logger.instance.info(
      "Resource <#{@name}> has been assigned to <#{caller.name}>",
      RubySimF::Simulator.instance.now)
      @active_list << {:process => caller, :priority => priority, :left_time_to_serve => nil }   
    end 
    
    waiting_time = (RubySimF::Simulator.instance.now - arrival_time)
    @waiting_time_collector << waiting_time if RubySimF::Simulator.instance.save_statistics? 
  end

  def request_until_time(delay, params = {})  
    defaults = {
      :priority => RubySimF::Constants::DEFAULT_PRIORITY,
      :preemptive => false
    }  
    params = defaults.merge(params)
    priority = params[:priority]   
    priority ||= RubySimF::Constants::DEFAULT_PRIORITY     
    preemptive = false #preemptive = params[:preemptive]   
    
    if @queue_capacity
      if @wait_queue.size >= @queue_capacity
        raise RubySimF::Exception::FullQueue.new "Wait queue of resource <#{@name}> is full"
      end 
    end
    
    @acquired = false  
    caller = RubySimF::Simulator.instance.current_process
    arrival_time = RubySimF::Simulator.instance.now
    @arrival_time_list[caller.name] = arrival_time
    
    RubySimF::Logger.instance.info(
    "Request until time <#{delay}> of <#{@name}> from <#{caller.name}>",        
    RubySimF::Simulator.instance.now)
 
    RubySimF::Logger.instance.info(
    "Status of <#{@name}> active_list:\nSize: #{@active_list.size}\n[#{@active_list.each{|x| "#{x}"}.join", "}]\n",
    RubySimF::Simulator.instance.now)
    
    RubySimF::Logger.instance.info(
    "Status of <#{@name}> wait_queue:\nSize: #{@wait_queue.size}\n[#{@wait_queue.each{|x| "#{x}"}.join", "}]\n",
    RubySimF::Simulator.instance.now)
   
    if (@active_list.size >= @number_of_servers) && 
       (!preemptive || !can_interrupt_process?(priority))
      if RubySimF::Simulator.instance.save_statistics?
        @wait_collector << @wait_queue.size 
        @active_collector << (@wait_queue.size + @active_list.size)
      end
      add_to_wait_queue caller, priority   
      
      RubySimF::Logger.instance.info(
      "<#{caller.name}> has been insert into queue of resource <#{@name}> and bloqued",
      RubySimF::Simulator.instance.now)
      
      RubySimF::Simulator.instance.wait delay            
    else
      @acquired = true   
      
      RubySimF::Logger.instance.info(
      "Resource <#{@name}> has been assigned to <#{caller.name}>",
      RubySimF::Simulator.instance.now)
      
      @active_list << {:process => caller, :priority => priority, :left_time_to_serve => nil }   
    end   
    waiting_time = (RubySimF::Simulator.instance.now - arrival_time)
    @waiting_time_collector << waiting_time if RubySimF::Simulator.instance.save_statistics?
  end
  
  def release              
    
    caller = RubySimF::Simulator.instance.current_process
    
    RubySimF::Logger.instance.info(
    "Release of resource <#{@name}> from process: <#{caller.name}>",
    RubySimF::Simulator.instance.now)
    
    RubySimF::Logger.instance.info(
    "Status of <#{@name}> active_list:\nSize: #{@active_list.size}\n[#{@active_list.each{|x| "#{x}"}.join", "}]\n",
    RubySimF::Simulator.instance.now)

    RubySimF::Logger.instance.info(
    "Status of <#{@name}> wait_queue:\nSize: #{@wait_queue.size}\n[#{@wait_queue.each{|x| "#{x}"}.join", "}]\n",
    RubySimF::Simulator.instance.now)

    if RubySimF::Simulator.instance.save_statistics?
      @wait_collector << @wait_queue.size
      @active_collector << (@wait_queue.size + @active_list.size)
    end   


    if @active_list.size > 0
      
      #puts "",caller.inspect,@active_list.inspect,""
      #puts
      caller = release_process(caller)
      arrival_time = @arrival_time_list[caller.name]   
      system_time = (RubySimF::Simulator.instance.now - arrival_time) 
      
      @arrival_time_list.delete_if{|x,y| x == caller.name}  
      
      @system_time_collector << system_time if RubySimF::Simulator.instance.save_statistics?
       
      
      RubySimF::Logger.instance.info(
      "Remove <#{caller.name}> of active list of <#{@name}>",
      RubySimF::Simulator.instance.now)          
 
      if @wait_queue.size > 0    
        
        
        node = @wait_queue.delete_at(0)             
        caller = node[:process]

        RubySimF::Logger.instance.info(
        "<#{caller.name}> has been remove from queue of resource <#{@name}> and activated",
        RubySimF::Simulator.instance.now)     
        
        @active_list << {:process => caller, :priority => node[:priority], :left_time_to_serve => nil  }   
        
        @acquired = true
        
        RubySimF::Simulator.instance.activate_process(caller,
        RubySimF::Simulator.instance.now)

      end      
    else
      raise RubySimF::Exception::ReleaseWithoutRequest.new "Release resource with not request"
    end
  end
  
  private 
  
  def add_to_wait_queue(object, priority, left_time_to_serve = nil)  
    i = 0                               
    found = false   
    pos = nil
    while (i < @wait_queue.size) && !found 
      if @wait_queue[i][:priority] < priority # >
        found = true
        pos = i
      end 
      i += 1
    end  
    if pos
      @wait_queue.insert pos, {:process => object, :priority => priority, :left_time_to_serve => left_time_to_serve } 
      return
    else
      @wait_queue << {:process => object, :priority => priority, :left_time_to_serve => left_time_to_serve}   
      return
    end
  end
  
  def add_to_wait_queue_before(object, priority, left_time_to_serve = nil)  
    i = 0                               
    found = false   
    pos = nil
    while (i < @wait_queue.size) && !found 
      if @wait_queue[i][:priority] <= priority # >
        found = true
        pos = i
      end 
      i += 1
    end  
    if pos
      @wait_queue.insert pos, {:process => object, :priority => priority, :left_time_to_serve => left_time_to_serve } 
      return
    else
      @wait_queue << {:process => object, :priority => priority, :left_time_to_serve => left_time_to_serve}   
      return
    end
  end  
  
  def can_interrupt_process?(priority) 
    @active_list.each{|x|
      return true if priority > x[:priority] 
    }                 
    return false
  end   
  
  def interrupt_served_process(priority)
    i = 0                                  
    found = false
    while (i < @active_list.size) && !found
      if priority > @active_list[i][:priority]
        found = true
        #puts 1,"interrupt",@number_of_servers ,@active_list.inspect,priority,2 
        
        element = @active_list.delete_at(i)
        caller = element[:process]
        #add_to_wait_queue_before(caller, priority, left_time_to_serve = 2) #calculate  
      end
      i += 1
    end 
  end
  
  def release_process(caller) 
    i = 0                                  
    while (i < @active_list.size)
      if caller.name == @active_list[i][:process].name
        element = @active_list.delete_at(i)
        return element[:process]
      end
      i += 1
    end
    return nil
  end
  
end