require 'setup_tests'

class TestEventGuard < Minitest::Test
  def setup
    @wall = Struct.new(:stones).new(10)

    @fsm = Hifsm::FSM.define do
      state :constructed, :initial => true
      state :broken

      event :break, :from => :constructed, :to => :broken, :guard => proc { stones < 5 }
    end
    @machine = @fsm.new(@wall)
  end

  def test_cant_break_wall_10_stones_thick
    assert_raises(Hifsm::MissingTransition) do
      @wall.break
    end
  end

  def test_cant_break_thin_wall
    @wall.stones = 3
    @wall.break
    assert_equal 'broken', @machine.state
  end

end
