# Hierarchical Finite State Machine in Ruby

This library was created from the desire to have nested states inspired by [rFSM](https://github.com/kmarkus/rFSM).

It can be used in plain old ruby objects, but works well with `ActiveRecord`s too.

## Installation

Add this line to your application's Gemfile:

    gem 'hifsm'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hifsm

I prefer 1.8-style hashes, and since no advanced Ruby magic used it should work in 1.8, but only tested in 2+.

__This is in early development, so be careful.__

## Features

* Easy to use
* Any number of state machines per object
* Nested states
* Parameterised events
* Support of both Mealy and Moore machines
* Lightweight and non-obtrusive

## Usage

Here is how to use it to model a monster in a Quake-like game. It covers most Hifsm features:

```ruby
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
  attr_reader :state

  def initialize
    @debug = false
    @home = 'home'
    @state = @@fsm.new(self) # or @@fsm.new(self, 'attacking.pursuing')
    @tick = 1
    @low_hp = false
  end

  def act!
    debug && puts("Acting @#{@state}")
    @state.act!(@tick)
    @tick = @tick + 1
  end

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

ogre = Monster.new
ogre.debug = true       # Console output:
ogre.act!               # -> Acting @idle
ogre.sight 'player'     # -> Setting target to player
ogre.act!               # -> Acting @attacking.acquiring_target
                        # -> planning...
                        # -> AARGHH!
# ogre.acquire        -> Hifsm::MissingTransition, already acquired in act!
ogre.act!               # -> Acting @attacking.pursuing
                        # -> step step player
ogre.enemy_dead         # -> Woohoo!
ogre.act!               # -> Acting @coming_back

ogre.sight 'player2'    # -> Setting target to player2
ogre.acquire            # -> AARGHH!
ogre.act!               # -> Acting @attacking.pursuing
                        # -> step step player2
ogre.reached
puts ogre.state         # -> attacking.fighting
ogre.act!               # -> ~~> player2
5.times { ogre.act! }   # -> ...
ogre.enemy_dead         # -> Woohoo!
ogre.act!               # -> Acting @coming_back
                        # -> step step home

```

## Guards

Events are tried in order they were defined, if guard callback returns `false` then event is skipped.

## Callbacks

On event:

* event.before
* to_state.before_enter
* from_state.before_exit
* *state changes*
* from_state.after_exit
* to_state.after_enter
* event.after

If `before...` callback returns `false` then no further processing is done

On `act!` just calls action block if it was given.

## Testing

Only 'public' API is unit-tested, internal implementation may be freely changed, so don't rely on it.

To run tests use `bundle exec rake test`

Try also `bundle exec ruby test/monster.rb`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
