// =====================================================================
// Neflis - contents
//
//            Title (abstract)                 Watchable (mixin)
//            /          \                     /            \
//        Movie         Series ---> Season ---> Episode    Movie
//
// * Titles (Movie, Series) are what a plan allows and what gets
//   recommended or rated.
// * Watchables (Movie, Episode) are what a profile can actually watch,
//   because they have a duration.
// * Every content (Movie, Series, Season, Episode) answers wasWatchedBy:
//   the containers delegate to their parts (Composite).
// =====================================================================

// ---------------------------------------------------------------------
// Mixins: behavior shared by classes that are not in the same hierarchy
// ---------------------------------------------------------------------
mixin Watchable {
  method durationInMinutes()
  method title()

  method beWatchedBy(profile, percentage) { profile.recordViewing(self, percentage) }
  method wasWatchedBy(profile) = profile.hasViewed(self)
  method percentageFor(minutes) = (minutes / self.durationInMinutes() * 100).min(100)
}

mixin Unwatchable {
  method beWatchedBy(profile, percentage) {
    throw new DomainException(message = "A series or a season cannot be watched: watch one of its episodes")
  }
  method percentageFor(minutes) {
    throw new DomainException(message = "A series or a season cannot be watched: watch one of its episodes")
  }
}

// ---------------------------------------------------------------------
// Titles
// ---------------------------------------------------------------------
class Title {
  const property name
  const genres = #{}
  const actors = #{}
  const requiredPlan
  const isNewRelease = false
  // Strategy injected by composition; each subclass suggests a default.
  const ratingCriterion = self.defaultRatingCriterion()
  const relatedTitles = #{}

  method defaultRatingCriterion()

  method rating() = ratingCriterion.ratingOf(self)

  method genreCount() = genres.size()
  method hasGenre(genre) = genres.contains(genre)
  method hasAnyGenreOf(someGenres) = someGenres.any { genre => self.hasGenre(genre) }
  method featuresAnyOf(someActors) = someActors.any { actor => actors.contains(actor) }
  method isNewRelease() = isNewRelease

  // Delegation: the plan decides what it covers.
  method isAvailableIn(plan) = plan.covers(requiredPlan)

  // "Titles are related to each other when the content is similar" (symmetric).
  method relateTo(otherTitle) {
    self.addRelatedTitle(otherTitle)
    otherTitle.addRelatedTitle(self)
  }
  method addRelatedTitle(otherTitle) { relatedTitles.add(otherTitle) }
  method isRelatedTo(otherTitle) = relatedTitles.contains(otherTitle)
}

class Movie inherits Watchable and Title {
  const property durationInMinutes

  override method defaultRatingCriterion() = genreBasedRating
  override method title() = self
}

class Series inherits Unwatchable and Title {
  const seasonCount
  const episodesPerSeason
  const episodeMinutes
  // A fully released series by default; a weekly-premiere one starts at 0.
  const releasedEpisodesPerSeason = episodesPerSeason
  const seasons = []

  method initialize() {
    seasonCount.times { number =>
      seasons.add(new Season(series = self, number = number, maxEpisodes = episodesPerSeason))
    }
    seasons.forEach { season => season.releaseEpisodes(releasedEpisodesPerSeason, episodeMinutes) }
  }

  override method defaultRatingCriterion() = plannedEpisodesRating

  method seasons() = seasons.copy()
  method season(number) = seasons.get(number - 1)
  method lastSeason() = seasons.last()
  method pilot() = seasons.first().firstEpisode()
  method plannedEpisodes() = seasons.sum { season => season.maxEpisodes() }

  // Weekly premieres go to the last season.
  method premiere(episodeName) { self.lastSeason().premiere(episodeName, episodeMinutes) }

  method wasWatchedBy(profile) = seasons.any { season => season.wasWatchedBy(profile) }
}

class Season inherits Unwatchable {
  const property series
  const number
  const property maxEpisodes
  const episodes = []

  method episodes() = episodes.copy()
  method episodeCount() = episodes.size()
  method hasRoomForAnotherEpisode() = self.episodeCount() < maxEpisodes

  method premiere(episodeName, minutes) {
    if (not self.hasRoomForAnotherEpisode())
      self.error("Season " + number + " of " + series.name() + " already has its " + maxEpisodes + " episodes")
    episodes.add(new Episode(name = episodeName, durationInMinutes = minutes, season = self))
  }

  method releaseEpisodes(amount, minutes) {
    amount.times { episodeNumber =>
      self.premiere(series.name() + " S" + number + "E" + episodeNumber, minutes)
    }
  }

  method firstEpisode() = episodes.first()

  method wasWatchedBy(profile) = episodes.any { episode => episode.wasWatchedBy(profile) }
}

class Episode inherits Watchable {
  const property name
  const property durationInMinutes
  const season

  // The title of an episode is its series (used by plans and ratings).
  override method title() = season.series()
}

// ---------------------------------------------------------------------
// Rating criteria (Strategy): stateless ones are singletons
// ---------------------------------------------------------------------
object genreBasedRating {
  method ratingOf(title) = title.genreCount() * 12
}

object plannedEpisodesRating {
  method ratingOf(series) = series.plannedEpisodes()
}

class FixedRating {
  const value

  method ratingOf(title) = value
}
