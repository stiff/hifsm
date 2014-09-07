module Hifsm
  class Event
    include Hifsm::Callbacks

    CALLBACKS = [:before, :after, :guard].freeze

    attr_reader :name, :to

    def initialize(name, to, callbacks_options)
      @name = name
      @to = to
      CALLBACKS.each do |cb|
        set_callbacks cb, callbacks_options[cb]
      end
    end

    def guard?(target, *args)
      trigger?(:guard, target, *args)
    end
  end
end
