module Hifsm
  # This is just a storage of current state
  class Machine
    def initialize(fsm, target, initial_state = nil)
      @target = target || self
      @fsm = fsm

      initial_state_method_name = "initial_#{fsm.name}"
      initial_state ||= target.send(initial_state_method_name) if target.respond_to?(initial_state_method_name)
      initial_state &&= fsm.get_state!(initial_state)
      initial_state ||= fsm.initial_state!

      @state = initial_state.enter!
    end

    # Public API

    def act!(*args)
      @state.act!(@target, *args)
    end

    def state
      @state
    end

    def valid_events(*args)
      @state.valid_events(@target, *args)
    end

    def states
      @fsm.states
    end

    def to_s
      @state.to_s
    end

    # internals
    def all_states
      @fsm.all_states.reject(&:sub_fsm).collect(&:to_s)
    end

    def fire(event, *args)
      @state.fire(@target, event, *args) do |new_state|
        @state = new_state
      end
    end
  end
end
