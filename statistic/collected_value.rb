class RubySimF::CollectedValue
  attr_accessor :time, :value

  def initialize(time, value)
    self.time = time
    self.value = value
  end
end