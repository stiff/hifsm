require 'setup_tests'

class TestGrouppedTransitions < Minitest::Test
  class Button
    include Hifsm

    hifsm do
      state :active, :initial => true
      state :alternative
      state :disabled

      # each :to generates new event
      event :click, :to => :disabled, :guard => :disable_on_click
      event :click, :from => :disabled, :to => :disabled
      event :click do
        from :active, :to => :alternative
        from :alternative, :to => :active

        after do
          log << "alternated"
        end
      end
    end

    attr_accessor :disable_on_click, :log

    def initialize
      self.log = []
    end
  end

  def setup
    @button = Button.new
  end

  def test_click_from_active
    @button.click
    assert_equal 'alternative', @button.state
    assert_equal ['alternated'], @button.log
  end

  def test_click_with_disable_on_click
    @button.disable_on_click = true
    @button.click
    assert_equal 'disabled', @button.state
    assert_equal [], @button.log
  end

  def test_click_from_disabled
    @button.disable_on_click = true
    @button.click
    @button.disable_on_click = false
    @button.click
    assert_equal 'disabled', @button.state
    assert_equal [], @button.log
  end

end
