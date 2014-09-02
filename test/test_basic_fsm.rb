require 'setup_tests'

class TestBasicFSM < Minitest::Test
  def setup
    @fsm = Hifsm::FSM.new do
      state :off, :initial => true
      state :on

      event :toggle, :from => :off, :to => :on
      event :toggle, :from => :on, :to => :off
    end
    @machine = @fsm.machine
  end

  def test_initial_state_is_off
    assert_equal 'off', @machine.state
  end

  def test_toggle_switches_state_to_on
    @machine.toggle
    assert_equal 'on', @machine.state
  end

  def test_toggle_twice_switches_state_back_to_off
    @machine.toggle
    @machine.toggle
    assert_equal 'off', @machine.state
  end
end
