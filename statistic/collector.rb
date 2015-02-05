class RubySimF::Collector
  def initialize() 
    init 
  end                 
  
  def count      
    @observations.size
  end
  
  def init 
    @observations = []      
    @statistic = RubySimF::BasicStatistics.new   
  end   
  
  def observe(value)
    @observations << RubySimF::CollectedValue.new(
      RubySimF::Simulator.instance.now(), value) if value
  end 
    
  def <<(value)       
    observe(value)
  end  
  
  auto_methods = %w{mean variance standard_desviation min max median sum}   
  auto_methods.each{|m|
    define_method(m.to_sym){
      @statistic.data=@observations.collect{|x| x.value}
      @statistic.send m.to_sym
    }
  }
    
  def percentile(x) #percenile 
    @statistic.data=@observations.collect{|y| y.value}
    @statistic.percentile(x)
  end
    
  def time_weighted_mean
    points = []
    last_time = 0
    @observations.each{|x|
      points << (x.time - last_time)
      last_time = x.time
    }   
    @statistic.data=@observations.collect{|x| x.value}
    @statistic.weighted_mean points                
  end           
  
end