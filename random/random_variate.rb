class RubySimF::Random::RandomVariate  
  
  def self.create(distribution_name, args = {})
    if distribution_name.to_s == "exponential"
      return RubySimF::Random::ExponentialVariate.new args
    elsif distribution_name.to_s == "normal"
      return RubySimF::Random::NormalVariate.new args
    elsif distribution_name.to_s == "uniform"
      return RubySimF::Random::UniformVariate.new args
    elsif distribution_name.to_s == "triangular"
      return RubySimF::Random::TriangularVariate.new args
    elsif distribution_name.to_s == "binomial"
      return RubySimF::Random::BinomialVariate.new args
    elsif distribution_name.to_s == "geometric"
      return RubySimF::Random::GeometricVariate.new args
    elsif distribution_name.to_s == "negative_binomial"
      return RubySimF::Random::NegativeBinomialVariate.new args
    elsif distribution_name.to_s == "bernoulli"
      return RubySimF::Random::BernoulliVariate.new args
    elsif distribution_name.to_s == "poisson"
      return RubySimF::Random::PoissonVariate.new args
    elsif distribution_name.to_s == "empirical"
      return RubySimF::Random::EmpiricalVariate.new args
    end                               
    raise RubySimF::Exception::InvalidParameter.new  "Unknowed distribution"
  end
  
  def generate_value
    raise RubySimF::Exception::AbstractClass
  end
  
  #private_class_method :new
  
end