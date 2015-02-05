require 'rubysimf'

open("generated_values.txt","w"){|f|
  20000.times{
    vals = [
          RubySimF::Random.exponential(:lambda => 3),
          RubySimF::Random.normal(:mu => 10, :sigma => 2),
          RubySimF::Random.uniform(:min => -3, :max => 10),
          RubySimF::Random.triangular(:min => 1, :mode => 10, :max => 15),
          RubySimF::Random.uniform_discrete(:min => 1, :max => 6),
          RubySimF::Random.bernoulli(:probability_of_success => 0.2),
          RubySimF::Random.binomial(:probability_of_success => 0.2,
                                   :number_of_trials => 3),
          RubySimF::Random.negative_binomial(:probability_of_success => 0.2,
                              :number_of_success => 2),
          RubySimF::Random.geometric(:probability_of_success => 0.2),
          RubySimF::Random.poisson(:lambda => 3),
          RubySimF::Random.empirical(:probabilities => [0.1, 0.3, 0.6])
          ]  
    f.puts vals.collect{|x| x.to_s}.join ", "
  }  
}      