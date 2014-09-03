require 'setup_tests'

class TestManyStates < Minitest::Test
  def inefficient_factorial(n)
    fsm = Hifsm::FSM.new do
      state :value0 do
        action { 1 }
      end
      (1..n).each do |x|
        state "value#{x}" do
          action do
            x * prev.act!
          end
        end
        event :prev, :from => "value#{x}", :to => "value#{x - 1}"
      end
    end
    machine = fsm.instantiate(nil, "value#{n}")
    machine.act!
  end

  def test_factorial_0
    assert_equal 1, inefficient_factorial(0)
  end

  def test_factorial_5
    assert_equal 120, inefficient_factorial(5)
  end

  def test_factorial_100
    assert_equal 93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000, inefficient_factorial(100)
  end

end
