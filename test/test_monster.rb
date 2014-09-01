require 'setup_tests'
require 'monster'

class TestMonster < Minitest::Test
  def setup
    @monster = Monster.new
  end

  def test_initial_state_is_idle
    assert_equal 'idle', @monster.state.to_s
  end

  def test_acting_from_idle_state
    @monster.act!
    pass
  end

  def test_will_attack_player_on_sight_if_alot_hp
    @monster.sight 'player'
    assert_equal 'attacking.acquiring_target', @monster.state.to_s
    assert_equal 'player', @monster.target
  end

  def test_will_runaway_on_sight_if_low_hp
    @monster.low_hp = true
    @monster.sight 'player'
    assert_equal 'runaway', @monster.state.to_s
    assert_nil @monster.target
  end

  def test_will_pursue_player_on_acquire
    @monster.sight 'player'
    @monster.acquire
    assert_equal 'attacking.pursuing', @monster.state.to_s
  end

  def test_kill_in_middle_of_attack
    @monster.sight 'player'
    @monster.acquire
    @monster.enemy_dead
    assert_equal 'coming_back', @monster.state.to_s
  end

end
