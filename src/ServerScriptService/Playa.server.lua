-- La Playa: una zona al este de la ciudad, con entrada libre al final de la avenida.
-- Arena con palmeras y sombrillas, mar de verdad (agua de Terrain, se puede nadar),
-- monedas que valen el triple (JuegoMonedas) y una isla del tesoro a la que se
-- llega saltando por plataformas flotantes, con un cofre de premio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))

local PREMIO_ISLA = 500
local ESPERA_COFRE = 10 * 60
local SEMILLA = 99

local P = Plano.PLAYA
local LIMITE = Plano.LIMITE
local ARENA = P.ALTO -- altura de la arena
local NIVEL_AGUA = P.NIVEL_AGUA -- el agua va del piso (0) hasta aca
local ISLA = Vector3.new(390, 0, 0)

local azar = Random.new(SEMILLA)

local playa = Instance.new("Folder")
playa.Name = "Playa"
playa.Parent = Workspace

local function parte(nombre, tamano, cframe, color, material, forma, colisiona)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = forma or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = colisiona ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = playa
	return p
end

local function cartel(cframe, ancho, alto, texto, color)
	local tabla = parte("Cartel", Vector3.new(ancho, alto, 0.4), cframe, color, Enum.Material.Wood)
	for _, cara in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = cara
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.Parent = tabla
		local etiqueta = Instance.new("TextLabel")
		etiqueta.Size = UDim2.fromScale(1, 1)
		etiqueta.BackgroundTransparency = 1
		etiqueta.Font = Enum.Font.GothamBlack
		etiqueta.TextScaled = true
		etiqueta.TextColor3 = Color3.new(1, 1, 1)
		etiqueta.Text = texto
		etiqueta.Parent = gui
	end
	return tabla
end

local aviso -- RemoteEvent AvisoTienda (cartelito abajo, de Negocios.lua)
local function avisar(jugador, texto, ok)
	aviso = aviso or ReplicatedStorage:FindFirstChild("AvisoTienda")
	if aviso then
		aviso:FireClient(jugador, texto, ok)
	end
end

-- Arena y mar ---------------------------------------------------------------

local largoZ = P.Z * 2
parte("Arena", Vector3.new(P.ARENA_X2 - P.ARENA_X1, ARENA, largoZ), CFrame.new((P.ARENA_X1 + P.ARENA_X2) / 2, ARENA / 2, 0), Color3.fromRGB(240, 220, 160), Enum.Material.Sand)
-- Escalones bajos desde la entrada hasta la arena (se suben caminando)
local escalones = 8
local largoEscalon = (P.ARENA_X1 - P.ESCALONES_X1) / escalones
for i = 1, escalones do
	local alto = ARENA * i / escalones
	local x = P.ESCALONES_X1 + largoEscalon * (i - 0.5)
	parte("Escalon", Vector3.new(largoEscalon, alto, P.PUERTA * 2 + 8), CFrame.new(x, alto / 2, 0), Color3.fromRGB(240, 220, 160), Enum.Material.Sand)
end
-- Fondo del mar (arena mas oscura) y el agua de Terrain encima, del piso hasta NIVEL_AGUA
parte("FondoMar", Vector3.new(P.MAR_X2 - P.ARENA_X2, 1, largoZ), CFrame.new((P.ARENA_X2 + P.MAR_X2) / 2, -0.5, 0), Color3.fromRGB(200, 180, 120), Enum.Material.Sand)
Workspace.Terrain:FillBlock(
	CFrame.new((P.ARENA_X2 + P.MAR_X2) / 2, NIVEL_AGUA / 2, 0),
	Vector3.new(P.MAR_X2 - P.ARENA_X2, NIVEL_AGUA, largoZ),
	Enum.Material.Water
)

-- Paredes invisibles alrededor (la de la ciudad tiene la entrada)
local function pared(x, z, ancho, fondo)
	local p = parte("Limite", Vector3.new(ancho, 80, fondo), CFrame.new(x, 30, z), Color3.new(1, 1, 1))
	p.Transparency = 1
end
pared((LIMITE + P.MAR_X2) / 2, -P.Z - 1, P.MAR_X2 - LIMITE, 2)
pared((LIMITE + P.MAR_X2) / 2, P.Z + 1, P.MAR_X2 - LIMITE, 2)
pared(P.MAR_X2 + 1, 0, 2, largoZ + 4)

-- Palmeras y sombrillas -------------------------------------------------------

local function palmera(x, z)
	local alto = azar:NextNumber(10, 14)
	parte("Tronco", Vector3.new(alto, 1.2, 1.2), CFrame.new(x, ARENA + alto / 2, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(140, 100, 60), Enum.Material.Wood, Enum.PartType.Cylinder)
	for i = 0, 4 do
		local angulo = math.rad(i * 72)
		local hoja = CFrame.new(x, ARENA + alto, z) * CFrame.Angles(0, angulo, 0) * CFrame.new(0, -0.6, -2.6) * CFrame.Angles(math.rad(-25), 0, 0)
		parte("Hoja", Vector3.new(1.6, 0.3, 5.5), hoja, Color3.fromRGB(50, 160, 60), Enum.Material.Grass, nil, false)
	end
	parte("Coco", Vector3.one * 0.9, CFrame.new(x + 0.5, ARENA + alto - 0.8, z), Color3.fromRGB(110, 75, 40), Enum.Material.Wood, Enum.PartType.Ball, false)
end

local COLORES_SOMBRILLA = { Color3.fromRGB(230, 60, 60), Color3.fromRGB(60, 140, 230), Color3.fromRGB(255, 200, 40), Color3.fromRGB(80, 200, 120) }
local function sombrilla(x, z)
	parte("Palo", Vector3.new(0.3, 7, 0.3), CFrame.new(x, ARENA + 3.5, z), Color3.fromRGB(240, 240, 240), Enum.Material.Metal)
	parte("Tela", Vector3.new(1.2, 7, 7), CFrame.new(x, ARENA + 7, z) * CFrame.Angles(0, 0, math.rad(90)), COLORES_SOMBRILLA[azar:NextInteger(1, #COLORES_SOMBRILLA)], Enum.Material.Fabric, Enum.PartType.Cylinder, false)
	parte("Toalla", Vector3.new(2.5, 0.1, 4.5), CFrame.new(x + 3, ARENA + 0.05, z), COLORES_SOMBRILLA[azar:NextInteger(1, #COLORES_SOMBRILLA)], Enum.Material.Fabric, nil, false)
end

for _ = 1, 14 do
	local z = azar:NextNumber(-P.Z + 6, P.Z - 6)
	if math.abs(z) > 12 then -- deja libre el camino desde la entrada
		palmera(azar:NextNumber(P.ARENA_X1 + 4, P.ARENA_X2 - 15), z)
	end
end
for _ = 1, 8 do
	local z = azar:NextNumber(-P.Z + 10, P.Z - 10)
	if math.abs(z) > 14 then
		sombrilla(azar:NextNumber(P.ARENA_X1 + 10, P.ARENA_X2 - 12), z)
	end
end

-- Entrada ----------------------------------------------------------------------
-- Un arco con cartel al final de la avenida del este; se pasa libremente.

for _, lado in { -1, 1 } do
	parte("Columna", Vector3.new(2.5, 16, 2.5), CFrame.new(LIMITE + 1, 8, lado * (P.PUERTA + 1.25)), Color3.fromRGB(240, 220, 160), Enum.Material.Sandstone)
end
-- Cartel mirando a la ciudad (hacia -X)
cartel(CFrame.new(LIMITE - 0.5, 18, 0) * CFrame.Angles(0, math.rad(90), 0), P.PUERTA * 2 + 5, 4, "🏝️ PLAYA", Color3.fromRGB(20, 140, 200))

-- Isla del tesoro --------------------------------------------------------------

parte("Isla", Vector3.new(4, 26, 26), CFrame.new(ISLA.X, NIVEL_AGUA - 0.5, ISLA.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(240, 220, 160), Enum.Material.Sand, Enum.PartType.Cylinder)
palmera(ISLA.X + 6, ISLA.Z + 5)
palmera(ISLA.X - 7, ISLA.Z - 4)
local suelo = NIVEL_AGUA + 1.5

-- Plataformas flotantes desde la orilla hasta la isla, en zigzag y subiendo un poco
local desde = P.ARENA_X2 + 6
local cantidad = 16
for i = 1, cantidad do
	local x = desde + (ISLA.X - 14 - desde) * (i - 1) / (cantidad - 1)
	local z = math.sin(i * 0.9) * 9
	local y = NIVEL_AGUA + 1 + math.sin(i * 0.5) * 1.5 + (i % 3)
	parte("Plataforma", Vector3.new(4.5, 1, 4.5), CFrame.new(x, y, z), Color3.fromRGB(160, 110, 60), Enum.Material.WoodPlanks)
end
cartel(CFrame.new(P.ARENA_X2 - 3, ARENA + 5, 12) * CFrame.Angles(0, math.rad(90), 0), 12, 3.5, "🏴‍☠️ Isla del tesoro →", Color3.fromRGB(150, 90, 40))

-- Cofre de la isla
local cofre = parte("Cofre", Vector3.new(4, 2.6, 2.6), CFrame.new(ISLA.X, suelo + 1.3, ISLA.Z), Color3.fromRGB(150, 95, 40), Enum.Material.Wood)
parte("Tapa", Vector3.new(4.2, 0.6, 2.8), CFrame.new(ISLA.X, suelo + 2.9, ISLA.Z), Color3.fromRGB(255, 205, 0), Enum.Material.Neon, nil, false)
local brillo = Instance.new("Sparkles")
brillo.SparkleColor = Color3.fromRGB(255, 220, 80)
brillo.Parent = cofre

local abrir = Instance.new("ProximityPrompt")
abrir.ActionText = "Abrir cofre"
abrir.ObjectText = string.format("Tesoro: %d monedas", PREMIO_ISLA)
abrir.MaxActivationDistance = 10
abrir.RequiresLineOfSight = false
abrir.Parent = cofre
abrir.Triggered:Connect(function(jugador)
	local leaderstats = jugador:FindFirstChild("leaderstats")
	local monedas = leaderstats and leaderstats:FindFirstChild("Monedas")
	if not monedas then
		return
	end
	local ahora = Workspace:GetServerTimeNow()
	local listo = jugador:GetAttribute("CofreIslaListo") or 0
	if ahora < listo then
		local falta = math.ceil(listo - ahora)
		avisar(jugador, string.format("El tesoro vuelve en %d:%02d", math.floor(falta / 60), falta % 60), false)
		return
	end
	jugador:SetAttribute("CofreIslaListo", ahora + ESPERA_COFRE)
	monedas.Value += PREMIO_ISLA
	avisar(jugador, string.format("🏴‍☠️ ¡Encontraste el tesoro! +%d monedas", PREMIO_ISLA), true)
end)
