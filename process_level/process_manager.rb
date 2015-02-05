class RubySimF::ProcessManager

  def initialize  
    @des_manager = RubySimF::DiscreteEventManager.new 
    RubySimF::Logger.instance.info("Init the process manager", clock) 
    @process_list = []
  end               
  
  def activate_process(process, at)      
    @process_list << process unless find_process_by_thread(process.thread)
    event = process.next_event(at)
    @des_manager.add_event(event)
  end       
  
  def find_process_by_thread(thread)
    @process_list.each{|current|
       return current if current.thread.object_id == thread.object_id
    } 
    nil
  end
  
  def clock
    @des_manager.clock
  end                                     
  
  def simulate(params = {}) 
    @des_manager.start_simulation(params) 
    @des_manager.dispose(@process_list)
  end  
  
  def passivate(process)
    @des_manager.inactive_event_of(process)
  end  
  
  def reactivate(process)
    @des_manager.reactivate_event_of(process)
  end   
  
  def stop      
    @des_manager.stop_simulation
  end
    
end
     