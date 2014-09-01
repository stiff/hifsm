module Hifsm
  class Machine
    def initialize(target, fsm, initial_state = nil)
      @target = target
      @fsm = fsm

      @state = fsm.states[initial_state] || fsm.initial_state || raise("No initial state given")

      mach = self
      fsm.events.each do |event_name, event|
        target.singleton_class.instance_exec do
          define_method(event_name) {|*args| mach.trigger(event_name, args) }
        end
      end
    end

    def act!(*args)
      @state.act!(*args)
    end

    def trigger(event, args)
      @fsm.transitions[@state.to_s][event.to_s].each do |event|
        if event.guard?(@target)
          from_state = @state
          to_state = @fsm.states[event.to]
          if event.trigger(@target, :before, *args) && to_state.trigger(@target, :before_enter, *args) && from_state.trigger(@target, :before_exit, *args)
            @state = to_state
            from_state.trigger(@target, :after_exit, *args)
            to_state.trigger(@target, :after_enter, *args)
            event.trigger(@target, :after, *args)
          end
          return
        end
      end
    end

    def to_s
      @state.to_s
    end
  end
end
