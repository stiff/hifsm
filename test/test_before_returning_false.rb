require 'setup_tests'

class TestBeforeReturningFalse < Minitest::Test
  class Door
    include Hifsm

    hifsm do
      state :open
      state :closed, :initial => true do
        state :unlocked, :initial => true
        state :locked

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

end
