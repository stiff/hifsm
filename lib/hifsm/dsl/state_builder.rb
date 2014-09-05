module Hifsm
  module DSL
    # Normalizes state definitions
    class StateBuilder < AbstractBuilder

      def initialize(options = {}, &block)
        super()
        build_def(options)
        instance_eval(&block) if block
      end

      Hifsm::State::CALLBACKS.each do |cb|
        define_dsl_callback(cb)
      end

      def state(*args, &block)
        defs.first[:sub_states].push [args, block]
      end

      def event(*args, &block)
        defs.first[:sub_events].push [args, block]
      end

      private
        def build_def(options)
          defs << slice_callbacks(options, Hifsm::State::CALLBACKS).merge(
            :initial => options[:initial],
            :sub_states => [],
            :sub_events => []
          )
        end
    end
  end
end
