-- Reglas y lista de mascotas. La usan el servidor (sortear, validar, construir el modelo)
-- y el cliente (mostrar la coleccion).
-- Cada mascota equipada suma un bonus de monedas. Agregar una mascota = agregar una fila.

local ConfigMascotas = {}

ConfigMascotas.COSTO_HUEVO = 500
ConfigMascotas.MAX_EQUIPADAS = 3
ConfigMascotas.REEMBOLSO_REPETIDA = 0.4 -- si te toca una que ya tenias, te devuelve esta parte del precio

-- escala: tamano del modelo segun la rareza
ConfigMascotas.Rarezas = {
	Comun = { nombre = "Común", color = Color3.fromRGB(190, 190, 190), escala = 1 },
	PocoComun = { nombre = "Poco común", color = Color3.fromRGB(90, 200, 90), escala = 1.1 },
	Rara = { nombre = "Rara", color = Color3.fromRGB(70, 150, 255), escala = 1.25 },
	Epica = { nombre = "Épica", color = Color3.fromRGB(190, 90, 255), escala = 1.4 },
	Legendaria = { nombre = "Legendaria", color = Color3.fromRGB(255, 180, 0), escala = 1.6 },
}

-- peso: cuanto mas alto, mas facil sale en el huevo (la chance es peso / suma de todos los pesos)
-- bonus: 0.05 = +5% de monedas mientras la tengas equipada
ConfigMascotas.Lista = {
	{ id = "Gatito", nombre = "Gatito", rareza = "Comun", bonus = 0.05, peso = 20, color = Color3.fromRGB(240, 170, 90) },
	{ id = "Perrito", nombre = "Perrito", rareza = "Comun", bonus = 0.05, peso = 20, color = Color3.fromRGB(180, 130, 90) },
	{ id = "Pollito", nombre = "Pollito", rareza = "Comun", bonus = 0.05, peso = 20, color = Color3.fromRGB(255, 230, 90) },
	{ id = "Conejo", nombre = "Conejo", rareza = "PocoComun", bonus = 0.10, peso = 12, color = Color3.fromRGB(245, 245, 245) },
	{ id = "Zorrito", nombre = "Zorrito", rareza = "PocoComun", bonus = 0.10, peso = 12, color = Color3.fromRGB(240, 110, 40) },
	{ id = "Panda", nombre = "Panda", rareza = "Rara", bonus = 0.20, peso = 5, color = Color3.fromRGB(60, 60, 60) },
	{ id = "Buho", nombre = "Búho", rareza = "Rara", bonus = 0.20, peso = 5, color = Color3.fromRGB(130, 100, 70) },
	{ id = "Dragon", nombre = "Dragón bebé", rareza = "Epica", bonus = 0.35, peso = 4, color = Color3.fromRGB(120, 60, 200) },
	{ id = "Fenix", nombre = "Fénix", rareza = "Legendaria", bonus = 0.60, peso = 2, color = Color3.fromRGB(255, 90, 20) },
}

local porId = {}
for _, mascota in ConfigMascotas.Lista do
	porId[mascota.id] = mascota
end

function ConfigMascotas.buscar(id)
	return porId[id]
end

-- Elige una mascota al azar segun los pesos
function ConfigMascotas.sortear()
	local total = 0
	for _, mascota in ConfigMascotas.Lista do
		total += mascota.peso
	end

	local azar = math.random() * total
	for _, mascota in ConfigMascotas.Lista do
		azar -= mascota.peso
		if azar <= 0 then
			return mascota
		end
	end
	return ConfigMascotas.Lista[1]
end

-- Multiplicador de monedas que dan las mascotas equipadas: 1 sin ninguna, 1.3 con +30%...
function ConfigMascotas.multiplicador(jugador)
	local equipadas = jugador:FindFirstChild("MascotasEquipadas")
	local bonus = 0
	if equipadas then
		for _, marca in equipadas:GetChildren() do
			local mascota = porId[marca.Name]
			if mascota then
				bonus += mascota.bonus
			end
		end
	end
	return 1 + bonus
end

return ConfigMascotas
