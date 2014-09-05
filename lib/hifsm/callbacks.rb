class Callbacks

  def initialize(listeners = [])
    @listeners = listeners
  end

  def trigger(target, *args)
    @listeners.map do |cb|
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
end
