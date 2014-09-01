module Hifsm
  class FSM
    attr_reader :states, :events, :transitions, :initial_state

    class <<self
      def define(&block)
        Hifsm::FSM.new(&block)
      end
    end

    def initialize(&block)
      @events = {}
      @states = {}
      @transitions = {}
      @initial_state

      instance_eval &block if block
    end

    def new(target, initial_state = nil)
      Hifsm::Machine.new(target, self, initial_state)
    end

    def event(name, options, &block)
      ev = @events[name] = Hifsm::Event.new(name, options[:to], options[:guard])
      array_wrap(options[:from]).each do |from|
        @transitions[from.to_s] ||= {}
        @transitions[from.to_s][name.to_s] ||= []
        @transitions[from.to_s][name.to_s].push ev
      end
      ev.instance_eval &block if block
    end

    def state(name, options = {}, &block)
      st = @states[name] = Hifsm::State.new(name)
      @initial_state = st if options[:initial]
      st.instance_eval &block if block
    end

    private
      # like in ActiveSupport
      def array_wrap(anything)
        anything.is_a?(Array) ? anything : [anything]
      end
  end
end
