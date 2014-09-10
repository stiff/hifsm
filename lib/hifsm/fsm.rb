module Hifsm

  # This class holds immutable state machine definition
  class FSM
    attr_reader :name, :transitions

    # public API
    def initialize(name = :state, parent = nil, &block)
      @name = name
      @parent = parent
      @states = {}
      @initial_state = nil

      instance_eval(&block) if block

      @fsm_module = nil
      @machine_class = nil
    end

    def instantiate(target = nil, initial_state = nil)
      machine_module = get_machine_module
      machine_name = "#{name}_machine"
      @machine_class ||= Class.new(Hifsm::Machine) do
        include machine_module
        define_method(machine_name) { self }
      end
      @machine_class.new(self, target, initial_state)
    end

    def states
      @states.keys
    end

    #DSL
    def event(name, options = {}, &block)
      Hifsm::DSL::EventBuilder.new(options, &block).each do |ev_def|
        ev = Hifsm::Event.new name,
                              get_state!(ev_def[:to]),
                              ev_def

        from_states = ev_def[:from]
        from_states = @states.keys if from_states.empty?
        from_states.each do |from|
          st = get_state!(from)
          st.add_transition(ev)
        end

      end
    end

    def state(name, options = {}, &block)
      Hifsm::DSL::StateBuilder.new(options, &block).each do |st_def|
        st = @states[name.to_s] = Hifsm::State.new(name, @parent, st_def)
        @initial_state = st if options[:initial]
      end
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
      get_fsm_module
    end

    private
      def get_machine_module
        fsm = self  # capture self
        machine_name = "#{name}_machine"
        @machine_module ||= Module.new do
          # <event> fires event
          fsm.all_events.each do |event_name, event|
            define_method(event_name) {|*args| send(machine_name).fire(event_name, *args) }
          end

          # <state.to_s.underscore>? = is machine currently in state <state>?
          fsm.all_states.each do |st|
            query = st.to_s
            define_method("#{query.gsub('.', '_')}?") do
              current = send(machine_name).to_s
              current == query || current.start_with?("#{query}.")
            end
          end
        end
      end

      def get_fsm_module
        fsm = self  # capture self
        machine_var = "@#{name}_machine"
        machine_name = "#{name}_machine"
        machine_module = get_machine_module
        @fsm_module ||= Module.new do
          include machine_module

          define_singleton_method :included do |base|
            base.class_eval do
              define_singleton_method("#{machine_name}_definition") { fsm }

              # act!
              define_method "act_with_#{machine_name}!" do |*args|
                send("act_without_#{machine_name}!", *args) if respond_to?("act_without_#{machine_name}!")
                send("#{machine_name}").act!(*args)
              end
              alias_method "act_without_#{machine_name}!", :act! if method_defined?(:act!)
              alias_method :act!, "act_with_#{machine_name}!"
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
        end
      end
  end
end
