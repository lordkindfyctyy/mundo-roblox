-- La Torre: un edificio muy alto en una manzana de la ciudad. Se sube saltando
-- por plataformas que dan vueltas alrededor (como un obby). Arriba hay un cofre
-- con monedas (una vez cada ESPERA_COFRE segundos por jugador) y una plataforma
-- para bajar de un toque. Ciudad.server.lua la pone con Torre.construir.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Torre = {}

local ALTO = 100
local MEDIO_LADO = 8 -- la torre mide 16 x 16
local SUBIDA = 3 -- cuanto sube cada plataforma (se pasa saltando)
local SEPARACION = 7 -- distancia entre plataformas a lo largo del recorrido
local LARGO_PLATAFORMA = 5
local ANCHO_PLATAFORMA = 5
local PREMIO = 300
local ESPERA_COFRE = 10 * 60

local COLORES_PLATAFORMAS = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(255, 180, 60),
	Color3.fromRGB(255, 230, 80),
	Color3.fromRGB(90, 210, 110),
	Color3.fromRGB(70, 160, 255),
	Color3.fromRGB(170, 100, 255),
}

local function parte(padre, nombre, tamano, cframe, color, material, colisiona)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = colisiona ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = padre
	return p
end

local function cartel(padre, cframe, ancho, alto, texto, color)
	local tabla = parte(padre, "Cartel", Vector3.new(ancho, alto, 0.4), cframe, color, Enum.Material.Wood)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = tabla
	local etiqueta = Instance.new("TextLabel")
	etiqueta.Size = UDim2.fromScale(1, 1)
	etiqueta.BackgroundTransparency = 1
	etiqueta.Font = Enum.Font.GothamBlack
	etiqueta.TextScaled = true
	etiqueta.TextColor3 = Color3.new(1, 1, 1)
	etiqueta.Text = texto
	etiqueta.Parent = gui
	return tabla
end

-- Punto del recorrido alrededor de la torre (un cuadrado a distancia radio del centro)
-- y hacia donde avanza ahi. s va de 0 a 8 * radio (el perimetro).
local function puntoDelRecorrido(s, radio)
	local lado = 2 * radio
	s %= 4 * lado
	if s < lado then
		return Vector3.new(-radio + s, 0, -radio), Vector3.new(1, 0, 0)
	elseif s < 2 * lado then
		return Vector3.new(radio, 0, -radio + (s - lado)), Vector3.new(0, 0, 1)
	elseif s < 3 * lado then
		return Vector3.new(radio - (s - 2 * lado), 0, radio), Vector3.new(-1, 0, 0)
	end
	return Vector3.new(-radio, 0, radio - (s - 3 * lado)), Vector3.new(0, 0, -1)
end

local function abrirCofre(jugador)
	local monedas = jugador:FindFirstChild("leaderstats") and jugador.leaderstats:FindFirstChild("Monedas")
	if not monedas then
		return
	end
	local aviso = ReplicatedStorage:FindFirstChild("AvisoTienda")
	local ahora = Workspace:GetServerTimeNow()
	local listo = jugador:GetAttribute("CofreTorreListo") or 0
	if ahora < listo then
		local falta = math.ceil(listo - ahora)
		if aviso then
			aviso:FireClient(jugador, string.format("El cofre se vuelve a llenar en %d:%02d", math.floor(falta / 60), falta % 60), false)
		end
		return
	end
	jugador:SetAttribute("CofreTorreListo", ahora + ESPERA_COFRE)
	monedas.Value += PREMIO
	if aviso then
		aviso:FireClient(jugador, string.format("¡Llegaste a la cima! +%d monedas", PREMIO), true)
	end
end

-- Arma la torre en el centro de la manzana x1..x2, z1..z2. piso: altura de la vereda.
function Torre.construir(padre, x1, x2, z1, z2, piso)
	local modelo = Instance.new("Model")
	modelo.Name = "Torre"
	modelo.Parent = padre

	local centro = Vector3.new((x1 + x2) / 2, piso, (z1 + z2) / 2)
	local base = CFrame.new(centro)

	-- Plaza de cesped alrededor
	parte(modelo, "Plaza", Vector3.new(x2 - x1 - 6, 0.2, z2 - z1 - 6), base * CFrame.new(0, 0.1, 0), Color3.fromRGB(90, 165, 70), Enum.Material.Grass)

	-- El cuerpo de la torre con franjas de colores cada 10
	parte(modelo, "Cuerpo", Vector3.new(MEDIO_LADO * 2, ALTO, MEDIO_LADO * 2), base * CFrame.new(0, ALTO / 2, 0), Color3.fromRGB(70, 75, 95), Enum.Material.Concrete)
	for y = 10, ALTO - 5, 10 do
		parte(modelo, "Franja", Vector3.new(MEDIO_LADO * 2 + 0.4, 1, MEDIO_LADO * 2 + 0.4), base * CFrame.new(0, y, 0), Color3.fromRGB(255, 205, 0), Enum.Material.Neon, false)
	end

	-- Plataformas en espiral: la primera arranca a la altura de un salto
	local radio = MEDIO_LADO + 0.5 + ANCHO_PLATAFORMA / 2
	local cantidad = math.ceil((ALTO - 2) / SUBIDA)
	for i = 1, cantidad do
		local punto, avance = puntoDelRecorrido(i * SEPARACION, radio)
		local y = i * SUBIDA
		local cframe = base * CFrame.lookAt(punto + Vector3.new(0, y, 0), punto + Vector3.new(0, y, 0) + avance)
		local color = COLORES_PLATAFORMAS[(i - 1) % #COLORES_PLATAFORMAS + 1]
		parte(modelo, "Plataforma", Vector3.new(ANCHO_PLATAFORMA, 1, LARGO_PLATAFORMA), cframe, color, Enum.Material.SmoothPlastic)
	end
	-- La terraza es el techo de la torre. La ultima plataforma llega por el lado +Z,
	-- asi que ese lado queda sin baranda.
	local terraza = ALTO
	local medio = MEDIO_LADO - 0.25
	parte(modelo, "Baranda", Vector3.new(MEDIO_LADO * 2, 2, 0.5), base * CFrame.new(0, terraza + 1, -medio), Color3.fromRGB(240, 240, 240), Enum.Material.Metal)
	for _, signo in { -1, 1 } do
		parte(modelo, "Baranda", Vector3.new(0.5, 2, MEDIO_LADO * 2), base * CFrame.new(signo * medio, terraza + 1, 0), Color3.fromRGB(240, 240, 240), Enum.Material.Metal)
	end

	-- Bandera
	parte(modelo, "Mastil", Vector3.new(0.4, 12, 0.4), base * CFrame.new(-5, terraza + 6.5, -5), Color3.fromRGB(200, 200, 200), Enum.Material.Metal)
	parte(modelo, "Bandera", Vector3.new(4, 2.5, 0.1), base * CFrame.new(-3, terraza + 11, -5), Color3.fromRGB(255, 60, 60), Enum.Material.Fabric, false)

	-- Cofre con el premio
	local cofre = parte(modelo, "Cofre", Vector3.new(4, 2.6, 2.6), base * CFrame.new(2, terraza + 1.8, 2), Color3.fromRGB(150, 95, 40), Enum.Material.Wood)
	parte(modelo, "Tapa", Vector3.new(4.2, 0.6, 2.8), base * CFrame.new(2, terraza + 3.4, 2), Color3.fromRGB(255, 205, 0), Enum.Material.Neon, false)
	local brillo = Instance.new("Sparkles")
	brillo.SparkleColor = Color3.fromRGB(255, 220, 80)
	brillo.Parent = cofre
	local abrir = Instance.new("ProximityPrompt")
	abrir.ActionText = "Abrir cofre"
	abrir.ObjectText = string.format("Premio: %d monedas", PREMIO)
	abrir.MaxActivationDistance = 10
	abrir.RequiresLineOfSight = false
	abrir.Parent = cofre
	abrir.Triggered:Connect(function(jugador)
		abrirCofre(jugador)
	end)

	-- Mira hacia +Z, por donde llega el jugador
	cartel(modelo, base * CFrame.new(0, terraza + 4, -medio) * CFrame.Angles(0, math.pi, 0), 14, 2.5, "¡Llegaste a la cima!", Color3.fromRGB(0, 150, 80))

	-- Plataforma para bajar: te deja al pie de la torre
	local bajar = parte(modelo, "Bajar", Vector3.new(4, 0.4, 4), base * CFrame.new(-4, terraza + 0.7, 4), Color3.fromRGB(0, 170, 255), Enum.Material.Neon)
	local botonBajar = Instance.new("ProximityPrompt")
	botonBajar.ActionText = "Bajar"
	botonBajar.ObjectText = "Volver a la calle"
	botonBajar.MaxActivationDistance = 8
	botonBajar.RequiresLineOfSight = false
	botonBajar.Parent = bajar
	local abajo = base * CFrame.new(0, 3, -(MEDIO_LADO + ANCHO_PLATAFORMA + 6))
	botonBajar.Triggered:Connect(function(jugador)
		local personaje = jugador.Character
		if personaje then
			personaje:PivotTo(abajo)
		end
	end)

	-- Cartel en la cara -Z, donde arranca la espiral (arriba de las primeras plataformas)
	cartel(modelo, base * CFrame.new(0, 13, -MEDIO_LADO - 0.3), 12, 4, "TORRE\nSubí y ganá un premio", Color3.fromRGB(220, 40, 50))

	return modelo
end

return Torre
