class RubySimF::Simulator

  include Singleton

  def initialize  
    init
  end    
    
  def wait(delay)
     process = current_process
     if process
       RubySimF::Logger.instance.info(
       "Wait for process <#{process.name}> of #{delay}", now) 
       activate_process(process, delay + now)
       Thread.stop  
     else 
       raise RubySimF::Exception::WaitWithoutProcess.new
     end         
  end
  
  def init
    @process_manager = RubySimF::ProcessManager.new           
    RubySimF::Logger.instance.info("Init the simulation", now)
  end         
  
  
  def now
    @process_manager.clock
  end     
  
  alias_method :clock, :now
  
  def declare_process(class_param, method_param)                        
    arity = nil
    begin
      arity = class_param.instance_method(method_param.to_sym).arity.abs 
      args = Array.new(arity){|x| "param_#{x}"}.join(", ") 
      args_a = Array.new(arity){|x| "param_#{x} = nil"}.join(", ")
      
      args_c = (arity>0)? " #{args}" : ""
    rescue Exception => e
      arity = nil                  
      args = "*args"
      args_c = " args"
    end

    code = <<CODE  
      unless method_defined? :__rubysimf_old_#{method_param}
        alias_method :__rubysimf_old_#{method_param}, :#{method_param}
        attr_reader :__rubysimf_parent_process
      
        def #{method_param}(#{args_a})   
          arity = #{arity} 
          ret = nil
          thread = Thread.new{
            Thread.stop  
            if arity                 
              if arity == 0 
                ret = __rubysimf_old_#{method_param} 
              else 
                ret = __rubysimf_old_#{method_param}#{args_c}
              end
            else
              begin
                ret = __rubysimf_old_#{method_param} 
              rescue ArgumentError
                ret = __rubysimf_old_#{method_param}#{args_c}
              end
            end          
            #Thread.pass
          }
          process = RubySimF::Process.new(thread,
            "#{class_param}.#{method_param}")    
          
          @__rubysimf_parent_process = process
          RubySimF::Simulator.instance.activate_process(process) 
          ret
        end   
      end
CODE
     class_param.class_eval{ eval code }
     RubySimF::Logger.instance.info(
      "Declare <:#{method_param}> as PEM of <#{class_param.to_s}>")

  end    

  def activate_process(process, at = now)
    @process_manager.activate_process(process, at)
  end 
      
  def current_process
    current_thread = Thread.current  
    @process_manager.find_process_by_thread(current_thread)
  end
    
  def simulate(params = {}) 
    defaults = {
      :until => RubySimF::Constants::BIGTIME,
      :transient_period => RubySimF::Constants::NO_TRANSIENT,
      :statistics_on => true
    } 
    params = defaults.merge(params)
    @transient_period = params[:transient_period]
    @statistics_on = params[:statistics_on]
    @process_manager.simulate(params)
  end
  
  def save_statistics? 
    return @process_manager.clock > @transient_period if @statistics_on
    return false
  end           
  
  def statistics_on 
    @statistics_on = true
  end                    
  
  def statistics_off 
    @statistics_on = false
  end                    
  
  
  def passivate_process_of(object)
    target = object.__rubysimf_parent_process    
    RubySimF::Logger.instance.info(
     "Passivate process <#{target.name}>", now)
    caller = current_process
    if target == caller
      Thread.stop
    else
      @process_manager.passivate(target)
    end
  end      
  
  def reactivate_process_of(object)    
    target = object.__rubysimf_parent_process 
    RubySimF::Logger.instance.info(
     "Reactivate process <#{target.name}>", now)
    @process_manager.reactivate(target)
  end 
  
  def stop 
    RubySimF::Logger.instance.info(
     "Stop simulation", now)
    @process_manager.stop
  end
    
end
     