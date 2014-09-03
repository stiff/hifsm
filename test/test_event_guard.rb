require 'setup_tests'

class TestEventGuard < Minitest::Test
  Wall = Struct.new(:stones)

  def build_wall(thickness)
    fsm = Hifsm::FSM.new do
      state :constructed, :initial => true
      state :broken

      event :break, :from => :constructed, :to => :broken, :guard => proc { stones < 5 }
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

end
