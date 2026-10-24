-- Pesca: peces, cañas y premios. La usan el servidor (Pesca.server.lua) y el cliente (Pesca.client.lua).
-- Todos los numeros de juego estan aca para poder ajustarlos jugando.
-- Agregar un pez o una caña = agregar una fila.
--
-- Del jugador (los guarda GuardadoMonedas.server.lua):
--   PescaCanas: ids de las cañas compradas separados por coma ("fibra,carbono")
--   PescaPeces: lo que atrapo, "sardina:3,pulpo:1"
--   PescaTotal: cuantos peces atrapo en total

local ConfigPesca = {}

-- Tiempos (segundos)
ConfigPesca.ESPERA_MINIMA = 4 -- hasta la picada, antes de la mejora de la caña
ConfigPesca.ESPERA_MAXIMA = 9
ConfigPesca.MARGEN = 0.7 -- tolerancia extra del servidor por la demora de la conexion

ConfigPesca.Rarezas = {
	{ nombre = "Común", color = Color3.fromRGB(190, 190, 190) },
	{ nombre = "Poco común", color = Color3.fromRGB(90, 200, 90) },
	{ nombre = "Rara", color = Color3.fromRGB(70, 150, 255) },
	{ nombre = "Épica", color = Color3.fromRGB(190, 90, 255) },
	{ nombre = "Legendaria", color = Color3.fromRGB(255, 190, 40) },
}

-- valor: monedas que paga al pescarlo (se vende solo; no suma al Total del ranking)
-- peso: que tan seguido sale. Con suerte, los de rareza alta pesan mas (ver elegirPez)
ConfigPesca.Peces = {
	{ id = "bota", nombre = "Bota vieja", icono = "👢", rareza = 1, valor = 3, peso = 12 },
	{ id = "sardina", nombre = "Sardina", icono = "🐟", rareza = 1, valor = 10, peso = 30 },
	{ id = "boga", nombre = "Boga", icono = "🐟", rareza = 1, valor = 14, peso = 25 },
	{ id = "trucha", nombre = "Trucha", icono = "🐟", rareza = 2, valor = 30, peso = 18 },
	{ id = "pejerrey", nombre = "Pejerrey", icono = "🐠", rareza = 2, valor = 40, peso = 14 },
	{ id = "globo", nombre = "Pez globo", icono = "🐡", rareza = 3, valor = 80, peso = 8 },
	{ id = "pulpo", nombre = "Pulpo", icono = "🐙", rareza = 3, valor = 110, peso = 6 },
	{ id = "tiburon", nombre = "Tiburón bebé", icono = "🦈", rareza = 4, valor = 300, peso = 2.5 },
	{ id = "cofre", nombre = "Cofre hundido", icono = "🧰", rareza = 4, valor = 400, peso = 1.5 },
	{ id = "dorado", nombre = "Pez dorado", icono = "✨", rareza = 5, valor = 1200, peso = 0.4 },
}

-- espera: multiplica el tiempo hasta la picada (menos = pican antes)
-- suerte: sube la chance de los peces raros
-- ventana: segundos que tenes para tirar cuando pica
ConfigPesca.Canas = {
	{ id = "bambu", nombre = "Caña de bambú", icono = "🎣", precio = 0, espera = 1, suerte = 0, ventana = 1.5, detalle = "La de siempre" },
	{ id = "fibra", nombre = "Caña de fibra", icono = "🎣", precio = 400, espera = 0.75, suerte = 0.5, ventana = 1.7, detalle = "Pica antes y algo más de suerte" },
	{ id = "carbono", nombre = "Caña de carbono", icono = "🎣", precio = 1500, espera = 0.55, suerte = 1.5, ventana = 1.9, detalle = "Pica rápido y trae peces raros" },
	{ id = "dorada", nombre = "Caña dorada", icono = "🎣", precio = 5000, espera = 0.4, suerte = 3, ventana = 2.2, detalle = "La mejor: pica enseguida, mucha suerte" },
}

function ConfigPesca.pez(id)
	for _, pez in ConfigPesca.Peces do
		if pez.id == id then
			return pez
		end
	end
	return nil
end

-- "fibra,carbono" (el atributo PescaCanas) -> { fibra = true, carbono = true }
function ConfigPesca.comprados(texto)
	local tengo = {}
	for id in string.gmatch(texto or "", "[^,]+") do
		tengo[id] = true
	end
	return tengo
end

function ConfigPesca.tiene(tengo, cana)
	return cana.precio == 0 or tengo[cana.id] == true
end

-- La caña que usa: la mejor (la mas cara) de las que tiene
function ConfigPesca.mejorCana(tengo)
	local mejor = ConfigPesca.Canas[1]
	for _, cana in ConfigPesca.Canas do
		if ConfigPesca.tiene(tengo, cana) then
			mejor = cana
		end
	end
	return mejor
end

-- "sardina:3,pulpo:1" (el atributo PescaPeces) -> { sardina = 3, pulpo = 1 }
function ConfigPesca.conteos(texto)
	local cuenta = {}
	for id, cantidad in string.gmatch(texto or "", "([^,:]+):(%d+)") do
		cuenta[id] = tonumber(cantidad)
	end
	return cuenta
end

function ConfigPesca.texto(cuenta)
	local partes = {}
	for _, pez in ConfigPesca.Peces do
		if cuenta[pez.id] then
			table.insert(partes, pez.id .. ":" .. cuenta[pez.id])
		end
	end
	return table.concat(partes, ",")
end

-- Cuantas especies distintas atrapo
function ConfigPesca.especies(texto)
	local n = 0
	for _ in ConfigPesca.conteos(texto) do
		n += 1
	end
	return n
end

-- Elige un pez al azar. suerte: de la caña (0 = ninguna)
function ConfigPesca.elegirPez(azar, suerte)
	local total = 0
	local pesos = {}
	for i, pez in ConfigPesca.Peces do
		pesos[i] = pez.peso * (1 + suerte * (pez.rareza - 1) / 2)
		total += pesos[i]
	end
	local tirada = azar:NextNumber(0, total)
	for i, pez in ConfigPesca.Peces do
		tirada -= pesos[i]
		if tirada <= 0 then
			return pez
		end
	end
	return ConfigPesca.Peces[1]
end

return ConfigPesca
