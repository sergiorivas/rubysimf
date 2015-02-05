require "rubysimf"    

b = RubySimF::EventList.new       

3.times{|x|
  a = RubySimF::WakeUpEvent.new(nil,10-x)    
  b << a                  
}
puts b.list.inspect  

m = RubySimF::DiscreteEventManager.new
#puts m.methods