class Callbacks

  class <<self
    def invoke(target, cb, *args)
      if cb.nil?
      elsif cb.is_a? Symbol
        target.send(cb, *args)
      else
        target.instance_exec(*args, &cb)
      end
    end
  end

  def initialize
    @listeners = []
  end

  def add(&callback)
    @listeners.push callback
  end

  def trigger(target, *args)
    @listeners.each do |callback|
      Callbacks.invoke target, callback, *args
    end
  end
end
