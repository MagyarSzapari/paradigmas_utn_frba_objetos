class Computadora {
    const property archivos = []
    const programas = []

    /* Punto 1 */
    method agregarArchivo(archivo) {
        archivos.add(archivo)
    }

    method agregarArchivos(archivosNuevos) {
        archivos.addAll(archivosNuevos)
    }

    method eliminarArchivo(archivo) {
        archivos.remove(archivo)
    }

    method afectarArchivosCon(virus) {
        archivos.forEach{ archivo => archivo.afectarCon(virus) }
    }

    method tieneComprobantePara(ransomware) = 
        archivos.any{ archivo => archivo.esComprobantePara(ransomware) }

    method tieneArchivosSecuestrablesPor(ransomware) =
        archivos.any{ archivo => archivo != ransomware.nuevoReadme() }

    method eliminarArchivos() {
        archivos.clear()
    }
}

/* Punto 2 */
class Archivo { 
    method peso()
    method afectarCon(virus)
    method esComprobantePara(ransomware) = false
}

class Texto inherits Archivo {
    var property contenido
    const property nombre

    override method peso() = (contenido.length() + nombre.length()) / 5
    override method afectarCon(virus) {
        contenido = virus.nombre()
    }
    override method esComprobantePara(ransomware) = 
        nombre == "comprobante de pago" and 
        contenido.contains(ransomware.cuenta())
    override method ==(otro) = nombre == otro.nombre() and
                                contenido == otro.contenido()
}

class Imagen inherits Archivo {
    var property resolucion
    var property nombre

    override method peso() = resolucion.totalDePixeles() / 100
    override method afectarCon(virus) {
        nombre = "Brad Pitt dentro de un caballo de madera gigante"
        resolucion = 
            new Resolucion(alto = resolucion.ancho(), 
                            ancho = resolucion.alto())
    }
}

class Resolucion {
    const alto
    const ancho

    method totalDePixeles() = alto * ancho
}

class Musica inherits Archivo {
    const property peso
    const nombreCancion
    var nombreArtista

    override method afectarCon(virus) {
        if(nombreCancion != "Pronta Entrega")
            nombreArtista = virus.nombre()
    }

    method nombre() = nombreCancion + " - " + nombreArtista
}

class ProgramaNormal {
    const property nombre

    /* Punto 3.a */
    method ejecutarEn(compu) {
        const archivo = 
            new Texto(contenido = "información muy importante para el trabajo",
                    nombre = "datos." + nombre)
        compu.agregarArchivo(archivo)
    }
}

class Virus {
    const property nombre

    /* Punto 3.b */
    method ejecutarEn(compu) {
        compu.afectarArchivosCon(self)
    }
}

class Ransomware {
    const property nombre
    const property cuenta
    const cantidad
    const archivosSecuestrados = []

    /* Punto 3.c */
    method ejecutarEn(compu) {
        if(compu.tieneComprobantePara(self))
            self.devolverArchivosA(compu)
        else 
            if(compu.tieneArchivosSecuestrablesPor(self))
                self.secuestrarArchivosDe(compu)
            else 
                throw new RansomwareException(message = "no se puede secuestrar")
    }

    method devolverArchivosA(compu) {
        compu.agregarArchivos(archivosSecuestrados)
    }

    method nuevoReadme() = 
        new Texto(contenido = "Pagame " + cantidad + " a la cuenta " + cuenta,
                nombre = "README")
    
    method secuestrarArchivosDe(compu) {
        archivosSecuestrados.addAll(compu.archivos())
        compu.eliminarArchivos()
        compu.agregarArchivo(self.nuevoReadme())
    }
}

class RansomwareException inherits Exception {}



