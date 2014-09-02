require 'setup_tests'

class TestEventGuard < Minitest::Test
  Wall = Struct.new(:stones)

  def setup
    @fsm = Hifsm::FSM.new do
      state :constructed, :initial => true
      state :broken

      event :break, :from => :constructed, :to => :broken, :guard => proc { stones < 5 }
    end
  end

  def test_cant_break_wall_10_stones_thick
    wall = Wall.new(10)
    machine = @fsm.machine(wall)
    assert_raises(Hifsm::MissingTransition) do
      wall.break
    end
  end

  def test_cant_break_thin_wall
    wall = Wall.new(3)
    machine = @fsm.machine(wall)
    wall.break
    assert_equal 'broken', machine.state
  end

end
