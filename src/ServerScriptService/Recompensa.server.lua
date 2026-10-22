-- Recompensa diaria: una vez por dia, con racha de dias seguidos.
-- Guarda dos atributos en el jugador (UltimoDia y Racha); GuardadoMonedas.server.lua
-- los carga y los guarda, y marca DatosCargados cuando ya estan listos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigRecompensa = require(ReplicatedStorage:WaitForChild("ConfigRecompensa"))

local reclamar = Instance.new("RemoteFunction")
reclamar.Name = "ReclamarRecompensa"
reclamar.Parent = ReplicatedStorage

reclamar.OnServerInvoke = function(jugador)
	-- Si los datos no cargaron bien no pagamos, para no pisar el progreso real
	if not jugador:GetAttribute("DatosCargados") then
		return false, "Todavía cargando, probá de nuevo"
	end

	local leaderstats = jugador:FindFirstChild("leaderstats")
	if not leaderstats then
		return false, "Todavía cargando, probá de nuevo"
	end

	local hoy = ConfigRecompensa.dia(os.time())
	local ultimoDia = jugador:GetAttribute("UltimoDia") or 0
	if ultimoDia == hoy then
		return false, "Ya reclamaste el regalo de hoy"
	end

	-- Si reclamo ayer la racha sigue; si falto algun dia, vuelve a empezar
	local racha = 1
	if ultimoDia == hoy - 1 then
		racha = (jugador:GetAttribute("Racha") or 0) + 1
	end

	local premio = ConfigRecompensa.premio(racha)
	jugador:SetAttribute("UltimoDia", hoy)
	jugador:SetAttribute("Racha", racha)
	leaderstats.Monedas.Value += premio -- el premio no suma al Total del ranking

	return true, string.format("¡+%d monedas! Racha: %d día(s)", premio, racha), premio
end
