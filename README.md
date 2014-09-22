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

Written in Ruby 1.8-style (hashes, lambdas), but few non-essential 1.9 niceties used, tested in 2+.

## Features

* Easy to use
* Any number of state machines per object
* Nested states
* Parameterised events
* Support of both Mealy and Moore machines
* Lightweight and non-obtrusive

## Usage

Start with the [basic example](https://github.com/stiff/hifsm/blob/master/test/test_basic_fsm.rb) and then try [something](https://github.com/stiff/hifsm/blob/master/test/test_hierarchical.rb) [more](https://github.com/stiff/hifsm/blob/master/test/test_many_states.rb) [interesting](https://github.com/stiff/hifsm/blob/master/test/test_dynamic_initial_state.rb).

Here is how to use it to model a monster in a Quake-like game. It covers most Hifsm features:

```ruby
require 'hifsm'

class Monster
  extend Hifsm

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
          true # since it would stop processing if roar! returns false
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
# ogre.attacking_fighting? = true
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

## Guards

Events are tried in order they were defined, if guard callback returns `false` then event is skipped as if it was not defined at all. See [example of this](https://github.com/stiff/hifsm/blob/master/test/test_event_guard.rb).

## Callbacks

On event:

* event.before
* to_state.before_enter
* from_state.before_exit
* *state changes*
* from_state.after_exit
* to_state.after_enter
* event.after

If any of `before...` callbacks returns `false` (literally, `nil` equals to `true` here) then no further processing is done, no exceptions raised, machine state is not changed.

On `act!` state's actions called from top state to nested. If [several FSMs defined](https://github.com/stiff/hifsm/blob/master/test/test_two_machines.rb), object's `act!` invokes them all in order as they were defined and returns value from last action.

## ActiveRecord integration

Add column to your database which would hold the state, and then:

```ruby
class Order < ActiveRecord::Base
  hifsm :status do
    state :draft, :initial => true
    state :processing do
      state :packaging, :initial => true
      state :delivering

      event :start_delivery, :from => :packaging, :to => :delivering
    end
    state :done
    state :cancelled

    event :start_processing, :from => :draft, :to => :processing
    event :cancel!, :to => :cancelled
  end
end
order = Order.create          # draft
order.start_processing.save   # 'processing.packaging'

# scopes defined automatically. parent scopes looked up via like "processing.%"
Order.processing.first.start_delivery.save
Order.first.processing?                         # true
Order.first.processing_delivering?              # true
Order.processing_packaging.first                # nil
Order.processing_delivering.first.cancel!.save  # save is never called inisde hifsm

```

## Get possible transitions from current state

The machine instance has `valid_events` method, with accepts arguments, that are passed to all event guards to find out if it is possible to fire the event.

```ruby
monster.state_machine.valid_events # -> ['reached', 'sight', 'acquire', ...]
```

The order of events is not guaranteed, events for parent states are included.

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
