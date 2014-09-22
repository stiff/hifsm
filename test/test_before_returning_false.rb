require 'setup_tests'

class TestBeforeReturningFalse < Minitest::Test
  class Door
    extend Hifsm

    hifsm do
      state :open
      state :closed, :initial => true do
        state :unlocked, :initial => true
        state :locked do
          before_enter do
            nil # nil equals true in this case, like in Rails
          end
        end

        event :lock, :from => :unlocked, :to => :locked
      end

      event :open, :from => :closed, :to => :open do
        before do
          state != 'closed.locked'
        end
      end
      event :close, :from => :open, :to => :closed
    end
  end

  def setup
    @door = Door.new
  end

  def test_opening_locked_door_does_nothing
    @door.lock
    @door.open
    assert_equal 'closed.locked', @door.state
    # assert nothing raised
  end

  def test_valid_events_include_parent_state_events
    assert_equal ['lock', 'open'], @door.state_machine.valid_events.sort
  end

  def test_valid_events_include_parent_state_events
    @door.lock
    assert_equal ['open'], @door.state_machine.valid_events.sort
  end

end
