require 'setup_tests'

class TestEventGuard < Minitest::Test
  class Wall < Struct.new(:stones)
    extend Hifsm

    hifsm do
      state :constructed, :initial => true
      state :broken

      event :break do
        # guards can be inline proc, or symbols
        from :constructed, :to => :broken, :guard => proc { stones < 5 }

        # event parameters are passed to guards only if arity > 0
        from :constructed, :to => :broken, :guard => :breakable?

        before do |strength|
          @last_hit_strength = strength.to_s
        end
      end
    end

    attr_reader :last_hit_strength

    def breakable?(hits = 1)
      hits * 5 > stones
    end
  end

  def test_can_break_thin_wall
    wall = Wall.new(3)
    wall.break
    assert_equal 'broken', wall.state
    # before callback invoked
    assert_equal '', wall.last_hit_strength
  end

  def test_cant_break_wall_10_stones_thick
    wall = Wall.new(10)
    assert_raises(Hifsm::MissingTransition) do
      wall.break
    end
    # before callback not called
    assert_equal nil, wall.last_hit_strength
  end

  def test_can_break_thick_wall_if_hit_3_times
    wall = Wall.new(10)
    wall.break 3
    assert_equal 'broken', wall.state
    # before callback invoked
    assert_equal '3', wall.last_hit_strength
  end

  def test_valid_events_for_thick_wall_and_low_power
    wall = Wall.new(10)
    assert_equal [], wall.state_machine.valid_events
  end

  def test_valid_events_for_thick_wall_high_power
    wall = Wall.new(10)
    assert_equal ['break'], wall.state_machine.valid_events(3)
  end

  def test_valid_events_for_thin_wall
    wall = Wall.new(4)
    assert_equal ['break'], wall.state_machine.valid_events
  end

end
