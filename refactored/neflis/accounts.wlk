import neflis.recommenders.*

// =====================================================================
// Neflis - accounts and profiles
// =====================================================================

// Clocks: the account depends on "something that knows today's date"
// (Dependency Inversion), so ages can be tested deterministically.
object systemClock {
  method today() = new Date()
}

class FixedClock {
  const today

  method today() = today
}

class Account {
  const plan
  const profiles = #{}
  const clock = systemClock

  method profiles() = profiles.copy()
  method profileCount() = profiles.size()
  method today() = clock.today()

  method allows(title) = title.isAvailableIn(plan)

  method createProfile(name, recommender, birthDate) {
    const profile = new Profile(name = name, account = self, recommender = recommender, birthDate = birthDate)
    profiles.add(profile)
    return profile
  }

  // A profile created without a recommender uses the default one.
  method createProfile(name, birthDate) = self.createProfile(name, defaultRecommender, birthDate)

  method isIdealToShare(title) = profiles.all { profile => profile.wouldBeRecommended(title) }
}

class Profile {
  const property name
  const account
  const birthDate
  var recommender
  const viewings = new Dictionary()  // watchable -> watched percentage (1..100)
  const scores = new Dictionary()    // title -> score (1..5)

  method initialize() {
    if (self.isMinor()) recommender = parentalControl
  }

  // ---- age and parental control -------------------------------------
  method age() {
    const today = account.today()
    const birthdayPending = today.month() * 100 + today.day() < birthDate.month() * 100 + birthDate.day()
    return today.year() - birthDate.year() - (if (birthdayPending) 1 else 0)
  }
  method isMinor() = self.age() < 13

  method changeRecommender(newRecommender) {
    if (self.isMinor()) self.error("A minor cannot change the recommender")
    recommender = newRecommender
  }

  // ---- watching -------------------------------------------------------
  method canWatch(title) = account.allows(title)

  method watch(content) { self.watch(content, 100) }

  method watch(content, percentage) {
    if (not percentage.between(1, 100)) self.error("The watched percentage must be between 1 and 100")
    // Double dispatch: the content knows whether it can be watched.
    content.beWatchedBy(self, percentage)
  }

  method watchMinutes(content, minutes) { self.watch(content, content.percentageFor(minutes)) }

  method recordViewing(watchable, percentage) {
    self.validateAccessTo(watchable.title())
    viewings.put(watchable, percentage)
  }

  method validateAccessTo(title) {
    if (not self.canWatch(title)) self.error(title.name() + " is not available in your current plan")
  }

  method hasViewed(watchable) = viewings.containsKey(watchable)
  method watched(content) = content.wasWatchedBy(self)
  method watchedPercentageOf(watchable) = viewings.getOrElse(watchable, { 0 })
  method hasWatchedNothing() = viewings.isEmpty()

  method watchedTitles() = viewings.keys().map { watchable => watchable.title() }.asSet()

  method averageRating() =
    if (self.hasWatchedNothing()) 0
    else self.watchedTitles().map { title => title.rating() }.average()

  // ---- scores -------------------------------------------------------------
  method score(title, points) {
    if (not self.watched(title)) self.error("You must watch " + title.name() + " before scoring it")
    if (not points.between(1, 5)) self.error("The score must be between 1 and 5")
    scores.put(title, points)
  }

  method scoreOf(title) = scores.getOrElse(title, { 0 })
  method likedTitles() = scores.keys().filter { title => self.scoreOf(title) >= 4 }
  method hasLikedAnything() = not self.likedTitles().isEmpty()
  method likesSomethingRelatedTo(title) = self.likedTitles().any { liked => liked.isRelatedTo(title) }

  // ---- recommendations ----------------------------------------------------
  method isVaried() = recommender.isVaried()

  method wouldBeRecommended(title) = not self.watched(title) and recommender.recommends(self, title)

  method recommendationsFrom(catalog) = catalog.titles().filter { title => self.wouldBeRecommended(title) }
}
