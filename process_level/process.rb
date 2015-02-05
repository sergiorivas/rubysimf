class RubySimF::Process   
  
  @@process_id = 1   
  
  attr_reader :name, :thread
  
  def initialize(thread, name)  
    @thread = thread
    @name = "#{name}__#{@@process_id}"
    @@process_id += 1                
    RubySimF::Logger.instance.info("Create the process: <#{@name}>",
    RubySimF::Simulator.instance.now)
  end             
  
  def next_event(at)
    RubySimF::WakeUpEvent.new(self, at)  
  end 

  def to_s
    "<#{name}>"
  end
end
     