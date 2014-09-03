class Callbacks

  class <<self
    def invoke(target, cb, *args)
      if cb.nil?
      elsif cb.is_a? Symbol
        if target.method(cb).arity > 0
          target.send(cb, *args)
        else
          target.send(cb)
        end
      else
        target.instance_exec(*args, &cb)
      end
    end
  end

  def initialize
    @listeners = []
  end

  def add(symbol = nil, &callback)
    @listeners.push symbol || callback
  end

  def trigger(target, *args)
    @listeners.map do |callback|
      Callbacks.invoke target, callback, *args
    end
  end
end
