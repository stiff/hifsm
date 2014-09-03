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

    def act!(*args)
      @state.act!(@target, *args)
    end

    def state
      @state.to_s
    end

    def fire(event, *args)
      @state.fire(@target, event, *args) do |new_state|
        @state = new_state
      end
    end

    def to_s
      @state.to_s
    end
  end
end
