module Hifsm
  module DSL
    # Normalizes event definitions to form
    # {:from => [], :to => ..., :guard => ..., before, after}
    class EventBuilder

      def initialize(options, &block)
        @defs = []
        build_def(options) if options[:to]
        instance_eval(&block) if block
      end

      def build_def(options)
        @defs << {
          :from => array_wrap(options[:from]),
          :to => options[:to],
          :guard => array_wrap(options[:guard]) + array_wrap(options[:guards]),
          :before => array_wrap(options[:before]),
          :after => array_wrap(options[:after])
        }
      end

      # from :state, :to => :state
      def from(state, options)
        build_def(options.dup.merge(:from => state))
      end

      def each(&block)
        raise(MissingTransition.new("")) if @defs.empty?
        @defs.each(&block)
      end

      Hifsm::Event::CALLBACKS.each do |cb|
        define_method(cb) do |symbol = nil, &block|
          @defs.each do |ev_def|
            ev_def[cb].push symbol || block
          end
        end
      end

      private
        # like in ActiveSupport
        def array_wrap(anything)
          anything.is_a?(Array) ? anything : [anything].compact
        end
    end
  end
end
