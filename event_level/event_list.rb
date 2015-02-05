class RubySimF::EventList
  
  attr_accessor :list 
  
  def initialize()  
    @list = []
  end
  
  def <<(event)      
    @list << event   
    @list = @list.sort_by{|x| x.at_time}
  end       
  
  def empty?
    @list.size == 0
  end          
  
  def next
    @list.delete_at 0
  end    
  
  def size
    @list.size
  end
  
end
     