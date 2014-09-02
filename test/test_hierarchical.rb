require 'setup_tests'

class TestHierarchical < Minitest::Test
  def setup
    @fsm = Hifsm::FSM.new do
      sync_fsm = proc do
        state :pending, :initial => true
        state :sync

        event :sync, :from => :pending, :to => :sync
      end

      state :off, :initial => true, &sync_fsm
      state :on, &sync_fsm

      event :toggle, :from => 'off.sync', :to => :on
      event :toggle, :from => 'on.sync', :to => 'off.sync'
    end
  end

  def test_initial_state_is_off_pending_by_default
    machine = @fsm.instantiate
    assert_equal 'off.pending', machine.state
  end

  def test_explicit_initial_state
    machine2 = @fsm.instantiate(nil, 'on.sync')
    assert_equal 'on.sync', machine2.state
    # assert_nothing_raised
    machine2.toggle
    pass
  end

  def test_toggle_raises_an_error_in_pending_state
    machine = @fsm.instantiate
    assert_raises(Hifsm::MissingTransition) do
      machine.toggle
    end
  end

  def test_sync
    machine = @fsm.instantiate
    machine.sync
    assert_equal 'off.sync', machine.state
  end

  def test_toggle_from_off_sync_to_on_pending
    machine = @fsm.instantiate
    machine.sync
    machine.toggle
    assert_equal 'on.pending', machine.state
  end

  def test_toggle_from_on_sync_to_off_sync
    machine2 = @fsm.instantiate(nil, 'on.sync')
    machine2.toggle
    assert_equal 'off.sync', machine2.state
  end
end
