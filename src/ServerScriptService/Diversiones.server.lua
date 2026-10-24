-- Parque de diversiones al sur de la ciudad (PlanoCiudad.DIVERSIONES), pasando el arco
-- que hay al final de la avenida sur. Tiene:
--   Montaña rusa: en la estacion, "Subir" te pone en un carrito y das una vuelta
--   Tobogan gigante: se sube trepando la escalera de la torre y "Tirarse" te larga
--   Trampolines: rebotan alto (Diversiones.client.lua); el "súper" llega a una
--     plataforma con un cofre de premio
--   Rueda gigante: gira todo el tiempo (de adorno)
--
-- Los recorridos (montaña rusa y tobogan) estan en Recorridos.lua. El servidor arma
-- las vias y el carrito (pegado al jugador, asi lo ven todos) y avisa al cliente con
-- SubirAtraccion; el cliente mueve a su personaje por la via. Al terminar, premio.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))
local Recorridos = require(ReplicatedStorage:WaitForChild("Recorridos"))

local D = Plano.DIVERSIONES
local LIMITE = Plano.LIMITE
local SUELO = 0.3
local SEMILLA = 909

local POTENCIA_TRAMPOLIN = 90 -- velocidad hacia arriba al rebotar
local POTENCIA_SUPER = 165
local PREMIO_COFRE = 150
local ESPERA_COFRE = 10 * 60 -- segundos hasta poder abrir el cofre otra vez
local VELOCIDAD_RUEDA = 0.15 -- radianes por segundo

local ROJO = Color3.fromRGB(220, 40, 50)
local AMARILLO = Color3.fromRGB(255, 200, 0)
local AZUL = Color3.fromRGB(40, 120, 230)
local VERDE = Color3.fromRGB(40, 170, 80)
local VIOLETA = Color3.fromRGB(150, 70, 210)
local ROSA = Color3.fromRGB(255, 110, 170)
local BLANCO = Color3.fromRGB(240, 240, 240)
local GRIS = Color3.fromRGB(70, 70, 75)
local COLORES = { ROJO, AMARILLO, AZUL, VERDE, VIOLETA, ROSA }

local PARADO = CFrame.Angles(0, 0, math.pi / 2) -- cilindro con el eje vertical
local DE_FRENTE = CFrame.Angles(0, math.pi / 2, 0) -- cilindro con el eje a lo largo de Z

local subir = Instance.new("RemoteEvent")
subir.Name = "SubirAtraccion"
subir.Parent = ReplicatedStorage

local azar = Random.new(SEMILLA)

local carpeta = Instance.new("Folder")
carpeta.Name = "Diversiones"
carpeta.Parent = Workspace

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

-- Cartel en un poste, mirando hacia frente (un vector)
local function cartel(padre, posicion, frente, texto, color)
	local base = CFrame.lookAt(posicion, posicion + frente)
	parte(padre, "Poste", Vector3.new(0.4, 7, 0.4), base * CFrame.new(0, 3.5, 0), GRIS, Enum.Material.Metal)
	local tabla = parte(padre, "Cartel", Vector3.new(8, 2.4, 0.3), base * CFrame.new(0, 7.2, 0), color, Enum.Material.Wood)
	escribir(tabla, Enum.NormalId.Front, texto)
	escribir(tabla, Enum.NormalId.Back, texto)
	return tabla
end

local function boton(padreParte, accion, objeto, distancia)
	local b = Instance.new("ProximityPrompt")
	b.ActionText = accion
	b.ObjectText = objeto
	b.MaxActivationDistance = distancia or 10
	b.RequiresLineOfSight = false
	b.Parent = padreParte
	return b
end

local aviso
local function avisar(jugador, texto, ok)
	aviso = aviso or ReplicatedStorage:FindFirstChild("AvisoTienda")
	if aviso then
		aviso:FireClient(jugador, texto, ok)
	end
end

local function monedasDe(jugador)
	local leaderstats = jugador:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Monedas")
end

---------------------------------------------------------------- Piso, paredes y entrada

local largoZ = D.Z_CERCA - D.Z_LEJOS
local centroZ = (D.Z_CERCA + D.Z_LEJOS) / 2
local general = Instance.new("Folder")
general.Name = "Parque"
general.Parent = carpeta

parte(general, "Pasto", Vector3.new(D.X * 2, SUELO, largoZ + 2), CFrame.new(0, SUELO / 2, centroZ + 1), Color3.fromRGB(100, 175, 75), Enum.Material.Grass)
parte(general, "Camino", Vector3.new(D.MEDIO_ANCHO_CAMINO * 2, 0.05, largoZ - 40), CFrame.new(0, SUELO + 0.025, D.Z_CERCA - (largoZ - 40) / 2 + 1), Color3.fromRGB(215, 195, 160), Enum.Material.Slate, nil, false)
-- Plaza redonda en el medio del camino
parte(general, "Plaza", Vector3.new(0.06, 34, 34), CFrame.new(0, SUELO + 0.03, -265) * PARADO, Color3.fromRGB(225, 205, 170), Enum.Material.Slate, Enum.PartType.Cylinder, false)
parte(general, "Fuente", Vector3.new(1.2, 10, 10), CFrame.new(0, SUELO + 0.6, -265) * PARADO, Color3.fromRGB(170, 170, 175), Enum.Material.Concrete, Enum.PartType.Cylinder)
local agua = parte(general, "Agua", Vector3.new(0.2, 8.6, 8.6), CFrame.new(0, SUELO + 1.15, -265) * PARADO, Color3.fromRGB(80, 170, 240), Enum.Material.Glass, Enum.PartType.Cylinder, false)
agua.Transparency = 0.3
local chorro = Instance.new("ParticleEmitter")
chorro.Color = ColorSequence.new(Color3.fromRGB(190, 230, 255))
chorro.Speed = NumberRange.new(14, 18)
chorro.SpreadAngle = Vector2.new(12, 12)
chorro.Lifetime = NumberRange.new(1, 1.3)
chorro.Rate = 60
chorro.Acceleration = Vector3.new(0, -30, 0)
chorro.EmissionDirection = Enum.NormalId.Right -- el cilindro esta parado: su eje X apunta arriba
chorro.Parent = agua

local function pared(x, z, ancho, fondo)
	local p = parte(general, "Limite", Vector3.new(ancho, 60, fondo), CFrame.new(x, 30, z), Color3.new(1, 1, 1))
	p.Transparency = 1
end
pared(-D.X - 1, centroZ, 2, largoZ + 4)
pared(D.X + 1, centroZ, 2, largoZ + 4)
pared(0, D.Z_LEJOS - 1, D.X * 2 + 4, 2)

-- Arco de entrada, en el hueco de la pared sur de la ciudad
for _, lado in { -1, 1 } do
	parte(general, "Columna", Vector3.new(2.5, 16, 2.5), CFrame.new(lado * (D.PUERTA + 1.25), 8, -LIMITE - 1), ROJO, Enum.Material.SmoothPlastic)
	parte(general, "Globo", Vector3.one * 3, CFrame.new(lado * (D.PUERTA + 1.25), 17.5, -LIMITE - 1), AMARILLO, Enum.Material.Neon, Enum.PartType.Ball)
end
local arco = parte(general, "Cartel", Vector3.new(D.PUERTA * 2 + 5, 4, 0.4), CFrame.new(0, 18, -LIMITE - 1), Color3.fromRGB(120, 40, 160), Enum.Material.SmoothPlastic)
escribir(arco, Enum.NormalId.Back, "🎢 DIVERSIONES", AMARILLO) -- mira hacia la ciudad (+Z)
escribir(arco, Enum.NormalId.Front, "🎢 DIVERSIONES", AMARILLO)

-- Faroles a los costados del camino y banderines de colores entre ellos
local function farol(x, z)
	parte(general, "Poste", Vector3.new(0.5, 10, 0.5), CFrame.new(x, SUELO + 5, z), GRIS, Enum.Material.Metal)
	local lampara = parte(general, "Lampara", Vector3.one * 1.6, CFrame.new(x, SUELO + 10.5, z), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, Enum.PartType.Ball, false)
	local luz = Instance.new("PointLight")
	luz.Range = 22
	luz.Brightness = 1.5
	luz.Color = Color3.fromRGB(255, 225, 170)
	luz.Parent = lampara
	CollectionService:AddTag(lampara, "LuzDeNoche")
end
for z = D.Z_CERCA - 12, -240, -20 do
	farol(-D.MEDIO_ANCHO_CAMINO - 2, z)
	farol(D.MEDIO_ANCHO_CAMINO + 2, z)
	-- Banderines colgando de un lado al otro
	for i = -3, 3 do
		parte(general, "Banderin", Vector3.new(1.6, 1.4, 0.1), CFrame.new(i * 2.4, SUELO + 9, z) * CFrame.Angles(0, 0, math.rad(45)), COLORES[(i + 3) % #COLORES + 1], Enum.Material.SmoothPlastic, nil, false)
	end
end

-- Puestos de comida (de adorno) a los costados del camino
local function puesto(x, z, texto, color)
	local frente = Vector3.new(x > 0 and -1 or 1, 0, 0)
	local base = CFrame.lookAt(Vector3.new(x, SUELO, z), Vector3.new(x, SUELO, z) + frente)
	parte(general, "Mostrador", Vector3.new(6, 3.4, 3), base * CFrame.new(0, 1.7, 0), BLANCO)
	for _, lado in { -2.8, 2.8 } do
		parte(general, "Poste", Vector3.new(0.3, 7, 0.3), base * CFrame.new(lado, 3.5, 1.2), BLANCO)
	end
	-- Toldo a rayas
	for i = 0, 5 do
		parte(general, "Toldo", Vector3.new(1, 0.3, 4), base * CFrame.new(-2.5 + i, 7.1, 0.4) * CFrame.Angles(math.rad(-12), 0, 0), i % 2 == 0 and color or BLANCO)
	end
	local tabla = parte(general, "Cartel", Vector3.new(6, 1.6, 0.2), base * CFrame.new(0, 5.8, -1.6), color)
	escribir(tabla, Enum.NormalId.Front, texto)
end
puesto(-17, -170, "🍿 POCHOCLOS", ROJO)
puesto(17, -175, "🍭 ALGODÓN", ROSA)
puesto(17, -245, "🌭 PANCHOS", AMARILLO)

-- Arboles en los bordes
local function arbol(x, z)
	local alto = azar:NextNumber(5, 7)
	parte(general, "Tronco", Vector3.new(alto, 1.4, 1.4), CFrame.new(x, SUELO + alto / 2, z) * PARADO, Color3.fromRGB(110, 75, 45), Enum.Material.Wood, Enum.PartType.Cylinder)
	local copa = azar:NextNumber(6, 8)
	parte(general, "Hojas", Vector3.one * copa, CFrame.new(x, SUELO + alto + copa / 3, z), Color3.fromRGB(40, 125, 50), Enum.Material.Grass, Enum.PartType.Ball)
end
for z = D.Z_CERCA - 10, D.Z_LEJOS + 10, -22 do
	arbol(-D.X + 5 + azar:NextNumber(-2, 2), z)
	arbol(D.X - 5 + azar:NextNumber(-2, 2), z)
end

---------------------------------------------------------------- Vias de los recorridos

-- Une dos puntos de la via con piezas; arma(cframe del tramo, largo, i) pone lo que va en cada tramo
local function porTramos(id, arma)
	local puntos = Recorridos.muestras(id).puntos
	for i = 1, #puntos - 1 do
		local a, b = puntos[i], puntos[i + 1]
		local largo = (b - a).Magnitude
		if largo > 0.01 then
			arma(CFrame.lookAt((a + b) / 2, b), largo, i, a)
		end
	end
end

-- Columna desde el piso hasta debajo de un punto de la via
local function columna(padre, punto, ancho, color)
	local alto = punto.Y - 0.6 - SUELO
	if alto > 1 then
		parte(padre, "Columna", Vector3.new(ancho, alto, ancho), CFrame.new(punto.X, SUELO + alto / 2, punto.Z), color, Enum.Material.Metal)
	end
end

-- Montaña rusa: dos rieles rojos, durmientes y columnas blancas
local montana = Instance.new("Folder")
montana.Name = "MontanaRusa"
montana.Parent = carpeta

porTramos("MontanaRusa", function(cf, largo, i, a)
	for _, x in { -1.3, 1.3 } do
		parte(montana, "Riel", Vector3.new(0.4, 0.4, largo + 0.25), cf * CFrame.new(x, -0.2, 0), ROJO, Enum.Material.Metal)
	end
	parte(montana, "Durmiente", Vector3.new(3.2, 0.25, 0.5), cf * CFrame.new(0, -0.45, 0), GRIS, Enum.Material.Metal, nil, false)
	if i % 3 == 1 then
		columna(montana, a, 0.8, BLANCO)
	end
end)

-- Estacion: plataforma al costado de la via con rampa, cartel y boton para subir
local ALTO_ANDEN = 2.6
local anden = parte(montana, "Anden", Vector3.new(6.5, ALTO_ANDEN - SUELO, 26), CFrame.new(-18.2, SUELO + (ALTO_ANDEN - SUELO) / 2, -202), Color3.fromRGB(200, 180, 140), Enum.Material.WoodPlanks)
local rampa = Instance.new("WedgePart")
rampa.Name = "Rampa"
rampa.Size = Vector3.new(6, ALTO_ANDEN - SUELO, 8)
-- La cuña sube hacia su +Z: girada para que suba hacia el anden (-X)
rampa.CFrame = CFrame.new(-11, SUELO + (ALTO_ANDEN - SUELO) / 2, -202) * CFrame.Angles(0, math.rad(-90), 0)
rampa.Color = anden.Color
rampa.Material = Enum.Material.WoodPlanks
rampa.Anchored = true
rampa.Parent = montana
parte(montana, "Techo", Vector3.new(8, 0.4, 26), CFrame.new(-20, 11, -202), ROJO)
for _, z in { -214, -190 } do
	for _, x in { -16, -24 + 2.5 } do
		parte(montana, "Poste", Vector3.new(0.5, 8.4, 0.5), CFrame.new(x, ALTO_ANDEN + 4.2, z), BLANCO, Enum.Material.Metal)
	end
end
local cartelMontana = cartel(montana, Vector3.new(-19, ALTO_ANDEN, -190.5), Vector3.new(0, 0, 1), "🎢 MONTAÑA RUSA", ROJO)
cartelMontana.Name = "CartelMontana"

-- Tobogan: canaleta de colores sobre columnas
local tobogan = Instance.new("Folder")
tobogan.Name = "Tobogan"
tobogan.Parent = carpeta

porTramos("Tobogan", function(cf, largo, i, a)
	local color = COLORES[(i // 3) % #COLORES + 1]
	parte(tobogan, "Piso", Vector3.new(4.4, 0.4, largo + 0.3), cf * CFrame.new(0, -0.2, 0), color, Enum.Material.SmoothPlastic)
	for _, x in { -2.2, 2.2 } do
		parte(tobogan, "Borde", Vector3.new(0.4, 1.4, largo + 0.3), cf * CFrame.new(x, 0.5, 0), color, Enum.Material.SmoothPlastic)
	end
	if i % 3 == 1 then
		columna(tobogan, a, 0.7, BLANCO)
	end
end)

-- La torre: cuatro postes, plataforma con baranda y una escalera para trepar
local TORRE = Vector3.new(60, 0, -220)
local ALTO_TORRE = 32
for _, x in { -5, 5 } do
	for _, z in { -5, 5 } do
		parte(tobogan, "Poste", Vector3.new(1, ALTO_TORRE, 1), CFrame.new(TORRE + Vector3.new(x, ALTO_TORRE / 2, z)), AZUL, Enum.Material.Metal)
	end
end
parte(tobogan, "Plataforma", Vector3.new(12, 1, 12), CFrame.new(TORRE + Vector3.new(0, ALTO_TORRE - 0.5, 0)), AMARILLO, Enum.Material.WoodPlanks)
parte(tobogan, "Techo", Vector3.new(13, 0.5, 13), CFrame.new(TORRE + Vector3.new(0, ALTO_TORRE + 8, 0)), ROJO)
for _, x in { -5.5, 5.5 } do
	for _, z in { -5.5, 5.5 } do
		parte(tobogan, "Columna", Vector3.new(0.5, 8, 0.5), CFrame.new(TORRE + Vector3.new(x, ALTO_TORRE + 4, z)), BLANCO, Enum.Material.Metal)
	end
end
-- Baranda: al norte y al oeste entera, al sur con un hueco para la escalera (al este esta el tobogan)
parte(tobogan, "Baranda", Vector3.new(12, 3, 0.4), CFrame.new(TORRE + Vector3.new(0, ALTO_TORRE + 1.5, 5.8)), BLANCO, Enum.Material.Metal)
parte(tobogan, "Baranda", Vector3.new(0.4, 3, 12), CFrame.new(TORRE + Vector3.new(-5.8, ALTO_TORRE + 1.5, 0)), BLANCO, Enum.Material.Metal)
for _, x in { -3.75, 3.75 } do
	parte(tobogan, "Baranda", Vector3.new(4.5, 3, 0.4), CFrame.new(TORRE + Vector3.new(x, ALTO_TORRE + 1.5, -5.8)), BLANCO, Enum.Material.Metal)
end
local escalera = Instance.new("TrussPart")
escalera.Name = "Escalera"
escalera.Size = Vector3.new(2, ALTO_TORRE, 2)
escalera.CFrame = CFrame.new(TORRE + Vector3.new(0, SUELO + ALTO_TORRE / 2, -7))
escalera.Color = BLANCO
escalera.Anchored = true
escalera.Parent = tobogan
cartel(tobogan, TORRE + Vector3.new(4, SUELO, -10), Vector3.new(0, 0, -1), "🛝 TOBOGÁN", AZUL)

-- Donde te tiras: un cuadrado verde en el borde de la plataforma que da al tobogan
local largada = parte(tobogan, "Largada", Vector3.new(3, 0.2, 4), CFrame.new(TORRE + Vector3.new(4.2, ALTO_TORRE + 0.1, 0)), VERDE, Enum.Material.Neon, nil, false)

---------------------------------------------------------------- Subir a un juego

local montados = {} -- jugador -> true mientras esta en un juego

-- Carrito de la montaña rusa, pegado al jugador (en coordenadas del jugador: el frente es -Z)
local function carrito(raiz)
	local modelo = Instance.new("Model")
	modelo.Name = "Carrito"
	local color = COLORES[azar:NextInteger(1, #COLORES)]
	local piezas = {
		{ "Chasis", Vector3.new(3, 0.7, 3.6), CFrame.new(0, -1.95, 0.2), GRIS },
		{ "Asiento", Vector3.new(3.2, 0.6, 3.8), CFrame.new(0, -1.3, 0.2), Color3.fromRGB(30, 30, 30) },
		{ "Lado", Vector3.new(0.3, 1.4, 4.2), CFrame.new(-1.6, -0.9, 0.2), color },
		{ "Lado", Vector3.new(0.3, 1.4, 4.2), CFrame.new(1.6, -0.9, 0.2), color },
		{ "Frente", Vector3.new(3.5, 1.6, 0.4), CFrame.new(0, -0.8, -1.9), color },
		{ "Respaldo", Vector3.new(3.5, 2.4, 0.4), CFrame.new(0, -0.4, 2.3), color },
		{ "Barra", Vector3.new(3, 0.25, 0.25), CFrame.new(0, -0.1, -1.2), Color3.fromRGB(200, 200, 205) },
	}
	for _, datos in piezas do
		local p = parte(modelo, datos[1], datos[2], raiz.CFrame * datos[3], datos[4], Enum.Material.SmoothPlastic, nil, false)
		p.Anchored = false
		p.Massless = true
		p.CanQuery = false
		p.CanTouch = false
		local soldadura = Instance.new("WeldConstraint")
		soldadura.Part0 = raiz
		soldadura.Part1 = p
		soldadura.Parent = p
	end
	modelo.Parent = raiz.Parent
	return modelo
end

local function montar(jugador, id)
	local personaje = jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if montados[jugador] or not raiz or not humanoide or humanoide.Health <= 0 or humanoide.SeatPart then
		return
	end
	montados[jugador] = true
	local recorrido = Recorridos.Lista[id]
	local extra = id == "MontanaRusa" and carrito(raiz) or nil
	subir:FireClient(jugador, id)

	task.delay(Recorridos.muestras(id).duracion + 0.4, function()
		montados[jugador] = nil
		if extra then
			extra:Destroy()
		end
		local monedas = monedasDe(jugador)
		if monedas and jugador.Character == personaje and humanoide.Health > 0 then
			monedas.Value += recorrido.premio
			avisar(jugador, string.format("¡Qué viaje! %s: +%d monedas", recorrido.nombre, recorrido.premio), true)
		end
	end)
end

boton(cartelMontana, "Subir", "🎢 Montaña rusa", 12).Triggered:Connect(function(jugador)
	montar(jugador, "MontanaRusa")
end)
boton(largada, "Tirarse", "🛝 Tobogán gigante", 8).Triggered:Connect(function(jugador)
	montar(jugador, "Tobogan")
end)

Players.PlayerRemoving:Connect(function(jugador)
	montados[jugador] = nil
end)

---------------------------------------------------------------- Trampolines

local trampolines = Instance.new("Folder")
trampolines.Name = "Trampolines"
trampolines.Parent = carpeta

local function trampolin(x, z, diametro, color, potencia)
	parte(trampolines, "Marco", Vector3.new(1, diametro + 1, diametro + 1), CFrame.new(x, SUELO + 0.9, z) * PARADO, Color3.fromRGB(40, 40, 45), Enum.Material.Metal, Enum.PartType.Cylinder)
	local lona = parte(trampolines, "Lona", Vector3.new(0.3, diametro, diametro), CFrame.new(x, SUELO + 1.45, z) * PARADO, color, Enum.Material.Fabric, Enum.PartType.Cylinder)
	lona:SetAttribute("Potencia", potencia)
	CollectionService:AddTag(lona, "Trampolin") -- Diversiones.client.lua hace rebotar
	return lona
end
for i, lugar in { { 35, -288 }, { 55, -290 }, { 75, -288 }, { 45, -308 }, { 65, -310 }, { 85, -308 } } do
	trampolin(lugar[1], lugar[2], 9, COLORES[i], POTENCIA_TRAMPOLIN)
end
cartel(trampolines, Vector3.new(30, SUELO, -276), Vector3.new(0, 0, 1), "🤸 TRAMPOLINES", VERDE)

-- Super trampolin y la plataforma alta con el cofre
local SUPER = Vector3.new(40, 0, -332)
trampolin(SUPER.X, SUPER.Z, 11, Color3.fromRGB(255, 190, 0), POTENCIA_SUPER)
cartel(trampolines, SUPER + Vector3.new(-9, SUELO, 0), Vector3.new(0, 0, 1), "🚀 SÚPER SALTO", Color3.fromRGB(230, 120, 0))
local ALTO_PLATAFORMA = 48
local plataforma = parte(trampolines, "PlataformaAlta", Vector3.new(16, 1, 16), CFrame.new(SUPER.X, ALTO_PLATAFORMA - 0.5, SUPER.Z + 15), Color3.fromRGB(120, 200, 255), Enum.Material.Glass)
plataforma.Transparency = 0.2
local cofre = parte(trampolines, "Cofre", Vector3.new(3, 2, 2), CFrame.new(SUPER.X, ALTO_PLATAFORMA + 1, SUPER.Z + 19), Color3.fromRGB(140, 80, 30), Enum.Material.Wood)
parte(trampolines, "TapaCofre", Vector3.new(3.1, 0.4, 2.1), CFrame.new(SUPER.X, ALTO_PLATAFORMA + 2.2, SUPER.Z + 19), AMARILLO, Enum.Material.Metal)
local brillo = Instance.new("Sparkles")
brillo.SparkleColor = AMARILLO
brillo.Parent = cofre
-- Para bajar: un tubo azul que te deja en el piso
local bajar = parte(trampolines, "Bajar", Vector3.new(4, 0.3, 4), CFrame.new(SUPER.X + 5, ALTO_PLATAFORMA + 0.15, SUPER.Z + 11), AZUL, Enum.Material.Neon, nil, false)

boton(cofre, "Abrir cofre", "🎁 Premio del súper salto", 8).Triggered:Connect(function(jugador)
	local ahora = Workspace:GetServerTimeNow()
	local listo = jugador:GetAttribute("CofreDiversionesListo") or 0
	if ahora < listo then
		avisar(jugador, string.format("El cofre se vuelve a llenar en %d min", math.ceil((listo - ahora) / 60)), false)
		return
	end
	local monedas = monedasDe(jugador)
	if monedas then
		monedas.Value += PREMIO_COFRE
		jugador:SetAttribute("CofreDiversionesListo", ahora + ESPERA_COFRE)
		avisar(jugador, string.format("¡Llegaste con el súper salto! +%d monedas", PREMIO_COFRE), true)
	end
end)
boton(bajar, "Bajar", "Volver al piso", 8).Triggered:Connect(function(jugador)
	local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
	if raiz then
		jugador.Character:PivotTo(CFrame.new(SUPER + Vector3.new(-6, SUELO + 4, 8)))
	end
end)

---------------------------------------------------------------- Rueda gigante

local rueda = Instance.new("Folder")
rueda.Name = "RuedaGigante"
rueda.Parent = carpeta

local EJE = Vector3.new(0, 28, -322)
local RADIO = 20
local RAYOS = 12
local CABINAS = 8

-- Patas en forma de A a cada lado de la rueda
for _, z in { -4, 4 } do
	for _, lado in { -1, 1 } do
		local pie = Vector3.new(lado * 14, SUELO, EJE.Z + z)
		local arriba = EJE + Vector3.new(0, 0, z)
		local largo = (arriba - pie).Magnitude
		parte(rueda, "Pata", Vector3.new(1, 1, largo), CFrame.lookAt((pie + arriba) / 2, arriba), BLANCO, Enum.Material.Metal)
	end
end
parte(rueda, "Eje", Vector3.new(2, 2, 9), CFrame.new(EJE) * DE_FRENTE, GRIS, Enum.Material.Metal, Enum.PartType.Cylinder)

-- Lo que gira: aro y rayos. Se guarda cada pieza con su lugar relativo al eje.
local giran = {}
local function pieza(nombre, tamano, relativo, color, material)
	local p = parte(rueda, nombre, tamano, CFrame.new(EJE) * relativo, color, material or Enum.Material.Metal, nil, false)
	table.insert(giran, { parte = p, relativo = relativo })
	return p
end
local SEGMENTOS = 24
for i = 0, SEGMENTOS - 1 do
	local angulo = (i + 0.5) / SEGMENTOS * math.pi * 2
	local largo = 2 * RADIO * math.sin(math.pi / SEGMENTOS) + 0.3
	local aro = pieza("Aro", Vector3.new(largo, 0.8, 0.8), CFrame.Angles(0, 0, angulo) * CFrame.new(0, RADIO, 0), COLORES[i % #COLORES + 1], Enum.Material.Neon)
	CollectionService:AddTag(aro, "LuzDeNoche")
end
for i = 0, RAYOS - 1 do
	local angulo = i / RAYOS * math.pi * 2
	pieza("Rayo", Vector3.new(0.4, RADIO, 0.4), CFrame.Angles(0, 0, angulo) * CFrame.new(0, RADIO / 2, 0), BLANCO)
end

-- Cabinas colgando, siempre derechas
local cabinas = {}
for i = 1, CABINAS do
	local color = COLORES[(i - 1) % #COLORES + 1]
	local modelo = Instance.new("Model")
	modelo.Name = "Cabina"
	parte(modelo, "Piso", Vector3.new(4, 0.4, 3), CFrame.new(0, -3, 0), color, Enum.Material.SmoothPlastic, nil, false)
	parte(modelo, "Frente", Vector3.new(4, 1.2, 0.3), CFrame.new(0, -2.3, -1.4), color, Enum.Material.SmoothPlastic, nil, false)
	parte(modelo, "Atras", Vector3.new(4, 1.2, 0.3), CFrame.new(0, -2.3, 1.4), color, Enum.Material.SmoothPlastic, nil, false)
	parte(modelo, "Techo", Vector3.new(4.4, 0.3, 3.4), CFrame.new(0, 0.2, 0), color, Enum.Material.SmoothPlastic, nil, false)
	parte(modelo, "Colgante", Vector3.new(0.3, 3, 0.3), CFrame.new(0, -1.3, 0), GRIS, Enum.Material.Metal, nil, false)
	modelo.WorldPivot = CFrame.new()
	modelo.Parent = rueda
	table.insert(cabinas, { modelo = modelo, angulo = (i - 1) / CABINAS * math.pi * 2 })
end

local giro = 0
RunService.Heartbeat:Connect(function(dt)
	giro += VELOCIDAD_RUEDA * dt
	local centro = CFrame.new(EJE)
	for _, g in giran do
		g.parte.CFrame = centro * CFrame.Angles(0, 0, giro) * g.relativo
	end
	for _, c in cabinas do
		local a = c.angulo + giro
		c.modelo:PivotTo(CFrame.new(EJE + Vector3.new(-math.sin(a) * RADIO, math.cos(a) * RADIO, 0)))
	end
end)
