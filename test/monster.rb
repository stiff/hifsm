require 'hifsm'

class Monster
  include Hifsm

  hifsm do
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
          true # since roar! returns nil it would stop processing
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
        debug && puts("#{tick}: Attack!")
      end
    end
    state :coming_back do
      action do
        step_towards @home
      end
    end
    state :runaway

    event :sight, :from => [:idle, :coming_back], :to => :runaway, :guard => :low_hp?
    event :sight, :from => [:idle, :coming_back], :to => :attacking do
      before do |t|
        debug && puts("Setting target to #{t}")
        self.target = t
      end
    end
    event :enemy_dead, :from => :attacking, :to => :coming_back do
      after do
        debug && puts("Woohoo!")
        self.target = nil
      end
    end
  end

  attr_accessor :target, :low_hp, :debug

  def initialize
    @debug = false
    @home = 'home'
    @tick = 1
    @low_hp = false
  end

  def act_with_tick!
    debug && puts("Acting @#{state}")
    act_without_tick! @tick
    @tick = @tick + 1
  end
  alias_method :act_without_tick!, :act!
  alias_method :act!, :act_with_tick!

  def hit(target)
    debug && puts("~~> #{target}")
  end

  def low_hp?
    @low_hp
  end

  def plan_attack
    debug && puts("planning...")
    acquire
  end

  def roar!
    debug && puts("AARGHH!")
  end

  def step_towards(target)
    debug && puts("step step #{target}")
  end

end

if $0 == __FILE__
  ogre = Monster.new
  ogre.debug = true       ### Console output:
  ogre.act!               # Acting @idle
  ogre.sight 'player'     # Setting target to player
  ogre.act!               # Acting @attacking.acquiring_target
                          # 2: Attack!     <- parent state act! first
                          # planning...
                          # AARGHH!
  # ogre.acquire        -> Hifsm::MissingTransition, already acquired in act!
  ogre.act!               # Acting @attacking.pursuing
                          # 3: Attack!
                          # step step player
  ogre.enemy_dead         # Woohoo!
  ogre.act!               # Acting @coming_back
                          # step step home

  ogre.sight 'player2'    # Setting target to player2
  ogre.acquire            # AARGHH!
  ogre.act!               # Acting @attacking.pursuing
                          # 5: Attack!
                          # step step player2
  ogre.reached
  puts ogre.state         # attacking.fighting
  ogre.act!               # Acting @attacking.fighting
                          # 6: Attack!
                          # ~~> player2
  5.times { ogre.act! }   # ...
  ogre.enemy_dead         # Woohoo!
  ogre.act!               # Acting @coming_back
                          # step step home
  ogre.low_hp = true
  ogre.sight 'player3'
  ogre.act!               # Acting @runaway
end
