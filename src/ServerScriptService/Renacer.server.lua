-- Logica de "Renacer": valida el pedido, reinicia monedas y mejoras y suma un renacimiento.
-- El bonus de monedas lo aplica JuegoMonedas.server.lua; el Total del ranking no se toca.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigRenacer = require(ReplicatedStorage:WaitForChild("ConfigRenacer"))

local renacer = Instance.new("RemoteFunction")
renacer.Name = "Renacer"
renacer.Parent = ReplicatedStorage

local enCurso = {} -- evita que dos pedidos seguidos se procesen a la vez

renacer.OnServerInvoke = function(jugador)
	if enCurso[jugador] then
		return false, "Espera un momento"
	end

	local leaderstats = jugador:FindFirstChild("leaderstats")
	local mejoras = jugador:FindFirstChild("Mejoras")
	if not leaderstats or not mejoras then
		return false, "Todavía cargando, probá de nuevo"
	end

	local monedas = leaderstats.Monedas
	local renacimientos = leaderstats.Renacimientos

	local costo = ConfigRenacer.costo(renacimientos.Value)
	if monedas.Value < costo then
		return false, "Necesitás " .. costo .. " monedas para renacer"
	end

	enCurso[jugador] = true

	monedas.Value = 0
	for _, nivel in mejoras:GetChildren() do
		nivel.Value = 0
	end
	renacimientos.Value += 1

	enCurso[jugador] = nil
	return true, "¡Renaciste! Ahora ganás +" .. math.floor((ConfigRenacer.multiplicador(renacimientos.Value) - 1) * 100 + 0.5) .. "% de monedas"
end

Players.PlayerRemoving:Connect(function(jugador)
	enCurso[jugador] = nil
end)
