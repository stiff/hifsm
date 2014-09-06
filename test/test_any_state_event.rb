require 'setup_tests'

class TestAnyStateEvent < Minitest::Test
  def setup
    @fsm = Hifsm::FSM.new do
      state :off, :initial => true
      state :on
      state :halt

      event :toggle, :from => :off, :to => :on
      event :toggle, :from => :on, :to => :off
      event :halt, :to => :halt
    end
    @machine = @fsm.instantiate
  end

  def test_halt_from_off
    @machine.halt
    assert_equal 'halt', @machine.state.to_s
  end

  def test_halt_from_on
    @machine.toggle
    @machine.halt
    assert_equal 'halt', @machine.state.to_s
  end

  def test_event_is_added_to_states
    assert_equal ['toggle', 'halt'], @machine.state.events
  end

end
