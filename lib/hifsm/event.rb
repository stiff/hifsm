module Hifsm
  class Event
    CALLBACKS = [:before, :after, :guard].freeze

    attr_reader :name, :to

    def initialize(name, to, guards)
      @name = name
      @to = to
      @callbacks = Hash.new {|h, key| h[key] = Callbacks.new }

      guards.each do |g|
        @callbacks[:guard].add g
      end
    end

    CALLBACKS.each do |cb|
      define_method(cb) { |&block| @callbacks[cb].add(&block) }
    end

    def trigger(target, cb, *args)
      @callbacks[cb].trigger(target, *args)
    end

    def guard?(target, *args)
      trigger(target, :guard, *args).all?
    end
  end
end
