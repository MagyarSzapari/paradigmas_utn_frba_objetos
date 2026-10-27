// =====================================================================
// Pokemon exam - refactored model
//  1.  pokemon.greatness()
//  2a. move.useBetween(user, opponent)
//  2b. pokemon.fight(opponent)
//  3.  Confusion: added without touching the previous classes (Open/Closed)
// =====================================================================

class Pokemon {
  const maxHealth
  const moves = []
  var health = maxHealth
  var condition = normal
  // Dependency Inversion: the pokemon depends on "something that flips",
  // not on the random number generator. Tests inject a rigged coin.
  const coin = fairCoin

  method health() = health
  method condition() = condition
  method isAlive() = health > 0

  // Point 1
  method greatness() = maxHealth * moves.sum { move => move.power() }

  method heal(points) { health = (health + points).min(maxHealth) }
  method takeDamage(points) { health = (health - points).max(0) }

  method sufferCondition(newCondition) { condition = newCondition }
  method normalize() { condition = normal }

  method flipCoin() = coin.landsHeads()

  // Point 2b - the condition decides (dynamic binding) whether the action runs.
  method fight(opponent) {
    self.validateCanFight()
    opponent.validateCanFight()
    const move = self.availableMove()
    condition.attemptToAct(self, { move.useBetween(self, opponent) })
  }

  method validateCanFight() {
    if (not self.isAlive()) self.error("The pokemon is not alive")
  }

  method availableMove() = moves.findOrElse(
    { move => move.isAvailable() },
    { self.error("The pokemon has no available moves") }
  )
}

// ---------------------------------------------------------------------
// Moves - Template Method: useBetween is common, applyEffect varies
// ---------------------------------------------------------------------
class Move {
  var remainingUses

  method remainingUses() = remainingUses
  method isAvailable() = remainingUses > 0

  // Point 2a
  method useBetween(user, opponent) {
    if (not self.isAvailable()) self.error("The move has no uses left")
    remainingUses -= 1
    self.applyEffect(user, opponent)
  }

  method applyEffect(user, opponent)
  method power()
}

class HealingMove inherits Move {
  const healingPoints

  override method power() = healingPoints
  override method applyEffect(user, opponent) { user.heal(healingPoints) }
}

class DamagingMove inherits Move {
  const damage

  override method power() = 2 * damage
  override method applyEffect(user, opponent) { opponent.takeDamage(damage) }
}

class SpecialMove inherits Move {
  // Conditions are immutable, so the same instance can be shared safely
  // between the move and every pokemon it affects.
  const inflictedCondition

  override method power() = inflictedCondition.power()
  override method applyEffect(user, opponent) { opponent.sufferCondition(inflictedCondition) }
}

// ---------------------------------------------------------------------
// Conditions - polymorphic objects; the pokemon never asks "which one?"
// ---------------------------------------------------------------------
object normal {
  method attemptToAct(pokemon, action) { action.apply() }
}

class SpecialCondition {
  method power()

  // Template Method: the coin decides, the hooks specialize.
  method attemptToAct(pokemon, action) {
    if (pokemon.flipCoin())
      self.onMoveAllowed(pokemon, action)
    else
      self.onMoveBlocked(pokemon)
  }

  method onMoveAllowed(pokemon, action) { action.apply() }
  method onMoveBlocked(pokemon) { }
}

object paralysis inherits SpecialCondition {
  override method power() = 30
}

object sleep inherits SpecialCondition {
  override method power() = 50

  override method onMoveAllowed(pokemon, action) {
    pokemon.normalize()
    super(pokemon, action)
  }
}

// Point 3
class Confusion inherits SpecialCondition {
  const turns

  method turns() = turns
  override method power() = 40 * turns

  override method attemptToAct(pokemon, action) {
    pokemon.sufferCondition(self.afterOneTurn())
    super(pokemon, action)
  }

  override method onMoveBlocked(pokemon) { pokemon.takeDamage(20) }

  // Immutable: a new instance represents the remaining turns.
  method afterOneTurn() = if (turns > 1) new Confusion(turns = turns - 1) else normal
}

// ---------------------------------------------------------------------
// Coins (randomness behind an abstraction)
// ---------------------------------------------------------------------
object fairCoin {
  method landsHeads() = 0.randomUpTo(2).roundUp().even()
}

// Deterministic coin, useful for tests and simulations.
class RiggedCoin {
  const result

  method landsHeads() = result
}
