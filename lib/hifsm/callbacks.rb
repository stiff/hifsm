module Hifsm
  module Callbacks

    def set_callbacks(key, listeners)
      @__callbacks ||= {}
      @__callbacks[key] = listeners
    end

    def trigger(key, target, *args)
      return [] unless @__callbacks[key]
      @__callbacks[key].map do |cb|
        if cb.nil?
          # raise something maybe? :)
        elsif cb.is_a? Symbol
          if target.method(cb).arity.zero?
            target.send(cb)
          else
            target.send(cb, *args)
          end
        else
          target.instance_exec(*args, &cb)
        end
      end
    end

    def trigger?(key, target, *args)
      !trigger(key, target, *args).any? {|v| v == false }
    end
  end
end
