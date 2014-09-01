module Hifsm
  class Event
    CALLBACKS = [:before, :after].freeze

    attr_reader :to

    def initialize(name, to, guard)
      @name = name
      @guard = guard
      @to = to

      @callbacks = Hash.new { Callbacks.new }
    end

    CALLBACKS.each do |cb|
      define_method(cb) { |&block| @callbacks[cb].add(&block) }
    end

    def trigger(target, cb, *args)
      puts "#{self.class.name} #{@name} triggering #{cb} #{args.inspect}"
      @callbacks[cb].trigger(target, *args)
    end

    def guard?(target)
      puts "#{self.class.name} #{@name} checking guard #{@guard}"
      !@guard || Callbacks.invoke(target, @guard)
    end
  end
end
