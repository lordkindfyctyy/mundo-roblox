-- Reglas de la cancha de golf. Las usan el servidor (construir la cancha, mover la
-- pelota, pagar) y el cliente (palos y nombres de superficies).
-- Todos los numeros de juego estan aca para poder ajustarlos jugando.

local ConfigGolf = {}

-- velocidad: con la potencia al maximo, a que velocidad sale la pelota (studs por segundo)
-- elevacion: cuanto sube por cada stud que avanza (0 = rueda por el piso)
-- precio: monedas en la tienda de golf (sin precio = viene gratis)
-- ignoraTerreno: el rough y el bunker no le quitan fuerza al golpe
-- detalle: lo que dice la tienda
ConfigGolf.Palos = {
	{ id = "Madera", nombre = "Madera", velocidad = 140, elevacion = 0.55 }, -- el mas largo, ~130 studs
	{ id = "Hierro", nombre = "Hierro", velocidad = 90, elevacion = 0.9 }, -- mas corto y mas alto, ~85
	{ id = "Putter", nombre = "Putter", velocidad = 48, elevacion = 0 }, -- rueda, para el green
	{
		id = "Cuna",
		nombre = "Cuña",
		velocidad = 62,
		elevacion = 1.6,
		precio = 500,
		ignoraTerreno = true,
		detalle = "Tiro corto y muy alto. Sale del bunker sin perder fuerza",
	},
	{
		id = "Hibrido",
		nombre = "Híbrido",
		velocidad = 118,
		elevacion = 0.7,
		precio = 1000,
		ignoraTerreno = true,
		detalle = "Largo y parejo. No lo frena el rough",
	},
	{
		id = "Driver",
		nombre = "Driver",
		velocidad = 170,
		elevacion = 0.5,
		precio = 2000,
		detalle = "Pega ~190 m. Ideal para los hoyos largos",
	},
	{
		id = "Cohete",
		nombre = "Cohete",
		velocidad = 200,
		elevacion = 0.45,
		precio = 5000,
		detalle = "El más potente: ~265 m. ¡Cuidado, te pasás!",
	},
}

function ConfigGolf.palo(id)
	for _, palo in ConfigGolf.Palos do
		if palo.id == id then
			return palo
		end
	end
	return nil
end

-- Estilos de pelota. Todos se ven iguales de lejos salvo por lo que tienen:
--   color, material: la pelota en si
--   luz: { color, brillo, rango }  una luz que la acompana (se nota de noche)
--   fuego: { color, secundario }   llamas
--   estela: color de la cola que deja al volar
--   arcoiris: cambia de color todo el tiempo
--   icono: emoji para la tienda
ConfigGolf.Pelotas = {
	{ id = "Clasica", nombre = "Clásica", precio = 0, icono = "⚪", color = Color3.fromRGB(250, 250, 250) },
	{ id = "Rosa", nombre = "Rosa", precio = 200, icono = "🩷", color = Color3.fromRGB(255, 130, 190) },
	{
		id = "Dorada",
		nombre = "Dorada",
		precio = 500,
		icono = "🟡",
		color = Color3.fromRGB(255, 200, 40),
		material = Enum.Material.Metal,
	},
	{
		id = "LuzCeleste",
		nombre = "Luz celeste",
		precio = 800,
		icono = "💠",
		color = Color3.fromRGB(80, 220, 255),
		material = Enum.Material.Neon,
		luz = { color = Color3.fromRGB(80, 220, 255), brillo = 3, rango = 18 },
		estela = Color3.fromRGB(80, 220, 255),
	},
	{
		id = "LuzVerde",
		nombre = "Luz verde",
		precio = 800,
		icono = "💚",
		color = Color3.fromRGB(90, 255, 120),
		material = Enum.Material.Neon,
		luz = { color = Color3.fromRGB(90, 255, 120), brillo = 3, rango = 18 },
		estela = Color3.fromRGB(90, 255, 120),
	},
	{
		id = "LuzVioleta",
		nombre = "Luz violeta",
		precio = 800,
		icono = "💜",
		color = Color3.fromRGB(190, 100, 255),
		material = Enum.Material.Neon,
		luz = { color = Color3.fromRGB(190, 100, 255), brillo = 3, rango = 18 },
		estela = Color3.fromRGB(190, 100, 255),
	},
	{
		id = "Fuego",
		nombre = "Bola de fuego",
		precio = 2000,
		icono = "🔥",
		color = Color3.fromRGB(255, 120, 20),
		material = Enum.Material.Neon,
		luz = { color = Color3.fromRGB(255, 140, 40), brillo = 4, rango = 22 },
		fuego = { color = Color3.fromRGB(255, 150, 30), secundario = Color3.fromRGB(220, 40, 20) },
	},
	{
		id = "FuegoAzul",
		nombre = "Fuego azul",
		precio = 3000,
		icono = "🧊",
		color = Color3.fromRGB(60, 140, 255),
		material = Enum.Material.Neon,
		luz = { color = Color3.fromRGB(70, 150, 255), brillo = 4, rango = 22 },
		fuego = { color = Color3.fromRGB(90, 190, 255), secundario = Color3.fromRGB(30, 60, 220) },
		estela = Color3.fromRGB(90, 190, 255),
	},
	{
		id = "Arcoiris",
		nombre = "Arcoíris",
		precio = 4000,
		icono = "🌈",
		color = Color3.fromRGB(255, 80, 80),
		material = Enum.Material.Neon,
		luz = { color = Color3.fromRGB(255, 80, 80), brillo = 3, rango = 20 },
		estela = Color3.fromRGB(255, 255, 255),
		arcoiris = true,
	},
}

function ConfigGolf.pelota(id)
	for _, pelota in ConfigGolf.Pelotas do
		if pelota.id == id then
			return pelota
		end
	end
	return ConfigGolf.Pelotas[1]
end

-- "Cuna,Driver" (el atributo GolfCosas del jugador) -> { Cuna = true, Driver = true }
function ConfigGolf.comprados(texto)
	local tengo = {}
	for id in string.gmatch(texto or "", "[^,]+") do
		tengo[id] = true
	end
	return tengo
end

-- Lo que no tiene precio (o cuesta 0) lo tiene todo el mundo
function ConfigGolf.tiene(tengo, cosa)
	return cosa.precio == nil or cosa.precio == 0 or tengo[cosa.id] == true
end

-- Como se porta la pelota en cada superficie (el nombre sale del atributo "Superficie" de la parte):
--   friccion y arrastre: cuanto la frenan al rodar (mas = frena antes)
--   aterrizaje: que parte de la velocidad horizontal conserva al caer de un tiro en el aire
--   potencia: cuanto se pierde al golpear desde ahi
ConfigGolf.Superficies = {
	Green = { nombre = "Green", friccion = 3, arrastre = 1.0, aterrizaje = 0.35, potencia = 1 },
	Fairway = { nombre = "Calle", friccion = 6, arrastre = 2.2, aterrizaje = 0.4, potencia = 1 },
	Tee = { nombre = "Tee", friccion = 6, arrastre = 2.2, aterrizaje = 0.4, potencia = 1 },
	Rough = { nombre = "Rough", friccion = 12, arrastre = 4, aterrizaje = 0.15, potencia = 0.85 },
	Bunker = { nombre = "Bunker", friccion = 30, arrastre = 10, aterrizaje = 0, potencia = 0.6 },
	Agua = { nombre = "Agua", friccion = 30, arrastre = 10, aterrizaje = 0, potencia = 1 },
	Otro = { nombre = "Camino", friccion = 8, arrastre = 2.5, aterrizaje = 0.4, potencia = 1 },
}

function ConfigGolf.superficie(nombre)
	return ConfigGolf.Superficies[nombre] or ConfigGolf.Superficies.Otro
end

ConfigGolf.DISTANCIA_MAXIMA = 45 -- el jugador tiene que estar a esta distancia de la pelota para pegarle
ConfigGolf.ESPERA_GOLPE = 0.4 -- segundos minimos entre dos golpes
ConfigGolf.LIMITE_GOLPES = 12 -- al llegar a este numero de golpes el hoyo se cierra sin premio

-- Premios en monedas. Por hoyo: BASE + POR_GOLPE por cada golpe menos que el par (minimo MINIMO).
-- Los premios no suman al Total del ranking.
ConfigGolf.Premios = {
	BASE = 40,
	POR_GOLPE = 30,
	MINIMO = 10,
	HOYO_EN_UNO = 300, -- extra
	RECORRIDO_BAJO_PAR = 250, -- extra por terminar todos los hoyos en par o mejor
}

-- Los hoyos. Todos van de norte a sur y estan uno al lado del otro.
--   x: el centro del hoyo (donde esta el tee)   largo: distancia del tee a la bandera
--   Todo lo que sigue se ubica con: dx = corrido al costado, avance = distancia desde el tee
--   bunkers y lagos: radio
--   monticulos: radio y alto (lomas que desvian la pelota; alto <= 0.45 * radio)
--   arboles: troncos en medio de la calle (la pelota rebota; las hojas no frenan)
--   tunel: una colina de roca con un paso en el medio; ancho = lo ancho de la colina
-- Ojo: nada de esto va encima del green (distancia al centro del green > radioGreen + radio).
ConfigGolf.Hoyos = {
	{
		-- Para empezar: corto, con dos lomas y bunkers junto al green
		numero = 1,
		par = 3,
		x = -210,
		largo = 110,
		radioGreen = 11,
		bunkers = {
			{ dx = -9, avance = 103, radio = 5.5 },
			{ dx = 10, avance = 98, radio = 5 },
		},
		lagos = {},
		monticulos = {
			{ dx = -16, avance = 88, radio = 9, alto = 3.5 },
			{ dx = 22, avance = 118, radio = 8, alto = 3 },
		},
		arboles = {
			{ dx = -7, avance = 50 },
			{ dx = 8, avance = 60 },
		},
	},
	{
		-- El lago te corta el camino: hay que rodearlo o pasarlo por arriba
		numero = 2,
		par = 4,
		x = -126,
		largo = 165,
		radioGreen = 11,
		bunkers = {
			{ dx = 11, avance = 157, radio = 6 },
			{ dx = -12, avance = 162, radio = 5 },
		},
		lagos = {
			{ dx = -4, avance = 85, radio = 15 },
		},
		monticulos = {
			{ dx = 14, avance = 58, radio = 10, alto = 4 },
			{ dx = -15, avance = 135, radio = 9, alto = 3.5 },
		},
		arboles = {
			{ dx = 6, avance = 35 },
			{ dx = -9, avance = 115 },
		},
	},
	{
		-- Par 5 con un tunel en el camino
		numero = 3,
		par = 5,
		x = -42,
		largo = 240,
		radioGreen = 12,
		bunkers = {
			{ dx = -10, avance = 165, radio = 7 },
			{ dx = 11, avance = 196, radio = 6 },
			{ dx = -12, avance = 236, radio = 5 },
			{ dx = 13, avance = 246, radio = 5 },
		},
		lagos = {
			{ dx = 15, avance = 215, radio = 12 },
		},
		monticulos = {
			{ dx = 13, avance = 60, radio = 9, alto = 3.5 },
			{ dx = -14, avance = 140, radio = 11, alto = 4.5 },
		},
		arboles = {
			{ dx = 8, avance = 150 },
			{ dx = -5, avance = 180 },
		},
		tunel = { avance = 105, ancho = 44 },
	},
	{
		-- Par 3 sobre el agua: o llegás volando o te mojás
		numero = 4,
		par = 3,
		x = 42,
		largo = 130,
		radioGreen = 11,
		bunkers = {
			{ dx = -12, avance = 128, radio = 6 },
			{ dx = 12, avance = 134, radio = 6 },
			{ dx = 0, avance = 146, radio = 5 },
		},
		lagos = {
			{ dx = 0, avance = 105, radio = 17 },
		},
		monticulos = {
			{ dx = -28, avance = 100, radio = 9, alto = 3.5 },
			{ dx = 28, avance = 102, radio = 9, alto = 3.5 },
		},
		arboles = {
			{ dx = -18, avance = 75 },
			{ dx = 18, avance = 80 },
		},
	},
	{
		-- Un tunel al principio y un bosquecito antes del green
		numero = 5,
		par = 4,
		x = 126,
		largo = 180,
		radioGreen = 11,
		bunkers = {
			{ dx = -11, avance = 172, radio = 6 },
			{ dx = 12, avance = 170, radio = 6 },
		},
		lagos = {},
		monticulos = {
			{ dx = -14, avance = 45, radio = 9, alto = 3.5 },
			{ dx = 12, avance = 150, radio = 10, alto = 4.5 },
		},
		arboles = {
			{ dx = -6, avance = 130 },
			{ dx = 2, avance = 135 },
			{ dx = 9, avance = 128 },
			{ dx = -10, avance = 145 },
		},
		tunel = { avance = 95, ancho = 40 },
	},
	{
		-- El final: dos lagos, una loma en el medio y bunkers por todos lados
		numero = 6,
		par = 5,
		x = 210,
		largo = 245,
		radioGreen = 12,
		bunkers = {
			{ dx = 10, avance = 100, radio = 7 },
			{ dx = -14, avance = 172, radio = 7 },
			{ dx = -15, avance = 240, radio = 6 },
			{ dx = 15, avance = 236, radio = 5 },
		},
		lagos = {
			{ dx = -12, avance = 135, radio = 13 },
			{ dx = 14, avance = 205, radio = 12 },
		},
		monticulos = {
			{ dx = 14, avance = 60, radio = 10, alto = 4 },
			{ dx = 4, avance = 168, radio = 8, alto = 3 },
			{ dx = -14, avance = 205, radio = 9, alto = 3.5 },
		},
		arboles = {
			{ dx = -3, avance = 100 },
			{ dx = -6, avance = 190 },
			{ dx = 6, avance = 225 },
		},
	},
}

function ConfigGolf.parTotal()
	local total = 0
	for _, hoyo in ConfigGolf.Hoyos do
		total += hoyo.par
	end
	return total
end

return ConfigGolf
