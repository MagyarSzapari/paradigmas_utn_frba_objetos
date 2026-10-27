# Refactor del Paradigma de Objetos (Wollok) — v2.0

Reingeniería del TP **Neflis** y de los parciales **Antivirus**, **Pokémon** y **Yaaar!**. El código refactorizado está en inglés y vive en `refactored/`, que es un proyecto Wollok-TS independiente. El código original (en castellano) queda intacto en `tp-neflis/` y `parciales/` para poder comparar.

---

## 1. Executive Summary & OO Architectural Overview

### 1.1 Diagnóstico inicial

| Proyecto | Estado original | Problemas de diseño principales |
|---|---|---|
| **TP Neflis** (`tp-neflis/cuenta.wlk`) | **No compila**: `wollok lint` reporta 13 errores, y `test.wtest` tiene una línea cortada (línea 136) y referencias a métodos inexistentes. | Estado que pertenece al perfil guardado en el contenido (porcentaje visto, puntuación). Representación duplicada de las series (`cantidadDeTemporadas` más un set `temporadas` que nunca se llena). Un flag `esMirable()` que se consulta con `if` en vez de usar polimorfismo. Constructores sobrecargados con código copiado. Getters y setters (`var property`) por todos lados. El desvío es configurable por perfil cuando el enunciado lo pide global. |
| **Entrega 1** (`historial/codigo-entrega-1.wlk`) | Compila, pero ya quedó superada. | Un `object` por usuario (`cosmeFulanito` y `margoZavala`) con el código copiado, y lo mismo en `cuentaBasica` y `cuentaPremium`: ahí faltaba una clase. |
| **Antivirus** | Compila. Los puntos 1.b, 4, 5 y 6 no están implementados. | `Resolucion` no expone `alto`/`ancho`, así que **el virus explota al tocar una imagen**. El ransomware reconoce su README armando un `Texto` nuevo y comparándolo con un `==` redefinido (sin `hash`). Nunca vacía la lista de archivos que secuestró. La carpeta de programas está declarada pero no se usa. |
| **Pokémon** | Compila. | `vida = 0` por defecto, así que **todo pokémon nace muerto**. `usosPendientes = 0` por defecto. Se usan excepciones como control de flujo para "perdió el turno". El azar está cableado (`randomUpTo`) y no se puede testear. |
| **Yaaar!** | Compila. Los puntos 5 y 6 no están implementados. | Un `Item` con `==` redefinido y sin `hash`, cuando el enunciado sugiere strings. Reglas que no están en el enunciado: hace falta botella de grogXD para estar "pasado", y para ser temible se pide "más de 5 útiles". El setter `mision(x)` tiene efectos colaterales escondidos. Hay un typo en `puedeSerSaquedoPor`. |

### 1.2 Enfoque de diseño adoptado

1. **Objetos que reciben mensajes, no estructuras que se consultan.** Cada regla vive en el objeto que tiene la información (*Information Expert*). Los demás le *dicen* qué hacer (*Tell, Don't Ask*).
2. **Polimorfismo en lugar de `if` por tipo o por flag.** Algunos ejemplos: `esMirable()` pasa a ser double dispatch `content.beWatchedBy(profile, %)`; `planBasico.puedeMirar` comparando planes pasa a `requiredPlan.isIncludedInBasic()`; "si tengo antivirus..." pasa al *Null Object* `noAntivirus`; "si la condición me deja..." pasa a `condition.attemptToAct(pokemon, action)`.
3. **Composición para lo que varía de forma independiente** (estrategias de valoración, recomendadores, licencias de antivirus, monedas). **Herencia** sólo cuando hay un "es-un" genuino y comportamiento común (`Program`, `Move`, `Mission`, `CrownSpy`). **Mixins** para comportamiento transversal a dos jerarquías (`Watchable`, `Unwatchable`). **`object`** para lo que no tiene estado propio o es único en el dominio (`basicPlan`, `paralysis`, `genreBasedRating`, `similarRating`).
4. **Inversión de dependencias en los bordes no deterministas.** La fecha de hoy (`clock`) y el azar (`coin`) se inyectan, y gracias a eso los tests son deterministas.
5. **Encapsulamiento.** Las colecciones se exponen como copia (`files().copy()`, `crew().copy()`, `titles().copy()`) y no hay `var property` salvo casos justificados.
6. **Módulos cohesivos.** Neflis se separa en `content`, `plans`, `recommenders`, `accounts` y `catalog`, cada uno con una única razón de cambio.

### 1.3 Arquitectura resultante (Neflis)

```
                 Title (abstracta)                      Watchable (mixin)
                 /            \                         /             \
   Movie (Watchable+Title)   Series (Unwatchable+Title) ...         Episode
                                 |  1..*                               ^
                               Season (Unwatchable) ---- 0..max -------+

Account --1..*--> Profile --usa--> Recommender (similarRating | GenrePreference | FanMode
   |                 |                               | defaultRecommender | parentalControl)
   +--> plan (basicPlan | premiumPlan)
   +--> clock (systemClock | FixedClock)

Title --usa--> ratingCriterion (genreBasedRating | plannedEpisodesRating | FixedRating)
```

### 1.4 Tabla de equivalencias: original (castellano) → refactorizado (inglés)

**TP Neflis**

| Original | Refactorizado | Archivo |
|---|---|---|
| `Contenido` | `Title` (abstracta) | `neflis/content.wlk` |
| `Pelicula` | `Movie` (`Watchable and Title`) | `neflis/content.wlk` |
| `Serie` (+ `cantidadDeTemporadas`, `capitulosPorTemporada`) | `Series` (crea sus `Season` en `initialize()`) | `neflis/content.wlk` |
| `Temporada.estrenar(capitulo)` | `Season.premiere(name, minutes)` / `Series.premiere(name)` | `neflis/content.wlk` |
| `Capitulo` | `Episode` (`Watchable`) | `neflis/content.wlk` |
| `esMirable()` (flag booleano) | mixins `Watchable` / `Unwatchable` | `neflis/content.wlk` |
| `fueVistoPor(perfil)` | `wasWatchedBy(profile)` (Composite) | `neflis/content.wlk` |
| `criterioDeValoracion`, `generosX12`, `temporadasXCapitulos`, `valoracion100` | `ratingCriterion`, `genreBasedRating`, `plannedEpisodesRating`, `FixedRating(value)` | `neflis/content.wlk` |
| `seRelacionanEntreSi` | `relateTo(title)` / `isRelatedTo(title)` | `neflis/content.wlk` |
| `planBasico.puedeMirar`, `planPremium.puedeMirar` | `basicPlan.covers(requiredPlan)`, `premiumPlan.covers(requiredPlan)` | `neflis/plans.wlk` |
| `valoracionSimilar` (+ `desvio` en cada `Perfil`) | `similarRating` (desvío global) | `neflis/recommenders.wlk` |
| `preferenciaDeGenero` (+ `preferencias` en `Perfil`) | `GenrePreference(genres)` | `neflis/recommenders.wlk` |
| `modoFan` (+ `actoresFavoritos` en `Perfil`) | `FanMode(favoriteActors)` | `neflis/recommenders.wlk` |
| `recomendadorPorDefecto` | `defaultRecommender` | `neflis/recommenders.wlk` |
| `controlParental` / `recomendadorInfantil` | `parentalControl` | `neflis/recommenders.wlk` |
| `Cuenta` (`planCuenta`, `crearPerfil` x2) | `Account` (`plan`, `createProfile` x2, `clock`) | `neflis/accounts.wlk` |
| `Perfil` | `Profile` | `neflis/accounts.wlk` |
| `ver(contenido, minutos)` | `watch(content)`, `watch(content, %)`, `watchMinutes(content, min)` | `neflis/accounts.wlk` |
| `vio(contenido)` | `watched(content)` | `neflis/accounts.wlk` |
| `promedioDeValoraciones()` | `averageRating()` | `neflis/accounts.wlk` |
| `puntuarContenido(c, p)` | `score(title, points)` | `neflis/accounts.wlk` |
| `recomendarContenido(c)` | `wouldBeRecommended(title)` | `neflis/accounts.wlk` |
| `generarRecomendaciones()` (atado a la global `repositorio`) | `recommendationsFrom(catalog)` | `neflis/accounts.wlk` |
| `esContenidoIdeal(c)` | `Account.isIdealToShare(title)` | `neflis/accounts.wlk` |
| `cambiarRecomendador(r)` | `changeRecommender(r)` | `neflis/accounts.wlk` |
| `calendarioActual` | `systemClock` / `FixedClock(today)` | `neflis/accounts.wlk` |
| `repositorio` | `Catalog` + `neflisCatalog` | `neflis/catalog.wlk` |
| `eternoResplandor`, `milenium2` | `eternalSunshine`, `millennium2` | `neflis/catalog.wlk` |
| 6 clases `...Exception` | `self.error(...)` (DomainException) con mensajes descriptivos | — |
| `test.wtest` | `neflis/stages.wtest` | `neflis/stages.wtest` |

**Parciales**

| Original | Refactorizado | Archivo |
|---|---|---|
| `Computadora` (`agregarArchivo`, `eliminarArchivo`, ...) | `Computer` (`addFile`, `removeFile`, `install`, `uninstall`, `run`) | `exams/antivirus.wlk` |
| `Archivo`, `Texto`, `Imagen`, `Musica`, `Resolucion` | `DataFile`, `TextFile`, `ImageFile`, `MusicFile`, `Resolution` | `exams/antivirus.wlk` |
| `peso()`, `afectarCon(virus)` | `sizeInMb()`, `beInfectedBy(virus)` | `exams/antivirus.wlk` |
| `ProgramaNormal`, `Virus`, `Ransomware` (sin superclase) | `Program` → `RegularProgram`, `Virus`, `Ransomware` | `exams/antivirus.wlk` |
| `ejecutarEn(compu)` | `runOn(computer)` | `exams/antivirus.wlk` |
| *(no existía)* | `Antivirus`, `noAntivirus`, `FreeLicense`, `TrialLicense`, `paidLicense`, `theUltimateAntivirusBenchmark` | `exams/antivirus.wlk` |
| `Pokemon` (`vidaMaxima`, `grositud`, `lucharContra`) | `Pokemon` (`maxHealth`, `greatness`, `fight`) | `exams/pokemon.wlk` |
| `Movimiento`, `MovimientoCurativo`, `MovimientoDanino`, `MovimientoEspecial` | `Move`, `HealingMove`, `DamagingMove`, `SpecialMove` | `exams/pokemon.wlk` |
| `usarEntre`, `afectarPokemones` | `useBetween`, `applyEffect` | `exams/pokemon.wlk` |
| `normal`, `CondicionEspecial`, `paralisis`, `suenio`, `Confusion` | `normal`, `SpecialCondition`, `paralysis`, `sleep`, `Confusion` | `exams/pokemon.wlk` |
| `intentaMoverse(pokemon)` + excepción | `attemptToAct(pokemon, action)` | `exams/pokemon.wlk` |
| `0.randomUpTo(2)...` dentro de la condición | `fairCoin` / `RiggedCoin` inyectados en el `Pokemon` | `exams/pokemon.wlk` |
| `BarcoPirata` | `PirateShip` | `exams/pirates.wlk` |
| `CiudadCostera` (`cuantoCobraElGrogXD`) | `CoastalTown` | `exams/pirates.wlk` |
| `Pirata`, `EspiaDeLaCorona` | `Pirate`, `CrownSpy` | `exams/pirates.wlk` |
| `pasadoDeGrogXD`, `seAnimaASaquearA`, `tomarTragoDeGrogXD` | `isWasted`, `daresToLoot`, `drinkGrog` | `exams/pirates.wlk` |
| `Mision`, `BusquedaDelTesoro`, `ConvertirseEnLeyenda`, `Saqueo` | `Mission`, `TreasureHunt`, `BecomeALegend`, `Plunder` | `exams/pirates.wlk` |
| `esUtil`, `puedeSerRealizadaPor`, `cumpleCondicionesParaRealizarla` | `isUsefulFor`, `canBeAccomplishedBy`, `meetsSpecificRequirements` | `exams/pirates.wlk` |
| `mision(nuevaMision)` (setter con efectos) | `changeMission(newMission)` | `exams/pirates.wlk` |
| `puedeSerSaquedoPor`, `esVulnerableA` | `isLootableBy`, `isVulnerableTo` | `exams/pirates.wlk` |
| `configuracionSaqueos.maximoDeMonedas` | `plunderRules.coinLimit()` / `changeCoinLimit(n)` | `exams/pirates.wlk` |
| `Item` + constantes `mapa`, `brujula`, ... | strings (`"map"`, `"compass"`, ...) | `exams/pirates.wlk` |

---

## 2. Refactored Code (English Wollok)

### 2.1 Mapa de archivos

```
refactored/
├── package.json             proyecto Wollok-TS (wollok test se corre desde acá)
├── .gitignore
├── neflis/
│   ├── content.wlk          Title, Movie, Series, Season, Episode, mixins, criterios de valoración
│   ├── plans.wlk            basicPlan, premiumPlan
│   ├── recommenders.wlk     similarRating, GenrePreference, FanMode, defaultRecommender, parentalControl
│   ├── accounts.wlk         Account, Profile, systemClock, FixedClock
│   ├── catalog.wlk          Catalog + los títulos del enunciado + neflisCatalog
│   └── stages.wtest         53 tests organizados por etapa del enunciado
└── exams/
    ├── antivirus.wlk        + antivirus.wtest  (26 tests)
    ├── pokemon.wlk          + pokemon.wtest    (23 tests)
    └── pirates.wlk          + pirates.wtest    (34 tests)   ← parcial "Yaaar!"
```

> El archivo de tests de Neflis se llama `stages.wtest` y no `neflis.wtest` a propósito. En Wollok-TS, un archivo `neflis/neflis.wtest` genera el paquete `neflis.neflis`, que choca con la carpeta `neflis`, y entonces fallan **todos** los imports `neflis.*`.

El código completo está en `refactored/`. Lo que sigue son los fragmentos que muestran cada decisión, con su "antes y después".

### 2.2 Polimorfismo en lugar de flags: mirable vs. título

**Antes.** El perfil consulta un booleano y decide él mismo (*Ask*):

```wollok
// tp-neflis/cuenta.wlk
method ver(contenido, minutosVistos){
    if(!contenido.esMirable()){
        throw new ContenidoNoMirableException(message = "El contenido que intenta ver no es mirable")
    }
    contenido.minutosVistos(minutosVistos)   // ¡el progreso queda guardado en el CONTENIDO!
    contenidoVisto.add(contenido)
}
```

**Después.** El perfil le *dice* al contenido "dejate ver por mí" (double dispatch), y cada contenido responde según lo que es:

```wollok
// refactored/neflis/accounts.wlk
method watch(content, percentage) {
  if (not percentage.between(1, 100)) self.error("The watched percentage must be between 1 and 100")
  content.beWatchedBy(self, percentage)
}

// refactored/neflis/content.wlk
mixin Watchable {
  method beWatchedBy(profile, percentage) { profile.recordViewing(self, percentage) }
  method wasWatchedBy(profile) = profile.hasViewed(self)
  ...
}
mixin Unwatchable {
  method beWatchedBy(profile, percentage) {
    throw new DomainException(message = "A series or a season cannot be watched: watch one of its episodes")
  }
}
class Movie  inherits Watchable and Title { ... }
class Series inherits Unwatchable and Title { ... }
class Season inherits Unwatchable { ... }
class Episode inherits Watchable { ... }
```

**Concepto: dynamic binding.** En tiempo de compilación, `content.beWatchedBy(...)` no sabe qué método se va a ejecutar. Lo decide el objeto receptor en tiempo de ejecución. Para sumar un tipo nuevo de contenido (por ejemplo, un "corto") alcanza con que entienda `beWatchedBy`: `Profile` no se toca (**Open/Closed**).

**Concepto: herencia vs. mixin.** `Movie` *es un* `Title` y además *es* mirable, mientras que `Episode` es mirable pero no es un título. Si sólo usáramos herencia simple habría que duplicar la lógica de "ser mirable". El mixin la comparte entre dos jerarquías distintas. Ojo con la linealización de Wollok-TS: la superclase va última (`inherits Watchable and Title`).

### 2.3 Composite: "¿lo vio?" para cualquier contenido

```wollok
class Series ... { method wasWatchedBy(profile) = seasons.any { season => season.wasWatchedBy(profile) } }
class Season ... { method wasWatchedBy(profile) = episodes.any { episode => episode.wasWatchedBy(profile) } }
// Movie y Episode lo heredan de Watchable: profile.hasViewed(self)
```

**Antes:** `Serie.fueVistoPor` hacía `temporadas.flatMap{...}.any{...}` sobre un set de temporadas que nunca se cargaba, porque la serie guardaba aparte `cantidadDeTemporadas`. Había dos representaciones del mismo dato, y una de ellas estaba vacía. **Después:** la serie construye sus temporadas en `initialize()` y cada nivel *delega* en sus partes. Eso es **delegación**: cada objeto resuelve sólo su parte y le pasa el resto al que sabe.

### 2.4 Estado en el objeto correcto (cohesión)

**Antes.** El porcentaje visto y la puntuación eran atributos del **contenido**:

```wollok
class Contenido { var property puntuacion = 0 ... }
class Pelicula inherits Contenido { var property minutosVistos = 0  var property porcentajeVisto = 1 ... }
```

Si Margo puntuaba "It" con 5 y Cosme con 1, el contenido terminaba con 1 para los dos. El enunciado dice explícitamente que dos perfiles pueden estar mirando lo mismo en porcentajes distintos.

**Después.** Es información **del perfil sobre** el contenido:

```wollok
class Profile {
  const viewings = new Dictionary()  // watchable -> watched percentage (1..100)
  const scores = new Dictionary()    // title -> score (1..5)
  ...
  method recordViewing(watchable, percentage) {
    self.validateAccessTo(watchable.title())
    viewings.put(watchable, percentage)
  }
}
```

**Concepto: cohesión.** `Title` ahora sólo sabe cosas del título (géneros, actores, valoración, relaciones), y `Profile` sabe todo lo que es historia del usuario. Cada clase tiene una sola razón para cambiar (**SRP**).

### 2.5 Estrategias por composición: valoración, recomendadores y planes

```wollok
class Title {
  const ratingCriterion = self.defaultRatingCriterion()   // default polimórfico, inyectable
  method defaultRatingCriterion()
  method rating() = ratingCriterion.ratingOf(self)
}
class Movie  ... { override method defaultRatingCriterion() = genreBasedRating }
class Series ... { override method defaultRatingCriterion() = plannedEpisodesRating }

// catalog.wlk: Sean Eternos tiene valoración fija
const seanEternos = new Series(..., ratingCriterion = new FixedRating(value = 100), ...)
```

Los recomendadores comparten una **interfaz** (`recommends(profile, title)` e `isVaried()`) y el perfil delega sin preguntar cuál le tocó:

```wollok
// Profile
method isVaried() = recommender.isVaried()
method wouldBeRecommended(title) = not self.watched(title) and recommender.recommends(self, title)
```

**Antes:** la configuración de cada recomendador vivía en el **perfil** (`preferencias`, `actoresFavoritos`, `desvio`), y el recomendador se la pedía (`perfil.preferencias().any{...}`). El acoplamiento era alto: cada recomendador nuevo obligaba a agregarle atributos a `Perfil`. **Después:** `GenrePreference(genres)` y `FanMode(favoriteActors)` son clases con su propio estado, mientras que `similarRating` es un `object` porque el enunciado dice que el desvío es *el mismo para todos los usuarios*.

**Planes con double dispatch.** Antes era `contenido.plan().equals(self)`, una comparación de identidad que Wollok-TS marca con "Comparing against named object is discouraged (missing polymorphism?)". Después:

```wollok
object basicPlan   { method covers(requiredPlan) = requiredPlan.isIncludedInBasic()  method isIncludedInBasic() = true }
object premiumPlan { method covers(requiredPlan) = true                              method isIncludedInBasic() = false }
```

### 2.6 Null Object: computadora sin antivirus y pirata sin invitante

**Antes** (y en la solución típica): `if (antivirus != null) antivirus.validar(programa)`. **Después:**

```wollok
class Computer {
  var antivirus = noAntivirus
  method run(app) {
    antivirus.validateExecutionOf(app)
    app.runOn(self)
  }
}
object noAntivirus {
  method validateExecutionOf(app) { }
  method isMalware(app) = false
}
```

Desaparece el `null` y con él el `if`. Lo mismo pasa con `object nobody` en `Pirate`, para los tripulantes fundadores que no fueron invitados por nadie.

### 2.7 Antivirus: composición de licencia y base de malware

El enunciado dice que *todos los antivirus funcionan igual* y que lo que cambia es la base de malware y el tipo de licencia. Por eso hay **una sola clase** `Antivirus` que **compone** una licencia. No conviene hacer `AntivirusGratuito inherits Antivirus`, porque la licencia es una dimensión independiente de la empresa:

```wollok
class Antivirus {
  const knownMalware = #{}
  const license
  method receiveUpdate(newMalwareNames) { knownMalware.addAll(newMalwareNames) }
  method isMalware(app) = license.authorizesCheck() and knownMalware.contains(app.name())
}
class FreeLicense  { const expirationDate  method authorizesCheck() = new Date() <= expirationDate }
class TrialLicense { var remainingChecks   method authorizesCheck() { ... remainingChecks -= 1 ... } }
object paidLicense { method authorizesCheck() = true }
```

**Ransomware: Tell, Don't Ask y objetos valor.**

```wollok
// Antes: reconocía su README creando un archivo nuevo y comparando con un == redefinido
method tieneArchivosSecuestrablesPor(ransomware) = archivos.any{ archivo => archivo != ransomware.nuevoReadme() }

// Después: cada archivo sabe si es una nota de rescate (polimorfismo con default en DataFile)
method hideableFiles() = files.filter { file => not file.isRansomNote() }
```

`Resolution` pasa a ser un **objeto valor inmutable** (`rotated()` devuelve una nueva). Eso además arregla el bug original, que llamaba a `resolucion.ancho()` sin que ese getter existiera.

### 2.8 Pokémon: Template Method, sin excepciones como control de flujo, azar inyectado

**Antes:** si la condición no lo dejaba moverse, se lanzaba `NoPuedeMoverseException`, y la confusión la *atrapaba y relanzaba*. Perder el turno es un resultado normal del juego, no un error.

**Después:** la condición recibe la acción como bloque y decide si ejecutarla:

```wollok
class Pokemon {
  const coin = fairCoin                          // DIP: se puede inyectar RiggedCoin
  method fight(opponent) {
    self.validateCanFight()
    opponent.validateCanFight()
    const move = self.availableMove()
    condition.attemptToAct(self, { move.useBetween(self, opponent) })
  }
}
object normal { method attemptToAct(pokemon, action) { action.apply() } }
class SpecialCondition {
  method attemptToAct(pokemon, action) {
    if (pokemon.flipCoin()) self.onMoveAllowed(pokemon, action) else self.onMoveBlocked(pokemon)
  }
  method onMoveAllowed(pokemon, action) { action.apply() }   // hook
  method onMoveBlocked(pokemon) { }                          // hook
}
object sleep inherits SpecialCondition {
  override method power() = 50
  override method onMoveAllowed(pokemon, action) { pokemon.normalize()  super(pokemon, action) }
}
class Confusion inherits SpecialCondition {
  const turns
  override method onMoveBlocked(pokemon) { pokemon.takeDamage(20) }
  method afterOneTurn() = if (turns > 1) new Confusion(turns = turns - 1) else normal
}
```

* El único `if` que queda es *la moneda*, que es la esencia de la regla. No se pregunta en ningún lado "¿qué condición tengo?".
* `paralysis` y `sleep` son `object` que **heredan** de una clase. No tienen estado y son únicos, así que no tiene sentido instanciarlos.
* `Confusion` es una **clase inmutable**: el movimiento especial puede compartir la misma instancia con todos los pokémon a los que afecta sin "gastarle" turnos (hay un test que lo verifica).
* Las validaciones reales (pokémon muerto, sin movimientos, movimiento agotado) **siguen** siendo excepciones.

### 2.9 Yaaar!: interfaz común de víctimas y una sola consulta reutilizada

`PirateShip` y `CoastalTown` no comparten superclase, pero sí una **interfaz** (`isLootableBy(pirate)` e `isVulnerableTo(ship)`). Para `Plunder` son intercambiables (*duck typing*):

```wollok
class Plunder inherits Mission {
  const victim
  override method isUsefulFor(pirate) =
    pirate.hasFewerCoinsThan(plunderRules.coinLimit()) and pirate.daresToLoot(victim)
  override method meetsSpecificRequirements(ship) = victim.isVulnerableTo(ship)
}
class Pirate { method daresToLoot(victim) = victim.isLootableBy(self) }   // double dispatch
```

Para el punto 5 ("¡Ojo con repetir código!") hay una sola consulta, `wastedCrew()`, que reutilizan las tres preguntas:

```wollok
method wastedCrew() = crew.filter { pirate => pirate.isWasted() }
method wastedCrewCount() = self.wastedCrew().size()
method wastedCrewItemTypes() = self.wastedCrew().flatMap { pirate => pirate.items() }.asSet().size()
method richestWastedCrewMember() = self.wastedCrew().max { pirate => pirate.coins() }
```

**Herencia bien usada:** `CrownSpy inherits Pirate`. Un espía *es un* pirata con dos métodos redefinidos, y uno de ellos usa `super`:

```wollok
class CrownSpy inherits Pirate {
  override method isWasted() = false
  override method daresToLoot(victim) = super(victim) and self.has("crown permit")
}
```

### 2.10 De `object` por usuario a clases (Entrega 1 → modelo actual)

```wollok
// historial/codigo-entrega-1.wlk: el MISMO código copiado en dos objetos
object cosmeFulanito { const cuenta = cuentaBasica  const contenidoVisto = #{} method puedeVer(c) {...} method ver(c) {...} }
object margoZavala   { const cuenta = cuentaPremium const contenidoVisto = #{} method puedeVer(c) {...} method ver(c) {...} }
```

Cuando hay **varios objetos con el mismo comportamiento y distinto estado**, eso es una **clase** (`Profile`). Un `object` se justifica cuando el concepto es único (`basicPlan`, `similarRating`, `systemClock`, `theUltimateAntivirusBenchmark`).

---

## 3. Engineering Justification Matrix

| # | Change Implemented | SWEBOK v4.0 Alignment | ISO/IEC 25010 Impact | Deep-Dive Explanation |
|---|---|---|---|---|
| 1 | `esMirable()` + `if` reemplazado por double dispatch `beWatchedBy` y mixins `Watchable`/`Unwatchable` | *Software Design*: principios de diseño (abstracción, encapsulamiento, Open/Closed), estrategias orientadas a objetos | Mantenibilidad → **modificabilidad**: un tipo nuevo de contenido no toca `Profile` | El receptor decide en tiempo de ejecución (*dynamic binding*). El emisor deja de preguntar por el tipo y sólo envía un mensaje. El mixin reutiliza comportamiento entre jerarquías sin herencia múltiple de clases. |
| 2 | Progreso y puntuación movidos de `Contenido` a `Profile` (`Dictionary`) | *Software Design*: asignación de responsabilidades, cohesión | **Adecuación funcional** (corrección: perfiles independientes) y **modularidad** | El dato vive con quien lo tiene (Information Expert). Se elimina el estado compartido por accidente entre perfiles. |
| 3 | `Series` construye sus `Season` y `Episode` en `initialize()`; `wasWatchedBy` se resuelve como Composite | *Software Design*: estructuras de diseño y patrones (Composite) | **Analizabilidad** (una sola representación) y corrección | Desaparece la redundancia `cantidadDeTemporadas` vs. `temporadas`. Cada nivel delega en sus partes, y el cliente trata igual a un contenido simple y a uno compuesto. |
| 4 | Recomendadores como Strategy con interfaz común; la configuración se mueve al recomendador | *Software Design*: SRP, DIP, bajo acoplamiento | **Modificabilidad** y **reusabilidad** | `Profile` depende de la abstracción "recomendador" y no de los detalles. Sumar un recomendador no agrega atributos a `Profile`. |
| 5 | Desvío global en `similarRating` (`object`) | *Software Requirements* (trazabilidad al enunciado) / *Software Design* | **Adecuación funcional** | El enunciado pide "manteniendo la de todos los usuarios por igual". Un singleton es la representación natural de una regla global. |
| 6 | Planes con double dispatch (`covers` / `isIncludedInBasic`) | *Software Design*: polimorfismo | **Analizabilidad** (sin comparar contra objetos nombrados) | Se reemplaza un `equals` contra un objeto concreto (lo que el linter llama *missing polymorphism*) por una conversación entre objetos. |
| 7 | `clock` (`systemClock`/`FixedClock`) y `coin` (`fairCoin`/`RiggedCoin`) inyectados | *Software Design*: DIP; *Software Testing*: controlabilidad | **Testeabilidad** | Lo no determinista queda detrás de una abstracción. Los tests de edad y de condiciones pokémon son reproducibles. |
| 8 | `crearPerfil` x2 sin duplicar código; el control parental va en `Profile.initialize()` | *Software Construction*: minimizar la complejidad, reutilización | **Modificabilidad** | Una sobrecarga delega en la otra, y la regla "menor → control parental" vive en un solo lugar y aplica aunque se haya elegido otro recomendador. |
| 9 | Null Objects `noAntivirus` y `nobody` | *Software Design*: patrones; *Software Construction*: manejo de casos borde | **Fiabilidad** (sin `null`) y **analizabilidad** | Se elimina la rama `if (x != null)`. "No tener" se modela como un objeto que entiende los mismos mensajes. |
| 10 | `Antivirus` único que compone `license` (Free/Trial/Paid) | *Software Design*: composición sobre herencia | **Modificabilidad** y **reusabilidad** | Licencia y base de malware son dimensiones independientes. Con herencia habría una explosión de subclases (empresa × licencia). |
| 11 | `Program` como superclase abstracta de `RegularProgram`, `Virus` y `Ransomware` | *Software Design*: abstracción, jerarquías | **Analizabilidad** | Se explicita la interfaz común (`name`, `runOn`). El antivirus y la computadora trabajan contra esa abstracción. |
| 12 | `Resolution` inmutable con `rotated()`; `isRansomNote()` polimórfico sin redefinir `==` | *Software Construction*: objetos valor, corrección | **Fiabilidad** (bug corregido) | Redefinir `==` sin `hash` rompe colecciones. Con un objeto valor y una pregunta polimórfica la intención queda clara. |
| 13 | Ransomware vacía `hiddenFiles` al devolver | *Software Quality*: defectos | **Fiabilidad** | Antes, cada ejecución posterior al pago duplicaba los archivos. |
| 14 | Pokémon: `attemptToAct(pokemon, action)` con Template Method y sin excepciones para perder el turno | *Software Design*: Template Method; *Software Construction*: manejo de errores | **Analizabilidad** y **modificabilidad** (Confusion se agrega sin tocar `Pokemon`) | Las excepciones quedan para errores reales. El flujo normal (perder turno, autodaño) se expresa con hooks polimórficos. |
| 15 | `Pokemon.health = maxHealth`, sin default `0` en usos | *Software Quality*: defectos | **Adecuación funcional** | Antes todo pokémon nacía muerto y todo movimiento nacía agotado. |
| 16 | Yaaar!: `Item` → strings, `mision(x)` → `changeMission(x)`, `removeAllSuchThat` | *Software Construction*: simplicidad (YAGNI) | **Analizabilidad** | Una clase sin comportamiento que además redefinía `==` sin `hash` sólo sumaba riesgo. Un "setter" con efectos sorprende, mientras que un mensaje con nombre de dominio comunica. |
| 17 | `wastedCrew()` reutilizada; víctimas polimórficas (`isLootableBy`/`isVulnerableTo`) | *Software Design*: DRY, polimorfismo | **Reusabilidad** | Una consulta base alimenta los tres puntos del 5. Barco y ciudad son intercambiables como víctimas sin compartir superclase. |
| 18 | Tell, Don't Ask en pirata: `hasFewerCoinsThan`, `hasAtMostCoins`, `isDrunkAtLeast` | *Software Design*: encapsulamiento | **Modificabilidad** | Las misiones no leen `monedas()` para comparar afuera: el pirata responde la pregunta de negocio. |
| 19 | Colecciones expuestas como copia; sin `var property` innecesarios | *Software Design*: ocultamiento de información | **Modularidad** | La interfaz pública de cada objeto queda limitada a mensajes de dominio. Nadie puede hacer `perfil.contenidoVisto().add(x)` desde afuera. |
| 20 | Módulos `content` / `plans` / `recommenders` / `accounts` / `catalog`; `recommendationsFrom(catalog)` | *Software Design*: modularización; *Software Configuration Management* | **Modularidad** y **reusabilidad** | `Profile` ya no depende de una global `repositorio`: el catálogo se recibe por parámetro (DIP). Los datos de ejemplo quedan separados del modelo. |
| 21 | Suite `.wtest` por punto o etapa, con casos de error (`assert.throwsExceptionWithMessage`) | *Software Testing*: niveles y técnicas (partición de equivalencia, valores límite); *Software Quality* | **Testeabilidad** | 136 tests. Cubren cada punto de los enunciados, los bordes (13 años exactos, 90 % de capacidad, 1 y 100 %) y las validaciones. |

### 3.1 Bugs encontrados en los originales

**TP Neflis (`cuenta.wlk` / `test.wtest`): no compila.**
1. `Temporada`: `capitulos().size()` y `cantidadDeCapitulos()` se envían sin `self.` (mensaje mal formado, líneas 72 y 74).
2. `Capitulo.calcularPorcentajeDeVisualizacion` usa `porcentajeVisto` y `minutosVistos`, que no existen.
3. `Perfil` usa `fechaDeNacimiento`, que no es un atributo. `esMenorDe13()` no está definido. `recomendador(...)` como setter no existe (es un `var` sin `property`). `recomendadorInfantil` no existe (el objeto se llama `controlParental`).
4. `crearPerfil(nombre, fecha)` no le pasa recomendador a `Perfil`, que lo exige, y tampoco asigna el recomendador por defecto.
5. `const margo = margoZavala.crearPerfil("margo", valoracionSimilar)` llama a la sobrecarga `(nombre, fecha)` y le pasa el recomendador como fecha.
6. `valoracionSimilar` llama a `perfil.contenidoVistos()` (typo), lo que da *message not understood*.
7. `recomendadorPorDefecto.esRecomendable` tiene un `if` sin `return`, así que no devuelve nada.
8. `Perfil.ver` rechaza las series, que no son mirables, pero los tests hacen `margo.ver(blackSails)`, y además con un solo argumento cuando el método pide dos.
9. El porcentaje visto y la puntuación se guardan en el contenido y se pisan entre perfiles.
10. `Serie.temporadas` nunca se carga, así que `fueVistoPor` de una serie siempre da `false`.
11. Sean Eternos tiene el género `"Fulbo"` cuando debería ser Documental, y los géneros son inconsistentes (`"accion"` vs. `"Acción"` vs. `"Accin"`). Por eso el test de Cosme con "documental" no puede pasar.
12. La edad se calcula sólo por año, y hay inconsistencia entre `<= 13` y "menor de 13".
13. `test.wtest`: la línea 136 quedó incompleta (error de sintaxis). Hay un typo `recomedadorPorDefecto`. Se envía `puedeMirar` a un perfil, cuando el método se llama `puedeVer`. `porcentajeVisto` se accede sin paréntesis. Los mensajes esperados no coinciden con los lanzados. El test "cosme NO es variado" en realidad evalúa a `margo`. Los actores favoritos de Murphy (`"jaeden"`, `"jeremy"`) no coinciden con los datos.

**Antivirus.**
1. `Resolucion` no expone `alto`/`ancho`, así que `Virus` sobre una `Imagen` lanza `MessageNotUnderstoodException` (verificado ejecutándolo).
2. `devolverArchivosA` no vacía `archivosSecuestrados`: cada nueva ejecución con comprobante duplica los archivos.
3. Busca `"comprobante de pago"` en minúscula, mientras que el enunciado dice "Comprobante de pago".
4. `Texto` redefine `==` sin `hash` y compara contra cualquier objeto que entienda `nombre()`/`contenido()`.
5. La carpeta `programas` está declarada pero no se usa (warning del linter), y faltan los puntos 1.b, 4, 5 y 6. `Musica` no tiene año.

**Pokémon.**
1. `var vida = 0`: todo pokémon recién creado está muerto y no puede luchar (verificado).
2. `var usosPendientes = 0`: todo movimiento recién creado está agotado.
3. Usa excepciones para un flujo normal del juego (perder el turno).

**Yaaar!**
1. `pasadoDeGrogXD` exige además una botella de grogXD, cosa que el enunciado no pide (sólo ebriedad ≥ 90).
2. `esTemible` agrega "más de 5 tripulantes útiles", que tampoco está en el enunciado.
3. `Item` redefine `==` sin `hash`, así que dos ítems "iguales" se cuentan distinto en un `Set`.
4. `configuracionSaqueos.maximoDeMonedas = 0`: hasta configurarlo, ningún pirata sirve para ningún saqueo.
5. Typo `puedeSerSaquedoPor`. Faltan los puntos 5 y 6.

### 3.2 Cambios de comportamiento (decisiones conscientes)

* **Neflis.** Avengers Endgame tiene 4 géneros según la lista de la etapa 2 del enunciado (valoración 48). Por eso el promedio de Margo tras ver Black Sails y Avengers da **40** y no los 34 del caso de la etapa 1, que asumía 3 géneros. Además, Cosme ahora **puede** ver Sean Eternos, porque en la etapa 3 su perfil pertenece a la cuenta premium de Margo; la expectativa de la etapa 1 se conserva con un perfil de cuenta básica. Las series se ven a través de sus episodios (`blackSails.pilot()`). El desvío es global. La puntuación y el progreso son por perfil. Los géneros quedaron en inglés (`"Action"`, `"Documentary"`, `"Kids"`). Black Sails dura 45 min por capítulo, según el enunciado (el original decía 48).
* **Antivirus.** El nombre del comprobante es `"Payment receipt"` y los textos de dominio están en inglés. El ransomware no vuelve a ocultar su propio README. Ejecutar un antivirus *Trial* en el benchmark consume chequeos, que es la consecuencia natural del enunciado.
* **Pokémon.** Perder el turno ya no lanza excepción: el turno termina sin efecto (o con 20 de autodaño si está confundido).
* **Yaaar!** Se sigue el enunciado: estar pasado de grogXD es tener ebriedad ≥ 90, temible es "puede realizar su misión", y el trago cuesta 1 moneda (sólo toman los que pueden pagarla, igual que el original). El límite de monedas por defecto para saqueos es 10 y se cambia con `plunderRules.changeCoinLimit(n)`. Los ítems son strings.
* **Agregados que no estaban implementados:** Antivirus puntos 1.b, 4, 5 y 6; Yaaar! puntos 5 y 6; Neflis estrenos semanales (`releasedEpisodesPerSeason = 0` + `premiere`), relación entre títulos y validación de edad con fecha completa.

---

## 4. Verification & Clean Code Recommendations

### 4.1 Cómo correrlo

Requisito: Wollok-TS CLI (`wollok`, probado con Wollok-TS-CLI v1.1.1 / Wollok-TS v4.3.0).

```bash
cd refactored
wollok test                              # toda la suite
wollok test -f exams/pokemon.wtest       # un archivo
wollok test -d "Stage 5 - scores"        # un describe
wollok lint                              # validaciones estáticas
```

Resultado actual: **136 tests, 136 passed**, y `wollok lint` sin errores ni warnings.

| Archivo | Tests | Qué cubre |
|---|---|---|
| `neflis/stages.wtest` | 53 | Los casos de prueba de cada etapa del enunciado (portados del `test.wtest` original y corregidos), más plan, progreso, estrenos, puntuación, recomendador por defecto y control parental |
| `exams/antivirus.wtest` | 26 | Puntos 1 a 6, incluidos ransomware sin archivos, comprobante de otra cuenta, licencias vencidas o agotadas y bloqueo de ejecución |
| `exams/pokemon.wtest` | 23 | Grositud, efectos de movimientos, validaciones, cada condición con moneda cargada a favor y en contra, y la inmutabilidad de Confusion |
| `exams/pirates.wtest` | 34 | Utilidad por misión, reclutamiento y sus errores, anclaje, temibilidad, espías, punto 5 e invitaciones |

### 4.2 Estrategia de testing aplicada

1. **Un `describe` por punto o etapa del enunciado.** El reporte de `wollok test` funciona como matriz de trazabilidad requisito → prueba.
2. **Fixtures explícitos.** `MargoZavalaAccountFixture` arma la cuenta de Margo con sus perfiles en `initialize()`, y cada `describe` declara sus objetos con `const` o los arma en `method initialize()`. Wollok-TS reinicia el estado (incluidos los `object` globales como `similarRating` o `plunderRules`) **en cada test**, así que un test no contamina a otro.
3. **Casos de error con `assert.throwsExceptionWithMessage`.** Se verifica el mensaje, que es parte de la interfaz con el usuario. Además, cuando importa, se verifica que el estado **no** cambió después del error (por ejemplo: `notes.content()` sigue igual si el antivirus bloqueó el virus, y `pepe.watched(millennium2)` es falso).
4. **Valores límite.** Se prueban 13 años exactos vs. el día anterior al cumpleaños, porcentaje 0/1/100/101, puntaje 0/1/5/6, 5 vs. 6 monedas, capacidad al 90 %, mitad de tripulación y 40 % de habitantes.
5. **Dobles de prueba en lugar de azar o reloj real.** Se usan `RiggedCoin(result = true/false)` y `FixedClock(today = ...)`. Para las licencias gratuitas alcanza con fechas relativas (`new Date().plusDays(10)`).
6. **Se testea comportamiento, no implementación.** Por ejemplo, "jorgito usa el recomendador por defecto" se verifica viendo *qué le recomienda* y no comparando `perfil.recomendador() == recomendadorPorDefecto`, que obligaría a exponer un getter y el linter lo marca como posible falta de polimorfismo.

### 4.3 Recomendaciones de Clean Code para seguir

* **Un test, un comportamiento.** El nombre del test es la especificación: escribilo como una oración del dominio ("a minor cannot change the recommender").
* **Nada de getters "por las dudas".** Si un test necesita un getter que el dominio no usa, primero preguntate si no conviene testear el efecto observable.
* **Antes de escribir un `if` sobre el tipo o un flag de un objeto, buscá a quién mandarle el mensaje.** Los `if` que quedan en este refactor son validaciones de dominio o reglas intrínsecas (la moneda, el cumpleaños), nunca "¿qué clase sos?".
* **Ojo con los nombres reservados de Wollok-TS.** `program` y `fixture` no se pueden usar como identificadores, por eso la variable se llama `app`. Un archivo `.wtest` no puede llamarse igual que su carpeta.
* **Próximos pasos sugeridos.** (a) Agregar un `program` (`.wpgm`) que simule una pelea pokémon completa con `fairCoin`. (b) Sumar tests de propiedades para el benchmark (por ejemplo, que el mejor antivirus siempre tenga hits ≥ a los demás). (c) Si crece el catálogo de Neflis, cargar las relaciones entre títulos desde un objeto `catalogRelations` en vez de hacerlo en los tests. (d) Correr `wollok test` en CI en cada push.
