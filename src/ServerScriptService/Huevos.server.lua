-- El busca huevos: esconde huevos de colores por todo el mapa (ConfigHuevos.lua tiene la lista y las zonas).
-- Cada jugador encuentra los suyos: el huevo se recoge con el boton de siempre ("Recoger"), paga monedas, se
-- anota en el atributo HuevosHallados del jugador (GuardadoMonedas.server.lua lo carga y lo guarda) y
-- Huevos.client.lua lo esconde solo para quien ya lo encontro. Los premios grandes son logros (ConfigLogros.lua).
--
-- El mapa se arma mientras corren los otros scripts, asi que se espera a que existan las zonas. Cada huevo se
-- apoya en el suelo de verdad (un rayo desde arriba) y, si ahi hay un edificio o un arbol, se busca el suelo
-- mas cercano en vez de dejarlo flotando o enterrado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConfigHuevos = require(ReplicatedStorage:WaitForChild("ConfigHuevos"))

-- Donde esconder cada huevo: x, z y entre que alturas tiene que estar el suelo (asi un huevo de la playa no
-- queda en el techo de una casa, ni uno del piso en la copa de un arbol). Por defecto, el suelo de la ciudad.
local SUELO = { -0.5, 1.5 }
local ARENA = { 4.5, 7.5 }
local POSICIONES = {
	{ id = "P1", x = -38, z = -30 },
	{ id = "P2", x = 30, z = 40 },
	{ id = "P3", x = 44, z = -8 },
	{ id = "C1", x = -73, z = -100 },
	{ id = "C2", x = 100, z = -73 },
	{ id = "C3", x = -100, z = 73 },
	{ id = "C4", x = 73, z = 100 },
	{ id = "C5", x = -140, z = -140 },
	{ id = "C6", x = 140, z = 140 },
	{ id = "C7", x = -12, z = 82 }, -- detras del taller de autos
	{ id = "C8", x = -150, z = 140 },
	{ id = "T1", x = 103, z = 103, alturas = { 97, 107 } }, -- en la cima de la Torre, junto al cofre
	{ id = "T2", x = 118, z = 100 }, -- al pie de la Torre
	{ id = "B1", x = 200, z = -80, alturas = ARENA },
	{ id = "B2", x = 240, z = 100, alturas = ARENA },
	{ id = "B3", x = 392, z = 6, alturas = { 4.5, 12 } }, -- en la isla del tesoro
	{ id = "B4", x = 338, z = -45, alturas = { 2, 9 } }, -- al final del muelle
	{ id = "H1", x = -300, z = 5 },
	{ id = "H2", x = -190, z = 66 },
	{ id = "H3", x = -280, z = -70 },
	{ id = "H4", x = -410, z = 0 },
	{ id = "M1", x = -336, z = 8, alturas = { -1, 3.5 } },
	{ id = "M2", x = -380, z = -62, alturas = { -1, 3.5 } },
	{ id = "D1", x = -90, z = -170 },
	{ id = "D2", x = 85, z = -250 },
	{ id = "D3", x = 0, z = -335 },
	{ id = "D4", x = 50, z = -300 },
	{ id = "G1", x = -250, z = -620 },
	{ id = "G2", x = 250, z = -620 },
	{ id = "G3", x = 0, z = -480 },
}

local PREMIO = ConfigHuevos.PREMIO
local COLORES = {
	Color3.fromRGB(255, 120, 170), -- rosa
	Color3.fromRGB(110, 190, 255), -- celeste
	Color3.fromRGB(255, 215, 80), -- amarillo
	Color3.fromRGB(120, 230, 170), -- menta
	Color3.fromRGB(185, 130, 255), -- violeta
	Color3.fromRGB(255, 160, 80), -- naranja
}

local aviso -- RemoteEvent AvisoTienda de Negocios.lua (cartelito de abajo)
local function avisar(jugador, texto, ok)
	aviso = aviso or ReplicatedStorage:FindFirstChild("AvisoTienda")
	if aviso then
		aviso:FireClient(jugador, texto, ok)
	end
end

local carpeta = Instance.new("Folder")
carpeta.Name = "Huevos"
carpeta.Parent = Workspace

-- El suelo debajo de (x, z), en el rango de alturas pedido; si ahi no sirve se prueba alrededor, cada vez mas lejos
local paramsRayo = RaycastParams.new()
paramsRayo.FilterType = Enum.RaycastFilterType.Exclude
paramsRayo.FilterDescendantsInstances = { carpeta }

local paramsHueco = OverlapParams.new()
paramsHueco.FilterType = Enum.RaycastFilterType.Exclude
paramsHueco.FilterDescendantsInstances = { carpeta }

local function buscarSuelo(x, z, alturas)
	local minimo, maximo = alturas[1], alturas[2]
	for _, radio in { 0, 3, 6, 10, 15, 22 } do
		local pasos = radio == 0 and 1 or 8
		for i = 1, pasos do
			local angulo = (i / pasos) * math.pi * 2
			local px, pz = x + math.cos(angulo) * radio, z + math.sin(angulo) * radio
			local rayo = Workspace:Raycast(Vector3.new(px, 500, pz), Vector3.new(0, -1000, 0), paramsRayo)
			if rayo and rayo.Normal.Y > 0.7 and rayo.Position.Y >= minimo and rayo.Position.Y <= maximo then
				-- que no quede metido adentro de algo macizo (una pared, un banco, el tronco de un arbol)
				local libre = true
				for _, parte in Workspace:GetPartBoundsInRadius(rayo.Position + Vector3.new(0, 1.6, 0), 1.2, paramsHueco) do
					if parte ~= rayo.Instance and parte.CanCollide and parte.Transparency < 1 then
						libre = false
						break
					end
				end
				if libre then
					return rayo.Position
				end
			end
		end
	end
	return nil
end

-- Un huevo: cuerpo ovalado de color con lunares, un brillo suave y chispas para que se vea de lejos
local function crearHuevo(id, posicion, indice)
	local color = COLORES[(indice - 1) % #COLORES + 1]
	local modelo = Instance.new("Model")
	modelo.Name = "Huevo"
	modelo:SetAttribute("Id", id)

	local function parte(nombre, tamano, cframe, colorParte, material)
		local p = Instance.new("Part")
		p.Name = nombre
		p.Size = tamano
		p.CFrame = cframe
		p.Color = colorParte
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = true
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		local malla = Instance.new("SpecialMesh")
		malla.MeshType = Enum.MeshType.Sphere
		malla.Parent = p
		p.Parent = modelo
		return p
	end

	local centro = CFrame.new(posicion + Vector3.new(0, 1.6, 0))
	local cuerpo = parte("Cuerpo", Vector3.new(2, 2.8, 2), centro, color)

	-- lunares: sobre la superficie del ovalo, a dos alturas
	local blanco = Color3.fromRGB(255, 255, 255)
	for fila, y in { 0.7, -0.5 } do
		for k = 1, 4 do
			local angulo = (k / 4) * math.pi * 2 + fila * 0.8
			local radio = math.sqrt(math.max(0, 1 - (y / 1.4) ^ 2)) + 0.02
			parte("Lunar", Vector3.one * 0.5, centro * CFrame.new(math.cos(angulo) * radio, y, math.sin(angulo) * radio), blanco)
		end
	end
	modelo.PrimaryPart = cuerpo

	local luz = Instance.new("PointLight")
	luz.Color = color
	luz.Brightness = 1.2
	luz.Range = 11
	luz.Parent = cuerpo

	local chispas = Instance.new("ParticleEmitter")
	chispas.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	chispas.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	chispas.LightEmission = 0.8
	chispas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	chispas.Lifetime = NumberRange.new(0.8, 1.4)
	chispas.Speed = NumberRange.new(1, 3)
	chispas.SpreadAngle = Vector2.new(180, 180)
	chispas.Rate = 4
	chispas.Parent = cuerpo

	local boton = Instance.new("ProximityPrompt")
	boton.ActionText = "Recoger"
	boton.ObjectText = "Huevo escondido"
	boton.HoldDuration = 0.25
	boton.MaxActivationDistance = 9
	boton.RequiresLineOfSight = false
	boton.Parent = cuerpo

	modelo:SetAttribute("Base", modelo:GetPivot()) -- de aca parte el giro y el vaiven que hace el cliente
	modelo.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	modelo.Parent = carpeta

	boton.Triggered:Connect(function(jugador)
		if not jugador:GetAttribute("DatosCargados") then
			return
		end
		local lista = ConfigHuevos.hallados(jugador:GetAttribute("HuevosHallados"))
		if lista[id] then
			return -- ya lo tenia
		end
		lista[id] = true
		jugador:SetAttribute("HuevosHallados", ConfigHuevos.texto(lista))
		local leaderstats = jugador:FindFirstChild("leaderstats")
		if leaderstats then
			leaderstats.Monedas.Value += PREMIO -- el premio no suma al Total del ranking
		end
		local cuenta = ConfigHuevos.cantidad(jugador)
		local total = ConfigHuevos.total()
		if cuenta >= total then
			avisar(jugador, string.format("🥚 ¡Los encontraste TODOS! (%d/%d) +%d monedas", cuenta, total, PREMIO), true)
		else
			avisar(jugador, string.format("🥚 ¡Huevo escondido! (%d/%d) +%d monedas", cuenta, total, PREMIO), true)
		end
	end)
end

-- Espera a que se arme el mapa (cada zona la construye su propio script)
local function esperarMapa()
	local zonas = { "Ciudad", "Playa", "Muelle", "Barrio", "Mansiones", "Diversiones", "Golf" }
	local limite = os.clock() + 90
	while os.clock() < limite do
		local listo = Workspace:GetAttribute("CiudadLista") == true
		for _, nombre in zonas do
			listo = listo and Workspace:FindFirstChild(nombre) ~= nil
		end
		if listo then
			break
		end
		task.wait(1)
	end
	task.wait(3) -- un poco mas: las zonas se siguen terminando de armar un instante despues de aparecer
end

task.spawn(function()
	esperarMapa()
	local colocados = 0
	for indice, cfg in POSICIONES do
		local suelo = buscarSuelo(cfg.x, cfg.z, cfg.alturas or SUELO)
		if suelo then
			crearHuevo(cfg.id, suelo, indice)
			colocados += 1
		else
			warn("Huevos: no se encontro suelo para el huevo", cfg.id, "cerca de", cfg.x, cfg.z)
		end
	end
	Workspace:SetAttribute("HuevosListos", colocados)
	if colocados ~= ConfigHuevos.total() then
		warn(string.format("Huevos: se escondieron %d de %d", colocados, ConfigHuevos.total()))
	end
end)

-- Si falta alguno en POSICIONES, avisa al arrancar (un huevo en la config sin lugar no se puede encontrar nunca)
do
	local conPosicion = {}
	for _, cfg in POSICIONES do
		conPosicion[cfg.id] = true
	end
	for _, huevo in ConfigHuevos.Huevos do
		if not conPosicion[huevo.id] then
			warn("Huevos: el huevo", huevo.id, "esta en ConfigHuevos pero no tiene posicion")
		end
	end
end

-- Los jugadores nuevos empiezan sin huevos hasta que GuardadoMonedas cargue los suyos
Players.PlayerAdded:Connect(function(jugador)
	if jugador:GetAttribute("HuevosHallados") == nil then
		jugador:SetAttribute("HuevosHallados", "")
	end
end)
for _, jugador in Players:GetPlayers() do
	if jugador:GetAttribute("HuevosHallados") == nil then
		jugador:SetAttribute("HuevosHallados", "")
	end
end
