require 'rubysimf' 

x = RubySimF::Random::ExponentialVariate.new :lambda => 11
valor_exponencial = RubySimF::Random.exponential :lambda => 11
puts valor_exponencial

3.times{
  puts x.generate_value
}
