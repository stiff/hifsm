module Hifsm
  class Machine
    def initialize(fsm, target, initial_state = nil)
      @target = target || self
      @fsm = fsm

      @state = (initial_state && fsm.get_state!(initial_state) || fsm.initial_state!).enter!

      # raise @state.inspect if initial_state == 'on.sync'

      mach = self
      fsm.all_events.each do |event_name, event|
        @target.singleton_class.instance_exec do
          define_method(event_name) {|*args| mach.fire(event_name, *args) }
        end
      end
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
