class RubySimF::Random::EmpiricalVariate <  RubySimF::Random::RandomVariate
  def initialize(params = {})
     if params[:probabilities]
       @probabilities = params[:probabilities] 
     else
       raise RubySimF::Exception::InvalidParameter.new "Parameter :probabilities no specified"
     end
  end       
  
  def generate_value
    RubySimF::Random.empirical(:probabilities => @probabilities)
  end
end