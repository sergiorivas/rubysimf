class RubySimF::Logger     

  include Singleton
  
  def initialize
    ObjectSpace.define_finalizer(self,self.class.method(:finalize).to_proc)  
    @filelog = open(RubySimF::Constants::LOG_NAME,"w")         
    debug("Init the log")
  end 
  
  def self.finalize(id) 
    #info("End of log") 
    #@filelog.close
  end  
  
  def trace?
    RubySimF::Constants::NO_TRACE
  end    
  
  def info(message, at = 0)
    if trace? > RubySimF::Constants::NO_TRACE
      m = "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} [INFO]: {#{at}} - #{message}"
      puts m
      @filelog.puts m if trace? == RubySimF::Constants::DEBUG_TRACE 
    end
  end
  
  def debug(message, at = 0)  
    if trace? == RubySimF::Constants::DEBUG_TRACE
      m = "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} [DEBUG]: {#{at}} - #{message}"
      puts m
      @filelog.puts m 
    end
  end                                                
  
end
     