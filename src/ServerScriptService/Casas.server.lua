-- El Barrio de casas, al oeste de la ciudad (PlanoCiudad.BARRIO). Hay terrenos con
-- cartel "Se vende": un jugador compra su casa una vez (ConfigCasas.PRECIO_CASA) y
-- queda guardada; cada vez que entra al juego su casa aparece en un terreno libre
-- de ese servidor y al irse se libera. Adentro decora con muebles que compra
-- (cada uno tiene su lugar fijo) y puede cerrar la puerta para que solo entre el.
--
-- La puerta cerrada choca con todos menos con el dueño (grupos de colision por
-- terreno). El panel de muebles y el boton "Mi casa" estan en Casas.client.lua.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConfigCasas = require(ReplicatedStorage:WaitForChild("ConfigCasas"))
local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))

local B = Plano.BARRIO
local LIMITE = Plano.LIMITE
local SUELO = 0.3
local SEMILLA = 321

local ANCHO_CASA, FONDO_CASA, ALTO_CASA = 22, 18, 10
local GROSOR = 0.8
local ANCHO_PUERTA, ALTO_PUERTA = 5, 8
local CENTRO_CASA_Z = 2 -- la casa esta un poco hacia el fondo del terreno (frente hacia -Z)

local COLORES_CASA = {
	Color3.fromRGB(250, 235, 200),
	Color3.fromRGB(200, 230, 250),
	Color3.fromRGB(255, 210, 210),
	Color3.fromRGB(215, 245, 210),
	Color3.fromRGB(240, 220, 255),
	Color3.fromRGB(255, 240, 180),
}
local COLORES_TECHO = {
	Color3.fromRGB(180, 60, 50),
	Color3.fromRGB(60, 90, 150),
	Color3.fromRGB(90, 60, 40),
}

local azar = Random.new(SEMILLA)

local barrio = Instance.new("Folder")
barrio.Name = "Barrio"
barrio.Parent = Workspace

local abrirMuebles = Instance.new("RemoteEvent")
abrirMuebles.Name = "AbrirMuebles"
abrirMuebles.Parent = ReplicatedStorage

local comprarMueble = Instance.new("RemoteFunction")
comprarMueble.Name = "ComprarMueble"
comprarMueble.Parent = ReplicatedStorage

local irAMiCasa = Instance.new("RemoteEvent")
irAMiCasa.Name = "IrAMiCasa"
irAMiCasa.Parent = ReplicatedStorage

local function parte(padre, nombre, tamano, cframe, color, material, forma, colisiona)
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
	p.Parent = padre
	return p
end

local function escribir(tabla, cara, texto, color)
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
	etiqueta.TextColor3 = color or Color3.new(1, 1, 1)
	etiqueta.Text = texto
	etiqueta.Parent = gui
	return etiqueta
end

local aviso
local function avisar(jugador, texto, ok)
	aviso = aviso or ReplicatedStorage:FindFirstChild("AvisoTienda")
	if aviso then
		aviso:FireClient(jugador, texto, ok)
	end
end

-- El barrio: pasto, calle, arboles, paredes y el arco de entrada --------------------

local largoX = B.X_CERCA - B.X_LEJOS
local centroX = (B.X_CERCA + B.X_LEJOS) / 2
parte(barrio, "Pasto", Vector3.new(largoX + 2, SUELO, B.Z * 2), CFrame.new(centroX + 1, SUELO / 2, 0), Color3.fromRGB(90, 165, 70), Enum.Material.Grass)
parte(barrio, "Calle", Vector3.new(largoX + 2, 0.05, B.MEDIO_ANCHO_CALLE * 2), CFrame.new(centroX + 1, SUELO + 0.025, 0), Color3.fromRGB(70, 70, 75), Enum.Material.Asphalt, nil, false)

local function pared(x, z, ancho, fondo)
	local p = parte(barrio, "Limite", Vector3.new(ancho, 60, fondo), CFrame.new(x, 30, z), Color3.new(1, 1, 1))
	p.Transparency = 1
end
pared(centroX, -B.Z - 1, largoX + 4, 2)
pared(centroX, B.Z + 1, largoX + 4, 2)
pared(B.X_LEJOS - 1, 0, 2, B.Z * 2 + 4)

for _, lado in { -1, 1 } do
	parte(barrio, "Columna", Vector3.new(2.5, 16, 2.5), CFrame.new(-LIMITE - 1, 8, lado * (B.PUERTA + 1.25)), Color3.fromRGB(150, 110, 80), Enum.Material.Brick)
end
local arco = parte(barrio, "Cartel", Vector3.new(0.4, 4, B.PUERTA * 2 + 5), CFrame.new(-LIMITE - 1, 18, 0), Color3.fromRGB(180, 60, 50), Enum.Material.Wood)
escribir(arco, Enum.NormalId.Right, "🏠 BARRIO") -- mira hacia la ciudad (+X)
escribir(arco, Enum.NormalId.Left, "🏠 BARRIO")

-- Arboles en el fondo de cada lado
local function arbol(x, z)
	local alto = azar:NextNumber(5, 7)
	parte(barrio, "Tronco", Vector3.new(alto, 1.4, 1.4), CFrame.new(x, SUELO + alto / 2, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood, Enum.PartType.Cylinder)
	local copa = azar:NextNumber(6, 8)
	parte(barrio, "Hojas", Vector3.one * copa, CFrame.new(x, SUELO + alto + copa / 3, z), Color3.fromRGB(40, 125, 50), Enum.Material.Grass, Enum.PartType.Ball)
end
for x = B.X_CERCA - 12, B.X_LEJOS + 8, -18 do
	arbol(x + azar:NextNumber(-3, 3), B.Z - 5)
	arbol(x + azar:NextNumber(-3, 3), -B.Z + 5)
end

-- Muebles ------------------------------------------------------------------------
-- Cada uno se arma en su lugar, en coordenadas del interior: origen en el centro del
-- piso, el frente (la puerta) hacia -Z y el fondo hacia +Z.

local MADERA = Color3.fromRGB(150, 105, 65)

local Muebles = {}

function Muebles.Alfombra(c, o)
	parte(c, "Alfombra", Vector3.new(8, 0.1, 6), o * CFrame.new(-1, 0.05, 1), Color3.fromRGB(190, 50, 60), Enum.Material.Fabric, nil, false)
end

function Muebles.Sillon(c, o)
	local base = o * CFrame.new(-1, 0, -1.5)
	local color = Color3.fromRGB(60, 110, 180)
	parte(c, "Asiento", Vector3.new(5, 1.2, 2), base * CFrame.new(0, 0.6, 0), color, Enum.Material.Fabric)
	parte(c, "Respaldo", Vector3.new(5, 2.2, 0.6), base * CFrame.new(0, 1.3, -1.1), color, Enum.Material.Fabric)
	for _, x in { -2.7, 2.7 } do
		parte(c, "Brazo", Vector3.new(0.6, 1.8, 2.4), base * CFrame.new(x, 0.9, -0.2), color, Enum.Material.Fabric)
	end
end

function Muebles.TV(c, o)
	parte(c, "Mueble", Vector3.new(5, 1.5, 1.5), o * CFrame.new(-1, 0.75, 7.3), MADERA, Enum.Material.Wood)
	parte(c, "Tele", Vector3.new(6, 3.5, 0.3), o * CFrame.new(-1, 3.5, 7.6), Color3.fromRGB(20, 20, 20))
	parte(c, "Pantalla", Vector3.new(5.6, 3.1, 0.05), o * CFrame.new(-1, 3.5, 7.43), Color3.fromRGB(70, 150, 255), Enum.Material.Neon, nil, false)
end

function Muebles.Cama(c, o)
	local base = o * CFrame.new(7.5, 0, 4.5)
	parte(c, "Cama", Vector3.new(4.5, 1.2, 7), base * CFrame.new(0, 0.6, 0), MADERA, Enum.Material.Wood)
	parte(c, "Colchon", Vector3.new(4.3, 0.6, 6.8), base * CFrame.new(0, 1.5, 0), Color3.fromRGB(245, 245, 245), Enum.Material.Fabric)
	parte(c, "Almohada", Vector3.new(3, 0.5, 1.2), base * CFrame.new(0, 2, 2.6), Color3.new(1, 1, 1), Enum.Material.Fabric)
	parte(c, "Frazada", Vector3.new(4.4, 0.2, 4), base * CFrame.new(0, 1.85, -1), Color3.fromRGB(60, 120, 210), Enum.Material.Fabric)
end

function Muebles.Mesa(c, o)
	local base = o * CFrame.new(6.5, 0, -3)
	parte(c, "Tabla", Vector3.new(4, 0.3, 3), base * CFrame.new(0, 2.6, 0), MADERA, Enum.Material.Wood)
	for _, x in { -1.7, 1.7 } do
		for _, z in { -1.2, 1.2 } do
			parte(c, "Pata", Vector3.new(0.3, 2.5, 0.3), base * CFrame.new(x, 1.25, z), MADERA, Enum.Material.Wood)
		end
	end
	for _, x in { -2.8, 2.8 } do
		parte(c, "Silla", Vector3.new(1.6, 0.3, 1.6), base * CFrame.new(x, 1.4, 0), MADERA, Enum.Material.Wood)
		parte(c, "Respaldo", Vector3.new(0.3, 1.6, 1.6), base * CFrame.new(x + (x > 0 and 0.7 or -0.7), 2.3, 0), MADERA, Enum.Material.Wood)
		parte(c, "PataSilla", Vector3.new(1.2, 1.3, 1.2), base * CFrame.new(x, 0.65, 0), MADERA:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.Wood)
	end
end

function Muebles.Lampara(c, o)
	local base = o * CFrame.new(-9, 0, 7.2)
	parte(c, "Pie", Vector3.new(1.2, 0.3, 1.2), base * CFrame.new(0, 0.15, 0), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	parte(c, "Palo", Vector3.new(0.3, 5, 0.3), base * CFrame.new(0, 2.6, 0), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	local pantalla = parte(c, "Pantalla", Vector3.new(1.8, 1.3, 1.8), base * CFrame.new(0, 5.4, 0), Color3.fromRGB(255, 235, 180), Enum.Material.Neon, nil, false)
	local luz = Instance.new("PointLight")
	luz.Range = 16
	luz.Brightness = 1.3
	luz.Color = Color3.fromRGB(255, 225, 170)
	luz.Parent = pantalla
end

function Muebles.Planta(c, o)
	local base = o * CFrame.new(9.2, 0, -7.2)
	parte(c, "Maceta", Vector3.new(1.4, 1.6, 1.6), base * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(190, 100, 60), Enum.Material.Slate, Enum.PartType.Cylinder)
	parte(c, "Hojas", Vector3.one * 2.4, base * CFrame.new(0, 2.6, 0), Color3.fromRGB(50, 150, 60), Enum.Material.Grass, Enum.PartType.Ball, false)
end

function Muebles.Cucha(c, o)
	local base = o * CFrame.new(-8, 0, -5)
	parte(c, "Cucha", Vector3.new(3.5, 2.5, 3), base * CFrame.new(0, 1.25, 0), MADERA, Enum.Material.WoodPlanks)
	parte(c, "Techito", Vector3.new(4, 0.4, 3.6), base * CFrame.new(0, 2.7, 0), Color3.fromRGB(200, 50, 50), Enum.Material.Wood)
	parte(c, "Entrada", Vector3.new(1.6, 1.8, 0.1), base * CFrame.new(0, 0.9, -1.52), Color3.fromRGB(30, 20, 15), nil, nil, false)
	parte(c, "Plato", Vector3.new(0.4, 1.2, 1.2), base * CFrame.new(2.5, 0.2, -1) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 140, 220), nil, Enum.PartType.Cylinder, false)
end

-- Terrenos -----------------------------------------------------------------------

local lotes = {}
local loteDe = {} -- jugador -> lote

-- Grupos de colision: la puerta cerrada no choca con su dueño
local function prepararGrupos(i)
	local puerta, dueno = "PuertaCasa" .. i, "DuenoCasa" .. i
	PhysicsService:RegisterCollisionGroup(puerta)
	PhysicsService:RegisterCollisionGroup(dueno)
	PhysicsService:CollisionGroupSetCollidable(puerta, dueno, false)
	return puerta, dueno
end

local function marcarPersonaje(personaje, grupo)
	for _, p in personaje:GetDescendants() do
		if p:IsA("BasePart") then
			p.CollisionGroup = grupo
		end
	end
end

local function textoCartel(lote, texto)
	for _, gui in lote.cartel:GetChildren() do
		if gui:IsA("SurfaceGui") then
			gui:FindFirstChildOfClass("TextLabel").Text = texto
		end
	end
end

-- Origen del interior: centro del piso de la casa, a la altura de arriba del piso
local function interior(lote)
	return lote.base * CFrame.new(0, SUELO + 0.3, CENTRO_CASA_Z)
end

local function armarMuebles(lote)
	if lote.muebles then
		lote.muebles:Destroy()
	end
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Muebles"
	carpeta.Parent = lote.casa
	lote.muebles = carpeta
	local tengo = ConfigCasas.muebles(lote.dueno)
	for _, mueble in ConfigCasas.Muebles do
		if tengo[mueble.id] and Muebles[mueble.id] then
			Muebles[mueble.id](carpeta, interior(lote))
		end
	end
end

local function ponerPuerta(lote, cerrada)
	lote.cerrada = cerrada
	lote.puerta.CanCollide = cerrada
	lote.puerta.Transparency = cerrada and 0 or 0.85
	lote.botonPuerta.ActionText = cerrada and "Abrir la puerta" or "Cerrar la puerta"
end

-- Arma la casa del dueño en el terreno
local function armarCasa(lote)
	local casa = Instance.new("Model")
	casa.Name = "Casa"
	casa.Parent = lote.carpeta
	lote.casa = casa

	local o = interior(lote)
	local pared = COLORES_CASA[lote.indice]
	local techo = COLORES_TECHO[(lote.indice - 1) % #COLORES_TECHO + 1]
	local vidrio = Color3.fromRGB(150, 210, 240)
	local frente = -FONDO_CASA / 2 + GROSOR / 2

	parte(casa, "Piso", Vector3.new(ANCHO_CASA, 0.3, FONDO_CASA), o * CFrame.new(0, -0.15, 0), Color3.fromRGB(200, 160, 110), Enum.Material.WoodPlanks)
	parte(casa, "Pared", Vector3.new(ANCHO_CASA, ALTO_CASA, GROSOR), o * CFrame.new(0, ALTO_CASA / 2, FONDO_CASA / 2 - GROSOR / 2), pared, Enum.Material.Concrete)
	for _, lado in { -1, 1 } do
		parte(casa, "Pared", Vector3.new(GROSOR, ALTO_CASA, FONDO_CASA), o * CFrame.new(lado * (ANCHO_CASA / 2 - GROSOR / 2), ALTO_CASA / 2, 0), pared, Enum.Material.Concrete)
		parte(casa, "Ventana", Vector3.new(0.1, 3.5, 5), o * CFrame.new(lado * (ANCHO_CASA / 2 + 0.02), 5, 2), vidrio, Enum.Material.Glass, nil, false)
		local tramo = (ANCHO_CASA - ANCHO_PUERTA) / 2
		local x = lado * (ANCHO_PUERTA / 2 + tramo / 2)
		parte(casa, "Frente", Vector3.new(tramo, ALTO_CASA, GROSOR), o * CFrame.new(x, ALTO_CASA / 2, frente), pared, Enum.Material.Concrete)
		parte(casa, "Ventana", Vector3.new(4.5, 3.5, 0.1), o * CFrame.new(x, 5, -FONDO_CASA / 2 - 0.02), vidrio, Enum.Material.Glass, nil, false)
	end
	parte(casa, "Frente", Vector3.new(ANCHO_PUERTA, ALTO_CASA - ALTO_PUERTA, GROSOR), o * CFrame.new(0, ALTO_PUERTA + (ALTO_CASA - ALTO_PUERTA) / 2, frente), pared, Enum.Material.Concrete)
	parte(casa, "Techo", Vector3.new(ANCHO_CASA + 1.6, 0.8, FONDO_CASA + 1.6), o * CFrame.new(0, ALTO_CASA + 0.4, 0), techo, Enum.Material.Slate)
	parte(casa, "Chimenea", Vector3.new(2, 3, 2), o * CFrame.new(-7, ALTO_CASA + 2.3, 5), Color3.fromRGB(140, 70, 50), Enum.Material.Brick)

	-- Puerta (se abre y se cierra) con su boton
	local puerta = parte(casa, "Puerta", Vector3.new(ANCHO_PUERTA, ALTO_PUERTA, 0.3), o * CFrame.new(0, ALTO_PUERTA / 2, frente), Color3.fromRGB(120, 75, 40), Enum.Material.Wood)
	puerta.CollisionGroup = lote.grupoPuerta
	lote.puerta = puerta
	local boton = Instance.new("ProximityPrompt")
	boton.ObjectText = "Puerta"
	boton.MaxActivationDistance = 8
	boton.RequiresLineOfSight = false
	boton.Parent = puerta
	lote.botonPuerta = boton
	boton.Triggered:Connect(function(jugador)
		if jugador ~= lote.dueno then
			avisar(jugador, "Solo el dueño puede abrir o cerrar la puerta", false)
			return
		end
		ponerPuerta(lote, not lote.cerrada)
	end)
	ponerPuerta(lote, false) -- abierta: pueden entrar los amigos

	-- Para decorar: un atril adentro, al lado de la puerta
	local atril = parte(casa, "Atril", Vector3.new(1.6, 3, 1), o * CFrame.new(5, 1.5, -FONDO_CASA / 2 + 2), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
	escribir(atril, Enum.NormalId.Back, "🛋️ Decorar", Color3.fromRGB(255, 205, 0))
	local decorar = Instance.new("ProximityPrompt")
	decorar.ActionText = "Decorar"
	decorar.ObjectText = "Muebles"
	decorar.MaxActivationDistance = 8
	decorar.RequiresLineOfSight = false
	decorar.Parent = atril
	decorar.Triggered:Connect(function(jugador)
		if jugador ~= lote.dueno then
			avisar(jugador, "Solo el dueño puede decorar esta casa", false)
			return
		end
		abrirMuebles:FireClient(jugador)
	end)

	armarMuebles(lote)
end

local function asignar(lote, jugador)
	lote.dueno = jugador
	loteDe[jugador] = lote
	lote.botonComprar.Enabled = false
	textoCartel(lote, "Casa de " .. jugador.DisplayName)
	armarCasa(lote)
	if jugador.Character then
		marcarPersonaje(jugador.Character, lote.grupoDueno)
	end
end

local function liberar(lote)
	if lote.dueno then
		loteDe[lote.dueno] = nil
	end
	lote.dueno = nil
	if lote.casa then
		lote.casa:Destroy()
	end
	lote.casa, lote.muebles, lote.puerta = nil, nil, nil
	lote.botonComprar.Enabled = true
	textoCartel(lote, string.format("SE VENDE\n%d monedas", ConfigCasas.PRECIO_CASA))
end

local function loteLibre()
	for _, lote in lotes do
		if not lote.dueno then
			return lote
		end
	end
	return nil
end

local function comprarCasa(jugador, lote)
	if lote.dueno then
		return
	end
	if loteDe[jugador] then
		avisar(jugador, "Ya tenés tu casa en este barrio", false)
		return
	end
	if not jugador:GetAttribute("DatosCargados") then
		return
	end
	if jugador:GetAttribute("TieneCasa") then
		-- Ya la habia comprado pero no habia terreno libre al entrar: se muda aca gratis
		asignar(lote, jugador)
		avisar(jugador, "🏠 ¡Tu casa está acá!", true)
		return
	end
	local leaderstats = jugador:FindFirstChild("leaderstats")
	local monedas = leaderstats and leaderstats:FindFirstChild("Monedas")
	if not monedas or monedas.Value < ConfigCasas.PRECIO_CASA then
		avisar(jugador, string.format("Te faltan %d monedas para la casa", ConfigCasas.PRECIO_CASA - (monedas and monedas.Value or 0)), false)
		return
	end
	monedas.Value -= ConfigCasas.PRECIO_CASA
	jugador:SetAttribute("TieneCasa", true)
	asignar(lote, jugador)
	avisar(jugador, "🏠 ¡Compraste tu casa! Entrá y decorala", true)
end

for i, centro in B.TERRENOS do
	local frente = Vector3.new(0, 0, centro.Z > 0 and -1 or 1) -- hacia la calle
	local base = CFrame.lookAt(centro, centro + frente)
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Terreno" .. i
	carpeta.Parent = barrio

	parte(carpeta, "Terreno", Vector3.new(38, 0.1, 34), base * CFrame.new(0, SUELO + 0.05, 0), Color3.fromRGB(110, 185, 85), Enum.Material.Grass, nil, false)
	-- Caminito de la vereda a la puerta
	parte(carpeta, "Camino", Vector3.new(4, 0.12, 10), base * CFrame.new(0, SUELO + 0.06, -12), Color3.fromRGB(200, 190, 170), Enum.Material.Slate, nil, false)

	-- Cartel junto al camino, mirando a la calle
	for _, x in { -2, 2 } do
		parte(carpeta, "Poste", Vector3.new(0.4, 5, 0.4), base * CFrame.new(5 + x, SUELO + 2.5, -15), MADERA, Enum.Material.Wood)
	end
	local cartel = parte(carpeta, "Cartel", Vector3.new(6, 3, 0.3), base * CFrame.new(5, SUELO + 5, -15), Color3.fromRGB(40, 120, 60), Enum.Material.Wood)
	escribir(cartel, Enum.NormalId.Front, "")
	escribir(cartel, Enum.NormalId.Back, "")

	local comprar = Instance.new("ProximityPrompt")
	comprar.ActionText = "Comprar casa"
	comprar.ObjectText = string.format("%d monedas", ConfigCasas.PRECIO_CASA)
	comprar.MaxActivationDistance = 10
	comprar.RequiresLineOfSight = false
	comprar.Parent = cartel

	local grupoPuerta, grupoDueno = prepararGrupos(i)
	local lote = {
		indice = i,
		base = base,
		carpeta = carpeta,
		cartel = cartel,
		botonComprar = comprar,
		grupoPuerta = grupoPuerta,
		grupoDueno = grupoDueno,
	}
	comprar.Triggered:Connect(function(jugador)
		comprarCasa(jugador, lote)
	end)
	table.insert(lotes, lote)
	liberar(lote)
end

-- Jugadores ----------------------------------------------------------------------

local function prepararJugador(jugador)
	jugador.CharacterAdded:Connect(function(personaje)
		local lote = loteDe[jugador]
		if lote then
			marcarPersonaje(personaje, lote.grupoDueno)
		end
		personaje.DescendantAdded:Connect(function(p)
			local actual = loteDe[jugador]
			if actual and p:IsA("BasePart") then
				p.CollisionGroup = actual.grupoDueno
			end
		end)
	end)

	-- Cuando terminan de cargar sus datos, si tiene casa se le arma en un terreno libre
	task.spawn(function()
		while jugador.Parent and not jugador:GetAttribute("DatosCargados") do
			task.wait(0.5)
		end
		if jugador.Parent and jugador:GetAttribute("TieneCasa") and not loteDe[jugador] then
			local lote = loteLibre()
			if lote then
				asignar(lote, jugador)
			else
				avisar(jugador, "No hay terreno libre para tu casa en este servidor", false)
			end
		end
	end)
end

Players.PlayerAdded:Connect(prepararJugador)
for _, jugador in Players:GetPlayers() do
	prepararJugador(jugador)
end
Players.PlayerRemoving:Connect(function(jugador)
	local lote = loteDe[jugador]
	if lote then
		liberar(lote)
	end
end)

-- Muebles: compra desde el panel (Casas.client.lua)
comprarMueble.OnServerInvoke = function(jugador, id)
	local mueble = type(id) == "string" and ConfigCasas.buscar(id)
	if not mueble then
		return false, "Ese mueble no existe"
	end
	if not jugador:GetAttribute("TieneCasa") then
		return false, "Primero comprá una casa en el Barrio"
	end
	if ConfigCasas.muebles(jugador)[mueble.id] then
		return false, "Ya lo tenés en tu casa"
	end
	local leaderstats = jugador:FindFirstChild("leaderstats")
	local monedas = leaderstats and leaderstats:FindFirstChild("Monedas")
	if not monedas or monedas.Value < mueble.precio then
		return false, string.format("Te faltan %d monedas", mueble.precio - (monedas and monedas.Value or 0))
	end
	monedas.Value -= mueble.precio
	local actual = jugador:GetAttribute("Muebles") or ""
	jugador:SetAttribute("Muebles", actual == "" and mueble.id or (actual .. "," .. mueble.id))
	local lote = loteDe[jugador]
	if lote then
		armarMuebles(lote)
	end
	return true, "¡" .. mueble.nombre .. " en tu casa!"
end

-- "Mi casa": lleva al jugador a la puerta de su casa
irAMiCasa.OnServerEvent:Connect(function(jugador)
	local lote = loteDe[jugador]
	local personaje = jugador.Character
	if not lote then
		avisar(jugador, "Todavía no tenés casa: comprá una en el Barrio (al oeste de la ciudad)", false)
		return
	end
	if personaje then
		local humanoide = personaje:FindFirstChildOfClass("Humanoid")
		if humanoide and humanoide.SeatPart then
			humanoide.Sit = false -- primero se baja del auto
			task.wait(0.2)
		end
		personaje:PivotTo(lote.base * CFrame.new(0, SUELO + 3, -12) * CFrame.Angles(0, math.pi, 0))
	end
end)
