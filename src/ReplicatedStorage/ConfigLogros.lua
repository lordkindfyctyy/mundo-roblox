-- Lista de logros. La usan el servidor (para detectar y pagar) y el cliente (para mostrar el progreso).
-- Cada logro mide un valor del jugador con valor() y se cumple cuando llega a meta.
-- El premio son monedas que NO suman al Total del ranking.
-- Agregar un logro = agregar una fila.

local ConfigMejoras = require(script.Parent:WaitForChild("ConfigMejoras"))

local function estadistica(jugador, nombre)
	local leaderstats = jugador:FindFirstChild("leaderstats")
	local valor = leaderstats and leaderstats:FindFirstChild(nombre)
	return valor and valor.Value or 0
end

-- Cuantos niveles de mejoras tiene comprados ahora (se reinicia al renacer)
local function nivelesComprados(jugador)
	local mejoras = jugador:FindFirstChild("Mejoras")
	local suma = 0
	if mejoras then
		for _, nivel in mejoras:GetChildren() do
			suma += nivel.Value
		end
	end
	return suma
end

-- Cuantas mejoras estan en su nivel maximo
local function mejorasAlMaximo(jugador)
	local mejoras = jugador:FindFirstChild("Mejoras")
	local cantidad = 0
	if mejoras then
		for _, mejora in ConfigMejoras.Lista do
			local nivel = mejoras:FindFirstChild(mejora.id)
			if nivel and nivel.Value >= mejora.nivelMaximo then
				cantidad += 1
			end
		end
	end
	return cantidad
end

-- Cuantas mascotas distintas tiene
local function cantidadDeMascotas(jugador)
	local mascotas = jugador:FindFirstChild("Mascotas")
	return mascotas and #mascotas:GetChildren() or 0
end

local ConfigLogros = {}

ConfigLogros.Lista = {
	{
		id = "PrimerosPasos",
		nombre = "Primeros pasos",
		descripcion = "Recolectá 10 monedas",
		meta = 10,
		premio = 20,
		valor = function(jugador)
			return estadistica(jugador, "Total")
		end,
	},
	{
		id = "Coleccionista",
		nombre = "Coleccionista",
		descripcion = "Recolectá 500 monedas en total",
		meta = 500,
		premio = 100,
		valor = function(jugador)
			return estadistica(jugador, "Total")
		end,
	},
	{
		id = "Tesorero",
		nombre = "Tesorero",
		descripcion = "Recolectá 5.000 monedas en total",
		meta = 5000,
		premio = 500,
		valor = function(jugador)
			return estadistica(jugador, "Total")
		end,
	},
	{
		id = "CazadorGigantes",
		nombre = "Cazador de gigantes",
		descripcion = "Recogé una moneda gigante",
		meta = 1,
		premio = 100,
		valor = function(jugador)
			return jugador:GetAttribute("Gigantes") or 0
		end,
	},
	{
		id = "GranCazador",
		nombre = "Gran cazador",
		descripcion = "Recogé 10 monedas gigantes",
		meta = 10,
		premio = 400,
		valor = function(jugador)
			return jugador:GetAttribute("Gigantes") or 0
		end,
	},
	{
		id = "DeCompras",
		nombre = "De compras",
		descripcion = "Comprá tu primera mejora",
		meta = 1,
		premio = 30,
		valor = nivelesComprados,
	},
	{
		id = "AlMaximo",
		nombre = "Al máximo",
		descripcion = "Llevá una mejora a su nivel máximo",
		meta = 1,
		premio = 200,
		valor = mejorasAlMaximo,
	},
	{
		id = "Renacido",
		nombre = "Renacido",
		descripcion = "Renacé por primera vez",
		meta = 1,
		premio = 300,
		valor = function(jugador)
			return estadistica(jugador, "Renacimientos")
		end,
	},
	{
		id = "MejorAmigo",
		nombre = "Mejor amigo",
		descripcion = "Conseguí tu primera mascota",
		meta = 1,
		premio = 100,
		valor = cantidadDeMascotas,
	},
	{
		id = "Zoologico",
		nombre = "Zoológico",
		descripcion = "Juntá 5 mascotas distintas",
		meta = 5,
		premio = 400,
		valor = cantidadDeMascotas,
	},
	{
		id = "Constante",
		nombre = "Constante",
		descripcion = "Llegá a una racha de 3 días",
		meta = 3,
		premio = 150,
		valor = function(jugador)
			return jugador:GetAttribute("Racha") or 0
		end,
	},
	{
		id = "Fiel",
		nombre = "Fiel",
		descripcion = "Llegá a una racha de 7 días",
		meta = 7,
		premio = 400,
		valor = function(jugador)
			return jugador:GetAttribute("Racha") or 0
		end,
	},
}

return ConfigLogros
