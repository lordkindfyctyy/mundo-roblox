-- Juego de ejemplo: "Recolector de Monedas"
-- Cada jugador tiene un puntaje (leaderstats) y suma puntos al tocar monedas.
-- Hay monedas doradas (1 punto), azules (5) y una gigante muy rara (25).
-- Con la mejora "Iman" las monedas cercanas viajan hacia el jugador.
-- Eventos.server.lua puede pedir monedas extra (lluvia) y duplicar los puntos (hora dorada).

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ConfigMejoras = require(ReplicatedStorage:WaitForChild("ConfigMejoras"))

local CANTIDAD_MONEDAS = 20
local TIEMPO_RESPAWN = 5
local AREA = 80 -- las monedas aparecen dentro de un cuadrado de AREA x AREA
local VELOCIDAD_GIRO = math.rad(120) -- grados por segundo
local DISTANCIA_RECOGER = 3 -- una moneda atraida por el iman se recoge a esta distancia
local VOLUMEN_SONIDO = 0.6
local DURACION_TEMPORAL = 25 -- las monedas de la lluvia desaparecen solas si nadie las agarra

-- sonido: ID de un efecto publico de Roblox. Si no suena, probá con otro ID del Toolbox.
local TIPOS = {
	{
		nombre = "Dorada",
		valor = 1,
		color = Color3.fromRGB(255, 205, 0),
		probabilidad = 0.82,
		sonido = "rbxassetid://4612374807",
	},
	{
		nombre = "Azul",
		valor = 5,
		color = Color3.fromRGB(0, 170, 255),
		probabilidad = 0.15,
		sonido = "rbxassetid://4612375051",
	},
	{
		nombre = "Gigante",
		valor = 25,
		color = Color3.fromRGB(190, 60, 255),
		probabilidad = 0.03,
		sonido = "rbxassetid://4612374937",
		tamano = 6,
	},
}

local carpeta = Instance.new("Folder")
carpeta.Name = "Monedas"
carpeta.Parent = Workspace

local crearMoneda -- se define mas abajo; recoger() la necesita para el respawn

local function elegirTipo()
	local azar = math.random()
	local acumulado = 0
	for _, tipo in TIPOS do
		acumulado += tipo.probabilidad
		if azar <= acumulado then
			return tipo
		end
	end
	return TIPOS[1]
end

-- Crea el puntaje de cada jugador cuando entra
local function crearLeaderstats(jugador)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = jugador

	local monedas = Instance.new("IntValue")
	monedas.Name = "Monedas"
	monedas.Value = 0
	monedas.Parent = leaderstats

	-- Total recolectado de toda la vida: no baja al gastar en la tienda. Lo usa el ranking.
	local total = Instance.new("IntValue")
	total.Name = "Total"
	total.Value = 0
	total.Parent = leaderstats
end

-- Animacion al recoger: la moneda sube y se desvanece
local function animarRecogida(moneda, jugador)
	-- El sonido va en el jugador, no en la moneda: la moneda se destruye enseguida y cortaria el sonido
	local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
	if raiz then
		local sonido = Instance.new("Sound")
		sonido.SoundId = moneda:GetAttribute("Sonido")
		sonido.Volume = VOLUMEN_SONIDO
		sonido.Parent = raiz
		sonido:Play()
		Debris:AddItem(sonido, 3)
	end

	local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(moneda, info, {
		Transparency = 1,
		Position = moneda.Position + Vector3.new(0, 4, 0),
	})
	tween:Play()
	tween.Completed:Connect(function()
		moneda:Destroy()
	end)
end

-- Un jugador recoge una moneda (por tocarla o por el iman)
local function recoger(moneda, jugador)
	if moneda:GetAttribute("Recogida") then
		return
	end
	moneda:SetAttribute("Recogida", true)

	-- Cada nivel de "Monedas extra" suma 1 punto por moneda
	local mejoras = jugador:FindFirstChild("Mejoras")
	local extra = mejoras and mejoras.Multiplicador.Value or 0
	-- Durante la "Hora dorada" Eventos.server.lua pone un multiplicador en Workspace
	local evento = Workspace:GetAttribute("MultiplicadorEvento") or 1
	local ganado = (moneda:GetAttribute("Valor") + extra) * evento

	-- "Suerte": cada nivel da una chance de que la moneda valga el doble
	local nivelSuerte = mejoras and mejoras.Suerte.Value or 0
	if math.random() < nivelSuerte * ConfigMejoras.SUERTE_POR_NIVEL then
		ganado *= 2
	end
	jugador.leaderstats.Monedas.Value += ganado
	jugador.leaderstats.Total.Value += ganado
	animarRecogida(moneda, jugador)

	-- Aparece otra moneda despues de unos segundos (las de la lluvia no se reponen)
	if not moneda:GetAttribute("Temporal") then
		task.delay(TIEMPO_RESPAWN, crearMoneda)
	end
end

-- Crea una moneda en una posicion al azar.
-- Si es temporal (lluvia), cae desde el cielo, no se repone y desaparece sola.
crearMoneda = function(temporal)
	local tipo = elegirTipo()
	local tamano = tipo.tamano or 3

	local moneda = Instance.new("Part")
	moneda.Name = "Moneda" .. tipo.nombre
	moneda.Shape = Enum.PartType.Cylinder
	moneda.Size = Vector3.new(0.3, tamano, tamano)
	moneda.Color = tipo.color
	moneda.Material = Enum.Material.Neon
	moneda.Anchored = true
	moneda.CanCollide = false
	moneda:SetAttribute("Valor", tipo.valor)
	moneda:SetAttribute("Sonido", tipo.sonido)
	moneda:SetAttribute("Recogida", false)
	moneda:SetAttribute("Temporal", temporal == true)
	moneda:SetAttribute("Angulo", math.random() * math.pi * 2)

	local destino = Vector3.new(
		math.random(-AREA / 2, AREA / 2),
		1.5 + tamano / 2, -- la moneda queda apoyada a la misma altura sin importar el tamano
		math.random(-AREA / 2, AREA / 2)
	)
	moneda.Position = temporal and destino + Vector3.new(0, 50, 0) or destino
	moneda.Parent = carpeta

	if temporal then
		local info = TweenInfo.new(1.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		TweenService:Create(moneda, info, { Position = destino }):Play()

		task.delay(DURACION_TEMPORAL, function()
			if moneda.Parent and not moneda:GetAttribute("Recogida") then
				moneda:Destroy()
			end
		end)
	end

	moneda.Touched:Connect(function(otraParte)
		local jugador = Players:GetPlayerFromCharacter(otraParte.Parent)
		if jugador then
			recoger(moneda, jugador)
		end
	end)
end

-- Devuelve el jugador con iman que tiene la moneda dentro de su radio, y su posicion
local function buscarImanCercano(posicion)
	for _, jugador in Players:GetPlayers() do
		local mejoras = jugador:FindFirstChild("Mejoras")
		local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
		if mejoras and raiz then
			local radio = mejoras.Iman.Value * ConfigMejoras.IMAN_RADIO_POR_NIVEL
			if radio > 0 and (raiz.Position - posicion).Magnitude <= radio then
				return jugador, raiz.Position
			end
		end
	end
	return nil
end

-- Hace girar todas las monedas y mueve hacia el jugador las que estan en rango del iman
RunService.Heartbeat:Connect(function(dt)
	for _, moneda in carpeta:GetChildren() do
		local angulo = moneda:GetAttribute("Angulo")
		if angulo and not moneda:GetAttribute("Recogida") then
			angulo += VELOCIDAD_GIRO * dt
			moneda:SetAttribute("Angulo", angulo)

			local posicion = moneda.Position
			local jugador, objetivo = buscarImanCercano(posicion)
			if jugador then
				local distancia = (objetivo - posicion).Magnitude
				if distancia <= DISTANCIA_RECOGER then
					recoger(moneda, jugador)
				else
					posicion += (objetivo - posicion).Unit * math.min(ConfigMejoras.IMAN_VELOCIDAD * dt, distancia)
				end
			end

			if not moneda:GetAttribute("Recogida") then
				moneda.CFrame = CFrame.new(posicion) * CFrame.Angles(0, angulo, 0)
			end
		end
	end
end)

Players.PlayerAdded:Connect(crearLeaderstats)
for _, jugador in Players:GetPlayers() do
	crearLeaderstats(jugador)
end

for _ = 1, CANTIDAD_MONEDAS do
	crearMoneda()
end

-- Eventos.server.lua dispara esto para pedir una lluvia de monedas extra
local pedirLluvia = Instance.new("BindableEvent")
pedirLluvia.Name = "CrearMonedasExtra"
pedirLluvia.Parent = ServerStorage

pedirLluvia.Event:Connect(function(cantidad)
	for _ = 1, cantidad do
		crearMoneda(true)
		task.wait(0.1) -- caen una atras de otra
	end
end)
