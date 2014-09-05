module Hifsm
  class Event
    CALLBACKS = [:before, :after, :guard].freeze

    attr_reader :name, :to

    def initialize(name, to, callbacks_options)
      @name = name
      @to = to
      @callbacks = {}
      CALLBACKS.each do |cb|
        @callbacks[cb] = Callbacks.new(callbacks_options[cb])
      end
    end

    def trigger(target, cb, *args)
      @callbacks[cb].trigger(target, *args)
    end

    def guard?(target, *args)
      trigger(target, :guard, *args).all?
    end
  end
end
