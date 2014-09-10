require 'setup_tests'

class TestDynamicInitialState < Minitest::Test
  class Value < Struct.new(:value)
    extend Hifsm
    hifsm :group do
      state :few do
        state :very
        state :almost
      end
      state :lots do
        state :very
        state :almost, :initial => true
      end
      state :throng
      state :swarm
    end

    def initial_group
      case value
      when 1..5 then 'few.very'
      when 5..10 then 'few.almost'
      when 10..50 then :lots
      when 50..150 then :throng
      when 150..1000 then :swarm
      else :unknown
      end
    end
  end

  def test_initial_group_3
    assert_equal 'few.very', Value.new(3).group
  end

  def test_initial_group_7
    assert_equal 'few.almost', Value.new(7).group
  end

  def test_initial_group_30
    assert_equal 'lots.almost', Value.new(30).group
  end

  def test_initial_group_120
    assert_equal 'throng', Value.new(120).group
  end

  def test_unknown_intiial_group
    assert_raises(Hifsm::MissingState) do
      Value.new(-3).group
    end
  end
end
