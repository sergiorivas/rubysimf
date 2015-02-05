require 'rubysimf'

exp = RubySimF::Random::ExponentialVariate.new :lambda => 3  
exp2 = RubySimF::Random::RandomVariate.create :exponential, :lambda => 3 
nor = RubySimF::Random::RandomVariate.create :normal, :mu => -10, :sigma => 2
unif = RubySimF::Random::UniformVariate.new :min => -3, :max => 10
tri = RubySimF::Random::TriangularVariate.new :min => 1, :mode => 10, :max => 15
bin = RubySimF::Random::BinomialVariate.new :probability_of_success => 0.3, 
                                      :number_of_trials => 5
bin_neg =  RubySimF::Random::NegativeBinomialVariate.new :probability_of_success => 0.3,  
                                            :number_of_success => 2
bern = RubySimF::Random::BernoulliVariate.new :probability_of_success => 0.3
poi =  RubySimF::Random::PoissonVariate.new :lambda => 3
empirical = RubySimF::Random::EmpiricalVariate.new :probabilities => [0.1, 0.3, 0.6]
geo =  RubySimF::Random::GeometricVariate.new :probability_of_success => 0.3

open("generated_values_2.txt","w"){|f|
  20000.times{
    vals = [
      exp.generate_value,
      exp2.generate_value,
      nor.generate_value,
      unif.generate_value,
      tri.generate_value,
      bin.generate_value,
      bin_neg.generate_value,
      bern.generate_value,
      poi.generate_value,
      empirical.generate_value,
      geo.generate_value]  
    f.puts vals.collect{|x| x.to_s}.join ", "
  }  
}      