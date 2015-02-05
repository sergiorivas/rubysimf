class RubySimF::Random::TriangularVariate <  RubySimF::Random::RandomVariate
  def initialize(params = {})
     if params[:min] && params[:mode] && params[:max]
       @min = params[:min] 
       @mode = params[:mode]
       @max = params[:max]   
     else
       raise RubySimF::Exception::InvalidParameter.new "Parameter :min, :mode or :max no specified"
     end 
     raise RubySimF::Exception::InvalidParameter.new "Parameter :max must be greater than :mode" if @mode >= @max
     raise RubySimF::Exception::InvalidParameter.new "Parameter :max must be greater than :min" if @min >= @max
     raise RubySimF::Exception::InvalidParameter.new "Parameter :mode must be greater than :min" if @min >= @mode             
  end       
  
  def generate_value
    RubySimF::Random.triangular(:min => @min, :mode => @mode, :max => @max)
  end
end