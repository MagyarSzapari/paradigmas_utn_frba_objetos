/** First Wollok example */

object cosmeFulanito{
	const cuenta = cuentaBasica
	const contenidoVisto = #{}
	
	method contenidoVisto(){
		return contenidoVisto
	}

	method puedeVer(contenido){
		return cuenta.contenidoDisponible(contenido)
	}
	
	method ver(contenido){	
		return cuenta.verContenido(self, contenido)
		
	}
	
	method promedioDeValoraciones(){
		return cuenta.calcularValoracionPromedio(self)
	
	}
	
	
}


object margoZavala{
	const cuenta = cuentaPremium
	
	const contenidoVisto = #{}
	
	method contenidoVisto()
	{
		return contenidoVisto
	}
	
	
	method puedeVer(contenido)
	{
		return cuenta.contenidoDisponible(contenido)
	}
	
	
	method ver(contenido)
	{
		
		return cuenta.verContenido(self, contenido)
		
	}
	
	method promedioDeValoraciones()
	{
		
		return cuenta.calcularValoracionPromedio(self)
	
	}
	
		
}

object blackSails
{
	const temporadas = 4
	
	const capitulosPorTemporada = 8 
	
	const generos = #{"accion"}
	
	
	method valoracion()
	{
		return temporadas * capitulosPorTemporada
	}
	
}

object avengersEndgame
{
	
	
	const generos = #{"accion", "drama", "aventuras"}
	
	
	method valoracion()
	{
		return generos.size() * 12
	}
	
}

object seanEternos
{
	
	const generos = #{"documental"}
	
	
	method valoracion() 
	{
		return 100
	} 

}

object cuentaBasica
{
	
	
	method contenidoDisponible(contenido)
	{
		return [blackSails, avengersEndgame].contains(contenido)
	}
	
	method verContenido(usuario, contenidoNuevo)
	{
		if(usuario.puedeVer(contenidoNuevo))
		{
		   usuario.contenidoVisto().add(contenidoNuevo)
		}
		
	}
	
	method calcularValoracionPromedio(usuario)
	{
		
		if(usuario.contenidoVisto().size() > 0)
		{
			
		var largoLista = usuario.contenidoVisto().size()
		var sumaDeValoraciones = usuario.contenidoVisto().map({contenido => contenido.valoracion()}).sum()
		
		return sumaDeValoraciones / largoLista
		
		}
		else
		{
		  return 0 
		}
		
	}
	
}

object cuentaPremium
{
	method contenidoDisponible(contenido)
	{
		return true
	}
	
	method verContenido(usuario, contenidoNuevo)
	{
		if(usuario.puedeVer(contenidoNuevo))
		{
		   usuario.contenidoVisto().add(contenidoNuevo)
		}
		
	}
	
	method calcularValoracionPromedio(usuario)
	{
		
		if(usuario.contenidoVisto().size() > 0)
		{
			
		var largoLista = usuario.contenidoVisto().size()
		var sumaDeValoraciones = usuario.contenidoVisto().map({contenido => contenido.valoracion()}).sum()
		
		return sumaDeValoraciones / largoLista
		
		}
		else
		{
		  return 0 
		}
		
	}
	
	
	
	
}



object wollok {
	method howAreYou() {
		return 'I am Wolloktastic!'
	}
}
