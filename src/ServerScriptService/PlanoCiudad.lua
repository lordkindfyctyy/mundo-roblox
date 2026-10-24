-- Plano de la ciudad: donde van las calles. Lo usan Ciudad.server.lua para
-- construirla y JuegoMonedas.server.lua para poner monedas sobre las calles
-- (nunca adentro de un edificio).

local Plano = {}

Plano.LIMITE = 158 -- la ciudad llega hasta +-LIMITE; ahi hay una pared invisible
Plano.CALLES = { -150, -63, 63, 150 } -- centro de cada calle (iguales en X y en Z)
Plano.AVENIDA = 0 -- avenida central, solo fuera del parque
Plano.MEDIO_ANCHO_CALLE = 8 -- las calles miden 16 de ancho
Plano.ANILLO = 63 -- la calle que rodea al parque

-- Un punto al azar sobre alguna calle o avenida (y = 0).
-- azar: un Random. Deja un margen para que la moneda no quede en el cordon.
function Plano.puntoEnCalle(azar)
	local margen = Plano.MEDIO_ANCHO_CALLE - 2
	local limite = Plano.LIMITE - 4

	-- Las calles de la cuadricula pesan mas que las avenidas porque son mas largas
	local opciones = #Plano.CALLES * 2 + 4
	local eleccion = azar:NextInteger(1, opciones)
	local corrido = azar:NextNumber(-margen, margen)

	if eleccion <= #Plano.CALLES * 2 then
		local centro = Plano.CALLES[(eleccion - 1) % #Plano.CALLES + 1] + corrido
		local largo = azar:NextNumber(-limite, limite)
		if eleccion <= #Plano.CALLES then
			return Vector3.new(largo, 0, centro) -- calle a lo largo de X
		end
		return Vector3.new(centro, 0, largo) -- calle a lo largo de Z
	end

	-- Avenidas: desde la calle del parque hacia afuera, en las cuatro direcciones
	local desde = Plano.ANILLO + Plano.MEDIO_ANCHO_CALLE + 2
	local largo = azar:NextNumber(desde, limite) * (azar:NextInteger(0, 1) == 0 and -1 or 1)
	local centro = Plano.AVENIDA + corrido
	if eleccion % 2 == 0 then
		return Vector3.new(largo, 0, centro)
	end
	return Vector3.new(centro, 0, largo)
end

-- La Playa (Playa.server.lua): al este de la ciudad, pasando el arco que hay al
-- final de la avenida (x = LIMITE, z = 0). Arena de ARENA_X1 a ARENA_X2 y el mar
-- despues. La entrada es libre.
-- La playa esta elevada (el agua queda arriba del piso del lugar): desde la entrada
-- se sube por escalones hasta la arena.
Plano.PLAYA = {
	ESCALONES_X1 = 160, -- desde aca suben los escalones
	ARENA_X1 = 176, -- desde aca la arena es plana
	ARENA_X2 = 262,
	MAR_X2 = 440,
	Z = 130, -- de -Z a +Z
	PUERTA = 7, -- medio ancho de la entrada
	ALTO = 5.6, -- altura de la arena
	NIVEL_AGUA = 5,
}

-- Un punto al azar sobre la arena (a la altura de la arena), lejos del agua y de los bordes
function Plano.puntoEnPlaya(azar)
	local p = Plano.PLAYA
	return Vector3.new(azar:NextNumber(p.ARENA_X1 + 4, p.ARENA_X2 - 8), p.ALTO, azar:NextNumber(-p.Z + 8, p.Z - 8))
end

-- El Barrio de casas (Casas.server.lua): al oeste de la ciudad, pasando el arco
-- que hay al final de la avenida (x = -LIMITE, z = 0). Una calle a lo largo de X
-- en z = 0 y terrenos a los dos lados, con el frente hacia la calle.
Plano.BARRIO = {
	X_CERCA = -160, -- donde empieza (junto a la pared de la ciudad)
	X_LEJOS = -310, -- donde termina
	Z = 75, -- de -Z a +Z
	PUERTA = 7, -- medio ancho de la entrada
	MEDIO_ANCHO_CALLE = 6,
	-- Centro de cada terreno; los de z > 0 miran hacia -Z (la calle) y los otros hacia +Z
	TERRENOS = {
		Vector3.new(-190, 0, 36),
		Vector3.new(-235, 0, 36),
		Vector3.new(-280, 0, 36),
		Vector3.new(-190, 0, -36),
		Vector3.new(-235, 0, -36),
		Vector3.new(-280, 0, -36),
	},
}

-- El parque de diversiones (Diversiones.server.lua): al sur de la ciudad, pasando el
-- arco que hay al final de la avenida (x = 0, z = -LIMITE). Va de Z_CERCA a Z_LEJOS
-- (hacia -Z) y de -X a +X. Un camino ancho baja por el medio (x = 0).
Plano.DIVERSIONES = {
	Z_CERCA = -160, -- donde empieza (junto a la pared de la ciudad)
	Z_LEJOS = -340, -- donde termina
	X = 100, -- de -X a +X
	PUERTA = 7, -- medio ancho de la entrada
	MEDIO_ANCHO_CAMINO = 8,
}

-- Un punto al azar sobre el camino del medio del parque de diversiones (y = 0)
function Plano.puntoEnDiversiones(azar)
	local d = Plano.DIVERSIONES
	local margen = d.MEDIO_ANCHO_CAMINO - 2
	return Vector3.new(azar:NextNumber(-margen, margen), 0, azar:NextNumber(d.Z_LEJOS + 45, d.Z_CERCA - 6))
end

-- Los cruces de la cuadricula (donde hay semaforos): centro de cada uno, y = 0
function Plano.cruces()
	local lista = {}
	for _, x in Plano.CALLES do
		for _, z in Plano.CALLES do
			table.insert(lista, Vector3.new(x, 0, z))
		end
	end
	return lista
end

-- Luces de los semaforos: Semaforos.server.lua pone en Workspace los atributos
-- "LuzX" y "LuzZ" ("verde", "amarilla" o "roja"), uno para los autos que van a lo
-- largo de X y otro para los que van a lo largo de Z. Los autos los leen.
Plano.ATRIBUTO_LUZ = { [true] = "LuzX", [false] = "LuzZ" }

return Plano
