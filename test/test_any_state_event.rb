require 'setup_tests'

class TestAnyStateEvent < Minitest::Test
  def setup
    @fsm = Hifsm::FSM.define do
      state :off, :initial => true
      state :on
      state :halt

      event :toggle, :from => :off, :to => :on
      event :toggle, :from => :on, :to => :off
      event :halt, :to => :halt
    end
    @machine = @fsm.new
  end

  def test_halt_from_off
    @machine.halt
    assert_equal 'halt', @machine.state
  end

  def test_halt_from_on
    @machine.toggle
    @machine.halt
    assert_equal 'halt', @machine.state
  end

end
