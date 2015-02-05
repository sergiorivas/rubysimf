class RubySimF::Exception::AbstractClass < Exception  
  def initialize
    super "This is a abstract class, this method must be implemented in a subclass"
  end
end