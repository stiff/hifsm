module Hifsm
  module DSL
    # Normalizes event definitions to form
    # {:from => [], :to => ..., :guard => ..., before, after}
    class EventBuilder < AbstractBuilder

      def initialize(options, &block)
        super()
        build_def(options) if options[:to]
        instance_eval(&block) if block
      end

      Hifsm::Event::CALLBACKS.each do |cb|
        define_dsl_callback(cb)
      end

      # from :state, :to => :state
      def from(state, options)
        build_def(options.dup.merge(:from => state))
      end

      private
        def build_def(options)
          defs << slice_callbacks(options, Hifsm::Event::CALLBACKS).merge(
            :from => array_wrap(options[:from]),
            :to => options[:to]
          )
        end
    end
  end
end
