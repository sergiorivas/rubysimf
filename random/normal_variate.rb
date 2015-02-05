class RubySimF::Random::NormalVariate <  RubySimF::Random::RandomVariate
  def initialize(params = {})
     if params[:mu] && params[:sigma]
       @mu = params[:mu] 
       @sigma = params[:sigma]
     else
       raise RubySimF::Exception::InvalidParameter.new  "Parameter :mu or :sigma no specified"
     end
     raise RubySimF::Exception::InvalidParameter.new "Parameter :sigma must be greater than 0" if @sigma <= 0
  end       

  def generate_value
    RubySimF::Random.normal(:mu => @mu, :sigma => @sigma)
  end
end