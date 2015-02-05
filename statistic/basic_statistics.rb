class RubySimF::BasicStatistics   
  def initialize(data=[])
    @data = data
  end                  
  
  def data=(data, reload=false)
    @data = data if @data.size != data.size || reload
  end
  
  def mean        
    return nil if @data.size == 0
    (@data.inject(0){|sum, x| sum + x })*1.0/@data.size
  end  
  
  def sum
    @data.inject(0){|sum, x| sum + x }
  end
  
  def variance
    return nil if @data.size == 0
    return 0 if @data.size == 1   
    average = mean
    (@data.inject(0){|sum, x| sum + ((x-average)**2) })*1.0/(@data.size - 1)
  end
  
  def standard_desviation
    return nil if @data.size == 0    
    return Math.sqrt variance
  end
  
  def max
    @data.max
  end
  
  def min
    @data.min
  end
  
  def percentile(x)
    return nil if @data.size == 0
    return @data.first if @data.size == 1
    sorted_data = @data.sort
    n = @data.size
    pos = (n-1)*x
    pos_i = pos.to_i
    return sorted_data[pos] if (pos-pos_i) == 0
    (sorted_data[pos_i]+sorted_data[pos_i+1])/2.0
  end  

  def median
    percentile 0.5
  end
  
  def weighted_mean(points)
    return nil if points.size != @data.size 
    return mean if @data.size < 2 
    sum = 0
    @data.each_with_index{|x,i| sum+= x*points[i]}
    total_data = sum
    total_points = points.inject(0){|sum, x| sum + x } 
    return nil if total_points == 0      
    total_data*1.0/total_points
  end 
  
end


