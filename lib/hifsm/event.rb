module Hifsm
  class Event
    CALLBACKS = [:before, :after].freeze

    attr_reader :name, :to

    def initialize(name, to, guard)
      @name = name
      @guard = guard
      @to = to

      @callbacks = Hash.new {|h, key| h[key] = Callbacks.new }
    end

    CALLBACKS.each do |cb|
      define_method(cb) { |&block| @callbacks[cb].add(&block) }
    end

    def trigger(target, cb, *args)
      @callbacks[cb].trigger(target, *args)
    end

    def guard?(target)
      !@guard || Callbacks.invoke(target, @guard)
    end
  end
end
