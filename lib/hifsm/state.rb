module Hifsm
  class State
    CALLBACKS = [:before_enter, :before_exit, :after_enter, :after_exit].freeze

    def initialize(fsm, name, parent = nil)
      @fsm = fsm
      @name = name
      @parent = parent
      @action = nil
      @sub_fsm = nil

      @callbacks = Hash.new {|h, key| h[key] = Callbacks.new }
      @transitions = Hash.new {|h, key| h[key] = Array.new }
    end

    def add_transition(ev)
      name = ev.name.to_s
      @transitions[name].push ev
    end

    def action(&block)
      @action = block
    end

    def state(*args, &block)
      sub_fsm!.state(*args, &block)
    end

    def event(*args, &block)
      sub_fsm!.event(*args, &block)
    end

    def events
      @transitions.keys + (@sub_fsm && @sub_fsm.all_events || [])
    end

    def fire(target, event_name, *args, &new_state_callback)
      event_name = event_name.to_s
      @transitions[event_name].each do |ev|
        if ev.guard?(target, *args)
          from_state = self
          to_state = ev.to
          if ev.trigger(target, :before, *args) &&
              to_state.trigger(target, :before_enter, *args) &&
              from_state.trigger(target, :before_exit, *args)
            new_state_callback.call(to_state.enter!)
            from_state.trigger(target, :after_exit, *args)
            to_state.trigger(target, :after_enter, *args)
            ev.trigger(target, :after, *args)
          end
          return target
        end
      end
      if @parent
        return @parent.fire(target, event_name, *args, &new_state_callback)
      end
      raise Hifsm::MissingTransition.new(to_s, event_name)
    end

    CALLBACKS.each do |cb|
      define_method(cb) { |&block| @callbacks[cb].add(&block) }
    end

    def trigger(target, cb, *args)
      @callbacks[cb].trigger(target, *args)
    end

    def act!(target, *args)
      @parent.act!(target, *args) if @parent
      @action && Callbacks.invoke(target, @action, *args)
    end

    def enter!
      if @sub_fsm
        @sub_fsm.initial_state!
      else
        self
      end
    end

    def get_substate!(name)
      raise Hifsm::MissingState.new(name.to_s) unless @sub_fsm
      @sub_fsm.get_state!(name)
    end

    def to_s
      if @parent
        "#{@parent.to_s}.#{@name.to_s}"
      else
        @name.to_s
      end
    end

    private
      def sub_fsm!
        # FIXME too much coupling
        @sub_fsm ||= Hifsm::FSM.new(@fsm.name, self)
      end
  end
end
