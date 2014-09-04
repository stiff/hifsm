require 'setup_tests'

class TestEventGuard < Minitest::Test
  class Wall < Struct.new(:stones)
    include Hifsm

    hifsm do
      state :constructed, :initial => true
      state :broken

      # guards can be inline proc, or symbols
      event :break, :from => :constructed, :to => :broken, :guard => proc { stones < 5 }

      # event parameters are passed to guards only if arity > 0
      event :shoot, :from => :constructed, :to => :broken, :guard => :breakable?
    end

    def breakable?(hits)
      hits * 5 > stones
    end
  end

  def test_can_break_thin_wall
    wall = Wall.new(3)
    wall.break
    assert_equal 'broken', wall.state
  end

  def test_cant_break_wall_10_stones_thick
    wall = Wall.new(10)
    assert_raises(Hifsm::MissingTransition) do
      wall.break
    end
  end

  def test_can_break_thick_wall_if_hit_3_times
    wall = Wall.new(10)
    wall.shoot 3
    assert_equal 'broken', wall.state
  end

end
