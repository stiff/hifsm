require "hifsm/callbacks"
require "hifsm/fsm"
require "hifsm/event"
require "hifsm/machine"
require "hifsm/state"
require "hifsm/version"

module Hifsm
  class MissingTransition < StandardError
    def initialize(state, name)
      super "No transition :#{name} from :#{state}"
    end
  end

  class MissingState < StandardError
    def initialize(name)
      super "No state :#{name} defined"
    end
  end

  class <<self
    def fsm_module(name = :state, &block)
      FSM::new(name, &block).to_module
    end
  end
end

begin
  require 'active_record'
  require 'hifsm/adapters/active_record_adapter'
rescue LoadError
end
