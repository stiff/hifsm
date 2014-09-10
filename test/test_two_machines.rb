require 'setup_tests'

class TestTwoMachines < Minitest::Test
  class ColorPrinter < Struct.new(:log)
    extend Hifsm

    hifsm :color do
      state :red, :initial => true
      state :green
      state :blue do
        action do
          self.log = [log, 'blue'].compact.join(' ; ')
        end
      end

      event :cycle_color! do
        from :red, :to => :green
        from :green, :to => :blue
        from :blue, :to => :red
      end
    end

    hifsm :working_state do
      state :off, :initial => true
      state :on do
        action do
          'printing ' + color_machine.to_s
        end
      end

      event :toggle, :from => :off, :to => :on
      event :toggle, :from => :on, :to => :off
    end
  end

  def setup
    @color_printer = ColorPrinter.new
  end

  def test_two_machines_defined
    assert_equal 'off', @color_printer.working_state_machine.state.to_s
    assert_equal 'red', @color_printer.color_machine.state.to_s
    assert_equal 'red', @color_printer.color # alias for color_mathine.state.to_s
  end

  def test_initial_state_is_off_and_red
    assert_equal 'off', @color_printer.working_state
    assert_equal 'red', @color_printer.color
  end

  def test_color_changes_independently
    @color_printer.cycle_color!
    assert_equal 'off', @color_printer.working_state
    assert_equal 'green', @color_printer.color
  end

  def test_working_state_changes_independently
    @color_printer.cycle_color!
    assert_equal 'off', @color_printer.working_state
    assert_equal 'green', @color_printer.color
  end

  def test_both_machines_act
    @color_printer.cycle_color!
    @color_printer.toggle
    @color_printer.cycle_color!
    assert_equal 'printing blue', @color_printer.act!
    assert_equal 'blue', @color_printer.log
  end

end
