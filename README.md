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

## Features

* Easy to use
* Nested states
* Parameterised events
* Support of both Mealy and Moore machines
* Lightweight and non-obtrusive

## Usage

Most features reside in a Hifsm::FSM class. Here is how to use it to model a monster in a Quake-like game:

```ruby
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

      action do
        puts "Attack!"
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
        self.target = t
      end
    end
    event :kill, :from => :attacking, :to => :coming_back
  end

  attr_accessor :target
  attr_reader :state
  delegate :act!, :to => :state

  def initialize
    @home = 'home'
  	@state = @@fsm.new(self) # or @@fsm.new('attacking.pursuing')
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

ogre = Monster.new
ogre.act!	# does nothing, idle
ogre.sight 'player' # ->
ogre.act!  # ->
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

If `before...` callback returns Hifsm.cancel then no further processing is done

On `act!` just calls action block if it was given.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
