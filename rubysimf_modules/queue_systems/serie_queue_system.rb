class RubySimF::QueueSystems::SerieQueueSystem   
  
  attr_accessor :deliver_to,:servers
  
  def initialize(params={})
    begin 
      @@id += 1 
    rescue
      @@id = 0
    end
   
    defaults = {  
      :name => "serie_queue_system_#{@@id}",
      :service_time_random_variate => nil,             
      :number_of_servers => 1,
      :number_of_servers => 2,
      :deliver_to => nil
    }                        
    
    params = defaults.merge params
    @name = params[:name]
    @number_of_servers = params[:number_of_servers]
    @service_time_random_variate = params[:service_time_random_variate] 
    @number_of_servers = params[:number_of_servers]   
    @servers = Array.new(@number_of_servers){|index|
      RubySimF::QueueSystems::BasicQueueSystem.new(
        :name => "#{@name}_#{(index)}",
        :service_time_random_variate => @service_time_random_variate,
        :number_of_servers => @number_of_servers
       )
    }
    @number_of_servers.times{|index|
      @servers[index].deliver_to @servers[index+1] if index < (@number_of_servers-1)
    }
    @output_block = nil 
    @deliver_to = params[:deliver_to] 
    
    @servers.last.declare_output_method{|client|
      if @deliver_to
        @deliver_to.admit client
      else
        @output_block.call client if @output_block 
      end
    }
  end                                         
  
  def admit(client, params = {})
    params = {} unless params
    defaults = {
      :priority => RubySimF::Constants::DEFAULT_PRIORITY
    }  
    params = defaults.merge(params)
    priority = params[:priority]
     
    sim = RubySimF::Simulator.instance 
    log = RubySimF::Logger.instance   
    log.info("Serie queue system <#{@name}> is admitting to <#{client}>", sim.now)
    @servers.first.admit client, :priority => priority
    log.info("Serie queue system <#{@name}> is release the <#{client}>", sim.now)
  end           
  
  def declare_output_method &block
    sim = RubySimF::Simulator.instance 
    RubySimF::Logger.instance.info("Declaring output method on serie queue system <#{@name}>", sim.now)
    @output_block = block
  end  
  
  
end