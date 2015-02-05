class RubySimF::Random::UniformVariate <  RubySimF::Random::RandomVariate
  def initialize(params = {})
     if params[:min] && params[:max]
       @min = params[:min] 
       @max = params[:max]
     else
       raise RubySimF::Exception::InvalidParameter.new "Parameter :min or :max no specified"
     end
     raise RubySimF::Exception::InvalidParameter.new "Parameter :max must be greater than :min" if @min >= @max
  end       
  
  def generate_value
    RubySimF::Random.uniform(:min => @min,:max => @max)
  end
end