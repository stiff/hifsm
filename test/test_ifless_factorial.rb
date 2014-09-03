require 'setup_tests'

class TestIflessFactorial < Minitest::Test
  class Value < Struct.new(:value)
    include Hifsm.fsm_module {
      state :idle, :initial => true
      state :computing

      event :compute, :to => :idle do
        guard { |x| x == 0 }
        after { |x| self.value = 1 }
      end
      event :compute, :to => :computing do
        after do |x|
          compute(x - 1)
          self.value *= x
        end
      end
    }
  end

  def factorial(n)
    val = Value.new
    val.compute(n).value
  end

  def test_factorial_0
    assert_equal 1, factorial(0)
  end

  def test_factorial_5
    assert_equal 120, factorial(5)
  end

  def test_factorial_100
    assert_equal 93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000, factorial(100)
  end
end
