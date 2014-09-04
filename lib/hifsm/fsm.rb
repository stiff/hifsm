module Hifsm

  # This class holds immutable state machine definition
  class FSM
    attr_reader :name, :states, :transitions

    def initialize(name = :state, parent = nil, &block)
      @name = name
      @parent = parent
      @states = {}
      @initial_state = nil

      instance_eval(&block) if block

      @fsm_module = fsm_module = initialize_module
      @machine_class = Class.new(Hifsm::Machine) do
        include fsm_module
        define_method("#{name}_machine") { self }
      end
    end

    def instantiate(target = nil, initial_state = nil)
      @machine_class.new(self, target, initial_state)
    end

    #DSL
    def event(name, options, &block)
      ev = Hifsm::Event.new(name, get_state!(options[:to]), array_wrap(options[:guard]))
      from_states = array_wrap(options[:from])
      from_states = @states.keys if from_states.empty?
      from_states.each do |from|
        st = get_state!(from)
        st.add_transition(ev)
      end
      ev.instance_eval(&block) if block
    end

    def state(name, options = {}, &block)
      st = @states[name.to_s] = Hifsm::State.new(self, name, @parent)
      @initial_state = st if options[:initial]
      st.instance_eval(&block) if block
    end

    # internals
    def all_events
      @states.flat_map {|name, st| st.events }.uniq
    end

    def all_states
      @states.flat_map do |state_name, st|
        # state should delegate to sub_fsm :)
        [st] + (st.sub_fsm && st.sub_fsm.all_states || [])
      end
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

    def to_module
      @fsm_module
    end

    private
      # like in ActiveSupport
      def array_wrap(anything)
        anything.is_a?(Array) ? anything : [anything].compact
      end

      def initialize_module
        fsm = self  # capture self
        machine_var = "@#{name}_machine"
        machine_name = "#{name}_machine"

        module_class_methods = Module.new do
          define_method("#{machine_name}_definition") { fsm }
        end

        Module.new do
          const_set('ClassMethods', module_class_methods)
          def self.included(base)
            base.class_exec do
              extend const_get('ClassMethods')
            end
          end

          # <state>_machine returns machine instance
          define_method(machine_name) do
            if instance_variable_defined?(machine_var)
              instance_variable_get(machine_var)
            else
              machine = fsm.instantiate(self)
              instance_variable_set(machine_var, machine)
            end
          end

          # <state> returns string representation of the current state
          define_method(fsm.name) { send(machine_name).to_s }

          # <event> fires event
          fsm.all_events.each do |event_name, event|
            define_method(event_name) {|*args| send(machine_name).fire(event_name, *args) }
          end
        end
      end
  end
end
