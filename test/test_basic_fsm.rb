require 'setup_tests'

class TestBasicFSM < Minitest::Test
  def setup
    @fsm = Hifsm::FSM.new do
      state :off, :initial => true
      state :on

      event :toggle, :from => :off, :to => :on
      event :toggle, :from => :on, :to => :off
    end
    @machine = @fsm.instantiate
  end

  def test_initial_state_is_off
    assert_equal 'off', @machine.state.to_s
  end

  def test_state_question_methods
    refute @machine.on?, "Machine .on? should be false"
    assert @machine.off?, "Machine .off? should be true"
  end

  def test_toggle_switches_state_to_on
    @machine.toggle
    assert_equal 'on', @machine.state.to_s
  end

  def test_toggle_twice_switches_state_back_to_off
    @machine.toggle
    @machine.toggle
    assert_equal 'off', @machine.state.to_s
  end

  def test_instantiating_maching_in_unknown_state_raises_error
    assert_raises(Hifsm::MissingState) do
      @fsm.instantiate(nil, 'on.no')
    end
  end

end
