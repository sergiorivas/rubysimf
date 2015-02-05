require File.expand_path("../rubysimf",__FILE__)

class RubySimF::Logger
  def trace?
    RubySimF::Constants::DEBUG_TRACE
  end
end