module Hifsm
  module DSL
    class AbstractBuilder

      def self.define_dsl_callback(cb)
        define_method(cb) do |symbol = nil, &block|
          @defs.each do |ev_def|
            ev_def[cb].push symbol || block
          end
        end
      end

      def initialize
        @defs = []
      end

      def each(&block)
        @defs.each(&block)
      end

      protected
        def defs
          @defs
        end

        def slice_callbacks(options, names)
          Hash[names.map {|n| [n, array_wrap(options[n])]}]
        end

        # like in ActiveSupport
        def array_wrap(anything)
          anything.is_a?(Array) ? anything : [anything].compact
        end
    end
  end
end
