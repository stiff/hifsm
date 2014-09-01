module Hifsm
  class State
    CALLBACKS = [:before_enter, :before_exit, :after_enter, :after_exit].freeze

    def initialize(name)
      @name = name
      @action

      @callbacks = Hash.new { Callbacks.new }
    end

    def action(&block)
      @action = block
    end

    def state(*args, &block)
      sub_fsm.state *args, &block
    end

    def event(*args, &block)
      sub_fsm.event *args, &block
    end

    CALLBACKS.each do |cb|
      define_method(cb) { |&block| @callbacks[cb].add(&block) }
    end

    def trigger(target, cb, *args)
      puts "#{self.class.name} #{@name} triggering #{cb} #{args.inspect}"
      @callbacks[cb].trigger(target, *args)
    end

    def act!(target, *args)
      puts "#{self.class.name} #{@name} act! #{args.inspect}"
      @action && Callbacks.invoke(target, @action, *args)
      if @sub_fsm
      end
    end

    def to_s
      if @sub_fsm
        @name.to_s # TODO append subfsm
      else
        @name.to_s
      end
    end

    private
      def sub_fsm
        @sub_fsm ||= Hifsm::FSM.new
      end
  end
end
