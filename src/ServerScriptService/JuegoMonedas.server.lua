-- Juego de ejemplo: "Recolector de Monedas"
-- Cada jugador tiene un puntaje (leaderstats) y suma puntos al tocar monedas.
-- Hay monedas doradas (1 punto) y azules, mas raras (5 puntos).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local CANTIDAD_MONEDAS = 20
local TIEMPO_RESPAWN = 5
local AREA = 80 -- las monedas aparecen dentro de un cuadrado de AREA x AREA
local VELOCIDAD_GIRO = math.rad(120) -- grados por segundo
local SONIDO_ID = "" -- opcional: pegá un "rbxassetid://..." para tener sonido al recoger

local TIPOS = {
	{ nombre = "Dorada", valor = 1, color = Color3.fromRGB(255, 205, 0), probabilidad = 0.85 },
	{ nombre = "Azul", valor = 5, color = Color3.fromRGB(0, 170, 255), probabilidad = 0.15 },
}

local carpeta = Instance.new("Folder")
carpeta.Name = "Monedas"
carpeta.Parent = Workspace

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
end

-- Animacion al recoger: la moneda sube y se desvanece
local function animarRecogida(moneda)
	if SONIDO_ID ~= "" then
		local sonido = Instance.new("Sound")
		sonido.SoundId = SONIDO_ID
		sonido.Parent = moneda
		sonido:Play()
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

-- Crea una moneda en una posicion al azar
local function crearMoneda()
	local tipo = elegirTipo()

	local moneda = Instance.new("Part")
	moneda.Name = "Moneda" .. tipo.nombre
	moneda.Shape = Enum.PartType.Cylinder
	moneda.Size = Vector3.new(0.3, 3, 3)
	moneda.Color = tipo.color
	moneda.Material = Enum.Material.Neon
	moneda.Anchored = true
	moneda.CanCollide = false
	moneda:SetAttribute("Angulo", math.random() * math.pi * 2)
	moneda.Position = Vector3.new(
		math.random(-AREA / 2, AREA / 2),
		3,
		math.random(-AREA / 2, AREA / 2)
	)
	moneda.Parent = carpeta

	local recogida = false
	moneda.Touched:Connect(function(otraParte)
		if recogida then
			return
		end

		local jugador = Players:GetPlayerFromCharacter(otraParte.Parent)
		if not jugador then
			return
		end

		recogida = true
		jugador.leaderstats.Monedas.Value += tipo.valor
		animarRecogida(moneda)

		-- Aparece otra moneda despues de unos segundos
		task.delay(TIEMPO_RESPAWN, crearMoneda)
	end)
end

-- Hace girar todas las monedas
RunService.Heartbeat:Connect(function(dt)
	for _, moneda in carpeta:GetChildren() do
		local angulo = moneda:GetAttribute("Angulo")
		if angulo and moneda.Transparency == 0 then
			angulo += VELOCIDAD_GIRO * dt
			moneda:SetAttribute("Angulo", angulo)
			moneda.CFrame = CFrame.new(moneda.Position) * CFrame.Angles(0, angulo, 0)
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
