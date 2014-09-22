module Hifsm
  class State
    include Hifsm::Callbacks

    CALLBACKS = [:before_enter, :before_exit, :after_enter, :after_exit, :action].freeze

    attr_reader :name, :sub_fsm

    def initialize(name, parent = nil, options)
      @name = name.to_s
      @parent = parent
      CALLBACKS.each do |cb|
        set_callbacks cb, options[cb]
      end
      @transitions = Hash.new {|h, key| h[key] = Array.new }

      if options[:sub_states].empty?
        @sub_fsm = nil
      else
        @sub_fsm = Hifsm::FSM.new(nil, self)
        options[:sub_states].each {|args, block| @sub_fsm.state(*args, &block) }
        options[:sub_events].each {|args, block| @sub_fsm.event(*args, &block) }
      end
    end

    def act!(target, *args)
      @parent.act!(target, *args) if @parent
      trigger(:action, target, *args).last
    end

    def add_transition(ev)
      name = ev.name.to_s
      @transitions[name].push ev
    end

    def enter!
      if @sub_fsm
        @sub_fsm.initial_state!.enter!
      else
        self
      end
    end

    def events
      @transitions.keys + (@sub_fsm && @sub_fsm.all_events || [])
    end

    def get_substate!(name)
      raise Hifsm::MissingState.new(name.to_s) unless @sub_fsm
      @sub_fsm.get_state!(name)
    end

    def valid_events(target, *args)
      own_events = events.find_all do |event_name|
        @transitions[event_name].any? {|event| event.guard?(target, *args)}
      end
      if @parent
        (own_events + @parent.valid_events(target, *args)).uniq
      else
        own_events.uniq
      end
    end

    def fire(target, event_name, *args, &new_state_callback)
      event_name = event_name.to_s
      @transitions[event_name].each do |ev|
        if ev.guard?(target, *args)
          from_state = self
          to_state = ev.to
          if ev.trigger?(:before, target, *args) &&
              to_state.trigger?(:before_enter, target, *args) &&
              from_state.trigger?(:before_exit, target, *args)
            new_state_callback.call(to_state.enter!)
            from_state.trigger(:after_exit, target, *args)
            to_state.trigger(:after_enter, target, *args)
            ev.trigger(:after, target, *args)
          end
          return target
        end
      end
      if @parent
        return @parent.fire(target, event_name, *args, &new_state_callback)
      end
      raise Hifsm::MissingTransition.new(to_s, event_name)
    end

    def to_s
      if @parent
        "#{@parent.to_s}.#{@name}"
      else
        @name
      end
    end
  end
end
