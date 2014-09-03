require 'setup_tests'
require 'active_record'

class TestActiverecrodAdapter < Minitest::Test
  class SodaMachine < ActiveRecord::Base
    hifsm :state do
      state :off, :initial => true
      state :on do
        state :idle, :initial => true
        state :accepting_cash
        state :cooking
        state :ready

        event :done, :from => :accepting_cash, :to => :cooking
        event :done, :from => :cooking, :to => :ready
        event :done, :from => :ready, :to => :idle do
          after { self.counter += 1 }
        end
      end
      state :broken

      event :toggle_power, :from => :off, :to => :on
      event :toggle_power, :from => :on, :to => :off
      event :break, :to => :broken
    end
  end

  def setup
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
    ActiveRecord::Base.connection.create_table :soda_machines do |t|
      t.column :address, :string
      t.column :state, :string
      t.column :counter, :integer, :null => false, :default => 0
    end

    insert_record 'South Park', 'on.idle'
    insert_record 'Springfield', 'broken'
  end

  def teardown
    ActiveRecord::Base.connection.disconnect!
  end

  def test_hifsm_installed
    @machine = SodaMachine.create
    assert @machine.state_machine.is_a?(Hifsm::Machine), ".state should be Hifsm::Mahine"
  end

  def test_new_machines_saved_in_initial_state
    @machine = SodaMachine.create
    assert_equal 'off', @machine.state_machine.state
    assert_equal 'off', @machine.state
  end

  def test_state_fetched_from_db
    @machine = SodaMachine.where(:address => 'South Park').first
    assert_equal 'on.idle', @machine.state.to_s
  end

  def test_events_defined_on_record
    @machine = SodaMachine.first
    @machine.toggle_power.save
    pass # assert_nothing_raised
  end

  def test_state_saved_in_db
    @machine = SodaMachine.where(:address => 'South Park').first
    @machine.toggle_power.save
    assert_equal 'off', SodaMachine.where(:id => @machine.id).pluck(:state).first
  end

  private
    def insert_record(address, state)
      insert_manager = Arel::InsertManager.new(SodaMachine)
      insert_manager.insert([[SodaMachine.arel_table[:address], address], [SodaMachine.arel_table[:state], state]])
      ActiveRecord::Base.connection.insert insert_manager
    end

end

