-- Ranking de golf: un cartel junto a la caseta con los 10 mejores recorridos (menos golpes
-- en todos los hoyos). Los puntajes viven en un OrderedDataStore; se anotan cuando cambia el
-- atributo GolfMejor del jugador (lo sube Golf.server.lua y lo guarda GuardadoMonedas.server.lua).
-- En Studio necesita "Enable Studio Access to API Services"; si no, muestra "no disponible".

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))
local ConfigGolf = require(ReplicatedStorage:WaitForChild("ConfigGolf"))

-- v2: la cancha pasó de 3 a 6 hoyos, así que los puntajes de antes no se pueden comparar
local RANKING = DataStoreService:GetOrderedDataStore("MundoRoblox_Golf_v2")
local PUESTOS = 10
local ACTUALIZAR = 60 -- segundos entre actualizaciones
local PAR_TOTAL = ConfigGolf.parTotal()

-- Al costado de la caseta, mirando hacia la entrada; fuera de las calles de los hoyos
local X_CARTEL = 24
local Z_CARTEL = Plano.GOLF.Z_CERCA - 10 -- junto a la caseta (que esta 12 detras de la puerta)
local ALTO_CARTEL = 9
local ANCHO_CARTEL = 16

local nombres = {} -- UserId -> nombre

local function nombreDe(userId)
	if nombres[userId] then
		return nombres[userId]
	end
	local ok, nombre = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nombres[userId] = ok and nombre or ("Jugador " .. userId)
	return nombres[userId]
end

local function crearCartel()
	local carpeta = Instance.new("Folder")
	carpeta.Name = "RankingGolf"
	carpeta.Parent = Workspace

	local suelo = Plano.GOLF.SUELO
	local madera = Color3.fromRGB(120, 85, 55)

	for _, dx in { -ANCHO_CARTEL / 2 + 1, ANCHO_CARTEL / 2 - 1 } do
		local poste = Instance.new("Part")
		poste.Name = "Poste"
		poste.Size = Vector3.new(0.8, 4 + 3, 0.8)
		poste.Position = Vector3.new(X_CARTEL + dx, suelo + 3.5, Z_CARTEL)
		poste.Color = madera
		poste.Material = Enum.Material.Wood
		poste.Anchored = true
		poste.Parent = carpeta
	end

	local tabla = Instance.new("Part")
	tabla.Name = "Cartel"
	tabla.Size = Vector3.new(ANCHO_CARTEL, ALTO_CARTEL, 0.6)
	tabla.CFrame = CFrame.new(X_CARTEL, suelo + 4 + ALTO_CARTEL / 2, Z_CARTEL) * CFrame.Angles(0, math.rad(180), 0) -- la cara frontal mira a +Z
	tabla.Color = Color3.fromRGB(25, 60, 40)
	tabla.Material = Enum.Material.SmoothPlastic
	tabla.Anchored = true
	tabla.Parent = carpeta

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = tabla

	local titulo = Instance.new("TextLabel")
	titulo.Size = UDim2.new(1, 0, 0, 70)
	titulo.BackgroundTransparency = 1
	titulo.Font = Enum.Font.GothamBold
	titulo.TextSize = 44
	titulo.TextColor3 = Color3.fromRGB(255, 205, 0)
	titulo.Text = string.format("⛳ MEJORES RECORRIDOS (par %d)", PAR_TOTAL)
	titulo.Parent = gui

	local cuerpo = Instance.new("TextLabel")
	cuerpo.Position = UDim2.fromOffset(30, 76)
	cuerpo.Size = UDim2.new(1, -60, 1, -90)
	cuerpo.BackgroundTransparency = 1
	cuerpo.Font = Enum.Font.Code
	cuerpo.TextSize = 28
	cuerpo.TextXAlignment = Enum.TextXAlignment.Left
	cuerpo.TextYAlignment = Enum.TextYAlignment.Top
	cuerpo.TextColor3 = Color3.new(1, 1, 1)
	cuerpo.Text = "Cargando..."
	cuerpo.Parent = gui

	return cuerpo
end

local cuerpo = crearCartel()

-- "+2", "-1" o "par" respecto del par del recorrido
local function contraElPar(golpes)
	local diferencia = golpes - PAR_TOTAL
	if diferencia == 0 then
		return "par"
	end
	return string.format("%+d", diferencia)
end

local function actualizar()
	local ok, resultado = pcall(function()
		return RANKING:GetSortedAsync(true, PUESTOS):GetCurrentPage() -- de menos a mas golpes
	end)

	if not ok then
		warn("No se pudo leer el ranking de golf:", resultado)
		cuerpo.Text = "Ranking no disponible"
		return
	end
	if #resultado == 0 then
		cuerpo.Text = "Todavía nadie terminó un recorrido"
		return
	end

	local lineas = {}
	for puesto, fila in resultado do
		local nombre = nombreDe(tonumber(fila.key))
		table.insert(lineas, string.format("%2d. %-16s %3d golpes (%s)", puesto, string.sub(nombre, 1, 16), fila.value, contraElPar(fila.value)))
	end
	cuerpo.Text = table.concat(lineas, "\n")
end

-- Anota el mejor recorrido del jugador, solo si mejora el que ya estaba guardado
local function anotar(jugador)
	local mejor = jugador:GetAttribute("GolfMejor") or 0
	if mejor <= 0 then
		return
	end
	local ok, falla = pcall(function()
		RANKING:UpdateAsync(tostring(jugador.UserId), function(anterior)
			if anterior and anterior <= mejor then
				return nil -- ya tenia uno igual o mejor
			end
			return mejor
		end)
	end)
	if not ok then
		warn("No se pudo anotar en el ranking de golf:", falla)
	end
end

local function vigilar(jugador)
	local function cuandoCambia()
		-- GuardadoMonedas.server.lua pone GolfMejor al cargar; recien con DatosCargados es un puntaje de verdad
		if jugador:GetAttribute("DatosCargados") then
			task.spawn(anotar, jugador)
		end
	end
	jugador:GetAttributeChangedSignal("GolfMejor"):Connect(cuandoCambia)
	-- Al cargar los datos anotamos el que ya tenia de antes, para que figure aunque no vuelva a jugar
	jugador:GetAttributeChangedSignal("DatosCargados"):Connect(cuandoCambia)
	cuandoCambia()
end

Players.PlayerAdded:Connect(vigilar)
for _, jugador in Players:GetPlayers() do
	vigilar(jugador)
end

while true do
	actualizar()
	task.wait(ACTUALIZAR)
end
