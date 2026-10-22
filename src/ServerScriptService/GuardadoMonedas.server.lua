-- Guarda y carga las monedas de cada jugador con DataStore.
-- Necesita que el juego este publicado y, para probar en Studio,
-- activar Game Settings > Security > "Enable Studio Access to API Services".

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local ALMACEN = DataStoreService:GetDataStore("MundoRoblox_Monedas_v1")
local RANKING = DataStoreService:GetOrderedDataStore("MundoRoblox_Ranking_v1") -- lo lee Ranking.server.lua
local INTENTOS = 3
local AUTOGUARDADO = 60 -- segundos

-- Jugadores cuyos datos se cargaron bien. Si la carga fallo, no guardamos
-- para no pisar el progreso real con un 0.
local cargados = {}

local function conReintentos(funcion)
	local ok, resultado
	for intento = 1, INTENTOS do
		ok, resultado = pcall(funcion)
		if ok then
			return true, resultado
		end
		task.wait(intento) -- espera cada vez mas antes de reintentar
	end
	warn("DataStore fallo:", resultado)
	return false, resultado
end

local function cargar(jugador)
	local leaderstats = jugador:WaitForChild("leaderstats")
	local monedas = leaderstats:WaitForChild("Monedas")
	local total = leaderstats:WaitForChild("Total")
	local renacimientos = leaderstats:WaitForChild("Renacimientos")
	local mejoras = jugador:WaitForChild("Mejoras")

	local ok, guardado = conReintentos(function()
		return ALMACEN:GetAsync(tostring(jugador.UserId))
	end)

	if not ok or not jugador.Parent then
		return
	end

	-- Los datos viejos eran solo un numero (las monedas); los nuevos son una tabla
	if type(guardado) == "number" then
		guardado = { Monedas = guardado }
	end
	guardado = guardado or {}

	monedas.Value = guardado.Monedas or 0
	-- Quien jugaba antes del ranking no tiene Total: arranca con las monedas que ya tenia
	total.Value = guardado.Total or monedas.Value
	renacimientos.Value = guardado.Renacimientos or 0
	jugador:SetAttribute("UltimoDia", guardado.UltimoDia or 0)
	jugador:SetAttribute("Racha", guardado.Racha or 0)
	for _, nivel in mejoras:GetChildren() do
		nivel.Value = (guardado.Mejoras and guardado.Mejoras[nivel.Name]) or 0
	end
	cargados[jugador] = true
	jugador:SetAttribute("DatosCargados", true) -- Recompensa.server.lua y el cliente esperan esto
end

local function guardar(jugador)
	if not cargados[jugador] then
		return
	end

	local leaderstats = jugador:FindFirstChild("leaderstats")
	local monedas = leaderstats and leaderstats:FindFirstChild("Monedas")
	local mejoras = jugador:FindFirstChild("Mejoras")
	if not monedas or not mejoras then
		return
	end

	local datos = {
		Monedas = monedas.Value,
		Total = leaderstats.Total.Value,
		Renacimientos = leaderstats.Renacimientos.Value,
		UltimoDia = jugador:GetAttribute("UltimoDia") or 0,
		Racha = jugador:GetAttribute("Racha") or 0,
		Mejoras = {},
	}
	for _, nivel in mejoras:GetChildren() do
		datos.Mejoras[nivel.Name] = nivel.Value
	end

	conReintentos(function()
		ALMACEN:SetAsync(tostring(jugador.UserId), datos)
	end)
	conReintentos(function()
		RANKING:SetAsync(tostring(jugador.UserId), datos.Total)
	end)
end

Players.PlayerAdded:Connect(cargar)
for _, jugador in Players:GetPlayers() do
	task.spawn(cargar, jugador)
end

Players.PlayerRemoving:Connect(function(jugador)
	guardar(jugador)
	cargados[jugador] = nil
end)

-- Al cerrar el servidor guardamos a todos los que quedan
game:BindToClose(function()
	if RunService:IsStudio() then
		task.wait(1)
	end
	for _, jugador in Players:GetPlayers() do
		task.spawn(guardar, jugador)
	end
	task.wait(3)
end)

-- Autoguardado periodico
task.spawn(function()
	while true do
		task.wait(AUTOGUARDADO)
		for _, jugador in Players:GetPlayers() do
			task.spawn(guardar, jugador)
		end
	end
end)
