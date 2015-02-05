class RubySimF::WakeUpEvent < RubySimF::Event
  
  attr_accessor :parent_process 
  
  def initialize(process, at) 
    @parent_process = process
    @at_time = at
  end         
  
end
     