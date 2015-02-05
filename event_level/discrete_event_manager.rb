class RubySimF::DiscreteEventManager
  
  attr_reader :clock
  attr_reader :event_list, :inactive_event_list

  def initialize  
    init_simulation
  end
  
  def init_simulation                           
    @clock = 0
    @event_list = RubySimF::EventList.new      
    @inactive_event_list = RubySimF::EventList.new      
    @simulation_break = false    
    @thread_manager =  RubySimF::ThreadManager.new   
    RubySimF::Logger.instance.debug("Init the discrete event manager", clock)
  end                                             
    
  def continue_simulation?
    return false if @simulation_break 
    @event_list.size > 0 
  end 
  
  def stop_simulation
    @simulation_break = true
  end        
    
  def start_simulation(params = {})    
    @simulation_end_time = params[:until]       
    @transient_period = params[:transient_period]
    RubySimF::Logger.instance.debug("Starting simulation", clock)
    
    while continue_simulation?
      if not @event_list.empty?
        next_event = @event_list.next
        RubySimF::Logger.instance.info(
        "Processing an event of process: <#{next_event.parent_process.name}>", 
        clock)
        
        if @clock != next_event.at_time   
          
          RubySimF::Logger.instance.debug(
          "Set the clock further in time by: #{next_event.at_time}", 
          clock) 
          @clock = next_event.at_time      
          if @clock > @simulation_end_time
            @simulation_break = true
            next
          end
        end                                            
        @thread_manager.yield_control_to(next_event.parent_process)#,Thread.current) 
        #Thread.stop
      end
    end   
    RubySimF::Logger.instance.info(
    "End of simulation", 
    clock)
  end   
  
  def dispose(processes)  
    RubySimF::Logger.instance.debug(
    "Dispose of all processes", 
    clock)
    @thread_manager.terminate(processes, @simulation_break)
  end
  
  def add_event(event)
    @event_list << event
    RubySimF::Logger.instance.info(
"Add a wakeup event at #{event.at_time} of process: <#{event.parent_process.name}>", clock)
  end  
  
  def inactive_event_of(process) 
    @event_list.list.each_with_index{ |event,index|
      if event.parent_process == process     
        event_to_inactivate = @event_list.list.delete_at(index) 
        event_to_inactivate.at_time = (event_to_inactivate.at_time - clock)  
        @inactive_event_list << event_to_inactivate
      end
    }
  end    
  
  def reactivate_event_of(process) 
    founded = false
    @inactive_event_list.list.each_with_index{ |event,index|
      if event.parent_process == process
        founded = true     
        event_to_reactivate = @inactive_event_list.list.delete_at(index) 
        event_to_reactivate.at_time = (event_to_reactivate.at_time + clock)  
        add_event event_to_reactivate
      end
    }   
    add_event process.next_event(clock) unless founded
  end
  
end
     