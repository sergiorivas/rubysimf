class RubySimF::Random::PoissonVariate <  RubySimF::Random::RandomVariate
  def initialize(params = {})
     if params[:lambda]
       @lambda = params[:lambda] 
     else
       raise RubySimF::Exception::InvalidParameter.new "Parameter :lambda no specified"
     end
     raise RubySimF::Exception::InvalidParameter.new "Parameter :lambda must be greater than 0" if @lambda <= 0
  end       
  
  def generate_value
    RubySimF::Random.poisson(:lambda => @lambda)
  end
end