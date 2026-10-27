// =====================================================================
// Yaaar! exam - refactored model
//  1.  mission.isUsefulFor(pirate)
//  2.  ship.canRecruit(pirate) / ship.recruit(pirate) / ship.changeMission(mission)
//  3.  ship.mostDrunkCrewMember() / ship.anchorAt(town)
//  4.  ship.isFearsome() / CrownSpy
//  5.  ship.wastedCrewCount() / ship.wastedCrewItemTypes() / ship.richestWastedCrewMember()
//  6.  ship.topInviter()
// Items are plain strings, as the statement suggests.
// =====================================================================

class PirateShip {
  var mission
  const capacity
  const crew = #{}

  method crew() = crew.copy()
  method crewSize() = crew.size()

  // Point 2.a
  method hasRoom() = capacity > self.crewSize()
  method canRecruit(pirate) = self.hasRoom() and mission.isUsefulFor(pirate)

  // Point 2.b
  method recruit(pirate) {
    if (not self.canRecruit(pirate)) self.error("The pirate cannot join this ship")
    crew.add(pirate)
  }

  // Point 6 - the invitation is recorded only when the recruitment succeeds.
  method recruitInvitedBy(pirate, inviter) {
    if (not crew.contains(inviter)) self.error("The inviter is not part of the crew")
    self.recruit(pirate)
    pirate.beInvitedBy(inviter)
  }

  // Point 2.c
  method changeMission(newMission) {
    mission = newMission
    crew.removeAllSuchThat { pirate => not newMission.isUsefulFor(pirate) }
  }

  // Point 3.a
  method mostDrunkCrewMember() = crew.max { pirate => pirate.drunkenness() }

  // Point 3.b
  method anchorAt(town) {
    crew.filter { pirate => pirate.canAfford(1) }.forEach { pirate => pirate.drinkGrog() }
    const lostPirate = self.mostDrunkCrewMember()
    crew.remove(lostPirate)
    town.welcome(lostPirate)
  }

  // Point 4.a
  method isFearsome() = mission.canBeAccomplishedBy(self)

  method hasEnoughCrew() = self.crewSize() >= capacity * 0.9
  method anyCrewMemberHas(item) = crew.any { pirate => pirate.has(item) }
  method wholeCrewIsWasted() = crew.all { pirate => pirate.isWasted() }

  // A ship can also be a plunder victim (same interface as CoastalTown).
  method isLootableBy(pirate) = pirate.isWasted()
  method isVulnerableTo(attacker) = self.crewSize() <= attacker.crewSize() / 2

  // Point 5 - a single query reused by the three questions (no repeated code).
  method wastedCrew() = crew.filter { pirate => pirate.isWasted() }
  method wastedCrewCount() = self.wastedCrew().size()
  method wastedCrewItemTypes() = self.wastedCrew().flatMap { pirate => pirate.items() }.asSet().size()
  method richestWastedCrewMember() = self.wastedCrew().max { pirate => pirate.coins() }

  // Point 6
  method topInviter() = crew.max { pirate => self.guestsOf(pirate) }
  method guestsOf(inviter) = crew.count { pirate => pirate.wasInvitedBy(inviter) }

  // Kept from the original solution: the item fewer crew members carry.
  method rarestItem() = self.allItems().min { item => self.crewMembersWith(item) }
  method allItems() = crew.flatMap { pirate => pirate.items() }.asSet()
  method crewMembersWith(item) = crew.count { pirate => pirate.has(item) }
}

class CoastalTown {
  var inhabitants

  method inhabitants() = inhabitants

  method isLootableBy(pirate) = pirate.isDrunkAtLeast(50)
  method isVulnerableTo(ship) =
    ship.crewSize() >= inhabitants * 0.4 or ship.wholeCrewIsWasted()

  method welcome(pirate) { inhabitants += 1 }
}

// ---------------------------------------------------------------------
// Pirates
// ---------------------------------------------------------------------

// Null Object for "invited by nobody" (founding crew members).
object nobody { }

class Pirate {
  var coins = 0
  const items = []
  var drunkenness = 0
  var inviter = nobody

  method coins() = coins
  method drunkenness() = drunkenness
  method items() = items.copy()

  method has(item) = items.contains(item)
  method itemCount() = items.size()

  method canAfford(amount) = coins >= amount
  method hasFewerCoinsThan(amount) = coins < amount
  method hasAtMostCoins(amount) = coins <= amount
  method isDrunkAtLeast(level) = drunkenness >= level

  method drinkGrog() {
    self.spend(1)
    drunkenness += 5
  }

  method spend(amount) {
    if (not self.canAfford(amount)) self.error("The pirate cannot afford " + amount + " coins")
    coins -= amount
  }

  method isWasted() = self.isDrunkAtLeast(90)

  // Double dispatch: the victim decides what it takes to dare to loot it.
  method daresToLoot(victim) = victim.isLootableBy(self)

  method beInvitedBy(aPirate) { inviter = aPirate }
  method wasInvitedBy(aPirate) = inviter == aPirate
}

// Point 4.b - inheritance is right here: a spy IS a pirate with two tweaks.
class CrownSpy inherits Pirate {
  override method isWasted() = false
  override method daresToLoot(victim) = super(victim) and self.has("crown permit")
}

// ---------------------------------------------------------------------
// Missions - Template Method: common requirement + specific hook
// ---------------------------------------------------------------------
class Mission {
  method isUsefulFor(pirate)

  method canBeAccomplishedBy(ship) =
    ship.hasEnoughCrew() and self.meetsSpecificRequirements(ship)

  method meetsSpecificRequirements(ship) = true
}

class TreasureHunt inherits Mission {
  const usefulItems = #{"compass", "map", "grogXD bottle"}

  override method isUsefulFor(pirate) =
    usefulItems.any { item => pirate.has(item) } and pirate.hasAtMostCoins(5)

  override method meetsSpecificRequirements(ship) = ship.anyCrewMemberHas("chest key")
}

class BecomeALegend inherits Mission {
  const requiredItem

  override method isUsefulFor(pirate) = pirate.itemCount() >= 10 and pirate.has(requiredItem)
}

class Plunder inherits Mission {
  const victim

  override method isUsefulFor(pirate) =
    pirate.hasFewerCoinsThan(plunderRules.coinLimit()) and pirate.daresToLoot(victim)

  override method meetsSpecificRequirements(ship) = victim.isVulnerableTo(ship)
}

// The same (configurable) coin limit applies to every plunder.
object plunderRules {
  var coinLimit = 10

  method coinLimit() = coinLimit
  method changeCoinLimit(newLimit) { coinLimit = newLimit }
}
