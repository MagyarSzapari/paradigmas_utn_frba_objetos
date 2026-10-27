// =====================================================================
// Neflis - recommenders (Strategy)
// Every recommender understands the same interface:
//   recommends(profile, title)   isVaried()
// so the profile delegates without knowing which one it has.
// =====================================================================

// The deviation is the same for every user (statement), so a single
// configurable object is enough.
object similarRating {
  var deviation = 0.15

  method deviation() = deviation
  method changeDeviation(newDeviation) { deviation = newDeviation }

  method recommends(profile, title) =
    profile.hasWatchedNothing() or self.isSimilar(title.rating(), profile.averageRating())

  method isSimilar(rating, reference) =
    rating.between(reference * (1 - deviation), reference * (1 + deviation))

  method isVaried() = false
}

class GenrePreference {
  const genres = #{}

  method addGenre(genre) { genres.add(genre) }

  method recommends(profile, title) = title.hasAnyGenreOf(genres)

  method isVaried() = genres.size() >= 5
}

class FanMode {
  const favoriteActors = #{}

  method addFavoriteActor(actor) { favoriteActors.add(actor) }

  method recommends(profile, title) = title.featuresAnyOf(favoriteActors)

  method isVaried() = true
}

// Recommends what is related to the titles the profile liked (score 4 or 5);
// with nothing liked yet, it recommends the new releases.
object defaultRecommender {
  method recommends(profile, title) =
    if (profile.hasLikedAnything()) profile.likesSomethingRelatedTo(title)
    else title.isNewRelease()

  method isVaried() = true
}

object parentalControl {
  method recommends(profile, title) = title.hasGenre("Kids")

  method isVaried() = true
}
