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
    base.send(:extend, ClassMethods) unless base.respond_to?(:hifsm)
  end

  module ClassMethods
    def hifsm(name = :state, &block)
      include FSM::new(name, &block).to_module

      # act!
      define_method("act_with_#{name}_machine!") do |*args|
        send("act_without_#{name}_machine!", *args) if respond_to?("act_without_#{name}_machine!")
        send("#{name}_machine").act!(*args)
      end
      alias_method "act_without_#{name}_machine!", :act! if method_defined?(:act!)
      alias_method :act!, "act_with_#{name}_machine!"
    end
  end
end

begin
  require 'active_record'
  require 'hifsm/adapters/active_record_adapter'
rescue LoadError
end
