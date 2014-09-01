require 'hifsm'

class Monster
  @@fsm = Hifsm::FSM.define do
    state :idle, :initial => true
    state :attacking do
      state :acquiring_target, :initial => true do
        action do
          # self is the monster instance here
          plan_attack
        end
      end
      state :pursuing do
        before_enter do
          self.roar!
        end
        action do
          step_towards target
        end
      end
      state :fighting do
        action do
          hit target
        end
      end

      event :acquire, :from => :acquiring_target, :to => :pursuing
      event :reached, :from => :pursuing, :to => :fighting

      action do |tick|
        puts "#{tick}: Attack!"
      end
    end
    state :coming_back do
      action do
        step_towards home
      end
    end
    state :runaway

    event :sight, :from => [:idle, :coming_back], :to => :runaway, :guard => :low_hp?
    event :sight, :from => [:idle, :coming_back], :to => :attacking do
      before do |t|
        puts "Setting target to #{t}"
        self.target = t
      end
    end
    event :kill, :from => :attacking, :to => :coming_back
  end

  attr_accessor :target
  attr_reader :state

  class <<self
    def example
      # set_trace_func proc { |event, file, line, id, binding, classname|
      #     unless [IO, Fixnum, Kernel, Hash, Array, Class, Module, BasicObject].include? classname
      #       printf "%8s %32s:%-2d %10s %16s\n", event, File.basename(file), line, id, classname
      #     end
      #   }
      ogre = Monster.new
      ogre.act!  # does nothing, idle
      ogre.sight 'player' # ->
      ogre.act!  # ->
    end
  end

  def initialize
    @home = 'home'
    @state = @@fsm.new(self) # or @@fsm.new(self, 'attacking.pursuing')
    @tick = 1
  end

  def act!
    puts "Acting @#{@state}"
    @state.act!(@tick)
    @tick = @tick + 1
  end

  def hit(target)
    puts "~~> #{target}"
  end

  def low_hp?
    false
  end

  def plan_attack
    puts "planning..."
    @state.acquire
  end

  def roar!
    puts "AARGHH!"
  end

  def step_towards(target)
    puts "step step #{target}"
  end

end

Monster.example

