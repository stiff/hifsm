require 'setup_tests'

class TestHierarchical < Minitest::Test
  def setup
    @fsm = Hifsm::FSM.new do
      async = proc do
        state :pending, :initial => true
        state :sync do
          state :third_level, :initial => true
          state :third_level_two

          event :switch_levels do
            from :third_level, :to => :third_level_two
            from :third_level_two, :to => :third_level
          end
        end

        event :sync, :from => :pending, :to => :sync
      end

      state :off, :initial => true, &async
      state :on, &async

      event :toggle, :from => 'off.sync', :to => :on
      event :toggle, :from => 'on.sync', :to => 'off.sync'
    end
  end

  def test_initial_state_is_off_pending_by_default
    machine = @fsm.instantiate
    assert_equal 'off.pending', machine.state.to_s
  end

  def test_explicit_initial_state
    machine2 = @fsm.instantiate(nil, 'on.sync')
    assert_equal 'on.sync.third_level', machine2.state.to_s
    machine2.toggle
    pass # assert_nothing_raised
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
    assert_equal 'off.sync.third_level', machine.state.to_s
  end

  def test_toggle_from_off_sync_to_on_pending
    machine = @fsm.instantiate
    machine.sync
    machine.toggle
    assert_equal 'on.pending', machine.state.to_s
  end

  def test_toggle_from_on_sync_to_off_sync
    machine2 = @fsm.instantiate(nil, 'on.sync')
    machine2.toggle
    assert_equal 'third_level', machine2.state.name
    assert_equal 'off.sync.third_level', machine2.state.to_s
  end

  def test_machine_states
    machine = @fsm.instantiate
    assert_equal ["off", "on"], machine.states
  end

  def test_machine_all_states
    machine = @fsm.instantiate
    # note the all_states do not include states from test_machine_states
    assert_equal ["off.pending", "off.sync.third_level", "off.sync.third_level_two", "on.pending", "on.sync.third_level", "on.sync.third_level_two"], machine.all_states
  end
end
