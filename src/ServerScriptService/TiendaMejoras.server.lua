-- Logica de la tienda en el servidor: crea los niveles de cada jugador,
-- valida las compras y aplica los efectos (velocidad, salto).
-- El multiplicador de monedas lo lee JuegoMonedas.server.lua.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigMejoras = require(ReplicatedStorage:WaitForChild("ConfigMejoras"))

local comprar = Instance.new("RemoteFunction")
comprar.Name = "ComprarMejora"
comprar.Parent = ReplicatedStorage

local function buscarMejora(id)
	for _, mejora in ConfigMejoras.Lista do
		if mejora.id == id then
			return mejora
		end
	end
	return nil
end

-- Aplica los efectos de las mejoras al personaje actual
local function aplicarEfectos(jugador)
	local personaje = jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	local mejoras = jugador:FindFirstChild("Mejoras")
	if not humanoide or not mejoras then
		return
	end

	humanoide.WalkSpeed = ConfigMejoras.VELOCIDAD_BASE
		+ ConfigMejoras.VELOCIDAD_POR_NIVEL * mejoras.Velocidad.Value
	humanoide.UseJumpPower = true
	humanoide.JumpPower = ConfigMejoras.SALTO_BASE
		+ ConfigMejoras.SALTO_POR_NIVEL * mejoras.Salto.Value
end

local function prepararJugador(jugador)
	local mejoras = Instance.new("Folder")
	mejoras.Name = "Mejoras"
	for _, mejora in ConfigMejoras.Lista do
		local nivel = Instance.new("IntValue")
		nivel.Name = mejora.id
		nivel.Value = 0
		nivel.Changed:Connect(function()
			aplicarEfectos(jugador)
		end)
		nivel.Parent = mejoras
	end
	mejoras.Parent = jugador

	jugador.CharacterAdded:Connect(function(personaje)
		personaje:WaitForChild("Humanoid")
		aplicarEfectos(jugador)
	end)
	if jugador.Character then
		aplicarEfectos(jugador)
	end
end

comprar.OnServerInvoke = function(jugador, id)
	local mejora = type(id) == "string" and buscarMejora(id)
	if not mejora then
		return false, "Mejora inválida"
	end

	local mejoras = jugador:FindFirstChild("Mejoras")
	local leaderstats = jugador:FindFirstChild("leaderstats")
	if not mejoras or not leaderstats then
		return false, "Todavía cargando, probá de nuevo"
	end

	local nivel = mejoras[mejora.id]
	local monedas = leaderstats.Monedas

	if nivel.Value >= mejora.nivelMaximo then
		return false, "Ya está al máximo"
	end

	local costo = ConfigMejoras.costo(mejora, nivel.Value)
	if monedas.Value < costo then
		return false, "No te alcanzan las monedas"
	end

	monedas.Value -= costo
	nivel.Value += 1
	return true, mejora.nombre .. " subió a nivel " .. nivel.Value
end

Players.PlayerAdded:Connect(prepararJugador)
for _, jugador in Players:GetPlayers() do
	prepararJugador(jugador)
end
