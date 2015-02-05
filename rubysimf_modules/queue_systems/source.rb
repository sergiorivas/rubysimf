class RubySimF::QueueSystems::Source   
                               
  def deliver_to(target)
    @deliver_to = target
  end
  
  def initialize(params={})
    begin 
      @@id += 1 
    rescue
      @@id = 0
    end
   
    defaults = {  
      :name => "source_#{@@id}",
      :class => nil,
      :interarrival_time_random_variate => nil,
      :until_clock_is => RubySimF::Constants::BIGTIME,
      :deliver_to => nil,
      :priority => nil,
      :preemptive => false,
      :bulk_size_variate => nil,
      :population_limit => RubySimF::Constants::BIGPOPULATION
    }                        
    
    params = defaults.merge params
    @name = params[:name]
    @class = params[:class]
    @interarrival_time_random_variate = params[:interarrival_time_random_variate]
    @until_clock_is = params[:until_clock_is] 
    @output_block = nil
    @deliver_to = params[:deliver_to] 
    @priority = params[:priority]
    @preemptive = params[:preemptive]
    @bulk_size_variate = params[:bulk_size_variate]
    @population_limit = params[:population_limit]
  end                                         
  
  def generate 
    @actual_population = 0
    sim = RubySimF::Simulator.instance 
    log = RubySimF::Logger.instance   
    log.info("Turn on source <#{@name}>")
    while sim.now < @until_clock_is && (@actual_population < @population_limit)   
      bulk_size = (@bulk_size_variate)? @bulk_size_variate.generate_value : 1
      log.info("Creating a bulk of <#{@class}> on source <#{@name}> of size <#{bulk_size}>", sim.now) 
      bulk_size.times{
        client = @class.new    
        log.info("Creating <#{@class}> on source <#{@name}>", sim.now)
        if @deliver_to       
          @deliver_to.admit client, 
            :priority => @priority, 
            :preemptive => @preemptive
        else
          @output_block.call client if @output_block 
        end    
      }
      sim.wait(@interarrival_time_random_variate.generate_value)
      @actual_population += 1 
    end
  end           
  
  def declare_output_method &block 
    sim = RubySimF::Simulator.instance 
    RubySimF::Logger.instance.info("Declaring output method on source <#{@name}>", sim.now)
    @output_block = block
  end
  
end  

RubySimF::Simulator.instance.declare_process RubySimF::QueueSystems::Source, :generate   
