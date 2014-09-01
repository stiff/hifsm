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

end
