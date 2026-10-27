import neflis.content.*
import neflis.plans.*

// =====================================================================
// Neflis - catalog (example data from the statement)
// Titles, actors and genres are DATA: proper names keep their original
// spelling; genres are written in English to keep a single vocabulary.
// =====================================================================

class Catalog {
  const titles = #{}

  method titles() = titles.copy()
  method add(title) { titles.add(title) }
}

// ---- Series -------------------------------------------------------------
const blackSails = new Series(
  name = "Black Sails",
  genres = #{"Action", "Drama", "Adventure"},
  actors = #{"Toby Stephens", "Luke Arnold", "Toby Schmitz", "Hannah New", "Jessica Parker Kennedy"},
  seasonCount = 4, episodesPerSeason = 8, episodeMinutes = 45,
  requiredPlan = basicPlan
)

const seanEternos = new Series(
  name = "Sean Eternos",
  genres = #{"Documentary"},
  actors = #{"Lionel Messi", "Angel Di Maria", "Xavi Hernández", "Luis Suarez"},
  seasonCount = 1, episodesPerSeason = 3, episodeMinutes = 50,
  ratingCriterion = new FixedRating(value = 100),
  requiredPlan = premiumPlan,
  isNewRelease = true
)

const theWitcher = new Series(
  name = "The Witcher",
  genres = #{"Action", "Fantasy", "Drama", "Mystery"},
  actors = #{"Henry Cavill", "Freya Allan", "Anya Chalotra"},
  seasonCount = 3, episodesPerSeason = 8, episodeMinutes = 60,
  requiredPlan = basicPlan,
  isNewRelease = true
)

const goodOmens = new Series(
  name = "Good Omens",
  genres = #{"Fantasy", "Comedy", "Drama"},
  actors = #{"David Tennant", "Michael Sheen"},
  seasonCount = 6, episodesPerSeason = 6, episodeMinutes = 50,
  requiredPlan = premiumPlan,
  isNewRelease = true
)

// ---- Movies -------------------------------------------------------------
const avengersEndgame = new Movie(
  name = "Avengers Endgame",
  genres = #{"Action", "Drama", "Adventure", "Science Fiction"},
  actors = #{"Robert Downey Jr", "Chris Evans", "Mark Ruffalo", "Chris Hemsworth",
             "Scarlett Johansson", "Jeremy", "Don Cheadle", "Paul Rudd", "Benedict Cumberbatch",
             "Chadwick Boseman", "Brie Larson", "Tom Holland", "Karen Gillan", "Zoe Saldana"},
  durationInMinutes = 182,
  requiredPlan = basicPlan,
  isNewRelease = true
)

const it = new Movie(
  name = "It",
  genres = #{"Horror"},
  actors = #{"Jaeden Martell", "Jeremy Ray Taylor", "Sophia Lillis", "Finn Wolfhard", "Chosen Jacobs"},
  durationInMinutes = 135,
  requiredPlan = premiumPlan,
  isNewRelease = true
)

const eternalSunshine = new Movie(
  name = "El eterno resplandor de una mente sin recuerdos",
  genres = #{"Drama", "Romance", "Science Fiction"},
  actors = #{"Jim Carrey", "Kate Winslet", "Gerry Robert Byrne", "Elijah Wood"},
  durationInMinutes = 108,
  requiredPlan = basicPlan,
  isNewRelease = true
)

const elementos = new Movie(
  name = "Elementos",
  genres = #{"Animation", "Comedy", "Fantasy"},
  actors = #{"Leah Lewis", "Mamoudou Athie", "Ronnie Del Carmen", "Shila Ommi"},
  durationInMinutes = 101,
  requiredPlan = basicPlan,
  isNewRelease = true
)

const millennium2 = new Movie(
  name = "Millennium 2: La chica que soñaba con una cerilla y un bidón de gasolina",
  genres = #{"Action", "Crime", "Drama", "Mystery", "Thriller"},
  actors = #{"Michael Nyqvist", "Noomi Rapace", "Lena Endre"},
  durationInMinutes = 129,
  requiredPlan = premiumPlan,
  isNewRelease = true
)

// ---- Repository ---------------------------------------------------------
const neflisCatalog = new Catalog(titles = #{
  avengersEndgame, it, eternalSunshine, elementos, millennium2,
  blackSails, seanEternos, theWitcher, goodOmens
})
