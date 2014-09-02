module Hifsm
  class FSM
    attr_reader :states, :transitions

    def initialize(parent = nil, &block)
      @parent = parent
      @states = {}
      @initial_state = nil

      instance_eval(&block) if block
    end

    def instantiate(target = nil, initial_state = nil)
      Hifsm::Machine.new(self, target, initial_state)
    end

    def all_events
      @states.collect {|name, st| st.events }.flatten.uniq
    end

    def initial_state!
      @initial_state || raise(Hifsm::MissingState.new("<initial>"))
    end

    def get_state!(name)
      top_level_state, rest = name.to_s.split('.', 2)
      st = @states[top_level_state] || raise(Hifsm::MissingState.new(name.to_s))
      if rest
        st.get_substate!(rest)
      else
        st
      end
    end

    def event(name, options, &block)
      ev = Hifsm::Event.new(name, get_state!(options[:to]), options[:guard])
      from_states = array_wrap(options[:from])
      from_states = @states.keys if from_states.empty?
      from_states.each do |from|
        st = get_state!(from)
        st.add_transition(ev)
      end
      ev.instance_eval(&block) if block
    end

    def state(name, options = {}, &block)
      st = @states[name.to_s] = Hifsm::State.new(name, @parent)
      @initial_state = st if options[:initial]
      st.instance_eval(&block) if block
    end

    private
      # like in ActiveSupport
      def array_wrap(anything)
        anything.is_a?(Array) ? anything : [anything].compact
      end
  end
end
