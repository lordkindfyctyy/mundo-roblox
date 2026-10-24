-- Recorridos de los juegos del parque de diversiones: la montaña rusa y el tobogan.
-- Los usa Diversiones.server.lua para construir las vias y saber cuanto dura cada
-- vuelta, y Diversiones.client.lua para mover al jugador por ellas.
--
-- Cada recorrido es una lista de puntos (en coordenadas del mundo) por donde pasa una
-- curva suave (Catmull-Rom). Los puntos marcan la cara de arriba de la via.
-- La velocidad sale de la altura, como si fuera la gravedad: abajo va mas rapido.
-- En la montaña rusa, hasta llegar a lo mas alto sube despacio, como en una de verdad.

local Recorridos = {}

local PASOS = 10 -- muestras de la curva entre dos puntos

Recorridos.Lista = {
	MontanaRusa = {
		nombre = "Montaña rusa",
		premio = 40,
		cerrado = true, -- termina donde empezo (la estacion)
		subidaLenta = true,
		velocidadMinima = 14,
		gravedad = 45,
		alturaJugador = 2.3, -- cuanto arriba de la via va el centro del jugador (sentado en el carrito)
		salida = Vector3.new(-18, 6, -202), -- al terminar te deja parado en el anden de la estacion
		puntos = {
			Vector3.new(-24, 3, -192), -- estacion
			Vector3.new(-24, 3, -212),
			Vector3.new(-27, 16, -238), -- subida
			Vector3.new(-33, 36, -264),
			Vector3.new(-44, 40, -282), -- lo mas alto
			Vector3.new(-58, 10, -298), -- la gran caida
			Vector3.new(-76, 6, -314),
			Vector3.new(-90, 20, -300),
			Vector3.new(-86, 26, -272),
			Vector3.new(-70, 10, -252),
			Vector3.new(-80, 22, -230),
			Vector3.new(-88, 14, -205),
			Vector3.new(-74, 6, -184),
			Vector3.new(-50, 11, -176),
			Vector3.new(-32, 5, -180),
		},
	},
	Tobogan = {
		nombre = "Tobogán gigante",
		premio = 20,
		cerrado = false,
		subidaLenta = false,
		velocidadMinima = 12,
		gravedad = 28,
		alturaJugador = 1.6,
		empujonFinal = 35, -- al llegar abajo sale disparado hacia adelante
		puntos = {
			Vector3.new(66, 32.5, -220), -- arriba de la torre
			Vector3.new(78, 27, -223),
			Vector3.new(88, 21, -211),
			Vector3.new(85, 15, -196),
			Vector3.new(72, 10, -189),
			Vector3.new(60, 6, -196),
			Vector3.new(47, 3, -191),
			Vector3.new(38, 1.2, -182), -- abajo
		},
	},
}

local function catmullRom(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

-- Muestras de la curva y el tiempo en que se pasa por cada una:
--   { puntos = {Vector3...}, tiempos = {segundos...}, duracion }
-- Se calcula una sola vez por recorrido.
function Recorridos.muestras(id)
	local r = Recorridos.Lista[id]
	if r.cache then
		return r.cache
	end

	local pts = r.puntos
	local n = #pts
	local function punto(i)
		if r.cerrado then
			return pts[(i - 1) % n + 1]
		end
		return pts[math.clamp(i, 1, n)]
	end

	local lista = {}
	local tramos = r.cerrado and n or n - 1
	for i = 1, tramos do
		for k = 0, PASOS - 1 do
			table.insert(lista, catmullRom(punto(i - 1), punto(i), punto(i + 1), punto(i + 2), k / PASOS))
		end
	end
	table.insert(lista, r.cerrado and pts[1] or pts[n])

	-- Lo mas alto del recorrido: de ahi para adelante, la velocidad sale de la altura
	local cima = 1
	for i, p in lista do
		if p.Y > lista[cima].Y then
			cima = i
		end
	end
	local alturaCima = lista[cima].Y
	local vMin = r.velocidadMinima

	local tiempos = { 0 }
	for i = 2, #lista do
		local velocidad = vMin
		if not (r.subidaLenta and i <= cima) then
			velocidad = math.sqrt(vMin * vMin + 2 * r.gravedad * math.max(0, alturaCima - lista[i].Y))
		end
		tiempos[i] = tiempos[i - 1] + (lista[i] - lista[i - 1]).Magnitude / velocidad
	end

	r.cache = { puntos = lista, tiempos = tiempos, duracion = tiempos[#tiempos] }
	return r.cache
end

-- Donde esta y hacia donde mira el recorrido a los t segundos.
-- desde: indice para empezar a buscar (para no recorrer toda la lista cada vez).
-- Devuelve posicion, direccion e indice.
function Recorridos.en(muestras, t, desde)
	local tiempos, puntos = muestras.tiempos, muestras.puntos
	local i = math.max(1, desde or 1)
	while i < #tiempos - 1 and tiempos[i + 1] < t do
		i += 1
	end
	local a, b = puntos[i], puntos[i + 1]
	local tramo = tiempos[i + 1] - tiempos[i]
	local alfa = tramo > 0 and math.clamp((t - tiempos[i]) / tramo, 0, 1) or 1
	return a:Lerp(b, alfa), (b - a).Unit, i
end

return Recorridos
