-- Dos mansiones de lujo al fondo del Barrio (PlanoCiudad.BARRIO.MANSIONES), abiertas
-- para todos: la Mansion Dorada (blanca y dorada) y la Mansion Diamante (moderna,
-- oscura con luces celestes). Las dos tienen la misma forma:
--   * Afuera: cerco con porton y cartel, camino con faroles, pileta de verdad (agua de
--     Terrain, se puede nadar) con reposeras, fuente, un deportivo estacionado y arboles.
--   * Planta baja: living con sillon, tele gigante, araña de cristales, piano,
--     comedor y cocina con isla. Una escalera sube al primer piso.
--   * Primer piso: dormitorio con cama king, bañera dorada, sala de juegos con
--     maquinitas, placard, balcon sobre la entrada y una caja fuerte con premio
--     (una vez cada 10 minutos por jugador).
-- Todo se arma en coordenadas del terreno: origen en el centro, el frente (la calle)
-- hacia -Z, igual que los terrenos de Casas.server.lua.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ModelosAutos = require(script.Parent:WaitForChild("ModelosAutos"))
local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))

local B = Plano.BARRIO
local SUELO = 0.3
local PREMIO_CAJA = 100
local ESPERA_CAJA = 10 * 60

-- Medidas de la casa (en coordenadas de la casa: piso de la planta baja en y = 0)
local ANCHO, FONDO = 44, 30 -- de -22 a 22 y de -15 a 15
local GROSOR = 0.8
local ALTO_PISO = 12.8 -- donde esta el piso del primer piso
local ALTO_TOTAL = 25.6
local PUERTA = 5 -- medio ancho de la entrada (y de la salida al balcon)
local ESCALERA_X, ESCALERA_ANCHO = -18.7, 5
local ESCALERA_DESDE, ESCALERA_HASTA = -11.7, 11.7 -- sube hacia el fondo
local ESCALONES = 13

local PARADO = CFrame.Angles(0, 0, math.rad(90)) -- los cilindros van a lo largo de X

local ESTILOS = {
	{
		nombre = "🏰 MANSIÓN DORADA",
		pared = Color3.fromRGB(245, 240, 228),
		materialPared = Enum.Material.Marble,
		borde = Color3.fromRGB(240, 190, 50),
		materialBorde = Enum.Material.Foil,
		piso = Color3.fromRGB(240, 235, 225),
		pisoArriba = Color3.fromRGB(170, 115, 70),
		acento = Color3.fromRGB(255, 215, 90),
		sillon = Color3.fromRGB(250, 248, 240),
		alfombra = Color3.fromRGB(170, 30, 45),
		auto = Color3.fromRGB(230, 180, 40),
		ventanaAncho = 10,
		ventanaAlto = 6,
	},
	{
		nombre = "💎 MANSIÓN DIAMANTE",
		pared = Color3.fromRGB(55, 60, 72),
		materialPared = Enum.Material.SmoothPlastic,
		borde = Color3.fromRGB(80, 220, 255),
		materialBorde = Enum.Material.Neon,
		piso = Color3.fromRGB(215, 220, 228),
		pisoArriba = Color3.fromRGB(120, 85, 60),
		acento = Color3.fromRGB(130, 230, 255),
		sillon = Color3.fromRGB(40, 45, 55),
		alfombra = Color3.fromRGB(30, 110, 170),
		auto = Color3.fromRGB(40, 150, 255),
		ventanaAncho = 14,
		ventanaAlto = 8,
	},
}

local carpeta = Instance.new("Folder")
carpeta.Name = "Mansiones"
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

local function luz(p, rango, brillo, color)
	local l = Instance.new("PointLight")
	l.Range = rango
	l.Brightness = brillo
	l.Color = color or Color3.fromRGB(255, 235, 190)
	l.Parent = p
	return l
end

local aviso
local function avisar(jugador, texto, ok)
	aviso = aviso or ReplicatedStorage:FindFirstChild("AvisoTienda")
	if aviso then
		aviso:FireClient(jugador, texto, ok)
	end
end

-- Caja fuerte: premio una vez cada ESPERA_CAJA por jugador y por mansion
local function abrirCaja(jugador, indice)
	local monedas = jugador:FindFirstChild("leaderstats") and jugador.leaderstats:FindFirstChild("Monedas")
	if not monedas then
		return
	end
	local atributo = "CajaMansion" .. indice .. "Lista"
	local ahora = Workspace:GetServerTimeNow()
	local lista = jugador:GetAttribute(atributo) or 0
	if ahora < lista then
		local falta = math.ceil(lista - ahora)
		avisar(jugador, string.format("La caja fuerte se vuelve a llenar en %d:%02d", math.floor(falta / 60), falta % 60), false)
		return
	end
	jugador:SetAttribute(atributo, ahora + ESPERA_CAJA)
	monedas.Value += PREMIO_CAJA
	avisar(jugador, string.format("💰 ¡Abriste la caja fuerte de la mansión! +%d monedas", PREMIO_CAJA), true)
end

---------------------------------------------------------------- Afuera

local function arbol(padre, cf)
	local alto = 7
	parte(padre, "Tronco", Vector3.new(alto, 1.6, 1.6), cf * CFrame.new(0, SUELO + alto / 2, 0) * PARADO, Color3.fromRGB(110, 75, 45), Enum.Material.Wood, Enum.PartType.Cylinder)
	parte(padre, "Hojas", Vector3.one * 9, cf * CFrame.new(0, SUELO + alto + 2.5, 0), Color3.fromRGB(45, 135, 55), Enum.Material.Grass, Enum.PartType.Ball)
end

local function palmera(padre, cf)
	local alto = 11
	parte(padre, "Tronco", Vector3.new(alto, 1.2, 1.2), cf * CFrame.new(0, SUELO + alto / 2, 0) * PARADO, Color3.fromRGB(150, 110, 70), Enum.Material.Wood, Enum.PartType.Cylinder)
	for i = 0, 5 do
		local giro = CFrame.Angles(0, i / 6 * math.pi * 2, 0)
		parte(padre, "Hoja", Vector3.new(1.6, 0.3, 6), cf * CFrame.new(0, SUELO + alto, 0) * giro * CFrame.new(0, -0.6, 2.8) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(60, 160, 60), Enum.Material.Grass, nil, false)
	end
end

local function reposera(padre, cf, color)
	parte(padre, "Reposera", Vector3.new(2.4, 0.4, 6), cf * CFrame.new(0, SUELO + 1, 0), color, Enum.Material.Fabric)
	parte(padre, "Respaldo", Vector3.new(2.4, 0.4, 2.6), cf * CFrame.new(0, SUELO + 1.9, 2.6) * CFrame.Angles(math.rad(-50), 0, 0), color, Enum.Material.Fabric)
	parte(padre, "Patas", Vector3.new(2, 0.8, 5), cf * CFrame.new(0, SUELO + 0.4, 0), Color3.fromRGB(240, 240, 240), Enum.Material.Metal)
end

local function sombrilla(padre, cf, color)
	parte(padre, "Palo", Vector3.new(8, 0.3, 0.3), cf * CFrame.new(0, SUELO + 4, 0) * PARADO, Color3.fromRGB(240, 240, 240), Enum.Material.Metal, Enum.PartType.Cylinder)
	parte(padre, "Tela", Vector3.new(0.6, 8, 8), cf * CFrame.new(0, SUELO + 8, 0) * PARADO, color, Enum.Material.Fabric, Enum.PartType.Cylinder, false)
end

-- Cerco bajo entre dos puntos del terreno (a lo largo de X o de Z), con postes
local function cerco(padre, desde, hasta, estilo)
	local medio = (desde + hasta) / 2
	local largo = (hasta - desde).Magnitude
	local alongX = math.abs(hasta.X - desde.X) > math.abs(hasta.Z - desde.Z)
	local tamano = alongX and Vector3.new(largo, 3, 0.6) or Vector3.new(0.6, 3, largo)
	parte(padre, "Cerco", tamano, CFrame.new(medio.X, SUELO + 1.5, medio.Z), estilo.pared, estilo.materialPared)
	local tapa = alongX and Vector3.new(largo, 0.3, 0.9) or Vector3.new(0.9, 0.3, largo)
	parte(padre, "Tapa", tapa, CFrame.new(medio.X, SUELO + 3.15, medio.Z), estilo.borde, estilo.materialBorde)
end

local function afuera(m, L, estilo, indice)
	-- Pasto mas verde del terreno y el camino de entrada
	parte(m, "Jardin", Vector3.new(95, 0.1, 61), L * CFrame.new(0, SUELO + 0.05, 0), Color3.fromRGB(95, 185, 80), Enum.Material.Grass, nil, false)
	parte(m, "Camino", Vector3.new(10, 0.12, 19), L * CFrame.new(0, SUELO + 0.06, -21.5), estilo.piso, Enum.Material.Slate, nil, false)

	-- Cerco alrededor (en coordenadas del terreno, despues se pasa al mundo con L)
	local cercoModelo = Instance.new("Model")
	cercoModelo.Name = "Cerco"
	cercoModelo.Parent = m
	local tramos = {
		{ Vector3.new(-48, 0, -30.7), Vector3.new(-7.5, 0, -30.7) },
		{ Vector3.new(7.5, 0, -30.7), Vector3.new(48, 0, -30.7) },
		{ Vector3.new(-48, 0, 30.7), Vector3.new(48, 0, 30.7) },
		{ Vector3.new(-47.7, 0, -31), Vector3.new(-47.7, 0, 31) },
		{ Vector3.new(47.7, 0, -31), Vector3.new(47.7, 0, 31) },
	}
	for _, tramo in tramos do
		cerco(cercoModelo, tramo[1], tramo[2], estilo)
	end
	cercoModelo:PivotTo(L * cercoModelo:GetPivot())

	-- Porton con el cartel
	for _, lado in { -1, 1 } do
		parte(m, "Pilar", Vector3.new(2, 9, 2), L * CFrame.new(lado * 7, SUELO + 4.5, -30.7), estilo.pared, estilo.materialPared)
		local bocha = parte(m, "Bocha", Vector3.new(1.8, 1.8, 1.8), L * CFrame.new(lado * 7, SUELO + 9.9, -30.7), estilo.acento, Enum.Material.Neon, Enum.PartType.Ball, false)
		CollectionService:AddTag(bocha, "LuzDeNoche")
	end
	parte(m, "Arco", Vector3.new(16, 1.4, 1.2), L * CFrame.new(0, SUELO + 9.6, -30.7), estilo.borde, estilo.materialBorde)
	local cartel = parte(m, "Cartel", Vector3.new(14, 3.2, 0.4), L * CFrame.new(0, SUELO + 12, -30.7), estilo.pared, estilo.materialPared)
	escribir(cartel, Enum.NormalId.Front, estilo.nombre, estilo.borde)
	escribir(cartel, Enum.NormalId.Back, estilo.nombre, estilo.borde)

	-- Faroles a los dos lados del camino
	for _, z in { -27, -19 } do
		for _, lado in { -1, 1 } do
			parte(m, "Poste", Vector3.new(0.4, 6, 0.4), L * CFrame.new(lado * 6.5, SUELO + 3, z), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
			local farol = parte(m, "Farol", Vector3.new(1.4, 1.4, 1.4), L * CFrame.new(lado * 6.5, SUELO + 6.6, z), estilo.acento, Enum.Material.Neon, Enum.PartType.Ball, false)
			luz(farol, 16, 1, estilo.acento)
			CollectionService:AddTag(farol, "LuzDeNoche")
		end
	end

	-- Pileta: agua de Terrain de x 16 a 40 y de z -24 a -8 (alineada a la grilla de 4
	-- del Terrain), con borde, piso de azulejos y escalon para subir
	local centroAgua = L * CFrame.new(28, 2, -16)
	parte(m, "Azulejos", Vector3.new(24, 0.2, 16), L * CFrame.new(28, SUELO + 0.1, -16), Color3.fromRGB(90, 190, 230), Enum.Material.SmoothPlastic)
	Workspace.Terrain:FillBlock(CFrame.new(centroAgua.Position), Vector3.new(24, 4, 16), Enum.Material.Water)
	for _, borde in {
		{ Vector3.new(26, 4.4, 1), Vector3.new(28, 2.2, -24.5) },
		{ Vector3.new(26, 4.4, 1), Vector3.new(28, 2.2, -7.5) },
		{ Vector3.new(1, 4.4, 16), Vector3.new(15.5, 2.2, -16) },
		{ Vector3.new(1, 4.4, 16), Vector3.new(40.5, 2.2, -16) },
	} do
		parte(m, "BordePileta", borde[1], L * CFrame.new(borde[2]), Color3.fromRGB(245, 245, 245), Enum.Material.Marble)
	end
	parte(m, "Escalon", Vector3.new(6, 2.2, 2), L * CFrame.new(28, 1.1, -26), Color3.fromRGB(245, 245, 245), Enum.Material.Marble)
	parte(m, "Trampolin", Vector3.new(2, 0.4, 6), L * CFrame.new(28, 4.6, -11), estilo.borde, estilo.materialBorde)
	for _, z in { -20, -13 } do
		reposera(m, L * CFrame.new(44, 0, z), estilo.alfombra)
	end
	sombrilla(m, L * CFrame.new(44, 0, -27), estilo.borde)
	palmera(m, L * CFrame.new(12, 0, -27))

	-- Fuente del otro lado del camino
	local fuente = L * CFrame.new(-18, 0, -21)
	parte(m, "Fuente", Vector3.new(1.4, 10, 10), fuente * CFrame.new(0, SUELO + 0.7, 0) * PARADO, Color3.fromRGB(235, 235, 235), Enum.Material.Marble, Enum.PartType.Cylinder)
	local agua = parte(m, "Agua", Vector3.new(0.2, 8.8, 8.8), fuente * CFrame.new(0, SUELO + 1.35, 0) * PARADO, Color3.fromRGB(80, 170, 240), Enum.Material.Glass, Enum.PartType.Cylinder, false)
	agua.Transparency = 0.3
	parte(m, "Columna", Vector3.new(3.4, 1.2, 1.2), fuente * CFrame.new(0, SUELO + 2.4, 0) * PARADO, Color3.fromRGB(235, 235, 235), Enum.Material.Marble, Enum.PartType.Cylinder)
	local plato = parte(m, "Plato", Vector3.new(0.5, 4, 4), fuente * CFrame.new(0, SUELO + 4.2, 0) * PARADO, estilo.borde, estilo.materialBorde, Enum.PartType.Cylinder)
	local chorro = Instance.new("ParticleEmitter")
	chorro.Color = ColorSequence.new(Color3.fromRGB(190, 230, 255))
	chorro.Speed = NumberRange.new(10, 13)
	chorro.SpreadAngle = Vector2.new(15, 15)
	chorro.Acceleration = Vector3.new(0, -30, 0)
	chorro.Lifetime = NumberRange.new(0.8, 1)
	chorro.Size = NumberSequence.new(0.4)
	chorro.Rate = 60
	chorro.Parent = plato

	-- Deportivo estacionado (de adorno)
	local auto = ModelosAutos.crear("deportivo", estilo.auto)
	auto.Name = "AutoMansion"
	auto:PivotTo(L * CFrame.new(-36, SUELO, -18))
	auto.Parent = m

	-- Arboles al fondo, a los costados de la casa
	for _, x in { -40, -30, 30, 40 } do
		arbol(m, L * CFrame.new(x, 0, 25))
	end
end

---------------------------------------------------------------- La casa

local function ventana(m, cf, tamano)
	local vidrio = parte(m, "Ventana", tamano, cf, Color3.fromRGB(150, 210, 240), Enum.Material.Glass, nil, false)
	vidrio.Transparency = 0.2
	return vidrio
end

local function casa(m, H, estilo, indice)
	local function muro(nombre, tamano, posicion)
		return parte(m, nombre, tamano, H * CFrame.new(posicion), estilo.pared, estilo.materialPared)
	end
	local function borde(nombre, tamano, posicion)
		return parte(m, nombre, tamano, H * CFrame.new(posicion), estilo.borde, estilo.materialBorde)
	end
	local medioAlto = ALTO_TOTAL / 2
	local fz = -FONDO / 2 + GROSOR / 2 -- la pared del frente

	-- Base de marmol (es el piso de la planta baja) y la galeria de la entrada
	parte(m, "Base", Vector3.new(ANCHO + 4, 1, FONDO + 4), H * CFrame.new(0, -0.5, 0), estilo.piso, Enum.Material.Marble)
	parte(m, "Galeria", Vector3.new(18, 1, 7), H * CFrame.new(0, -0.5, -FONDO / 2 - 3.5), estilo.piso, Enum.Material.Marble)
	parte(m, "Escalon", Vector3.new(10, 0.5, 1.5), H * CFrame.new(0, -0.75, -FONDO / 2 - 7.75), estilo.piso, Enum.Material.Marble)

	-- Paredes
	muro("Pared", Vector3.new(ANCHO, ALTO_TOTAL, GROSOR), Vector3.new(0, medioAlto, FONDO / 2 - GROSOR / 2))
	for _, lado in { -1, 1 } do
		muro("Pared", Vector3.new(GROSOR, ALTO_TOTAL, FONDO), Vector3.new(lado * (ANCHO / 2 - GROSOR / 2), medioAlto, 0))
		local tramo = ANCHO / 2 - PUERTA
		muro("Frente", Vector3.new(tramo, ALTO_TOTAL, GROSOR), Vector3.new(lado * (PUERTA + tramo / 2), medioAlto, fz))
	end
	-- Arriba de la entrada y arriba de la salida al balcon
	muro("Frente", Vector3.new(PUERTA * 2, 2.8, GROSOR), Vector3.new(0, 11.4, fz))
	muro("Frente", Vector3.new(PUERTA * 2, 2.8, GROSOR), Vector3.new(0, ALTO_TOTAL - 1.4, fz))

	-- Ventanas (vidrio de los dos lados de la pared), en los dos pisos
	local va, vh = estilo.ventanaAncho, estilo.ventanaAlto
	for _, y in { 5.5, ALTO_PISO + 6 } do
		for _, lado in { -1, 1 } do
			for _, z in { -FONDO / 2 - 0.03, -FONDO / 2 + GROSOR + 0.03 } do
				ventana(m, H * CFrame.new(lado * 13.5, y, z), Vector3.new(va, vh, 0.1))
			end
			for _, z in { FONDO / 2 + 0.03, FONDO / 2 - GROSOR - 0.03 } do
				ventana(m, H * CFrame.new(lado * 10, y + 1, z), Vector3.new(va * 0.8, vh * 0.7, 0.1))
			end
			for _, x in { ANCHO / 2 + 0.03, ANCHO / 2 - GROSOR - 0.03 } do
				for _, z in { -7, 7 } do
					ventana(m, H * CFrame.new(lado * x, y, z), Vector3.new(0.1, vh, va * 0.8))
				end
			end
		end
	end

	-- Piso del primer piso, con el agujero de la escalera
	local xAgujero = ESCALERA_X + ESCALERA_ANCHO / 2 + 0.2 -- -16
	local anchoA = ANCHO / 2 - xAgujero
	parte(m, "PisoArriba", Vector3.new(anchoA, 0.8, FONDO), H * CFrame.new(xAgujero + anchoA / 2, ALTO_PISO - 0.4, 0), estilo.pisoArriba, Enum.Material.WoodPlanks)
	local fondoB = FONDO / 2 - ESCALERA_HASTA
	parte(m, "PisoArriba", Vector3.new(xAgujero + ANCHO / 2, 0.8, fondoB), H * CFrame.new((xAgujero - ANCHO / 2) / 2, ALTO_PISO - 0.4, ESCALERA_HASTA + fondoB / 2), estilo.pisoArriba, Enum.Material.WoodPlanks)
	local baranda = ventana(m, H * CFrame.new(xAgujero + 0.1, ALTO_PISO + 1.5, (-FONDO / 2 + ESCALERA_HASTA) / 2), Vector3.new(0.2, 3, ESCALERA_HASTA + FONDO / 2))
	baranda.CanCollide = true
	baranda.Transparency = 0.5
	borde("Pasamanos", Vector3.new(0.3, 0.3, ESCALERA_HASTA + FONDO / 2), Vector3.new(xAgujero + 0.1, ALTO_PISO + 3.1, (-FONDO / 2 + ESCALERA_HASTA) / 2))

	-- Escalera
	local paso = (ESCALERA_HASTA - ESCALERA_DESDE) / ESCALONES
	for i = 1, ESCALONES do
		local alto = i * ALTO_PISO / ESCALONES
		parte(m, "Escalon", Vector3.new(ESCALERA_ANCHO, alto, paso), H * CFrame.new(ESCALERA_X, alto / 2, ESCALERA_DESDE + (i - 0.5) * paso), estilo.piso, Enum.Material.Marble)
	end

	-- Techo con baranda de color arriba
	parte(m, "Techo", Vector3.new(ANCHO + 2, 0.8, FONDO + 2), H * CFrame.new(0, ALTO_TOTAL - 0.4, 0), estilo.pared, estilo.materialPared)
	for _, lado in { -1, 1 } do
		borde("Parapeto", Vector3.new(ANCHO + 2, 2, 0.6), Vector3.new(0, ALTO_TOTAL + 1, lado * (FONDO / 2 + 0.7)))
		borde("Parapeto", Vector3.new(0.6, 2, FONDO + 2), Vector3.new(lado * (ANCHO / 2 + 0.7), ALTO_TOTAL + 1, 0))
		-- Franja entre los dos pisos
		borde("Franja", Vector3.new(ANCHO + 0.6, 0.7, 0.3), Vector3.new(0, ALTO_PISO - 0.4, lado * (FONDO / 2 + 0.15)))
		borde("Franja", Vector3.new(0.3, 0.7, FONDO + 0.6), Vector3.new(lado * (ANCHO / 2 + 0.15), ALTO_PISO - 0.4, 0))
	end
	if indice == 1 then
		-- Cupula dorada
		parte(m, "Cupula", Vector3.new(10, 10, 10), H * CFrame.new(0, ALTO_TOTAL, 0), estilo.borde, estilo.materialBorde, Enum.PartType.Ball)
		parte(m, "Punta", Vector3.new(3, 0.6, 0.6), H * CFrame.new(0, ALTO_TOTAL + 6.2, 0) * PARADO, estilo.borde, estilo.materialBorde, Enum.PartType.Cylinder)
	else
		-- Helipuerto
		parte(m, "Helipuerto", Vector3.new(0.2, 16, 16), H * CFrame.new(0, ALTO_TOTAL + 0.1, 0) * PARADO, Color3.fromRGB(70, 75, 85), Enum.Material.Concrete, Enum.PartType.Cylinder)
		local h = parte(m, "H", Vector3.new(8, 0.05, 8), H * CFrame.new(0, ALTO_TOTAL + 0.22, 0), Color3.new(1, 1, 1), nil, nil, false)
		h.Transparency = 1
		escribir(h, Enum.NormalId.Top, "H", estilo.acento)
	end

	-- Balcon sobre la entrada, con columnas abajo
	parte(m, "Balcon", Vector3.new(16, 0.8, 6), H * CFrame.new(0, ALTO_PISO - 0.4, -FONDO / 2 - 3), estilo.pisoArriba, Enum.Material.WoodPlanks)
	borde("Baranda", Vector3.new(16, 0.3, 0.3), Vector3.new(0, ALTO_PISO + 3, -FONDO / 2 - 5.85))
	for _, lado in { -1, 1 } do
		borde("Baranda", Vector3.new(0.3, 0.3, 6), Vector3.new(lado * 7.85, ALTO_PISO + 3, -FONDO / 2 - 3))
		parte(m, "Columna", Vector3.new(ALTO_PISO - 0.8, 1.6, 1.6), H * CFrame.new(lado * 7, (ALTO_PISO - 0.8) / 2, -FONDO / 2 - 5) * PARADO, estilo.pared, estilo.materialPared, Enum.PartType.Cylinder)
	end
	for x = -7.2, 7.2, 1.6 do
		borde("Barrote", Vector3.new(0.2, 3, 0.2), Vector3.new(x, ALTO_PISO + 1.5, -FONDO / 2 - 5.85))
	end
	for _, lado in { -1, 1 } do
		for z = -FONDO / 2 - 0.8, -FONDO / 2 - 5.6, -1.6 do
			borde("Barrote", Vector3.new(0.2, 3, 0.2), Vector3.new(lado * 7.85, ALTO_PISO + 1.5, z))
		end
	end

	-- Puertas de la entrada, abiertas para adentro
	for _, lado in { -1, 1 } do
		parte(m, "Puerta", Vector3.new(0.3, 10, PUERTA - 0.2), H * CFrame.new(lado * (PUERTA - 0.2), 5, fz + GROSOR / 2 + PUERTA / 2), estilo.borde, estilo.materialBorde, nil, false)
	end
end

---------------------------------------------------------------- Muebles

local BLANCO = Color3.fromRGB(245, 245, 245)
local NEGRO = Color3.fromRGB(25, 25, 28)
local MADERA = Color3.fromRGB(120, 80, 50)

local function plantaBaja(m, H, estilo)
	local function p(nombre, tamano, posicion, color, material, forma, colisiona)
		return parte(m, nombre, tamano, H * CFrame.new(posicion), color, material, forma, colisiona)
	end

	-- Alfombra roja (o azul) desde la puerta
	p("Alfombra", Vector3.new(6, 0.1, 13), Vector3.new(0, 0.05, -8), estilo.alfombra, Enum.Material.Fabric, nil, false)

	-- Living: sillon grande mirando a la tele de la pared de la derecha
	p("Alfombra", Vector3.new(14, 0.1, 12), Vector3.new(12, 0.05, -4), Color3.fromRGB(230, 225, 215), Enum.Material.Fabric, nil, false)
	p("Asiento", Vector3.new(3, 1.4, 10), Vector3.new(5, 0.7, -4), estilo.sillon, Enum.Material.Fabric)
	p("Respaldo", Vector3.new(1, 3.6, 10), Vector3.new(3, 1.8, -4), estilo.sillon, Enum.Material.Fabric)
	for _, z in { -9.4, 1.4 } do
		p("Brazo", Vector3.new(4, 2.2, 0.8), Vector3.new(4.5, 1.1, z), estilo.sillon, Enum.Material.Fabric)
	end
	for _, z in { -7, -4, -1 } do
		p("Almohadon", Vector3.new(0.6, 1.6, 1.6), Vector3.new(3.9, 2.2, z), estilo.borde, Enum.Material.Fabric, nil, false)
	end
	p("Mesita", Vector3.new(4, 0.3, 6), Vector3.new(11, 1.4, -4), Color3.fromRGB(180, 220, 240), Enum.Material.Glass)
	p("PieMesita", Vector3.new(3, 1.25, 5), Vector3.new(11, 0.625, -4), estilo.borde, estilo.materialBorde)
	p("Tele", Vector3.new(0.4, 6.4, 11.4), Vector3.new(20.9, 6, -4), NEGRO)
	local pantalla = p("Pantalla", Vector3.new(0.05, 6, 11), Vector3.new(20.67, 6, -4), Color3.fromRGB(70, 150, 255), Enum.Material.Neon, nil, false)
	luz(pantalla, 10, 0.6, Color3.fromRGB(120, 180, 255))
	p("MuebleTele", Vector3.new(2, 1.6, 12), Vector3.new(20, 0.8, -4), MADERA, Enum.Material.Wood)

	-- Araña de cristales en el techo
	local centro = Vector3.new(6, 9.6, -3)
	p("Cadena", Vector3.new(0.2, 2, 0.2), Vector3.new(6, 11, -3), estilo.borde, Enum.Material.Metal, nil, false)
	parte(m, "Aro", Vector3.new(0.4, 6, 6), H * CFrame.new(6, 10, -3) * PARADO, estilo.borde, Enum.Material.Metal, Enum.PartType.Cylinder, false)
	local foco = p("Foco", Vector3.new(1.4, 1.4, 1.4), centro, Color3.fromRGB(255, 245, 220), Enum.Material.Neon, Enum.PartType.Ball, false)
	luz(foco, 45, 2.2)
	for i = 0, 7 do
		local angulo = i / 8 * math.pi * 2
		p("Cristal", Vector3.new(0.6, 0.6, 0.6), Vector3.new(6 + math.cos(angulo) * 3, 9.3, -3 + math.sin(angulo) * 3), Color3.fromRGB(220, 240, 255), Enum.Material.Neon, Enum.PartType.Ball, false)
	end

	-- Piano de cola, adelante a la derecha
	p("Piano", Vector3.new(6, 1.4, 4.4), Vector3.new(15, 3, -11.3), NEGRO, Enum.Material.SmoothPlastic)
	p("Teclado", Vector3.new(5.4, 0.2, 1), Vector3.new(15, 2.5, -8.7), BLANCO)
	for _, x in { 12.6, 17.4 } do
		p("PataPiano", Vector3.new(0.5, 2.3, 0.5), Vector3.new(x, 1.15, -11.3), NEGRO)
	end
	p("Banqueta", Vector3.new(3, 1.6, 1.4), Vector3.new(15, 0.8, -6.8), NEGRO, Enum.Material.Fabric)

	-- Comedor con seis sillas
	p("Mesa", Vector3.new(10, 0.4, 4), Vector3.new(-4, 2.8, 7), BLANCO, Enum.Material.Marble)
	for _, x in { -8, 0 } do
		p("PataMesa", Vector3.new(0.6, 2.6, 2), Vector3.new(x, 1.3, 7), estilo.borde, estilo.materialBorde)
	end
	for _, x in { -8, -4, 0 } do
		for _, lado in { -1, 1 } do
			p("Silla", Vector3.new(1.8, 0.4, 1.8), Vector3.new(x, 1.6, 7 + lado * 3), estilo.sillon, Enum.Material.Fabric)
			p("PataSilla", Vector3.new(1.4, 1.4, 1.4), Vector3.new(x, 0.7, 7 + lado * 3), estilo.borde, estilo.materialBorde)
			p("RespaldoSilla", Vector3.new(1.8, 2.6, 0.3), Vector3.new(x, 3.1, 7 + lado * 3.85), estilo.sillon, Enum.Material.Fabric)
		end
	end
	p("Florero", Vector3.new(0.8, 1.6, 0.8), Vector3.new(-4, 3.8, 7), estilo.borde, estilo.materialBorde)
	p("Flores", Vector3.new(1.8, 1.8, 1.8), Vector3.new(-4, 5, 7), Color3.fromRGB(255, 100, 150), Enum.Material.Grass, Enum.PartType.Ball, false)

	-- Cocina en el fondo a la derecha
	p("Mesada", Vector3.new(13, 3, 2.4), Vector3.new(10.5, 1.5, 13.4), BLANCO, Enum.Material.Marble)
	p("Bacha", Vector3.new(2.4, 0.1, 1.4), Vector3.new(8, 3.03, 13.4), Color3.fromRGB(170, 170, 175), Enum.Material.Metal, nil, false)
	p("Anafe", Vector3.new(3, 0.1, 1.8), Vector3.new(13, 3.03, 13.4), NEGRO, nil, nil, false)
	p("Heladera", Vector3.new(3.5, 8, 2.4), Vector3.new(19.3, 4, 13.4), Color3.fromRGB(200, 200, 205), Enum.Material.Metal)
	p("Isla", Vector3.new(8, 3, 3), Vector3.new(10.5, 1.5, 7), BLANCO, Enum.Material.Marble)
	p("TapaIsla", Vector3.new(8.4, 0.2, 3.4), Vector3.new(10.5, 3.1, 7), estilo.borde, estilo.materialBorde)
	for _, x in { 8, 10.5, 13 } do
		p("Banco", Vector3.new(1.2, 2.2, 1.2), Vector3.new(x, 1.1, 4.4), NEGRO)
	end

	-- Plantas a los lados de la entrada
	for _, lado in { -1, 1 } do
		parte(m, "Maceta", Vector3.new(1.6, 2, 2), H * CFrame.new(lado * 8, 0.8, -12.8) * PARADO, estilo.borde, estilo.materialBorde, Enum.PartType.Cylinder)
		p("Hojas", Vector3.new(3, 3, 3), Vector3.new(lado * 8, 3.2, -12.8), Color3.fromRGB(50, 150, 60), Enum.Material.Grass, Enum.PartType.Ball, false)
	end
end

local function primerPiso(m, H, estilo, indice)
	local F = H * CFrame.new(0, ALTO_PISO, 0)
	local function p(nombre, tamano, posicion, color, material, forma, colisiona)
		return parte(m, nombre, tamano, F * CFrame.new(posicion), color, material, forma, colisiona)
	end

	-- Luces del techo
	for _, posicion in { Vector3.new(4, 11.9, -4), Vector3.new(12, 11.9, 8), Vector3.new(-8, 11.9, 4) } do
		local panel = p("LuzTecho", Vector3.new(5, 0.2, 5), posicion, Color3.fromRGB(255, 245, 225), Enum.Material.Neon, nil, false)
		luz(panel, 30, 1.4)
	end

	-- Dormitorio: cama king contra la pared del fondo
	p("Alfombra", Vector3.new(14, 0.1, 12), Vector3.new(14, 0.05, 7), estilo.alfombra, Enum.Material.Fabric, nil, false)
	p("Cama", Vector3.new(9, 1.4, 9), Vector3.new(14, 0.7, 9.6), MADERA, Enum.Material.Wood)
	p("Colchon", Vector3.new(8.8, 0.8, 8.8), Vector3.new(14, 1.8, 9.6), BLANCO, Enum.Material.Fabric)
	p("Acolchado", Vector3.new(8.9, 0.3, 5.6), Vector3.new(14, 2.3, 8), estilo.borde, Enum.Material.Fabric)
	for _, x in { 11.8, 16.2 } do
		p("Almohada", Vector3.new(3.6, 0.8, 1.6), Vector3.new(x, 2.5, 12.6), BLANCO, Enum.Material.Fabric)
	end
	p("Respaldar", Vector3.new(10, 6, 0.6), Vector3.new(14, 3, 14.3), estilo.borde, estilo.materialBorde)
	for _, x in { 7.6, 20.4 } do
		p("Mesita", Vector3.new(2.2, 2, 2.2), Vector3.new(x, 1, 13), MADERA, Enum.Material.Wood)
		local velador = p("Velador", Vector3.new(1.2, 1.2, 1.2), Vector3.new(x, 2.8, 13), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, Enum.PartType.Ball, false)
		luz(velador, 10, 0.8)
	end

	-- Placard
	p("Placard", Vector3.new(2, 8, 9), Vector3.new(20.2, 4, -6), MADERA, Enum.Material.Wood)
	for _, z in { -7, -5 } do
		p("Manija", Vector3.new(0.2, 1.6, 0.3), Vector3.new(19.1, 4, z), estilo.borde, Enum.Material.Metal, nil, false)
	end

	-- Caja fuerte con premio
	local caja = p("CajaFuerte", Vector3.new(2.6, 3, 2.6), Vector3.new(19.6, 1.5, 2), Color3.fromRGB(70, 75, 85), Enum.Material.DiamondPlate)
	p("Perilla", Vector3.new(0.2, 1, 1), Vector3.new(18.25, 1.8, 2), estilo.borde, Enum.Material.Metal, Enum.PartType.Cylinder, false)
	local brillo = Instance.new("Sparkles")
	brillo.SparkleColor = estilo.acento
	brillo.Parent = caja
	local abrir = Instance.new("ProximityPrompt")
	abrir.ActionText = "Abrir caja fuerte"
	abrir.ObjectText = string.format("+%d monedas", PREMIO_CAJA)
	abrir.MaxActivationDistance = 8
	abrir.RequiresLineOfSight = false
	abrir.Parent = caja
	abrir.Triggered:Connect(function(jugador)
		abrirCaja(jugador, indice)
	end)

	-- Bañera dorada con espuma
	p("Banera", Vector3.new(7, 2.4, 3.8), Vector3.new(-7, 1.2, 12.4), estilo.borde, estilo.materialBorde)
	p("AguaBanera", Vector3.new(6.2, 0.2, 3), Vector3.new(-7, 2.35, 12.4), Color3.fromRGB(120, 200, 255), Enum.Material.Glass, nil, false)
	for i = 0, 4 do
		p("Espuma", Vector3.new(1.2, 1.2, 1.2), Vector3.new(-9.4 + i * 1.2, 2.6, 12.4 + (i % 2 - 0.5) * 0.8), BLANCO, Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)
	end

	-- Sala de juegos: dos maquinitas contra el frente y puffs
	local colores = { Color3.fromRGB(255, 60, 120), Color3.fromRGB(60, 220, 120) }
	for i, x in { -12, -8 } do
		p("Maquinita", Vector3.new(3, 6, 2.4), Vector3.new(x, 3, -13), Color3.fromRGB(35, 35, 60))
		local pantallita = p("Pantallita", Vector3.new(2.4, 2, 0.1), Vector3.new(x, 4.2, -11.75), colores[i], Enum.Material.Neon, nil, false)
		luz(pantallita, 8, 0.8, colores[i])
		p("Botonera", Vector3.new(3, 0.3, 1.2), Vector3.new(x, 2.6, -11.4), NEGRO)
	end
	for i, x in { -12, -8 } do
		p("Puff", Vector3.new(2.6, 2.6, 2.6), Vector3.new(x, 1.1, -7), colores[i], Enum.Material.Fabric, Enum.PartType.Ball)
	end

	-- Balcon: dos reposeras mirando a la calle
	for _, x in { -4, 4 } do
		reposera(m, F * CFrame.new(x, -SUELO, -FONDO / 2 - 3), estilo.alfombra)
	end
end

---------------------------------------------------------------- Armado

for indice, centro in B.MANSIONES do
	local estilo = ESTILOS[indice]
	local frente = Vector3.new(0, 0, centro.Z > 0 and -1 or 1) -- hacia la calle
	local L = CFrame.lookAt(centro, centro + frente)
	local H = L * CFrame.new(0, 1, 10) -- la casa, un poco hacia el fondo y arriba de la base

	local m = Instance.new("Model")
	m.Name = "Mansion" .. indice
	m.Parent = carpeta

	afuera(m, L, estilo, indice)
	casa(m, H, estilo, indice)
	plantaBaja(m, H, estilo)
	primerPiso(m, H, estilo, indice)
end
