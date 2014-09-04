# Hierarchical Finite State Machine in Ruby

[![Build Status](https://travis-ci.org/stiff/hifsm.svg?branch=master)](https://travis-ci.org/stiff/hifsm)
[![Coverage Status](https://coveralls.io/repos/stiff/hifsm/badge.png?branch=master)](https://coveralls.io/r/stiff/hifsm?branch=master)

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
  include Hifsm.fsm_module {
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
  }

  attr_accessor :target, :low_hp, :debug

  def initialize
    @debug = false
    @home = 'home'
    @tick = 1
    @low_hp = false
  end

  def act!
    debug && puts("Acting @#{state}")
    state_machine.act! @tick
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

```

Note the use of `{..}` construct instead of `do..end` in `include`. `do..end` is treated as block for include itself, instead of `fsm_module`.

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

If any of `before...` callbacks returns `false` then no further processing is done, no exceptions raised, machine state is not changed.

On `act!` just calls action block if it was given.

## ActiveRecord integration

Add column to your database which would hold the state, and then:

```ruby
class Order < ActiveRecord::Base
  hifsm do
    state :draft, :initial => true
    state :processing do
      state :packaging, :initial => true
      state :delivering
    end
    state :done
    state :cancelled

    event :start_processing, :from => :draft, :to => :processing
    event :cancel, :to => :cancelled
  end
end
Order.new # draft

```

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
