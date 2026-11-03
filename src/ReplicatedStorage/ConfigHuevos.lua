-- El busca huevos: huevos de colores escondidos por el mapa. Cada jugador encuentra los suyos (el que recoge
-- desaparece solo para el) y queda guardado. Cada huevo paga monedas; los premios grandes son logros
-- (ConfigLogros.lua: 5, 15 y 30 huevos).
-- Aca solo esta lo que necesitan el servidor y el cliente. DONDE esta cada huevo lo decide Huevos.server.lua.
-- Agregar un huevo = una fila en Huevos (con su zona) y su posicion en Huevos.server.lua.

local ConfigHuevos = {}

ConfigHuevos.PREMIO = 30 -- monedas por cada huevo (no suman al Total del ranking)

-- Las zonas, en el orden en que se muestran. pista: una ayuda para saber por donde buscar.
ConfigHuevos.Zonas = {
	{ id = "Parque", nombre = "El parque", icono = "🌳", pista = "Entre los árboles y las flores del centro" },
	{ id = "Ciudad", nombre = "La ciudad", icono = "🏙️", pista = "En las esquinas y detrás de los edificios" },
	{ id = "Torre", nombre = "La Torre", icono = "🗼", pista = "Uno arriba de todo, cerca del cofre... y otro abajo" },
	{ id = "Playa", nombre = "La Playa", icono = "🏖️", pista = "En la arena, en la isla del tesoro y al final del muelle" },
	{ id = "Barrio", nombre = "El Barrio", icono = "🏠", pista = "En los fondos de las casas y al final de la calle" },
	{ id = "Mansiones", nombre = "Las mansiones", icono = "🏰", pista = "Cerca de las piletas del fondo" },
	{ id = "Diversiones", nombre = "Parque de diversiones", icono = "🎢", pista = "Detrás de los juegos, por los costados" },
	{ id = "Golf", nombre = "La cancha de golf", icono = "⛳", pista = "En los rincones del fondo, lejos de los hoyos" },
}

-- Todos los huevos. id: unico (se guarda). zona: una de las de arriba.
ConfigHuevos.Huevos = {
	{ id = "P1", zona = "Parque" },
	{ id = "P2", zona = "Parque" },
	{ id = "P3", zona = "Parque" },
	{ id = "C1", zona = "Ciudad" },
	{ id = "C2", zona = "Ciudad" },
	{ id = "C3", zona = "Ciudad" },
	{ id = "C4", zona = "Ciudad" },
	{ id = "C5", zona = "Ciudad" },
	{ id = "C6", zona = "Ciudad" },
	{ id = "C7", zona = "Ciudad" },
	{ id = "C8", zona = "Ciudad" },
	{ id = "T1", zona = "Torre" },
	{ id = "T2", zona = "Torre" },
	{ id = "B1", zona = "Playa" },
	{ id = "B2", zona = "Playa" },
	{ id = "B3", zona = "Playa" },
	{ id = "B4", zona = "Playa" },
	{ id = "H1", zona = "Barrio" },
	{ id = "H2", zona = "Barrio" },
	{ id = "H3", zona = "Barrio" },
	{ id = "H4", zona = "Barrio" },
	{ id = "M1", zona = "Mansiones" },
	{ id = "M2", zona = "Mansiones" },
	{ id = "D1", zona = "Diversiones" },
	{ id = "D2", zona = "Diversiones" },
	{ id = "D3", zona = "Diversiones" },
	{ id = "D4", zona = "Diversiones" },
	{ id = "G1", zona = "Golf" },
	{ id = "G2", zona = "Golf" },
	{ id = "G3", zona = "Golf" },
}

local zonaDe = {}
for _, huevo in ConfigHuevos.Huevos do
	zonaDe[huevo.id] = huevo.zona
end

-- Lo que encontro un jugador se guarda como texto ("P1,C3,T1"): { id = true }
function ConfigHuevos.hallados(texto)
	local lista = {}
	if type(texto) == "string" then
		for id in string.gmatch(texto, "[^,]+") do
			if zonaDe[id] then -- ignora ids viejos o raros
				lista[id] = true
			end
		end
	end
	return lista
end

function ConfigHuevos.texto(lista)
	local ids = {}
	for _, huevo in ConfigHuevos.Huevos do
		if lista[huevo.id] then
			table.insert(ids, huevo.id)
		end
	end
	return table.concat(ids, ",")
end

function ConfigHuevos.total()
	return #ConfigHuevos.Huevos
end

-- Cuantos lleva encontrados un jugador (lo usan los logros)
function ConfigHuevos.cantidad(jugador)
	local cuenta = 0
	for _ in ConfigHuevos.hallados(jugador:GetAttribute("HuevosHallados")) do
		cuenta += 1
	end
	return cuenta
end

-- { [zonaId] = { hallados = n, total = n } }
function ConfigHuevos.porZona(lista)
	local resultado = {}
	for _, zona in ConfigHuevos.Zonas do
		resultado[zona.id] = { hallados = 0, total = 0 }
	end
	for _, huevo in ConfigHuevos.Huevos do
		local fila = resultado[huevo.zona]
		fila.total += 1
		if lista[huevo.id] then
			fila.hallados += 1
		end
	end
	return resultado
end

return ConfigHuevos
