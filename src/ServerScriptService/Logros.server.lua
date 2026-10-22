-- Detecta cuando un jugador cumple un logro, le paga el premio y le avisa.
-- Los logros ya desbloqueados viven como BoolValue dentro de la carpeta "Logros" del jugador;
-- GuardadoMonedas.server.lua los carga y los guarda.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigLogros = require(ReplicatedStorage:WaitForChild("ConfigLogros"))

local REVISAR_CADA = 2 -- segundos

local aviso = Instance.new("RemoteEvent")
aviso.Name = "LogroDesbloqueado"
aviso.Parent = ReplicatedStorage

local function prepararJugador(jugador)
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Logros"
	carpeta.Parent = jugador
end

local function revisar(jugador)
	local carpeta = jugador:FindFirstChild("Logros")
	local leaderstats = jugador:FindFirstChild("leaderstats")
	-- Esperamos a que los datos hayan cargado para no dar premios dos veces
	if not carpeta or not leaderstats or not jugador:GetAttribute("DatosCargados") then
		return
	end

	for _, logro in ConfigLogros.Lista do
		if not carpeta:FindFirstChild(logro.id) and logro.valor(jugador) >= logro.meta then
			local desbloqueado = Instance.new("BoolValue")
			desbloqueado.Name = logro.id
			desbloqueado.Value = true
			desbloqueado.Parent = carpeta

			leaderstats.Monedas.Value += logro.premio
			aviso:FireClient(jugador, logro.nombre, logro.premio)
		end
	end
end

Players.PlayerAdded:Connect(prepararJugador)
for _, jugador in Players:GetPlayers() do
	prepararJugador(jugador)
end

while true do
	task.wait(REVISAR_CADA)
	for _, jugador in Players:GetPlayers() do
		revisar(jugador)
	end
end
