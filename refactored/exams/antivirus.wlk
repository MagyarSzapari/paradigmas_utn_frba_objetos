// =====================================================================
// Antivirus exam (19/11/2022) - refactored model
// =====================================================================

const ransomNoteName = "README"
const paymentReceiptName = "Payment receipt"

// ---------------------------------------------------------------------
// Computer (point 1 and point 5)
// ---------------------------------------------------------------------
class Computer {
  const files = []
  const programs = []
  var antivirus = noAntivirus

  // Read-only views: callers cannot mutate the internal folders.
  method files() = files.copy()
  method programs() = programs.copy()

  // Point 1.a - data files folder
  method addFile(file) { files.add(file) }
  method addFiles(newFiles) { files.addAll(newFiles) }
  method removeFile(file) { files.remove(file) }
  method removeFiles(filesToRemove) { files.removeAll(filesToRemove) }

  // Point 1.b - programs folder
  method install(app) { programs.add(app) }
  method uninstall(app) { programs.remove(app) }

  method installAntivirus(newAntivirus) { antivirus = newAntivirus }

  // Point 5 - the antivirus (or the null object) guards every execution.
  method run(app) {
    antivirus.validateExecutionOf(app)
    app.runOn(self)
  }

  // Services offered to the programs (Tell, Don't Ask).
  method infectFilesWith(virus) {
    files.forEach { file => file.beInfectedBy(virus) }
  }
  method hasPaymentReceiptFor(ransomware) =
    files.any { file => file.isPaymentReceiptFor(ransomware) }
  method hideableFiles() = files.filter { file => not file.isRansomNote() }
}

// ---------------------------------------------------------------------
// Data files (point 2) - every file knows its name and size in MB
// ---------------------------------------------------------------------
class DataFile {
  method name()
  method sizeInMb()
  method beInfectedBy(virus)

  // Hooks with a neutral default: only text files can be receipts or notes.
  method isPaymentReceiptFor(ransomware) = false
  method isRansomNote() = false
}

class TextFile inherits DataFile {
  const property name
  var content

  method content() = content

  override method sizeInMb() = (content.length() + name.length()) / 5

  override method beInfectedBy(virus) { content = virus.name() }

  override method isPaymentReceiptFor(ransomware) =
    name == paymentReceiptName and ransomware.isMentionedIn(content)

  override method isRansomNote() = name == ransomNoteName
}

class ImageFile inherits DataFile {
  var description
  var resolution

  // The description of an image is also its name.
  override method name() = description
  method resolution() = resolution

  override method sizeInMb() = resolution.totalPixels() / 100

  override method beInfectedBy(virus) {
    description = "Brad Pitt inside a giant wooden horse"
    resolution = resolution.rotated()
  }
}

// Immutable value object: rotating returns a NEW resolution.
class Resolution {
  const property width
  const property height

  method totalPixels() = width * height
  method rotated() = new Resolution(width = height, height = width)
}

class MusicFile inherits DataFile {
  const property sizeInMb
  const song
  var artist
  const year

  method year() = year
  override method name() = song + " - " + artist

  override method beInfectedBy(virus) {
    if (not self.isImmuneToViruses()) artist = virus.name()
  }

  method isImmuneToViruses() = song == "Pronta Entrega"
}

// ---------------------------------------------------------------------
// Programs (point 3) - common abstraction: every program (app) has a name
// ---------------------------------------------------------------------
class Program {
  const property name

  method runOn(computer)
}

class RegularProgram inherits Program {
  override method runOn(computer) {
    computer.addFile(new TextFile(
      name = "data." + name,
      content = "very important information for work"
    ))
  }
}

class Virus inherits Program {
  override method runOn(computer) { computer.infectFilesWith(self) }
}

class Ransomware inherits Program {
  const bitcoinAccount
  const bitcoinAmount
  const hiddenFiles = []

  method hiddenFiles() = hiddenFiles.copy()
  method isMentionedIn(text) = text.contains(bitcoinAccount)

  override method runOn(computer) {
    if (computer.hasPaymentReceiptFor(self))
      self.giveBackFilesTo(computer)
    else
      self.hideFilesOf(computer)
  }

  method giveBackFilesTo(computer) {
    computer.addFiles(hiddenFiles)
    hiddenFiles.clear()
  }

  method hideFilesOf(computer) {
    const filesToHide = computer.hideableFiles()
    if (filesToHide.isEmpty())
      self.error("There are no files to hide and no payment receipt was found")
    hiddenFiles.addAll(filesToHide)
    computer.removeFiles(filesToHide)
    computer.addFile(self.ransomNote())
  }

  method ransomNote() = new TextFile(
    name = ransomNoteName,
    content = "Pay " + bitcoinAmount + " bitcoins to the account " + bitcoinAccount
  )
}

// ---------------------------------------------------------------------
// Antivirus (point 4) - same algorithm for every vendor (composition):
// what varies is the malware database and the license.
// ---------------------------------------------------------------------
class Antivirus {
  const knownMalware = #{}
  const license

  method receiveUpdate(newMalwareNames) { knownMalware.addAll(newMalwareNames) }

  method isMalware(app) =
    license.authorizesCheck() and knownMalware.contains(app.name())

  method validateExecutionOf(app) {
    if (self.isMalware(app))
      self.error("Execution blocked: " + app.name() + " is a known malware")
  }
}

// Null Object: a computer without antivirus still works.
object noAntivirus {
  method validateExecutionOf(app) { }
  method isMalware(app) = false
}

// Licenses (Strategy) ----------------------------------------------------
class FreeLicense {
  const expirationDate

  method authorizesCheck() = new Date() <= expirationDate
}

class TrialLicense {
  var remainingChecks

  method remainingChecks() = remainingChecks

  method authorizesCheck() {
    const authorized = remainingChecks > 0
    remainingChecks = (remainingChecks - 1).max(0)
    return authorized
  }
}

object paidLicense {
  method authorizesCheck() = true
}

// ---------------------------------------------------------------------
// Benchmark (point 6)
// ---------------------------------------------------------------------
object theUltimateAntivirusBenchmark {
  const regularPrograms = []
  const malwares = []

  method addRegularProgram(app) { regularPrograms.add(app) }
  method addMalware(app) { malwares.add(app) }

  method bestOf(antiviruses) = antiviruses.max { antivirus => self.hitsOf(antivirus) }

  method hitsOf(antivirus) =
    regularPrograms.count { app => not antivirus.isMalware(app) } +
    malwares.count { app => antivirus.isMalware(app) }
}
