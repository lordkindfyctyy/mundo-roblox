-- Cartel con el ranking global: los 10 jugadores que mas monedas recolectaron en total.
-- Los puntajes los escribe GuardadoMonedas.server.lua en un OrderedDataStore.
-- Se actualiza solo cada ACTUALIZAR segundos.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local RANKING = DataStoreService:GetOrderedDataStore("MundoRoblox_Ranking_v1")
local PUESTOS = 10
local ACTUALIZAR = 60 -- segundos entre actualizaciones

local ALTURA_CARTEL = 18
local ZONA_Z = 46 -- contra el cerco del fondo, mirando hacia el centro del mapa

local nombres = {} -- UserId -> nombre, para no pedirlo cada vez

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

-- Construye el cartel y devuelve el texto que hay que ir actualizando
local function crearCartel()
	local madera = Color3.fromRGB(120, 85, 55)

	for _, x in { -13, 13 } do
		local poste = Instance.new("Part")
		poste.Name = "PosteRanking"
		poste.Size = Vector3.new(1, 6, 1)
		poste.Position = Vector3.new(x, 3.4, ZONA_Z)
		poste.Color = madera
		poste.Material = Enum.Material.Wood
		poste.Anchored = true
		poste.Parent = Workspace
	end

	local tabla = Instance.new("Part")
	tabla.Name = "CartelRanking"
	tabla.Size = Vector3.new(30, ALTURA_CARTEL, 1)
	tabla.Position = Vector3.new(0, 0.4 + 6 + ALTURA_CARTEL / 2, ZONA_Z)
	tabla.Color = Color3.fromRGB(35, 35, 45)
	tabla.Material = Enum.Material.SmoothPlastic
	tabla.Anchored = true
	tabla.Parent = Workspace

	-- La cara "Front" mira hacia -Z, o sea hacia el centro del mapa
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = tabla

	local titulo = Instance.new("TextLabel")
	titulo.Size = UDim2.new(1, 0, 0, 80)
	titulo.BackgroundTransparency = 1
	titulo.Font = Enum.Font.GothamBold
	titulo.TextSize = 54
	titulo.TextColor3 = Color3.fromRGB(255, 205, 0)
	titulo.Text = "RANKING"
	titulo.Parent = gui

	local cuerpo = Instance.new("TextLabel")
	cuerpo.Position = UDim2.fromOffset(40, 85)
	cuerpo.Size = UDim2.new(1, -80, 1, -100)
	cuerpo.BackgroundTransparency = 1
	cuerpo.Font = Enum.Font.Code
	cuerpo.TextSize = 36
	cuerpo.TextXAlignment = Enum.TextXAlignment.Left
	cuerpo.TextYAlignment = Enum.TextYAlignment.Top
	cuerpo.TextColor3 = Color3.new(1, 1, 1)
	cuerpo.Text = "Cargando..."
	cuerpo.Parent = gui

	return cuerpo
end

local cuerpo = crearCartel()

local function actualizar()
	local ok, resultado = pcall(function()
		return RANKING:GetSortedAsync(false, PUESTOS):GetCurrentPage()
	end)

	if not ok then
		warn("No se pudo leer el ranking:", resultado)
		cuerpo.Text = "Ranking no disponible"
		return
	end

	if #resultado == 0 then
		cuerpo.Text = "Todavia no hay puntajes"
		return
	end

	local lineas = {}
	for puesto, fila in resultado do
		local nombre = nombreDe(tonumber(fila.key))
		table.insert(lineas, string.format("%2d. %-16s %6d", puesto, string.sub(nombre, 1, 16), fila.value))
	end
	cuerpo.Text = table.concat(lineas, "\n")
end

while true do
	actualizar()
	task.wait(ACTUALIZAR)
end
