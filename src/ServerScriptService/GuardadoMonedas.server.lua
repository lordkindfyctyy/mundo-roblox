-- Guarda y carga las monedas de cada jugador con DataStore.
-- Necesita que el juego este publicado y, para probar en Studio,
-- activar Game Settings > Security > "Enable Studio Access to API Services".

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local ALMACEN = DataStoreService:GetDataStore("MundoRoblox_Monedas_v1")
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
	local monedas = jugador:WaitForChild("leaderstats"):WaitForChild("Monedas")

	local ok, guardado = conReintentos(function()
		return ALMACEN:GetAsync(tostring(jugador.UserId))
	end)

	if not ok or not jugador.Parent then
		return
	end

	monedas.Value = guardado or 0
	cargados[jugador] = true
end

local function guardar(jugador)
	if not cargados[jugador] then
		return
	end

	local leaderstats = jugador:FindFirstChild("leaderstats")
	local monedas = leaderstats and leaderstats:FindFirstChild("Monedas")
	if not monedas then
		return
	end

	local valor = monedas.Value
	conReintentos(function()
		ALMACEN:SetAsync(tostring(jugador.UserId), valor)
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
