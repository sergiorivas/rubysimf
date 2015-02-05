class RubySimF::Exception::WaitWithoutProcess < Exception 
  def initialize
    super "Method must be declared as process to invocated an wait"
  end 
end