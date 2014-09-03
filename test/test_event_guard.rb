require 'setup_tests'

class TestEventGuard < Minitest::Test
  class Wall < Struct.new(:stones)
    def breakable?(hits)
      hits * 5 > stones
    end
  end

  def build_wall(thickness)
    fsm = Hifsm::FSM.new do
      state :constructed, :initial => true
      state :broken

      # guards can be inline proc, or symbols
      event :break, :from => :constructed, :to => :broken, :guard => proc { stones < 5 }

      # event parameters are passed to guards only if arity > 0
      event :shoot, :from => :constructed, :to => :broken, :guard => :breakable?
    end
    wall = Wall.new(thickness)
    @machine = fsm.instantiate(wall)
    wall
  end

  def test_cant_break_wall_10_stones_thick
    wall = build_wall 10
    assert_raises(Hifsm::MissingTransition) do
      wall.break
    end
  end

  def test_cant_break_thin_wall
    wall = build_wall 3
    wall.break
    assert_equal 'broken', @machine.state
  end

  def test_can_break_thick_wall_if_hit_3_times
    wall = build_wall 10
    wall.shoot 3
    assert_equal 'broken', @machine.state
  end

end
