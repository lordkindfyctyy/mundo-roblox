-- Juego de ejemplo: "Recolector de Monedas"
-- Pegá este script en ServerScriptService dentro de Roblox Studio.
-- Cada jugador tiene un puntaje (leaderstats) y suma puntos al tocar monedas.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CANTIDAD_MONEDAS = 20
local VALOR_MONEDA = 1
local TIEMPO_RESPAWN = 5
local AREA = 80 -- las monedas aparecen dentro de un cuadrado de AREA x AREA

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

-- Crea una moneda en una posicion al azar
local function crearMoneda()
	local moneda = Instance.new("Part")
	moneda.Name = "Moneda"
	moneda.Shape = Enum.PartType.Cylinder
	moneda.Size = Vector3.new(0.3, 3, 3)
	moneda.Color = Color3.fromRGB(255, 205, 0)
	moneda.Material = Enum.Material.Neon
	moneda.Anchored = true
	moneda.CanCollide = false
	moneda.Orientation = Vector3.new(0, 0, 90) -- de pie, como una moneda
	moneda.Position = Vector3.new(
		math.random(-AREA / 2, AREA / 2),
		3,
		math.random(-AREA / 2, AREA / 2)
	)
	moneda.Parent = Workspace

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
		jugador.leaderstats.Monedas.Value += VALOR_MONEDA
		moneda:Destroy()

		-- Aparece otra moneda despues de unos segundos
		task.delay(TIEMPO_RESPAWN, crearMoneda)
	end)
end

Players.PlayerAdded:Connect(crearLeaderstats)

for _ = 1, CANTIDAD_MONEDAS do
	crearMoneda()
end
