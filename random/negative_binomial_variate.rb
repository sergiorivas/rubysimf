class RubySimF::Random::NegativeBinomialVariate <  RubySimF::Random::RandomVariate
  def initialize(params = {})
     if params[:probability_of_success]
       @probability_of_success = params[:probability_of_success] 
     else
       raise RubySimF::Exception::InvalidParameter.new "Parameter :probability_of_success no specified"
     end
     raise RubySimF::Exception::InvalidParameter.new "Parameter :probability_of_success must be greater than 0" if @probability_of_success <= 0
     if params[:number_of_success]
       @number_of_success = params[:number_of_success] 
     else
       raise RubySimF::Exception::InvalidParameter.new "Parameter :number_of_success no specified"
     end
     raise RubySimF::Exception::InvalidParameter.new "Parameter :number_of_success must be greater than 0" if @number_of_success <= 0
  end       
  
  def generate_value
    RubySimF::Random.negative_binomial(
      :probability_of_success => @probability_of_success,
      :number_of_success => @number_of_success)
  end
end