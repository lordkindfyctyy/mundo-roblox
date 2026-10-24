-- Reglas y lista de mascotas. La usan el servidor (sortear, validar, construir el modelo)
-- y el cliente (mostrar la coleccion).
-- Cada mascota equipada suma un bonus de monedas. Agregar una mascota = agregar una fila.
-- Si te sale una repetida sube de nivel (hasta NIVEL_MAXIMO) y cada nivel le suma
-- BONUS_POR_NIVEL de su bonus. El nivel es el atributo "Nivel" de su marca en la
-- carpeta Mascotas del jugador (sin atributo = nivel 1).

local ConfigAlimentos = require(script.Parent:WaitForChild("ConfigAlimentos"))

local ConfigMascotas = {}

ConfigMascotas.MAX_EQUIPADAS = 3
ConfigMascotas.REEMBOLSO_REPETIDA = 0.4 -- con la mascota en nivel maximo, una repetida devuelve esta parte del precio
ConfigMascotas.NIVEL_MAXIMO = 5
ConfigMascotas.BONUS_POR_NIVEL = 0.25 -- cada nivel arriba del 1 suma +25% del bonus de la mascota

ConfigMascotas.RADIO_POR_NIVEL = 2 -- cada nivel arriba del 1 suma estos studs al radio para juntar monedas

-- escala: tamano del modelo segun la rareza
-- radio: hasta que distancia del jugador la mascota va a buscar monedas sola
-- velocidad: studs por segundo cuando va a buscar una moneda
ConfigMascotas.Rarezas = {
	Comun = { nombre = "Común", color = Color3.fromRGB(190, 190, 190), escala = 1, radio = 12, velocidad = 22 },
	PocoComun = { nombre = "Poco común", color = Color3.fromRGB(90, 200, 90), escala = 1.1, radio = 15, velocidad = 26 },
	Rara = { nombre = "Rara", color = Color3.fromRGB(70, 150, 255), escala = 1.25, radio = 18, velocidad = 30 },
	Epica = { nombre = "Épica", color = Color3.fromRGB(190, 90, 255), escala = 1.4, radio = 22, velocidad = 35 },
	Legendaria = { nombre = "Legendaria", color = Color3.fromRGB(255, 180, 0), escala = 1.6, radio = 28, velocidad = 42 },
}

-- Huevos. Cada mascota dice su peso en cada huevo (pesos.Comun, pesos.Dorado);
-- sin peso en un huevo, no sale en ese huevo. La chance es peso / suma de los pesos.
ConfigMascotas.Huevos = {
	{ id = "Comun", nombre = "Huevo común", costo = 500, color = Color3.fromRGB(0, 170, 80) },
	{ id = "Dorado", nombre = "Huevo dorado", costo = 2500, color = Color3.fromRGB(220, 160, 0) },
}

-- bonus: 0.05 = +5% de monedas mientras la tengas equipada (en nivel 1)
ConfigMascotas.Lista = {
	{ id = "Gatito", nombre = "Gatito", rareza = "Comun", bonus = 0.05, pesos = { Comun = 20 }, color = Color3.fromRGB(240, 170, 90) },
	{ id = "Perrito", nombre = "Perrito", rareza = "Comun", bonus = 0.05, pesos = { Comun = 20 }, color = Color3.fromRGB(180, 130, 90) },
	{ id = "Pollito", nombre = "Pollito", rareza = "Comun", bonus = 0.05, pesos = { Comun = 20 }, color = Color3.fromRGB(255, 230, 90) },
	{ id = "Conejo", nombre = "Conejo", rareza = "PocoComun", bonus = 0.10, pesos = { Comun = 12, Dorado = 15 }, color = Color3.fromRGB(245, 245, 245) },
	{ id = "Zorrito", nombre = "Zorrito", rareza = "PocoComun", bonus = 0.10, pesos = { Comun = 12, Dorado = 15 }, color = Color3.fromRGB(240, 110, 40) },
	{ id = "Pinguino", nombre = "Pingüino", rareza = "PocoComun", bonus = 0.10, pesos = { Comun = 12, Dorado = 15 }, color = Color3.fromRGB(40, 45, 60) },
	{ id = "Panda", nombre = "Panda", rareza = "Rara", bonus = 0.20, pesos = { Comun = 5, Dorado = 14 }, color = Color3.fromRGB(60, 60, 60) },
	{ id = "Buho", nombre = "Búho", rareza = "Rara", bonus = 0.20, pesos = { Comun = 5, Dorado = 14 }, color = Color3.fromRGB(130, 100, 70) },
	{ id = "Tigre", nombre = "Tigre", rareza = "Rara", bonus = 0.25, pesos = { Comun = 4, Dorado = 12 }, color = Color3.fromRGB(250, 140, 30) },
	{ id = "Dragon", nombre = "Dragón bebé", rareza = "Epica", bonus = 0.35, pesos = { Comun = 4, Dorado = 7 }, color = Color3.fromRGB(120, 60, 200) },
	{ id = "Unicornio", nombre = "Unicornio", rareza = "Epica", bonus = 0.40, pesos = { Dorado = 5 }, color = Color3.fromRGB(255, 240, 250) },
	{ id = "Fenix", nombre = "Fénix", rareza = "Legendaria", bonus = 0.60, pesos = { Comun = 2, Dorado = 2 }, color = Color3.fromRGB(255, 90, 20) },
	{ id = "DragonDorado", nombre = "Dragón dorado", rareza = "Legendaria", bonus = 0.80, pesos = { Dorado = 1 }, color = Color3.fromRGB(255, 195, 30) },
}

local porId = {}
for _, mascota in ConfigMascotas.Lista do
	porId[mascota.id] = mascota
end

local huevoPorId = {}
for _, huevo in ConfigMascotas.Huevos do
	huevoPorId[huevo.id] = huevo
end

function ConfigMascotas.buscar(id)
	return porId[id]
end

function ConfigMascotas.huevo(id)
	return huevoPorId[id]
end

-- Elige una mascota al azar de un huevo, segun los pesos
function ConfigMascotas.sortear(huevoId)
	local total = 0
	for _, mascota in ConfigMascotas.Lista do
		total += mascota.pesos[huevoId] or 0
	end

	local azar = math.random() * total
	for _, mascota in ConfigMascotas.Lista do
		local peso = mascota.pesos[huevoId] or 0
		azar -= peso
		if peso > 0 and azar <= 0 then
			return mascota
		end
	end
	return ConfigMascotas.Lista[1]
end

-- Nivel de una mascota que tiene el jugador (1 si no tiene el atributo)
function ConfigMascotas.nivel(jugador, id)
	local tengo = jugador:FindFirstChild("Mascotas")
	local marca = tengo and tengo:FindFirstChild(id)
	return marca and (marca:GetAttribute("Nivel") or 1) or 1
end

-- Bonus de una mascota en un nivel: +25% del bonus base por cada nivel arriba del 1
function ConfigMascotas.bonusEnNivel(mascota, nivel)
	return mascota.bonus * (1 + ConfigMascotas.BONUS_POR_NIVEL * (nivel - 1))
end

-- Hasta que distancia del jugador va a buscar monedas una mascota en un nivel
function ConfigMascotas.radioJuntar(mascota, nivel)
	return ConfigMascotas.Rarezas[mascota.rareza].radio + ConfigMascotas.RADIO_POR_NIVEL * (nivel - 1)
end

-- Multiplicador de monedas que dan las mascotas equipadas: 1 sin ninguna, 1.3 con +30%...
-- Si las alimentaron en el pet shop, el bonus se multiplica (ConfigAlimentos).
function ConfigMascotas.multiplicador(jugador)
	local equipadas = jugador:FindFirstChild("MascotasEquipadas")
	local bonus = 0
	if equipadas then
		for _, marca in equipadas:GetChildren() do
			local mascota = porId[marca.Name]
			if mascota then
				bonus += ConfigMascotas.bonusEnNivel(mascota, ConfigMascotas.nivel(jugador, marca.Name))
			end
		end
	end
	return 1 + bonus * ConfigAlimentos.factorActivo(jugador)
end

return ConfigMascotas
