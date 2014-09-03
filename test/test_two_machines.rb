require 'setup_tests'

class TestTwoMachines < Minitest::Test
  class ColorPrinter
    include Hifsm.fsm_module(:working_state) {
      state :off, :initial => true
      state :on do
        action do
          color_machine.to_s
        end
      end

      event :toggle, :from => :off, :to => :on
      event :toggle, :from => :on, :to => :off
    }
    include Hifsm.fsm_module(:color) {
      state :red, :initial => true
      state :green
      state :blue

      event :cycle_color!, :from => :red, :to => :green
      event :cycle_color!, :from => :green, :to => :blue
      event :cycle_color!, :from => :blue, :to => :red
    }
  end

  def setup
    @color_printer = ColorPrinter.new
  end

  def test_initial_state_is_off_and_red
    assert_equal 'off', @color_printer.working_state
    assert_equal 'red', @color_printer.color
  end

end
