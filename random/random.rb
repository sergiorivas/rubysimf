module RubySimF::Random 
  
  def self.exponential(params)    
    u = rand()
    u = rand() while u <= 1e-7
    -Math.log(u)/params[:lambda]
 end
  
  def self.normal(params)
    x2pi = rand() * Math::PI
    g2rad = Math.sqrt(-2.0 * Math.log(1.0 - rand()))
    z = Math.cos(x2pi) * g2rad
    params[:mu] + z*params[:sigma]
  end

  def self.uniform(params)
    params[:min] + (params[:max]-params[:min]) * rand()
  end
  
  def self.triangular(params)
    params[:min] *= 1.0
    params[:mode] *= 1.0
    params[:max] *= 1.0
    u = rand()
    c = 0.5
    (params[:mode] - params[:min]) / (params[:max] - params[:min]) if params[:mode]
    if u > c
      u = 1.0 - u
      c = 1.0 - c
      params[:min], params[:max] = params[:max], params[:min]
    end
    params[:min] + (params[:max] - params[:min]) * (u * c) ** 0.5
  end
  
  def self.uniform_discrete(params)
    uniform(:min => params[:min],
            :max => (params[:max]+1)).to_i
  end   
    
  def self.bernoulli(params)
    (rand() < params[:probability_of_success])? 1 : 0
  end
  
  def self.binomial(params)
    counter = 0
    params[:number_of_trials].times{ 
      counter += bernoulli(:probability_of_success => params[:probability_of_success]) 
    } 
    counter
  end

  def self.negative_binomial(params)
    counter = 0
    success_counter = 0
    while success_counter < params[:number_of_success]
      counter += 1
      success_counter += bernoulli(:probability_of_success => params[:probability_of_success])
    end           
    counter
  end
  def self.geometric(params) 
    negative_binomial(:number_of_success => 1,
                      :probability_of_success => params[:probability_of_success])
  end
  
  def self.poisson(params) 
    cummulative_time = 0
    cummulative_time += exponential(:lambda => params[:lambda])
    counter = 0
    while cummulative_time <= 1.0
      counter += 1
      cummulative_time += exponential(:lambda => params[:lambda])
    end   
    counter
  end
  
  def self.empirical(params) 
    probs = params[:probabilities]
    cda = []
    acum = 0
    probs.each{|x|
      acum += x
      cda << acum
    }
    cda << 1 
    cda.each{|x| x=1 if x > 1}
    u = rand
    index = 0
    index += 1 while u > cda[index]
    index
  end
end