-- Genera el mapa del juego: cesped, cerco, arboles, flores y un cartel de bienvenida.
-- Todo se crea por codigo y queda dentro de la carpeta "Mapa" en Workspace.
-- El mapa es siempre igual porque usa una semilla fija (SEMILLA).

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local TAMANO = 100 -- el cesped es un cuadrado de TAMANO x TAMANO
local GROSOR = 0.4 -- grosor del cesped; su cara de arriba queda en y = GROSOR
local SEMILLA = 12345
local CANTIDAD_ARBOLES = 16
local CANTIDAD_FLORES = 50
local COLORES_FLORES = {
	Color3.fromRGB(255, 90, 130),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(190, 120, 255),
	Color3.fromRGB(255, 160, 40),
}

local azar = Random.new(SEMILLA)
local mitad = TAMANO / 2

local mapa = Instance.new("Folder")
mapa.Name = "Mapa"
mapa.Parent = Workspace

local function crearParte(nombre, tamano, cframe, color, material, forma, colisiona)
	local parte = Instance.new("Part")
	parte.Name = nombre
	parte.Size = tamano
	parte.CFrame = cframe
	parte.Color = color
	parte.Material = material
	parte.Shape = forma or Enum.PartType.Block
	parte.Anchored = true
	parte.CanCollide = colisiona ~= false
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	parte.Parent = mapa
	return parte
end

local function crearCesped()
	crearParte(
		"Cesped",
		Vector3.new(TAMANO, GROSOR, TAMANO),
		CFrame.new(0, GROSOR / 2, 0),
		Color3.fromRGB(86, 160, 60),
		Enum.Material.Grass
	)
end

local function crearCerco()
	local altura = 3
	local y = GROSOR + altura / 2
	local color = Color3.fromRGB(120, 85, 55)
	local largo = TAMANO + 2

	crearParte("Cerco", Vector3.new(largo, altura, 1), CFrame.new(0, y, -mitad - 0.5), color, Enum.Material.Wood)
	crearParte("Cerco", Vector3.new(largo, altura, 1), CFrame.new(0, y, mitad + 0.5), color, Enum.Material.Wood)
	crearParte("Cerco", Vector3.new(1, altura, largo), CFrame.new(-mitad - 0.5, y, 0), color, Enum.Material.Wood)
	crearParte("Cerco", Vector3.new(1, altura, largo), CFrame.new(mitad + 0.5, y, 0), color, Enum.Material.Wood)
end

-- Los arboles van en la franja de afuera para no tapar a las monedas
-- (las monedas aparecen dentro de +-40 del centro)
local function posicionEnBorde()
	local lado = azar:NextInteger(1, 4)
	local cerca = azar:NextNumber(42, 47)
	local largo = azar:NextNumber(-47, 47)
	if lado == 1 then
		return Vector3.new(largo, 0, -cerca)
	elseif lado == 2 then
		return Vector3.new(largo, 0, cerca)
	elseif lado == 3 then
		return Vector3.new(-cerca, 0, largo)
	end
	return Vector3.new(cerca, 0, largo)
end

local function crearArbol(posicion)
	local alturaTronco = azar:NextNumber(5, 7)
	-- El cilindro mide su largo en X, asi que lo giramos para que quede parado
	crearParte(
		"Tronco",
		Vector3.new(alturaTronco, 1.6, 1.6),
		CFrame.new(posicion.X, GROSOR + alturaTronco / 2, posicion.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(110, 75, 45),
		Enum.Material.Wood,
		Enum.PartType.Cylinder
	)

	local diametro = azar:NextNumber(7, 9)
	crearParte(
		"Hojas",
		Vector3.new(diametro, diametro, diametro),
		CFrame.new(posicion.X, GROSOR + alturaTronco + diametro / 3, posicion.Z),
		Color3.fromRGB(40, 125, 50),
		Enum.Material.Grass,
		Enum.PartType.Ball
	)
end

local function crearFlor(posicion)
	local color = COLORES_FLORES[azar:NextInteger(1, #COLORES_FLORES)]
	crearParte(
		"Tallo",
		Vector3.new(0.2, 1, 0.2),
		CFrame.new(posicion.X, GROSOR + 0.5, posicion.Z),
		Color3.fromRGB(50, 130, 50),
		Enum.Material.Plastic,
		nil,
		false
	)
	crearParte(
		"Flor",
		Vector3.new(0.9, 0.9, 0.9),
		CFrame.new(posicion.X, GROSOR + 1.1, posicion.Z),
		color,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball,
		false
	)
end

local function crearCartel()
	local z = -mitad + 5
	local madera = Color3.fromRGB(120, 85, 55)

	for _, x in { -10, 10 } do
		crearParte("PosteCartel", Vector3.new(1, 8, 1), CFrame.new(x, GROSOR + 4, z), madera, Enum.Material.Wood)
	end

	-- Girado 180 grados para que la cara con el texto mire hacia el centro del mapa
	local tabla = crearParte(
		"Cartel",
		Vector3.new(24, 6, 1),
		CFrame.new(0, GROSOR + 8, z) * CFrame.Angles(0, math.pi, 0),
		Color3.fromRGB(235, 215, 170),
		Enum.Material.Wood
	)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = tabla

	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.GothamBold
	texto.TextScaled = true
	texto.TextColor3 = Color3.fromRGB(60, 40, 20)
	texto.Text = "¡Bienvenido a Mundo Roblox!"
	texto.Parent = gui
end

crearCesped()
crearCerco()
crearCartel()

for _ = 1, CANTIDAD_ARBOLES do
	crearArbol(posicionEnBorde())
end

for _ = 1, CANTIDAD_FLORES do
	crearFlor(Vector3.new(azar:NextNumber(-mitad + 3, mitad - 3), 0, azar:NextNumber(-mitad + 3, mitad - 3)))
end

-- Un dia soleado
Lighting.ClockTime = 14
