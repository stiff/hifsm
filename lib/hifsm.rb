require "hifsm/callbacks"
require "hifsm/fsm"
require "hifsm/event"
require "hifsm/machine"
require "hifsm/state"
require "hifsm/dsl/abstract_builder"
require "hifsm/dsl/event_builder"
require "hifsm/dsl/state_builder"
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

  def self.included(base)
    raise 'use extend Hifsm instead of include'
  end

  def hifsm(name = :state, &block)
    include FSM::new(name, &block).to_module
  end
end

begin
  require 'active_record'
  require 'hifsm/adapters/active_record_adapter'
rescue LoadError
end
