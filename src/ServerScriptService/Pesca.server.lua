-- Pesca: un muelle que sale de la Playa hacia el mar, con puestos para pescar y el kiosco de
-- la tienda de cañas. Se toca "Pescar" en un puesto, se lanza el corcho, pica a los pocos
-- segundos y hay que tirar a tiempo (Pesca.client.lua). El pez se vende solo.
--
-- Del jugador (los guarda GuardadoMonedas.server.lua): PescaCanas, PescaPeces, PescaTotal
-- (ver ConfigPesca.lua).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConfigPesca = require(ReplicatedStorage:WaitForChild("ConfigPesca"))
local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))

local P = Plano.PLAYA
local ARENA = P.ALTO
local NIVEL_AGUA = P.NIVEL_AGUA
local DISTANCIA_MAXIMA = 14 -- si te alejas tanto del puesto se cancela
local PUESTOS_X = { 296, 308, 320, 332 }
local ANCHO_MUELLE = 9
local Z_MUELLE = -45
local FIN_MUELLE = 342
local ALTO_CUBIERTA = NIVEL_AGUA + 0.5 -- centro de la cubierta (1 de espesor)
local LARGO_LINEA = 8 -- del puesto al corcho, hacia el mar

local azar = Random.new()

local evento = Instance.new("RemoteEvent") -- servidor -> cliente: "espera", "picada", "fin", "pez"
evento.Name = "PescaEvento"
evento.Parent = ReplicatedStorage

local accion = Instance.new("RemoteEvent") -- cliente -> servidor: "tirar", "cancelar"
accion.Name = "PescaAccion"
accion.Parent = ReplicatedStorage

local tienda = Instance.new("RemoteFunction")
tienda.Name = "TiendaPesca"
tienda.Parent = ReplicatedStorage

local abrirTienda = Instance.new("RemoteEvent")
abrirTienda.Name = "AbrirTiendaPesca"
abrirTienda.Parent = ReplicatedStorage

local muelle = Instance.new("Folder")
muelle.Name = "Muelle"
muelle.Parent = Workspace

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
	p.Parent = muelle
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

-- Construccion -------------------------------------------------------------------

local MADERA = Color3.fromRGB(150, 105, 60)
local MADERA_OSCURA = Color3.fromRGB(105, 72, 40)

local inicioMuelle = P.ARENA_X2 - 1
parte("Cubierta", Vector3.new(FIN_MUELLE - inicioMuelle, 1, ANCHO_MUELLE), CFrame.new((inicioMuelle + FIN_MUELLE) / 2, ALTO_CUBIERTA, Z_MUELLE), MADERA, Enum.Material.WoodPlanks)
-- Pilotes hasta el fondo del mar
for x = inicioMuelle + 8, FIN_MUELLE - 2, 12 do
	for _, lado in { -1, 1 } do
		parte("Pilote", Vector3.new(ALTO_CUBIERTA, 1.2, 1.2), CFrame.new(x, ALTO_CUBIERTA / 2 - 0.5, Z_MUELLE + lado * (ANCHO_MUELLE / 2 - 0.8)) * CFrame.Angles(0, 0, math.rad(90)), MADERA_OSCURA, Enum.Material.Wood, Enum.PartType.Cylinder)
	end
end
cartel(CFrame.new(FIN_MUELLE - 0.5, ALTO_CUBIERTA + 4, Z_MUELLE) * CFrame.Angles(0, math.rad(90), 0), 8, 2.6, "🎣 ¡A pescar!", Color3.fromRGB(20, 120, 180))
parte("PosteCartel", Vector3.new(0.5, 4, 0.5), CFrame.new(FIN_MUELLE - 0.5, ALTO_CUBIERTA + 2, Z_MUELLE + 3.5), MADERA_OSCURA, Enum.Material.Wood)
parte("PosteCartel", Vector3.new(0.5, 4, 0.5), CFrame.new(FIN_MUELLE - 0.5, ALTO_CUBIERTA + 2, Z_MUELLE - 3.5), MADERA_OSCURA, Enum.Material.Wood)

-- Kiosco de la tienda, en la arena junto al comienzo del muelle
local KX, KZ = inicioMuelle - 14, Z_MUELLE
local mostrador = parte("Mostrador", Vector3.new(7, 3.4, 3), CFrame.new(KX, ARENA + 1.7, KZ), Color3.fromRGB(245, 235, 210), Enum.Material.Wood)
for _, lado in { -1, 1 } do
	parte("PosteKiosco", Vector3.new(0.5, 8, 0.5), CFrame.new(KX + lado * 3.5, ARENA + 4, KZ - 1.4), MADERA_OSCURA, Enum.Material.Wood)
end
parte("TechoKiosco", Vector3.new(9, 0.6, 5), CFrame.new(KX, ARENA + 8.2, KZ - 0.6), Color3.fromRGB(40, 140, 210), Enum.Material.Fabric)
cartel(CFrame.new(KX, ARENA + 6.7, KZ - 1.5), 6, 1.5, "🎣 PESCA", Color3.fromRGB(20, 100, 160))
local abrirTiendaPrompt = Instance.new("ProximityPrompt")
abrirTiendaPrompt.ActionText = "Tienda de pesca"
abrirTiendaPrompt.ObjectText = "Cañas y peces"
abrirTiendaPrompt.MaxActivationDistance = 10
abrirTiendaPrompt.RequiresLineOfSight = false
abrirTiendaPrompt.Parent = mostrador
abrirTiendaPrompt.Triggered:Connect(function(jugador)
	abrirTienda:FireClient(jugador)
end)

-- Pesca -----------------------------------------------------------------------------

-- estado[jugador] = { fase = "espera" | "picada" | "listo", puesto, corcho, t0, ventana }
local estado = {}

local function crearCorcho(jugador, puesto)
	local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
	local corcho = Instance.new("Part")
	corcho.Name = "Corcho"
	corcho.Shape = Enum.PartType.Ball
	corcho.Size = Vector3.one * 1.1
	corcho.Color = Color3.fromRGB(235, 50, 50)
	corcho.Material = Enum.Material.SmoothPlastic
	corcho.Anchored = true
	corcho.CanCollide = false
	corcho.Position = Vector3.new(puesto.Position.X, NIVEL_AGUA + 0.3, puesto.Position.Z + puesto:GetAttribute("Lado") * LARGO_LINEA)
	corcho.Parent = muelle

	local brillo = Instance.new("Part") -- la puntita blanca
	brillo.Shape = Enum.PartType.Ball
	brillo.Size = Vector3.one * 0.6
	brillo.Color = Color3.new(1, 1, 1)
	brillo.Material = Enum.Material.SmoothPlastic
	brillo.CanCollide = false
	brillo.Massless = true
	brillo.CFrame = corcho.CFrame * CFrame.new(0, 0.6, 0)
	brillo.Parent = corcho
	local soldadura = Instance.new("WeldConstraint")
	soldadura.Part0 = corcho
	soldadura.Part1 = brillo
	soldadura.Parent = brillo

	local salpicadura = Instance.new("ParticleEmitter")
	salpicadura.Name = "Salpicadura"
	salpicadura.Enabled = false
	salpicadura.Rate = 0
	salpicadura.Lifetime = NumberRange.new(0.4, 0.8)
	salpicadura.Speed = NumberRange.new(6, 12)
	salpicadura.SpreadAngle = Vector2.new(60, 60)
	salpicadura.EmissionDirection = Enum.NormalId.Top
	salpicadura.Acceleration = Vector3.new(0, -30, 0)
	salpicadura.Size = NumberSequence.new(0.5, 0)
	salpicadura.Color = ColorSequence.new(Color3.fromRGB(190, 230, 255))
	salpicadura.Parent = corcho

	-- Hilo desde el jugador hasta el corcho
	local atCorcho = Instance.new("Attachment")
	atCorcho.Parent = corcho
	local atRaiz = raiz and raiz:FindFirstChild("RootRigAttachment")
	if atRaiz then
		local hilo = Instance.new("Beam")
		hilo.Attachment0 = atRaiz
		hilo.Attachment1 = atCorcho
		hilo.Width0 = 0.08
		hilo.Width1 = 0.08
		hilo.FaceCamera = true
		hilo.Segments = 1
		hilo.Color = ColorSequence.new(Color3.new(1, 1, 1))
		hilo.Parent = corcho
	end
	return corcho
end

local function terminar(jugador, e, mensaje, ok)
	if estado[jugador] ~= e then
		return
	end
	estado[jugador] = nil
	if e.corcho then
		e.corcho:Destroy()
	end
	evento:FireClient(jugador, "fin", mensaje, ok)
end

local function lejos(jugador, e)
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	if not raiz or not humanoide or humanoide.Health <= 0 then
		return true
	end
	return (raiz.Position - e.puesto.Position).Magnitude > DISTANCIA_MAXIMA
end

-- Espera hasta que pase el tiempo, avisando si se cancelo. Devuelve false si se cancelo.
local function esperar(jugador, e, segundos)
	local hasta = os.clock() + segundos
	while os.clock() < hasta do
		task.wait(0.15)
		if estado[jugador] ~= e then
			return false
		end
		if lejos(jugador, e) then
			terminar(jugador, e, "Te alejaste del muelle", false)
			return false
		end
	end
	return true
end

local function sumarPez(jugador, pez)
	local cuenta = ConfigPesca.conteos(jugador:GetAttribute("PescaPeces"))
	local nuevo = cuenta[pez.id] == nil
	cuenta[pez.id] = (cuenta[pez.id] or 0) + 1
	jugador:SetAttribute("PescaPeces", ConfigPesca.texto(cuenta))
	jugador:SetAttribute("PescaTotal", (jugador:GetAttribute("PescaTotal") or 0) + 1)
	local leaderstats = jugador:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Monedas.Value += pez.valor
	end
	return nuevo
end

local function pescar(jugador, puesto)
	if estado[jugador] or not jugador:GetAttribute("DatosCargados") then
		return
	end
	local cana = ConfigPesca.mejorCana(ConfigPesca.comprados(jugador:GetAttribute("PescaCanas")))
	local e = { fase = "espera", puesto = puesto }
	estado[jugador] = e
	e.corcho = crearCorcho(jugador, puesto)
	evento:FireClient(jugador, "espera", cana.nombre)

	local espera = azar:NextNumber(ConfigPesca.ESPERA_MINIMA, ConfigPesca.ESPERA_MAXIMA) * cana.espera
	if not esperar(jugador, e, espera) then
		return
	end

	e.fase = "picada"
	e.ventana = cana.ventana
	e.t0 = os.clock()
	e.cana = cana
	evento:FireClient(jugador, "picada", cana.ventana)

	-- El corcho se hunde y salpica mientras dura la ventana
	local corcho = e.corcho
	local arriba = corcho.Position
	corcho.Salpicadura:Emit(14)
	task.spawn(function()
		while estado[jugador] == e and e.fase == "picada" do
			corcho.Position = arriba - Vector3.new(0, 0.7, 0)
			task.wait(0.12)
			if estado[jugador] ~= e then
				break
			end
			corcho.Position = arriba
			task.wait(0.12)
		end
	end)

	if not esperar(jugador, e, cana.ventana + ConfigPesca.MARGEN) then
		return
	end
	if e.fase == "picada" then
		terminar(jugador, e, "Se escapó el pez... ¡tirá más rápido!", false)
	end
end

accion.OnServerEvent:Connect(function(jugador, que)
	local e = estado[jugador]
	if not e then
		return
	end
	if que == "cancelar" then
		terminar(jugador, e, "Recogiste la línea", false)
	elseif que == "tirar" then
		if e.fase == "espera" then
			terminar(jugador, e, "¡Muy pronto! Esperá a que pique", false)
		elseif e.fase == "picada" then
			if os.clock() - e.t0 > e.ventana + ConfigPesca.MARGEN then
				terminar(jugador, e, "Se escapó el pez... ¡tirá más rápido!", false)
				return
			end
			e.fase = "listo"
			local pez = ConfigPesca.elegirPez(azar, e.cana.suerte)
			local nuevo = sumarPez(jugador, pez)
			evento:FireClient(jugador, "pez", pez.id, pez.valor, nuevo)
			-- Cierra sin otro mensaje: "pez" ya mostro el resultado
			estado[jugador] = nil
			if e.corcho then
				e.corcho:Destroy()
			end
		end
	end
end)

-- Puestos para pescar: un poste con cartel a cada lado del muelle
for _, x in PUESTOS_X do
	for _, lado in { -1, 1 } do
		local poste = parte("Puesto", Vector3.new(0.7, 3, 0.7), CFrame.new(x, ALTO_CUBIERTA + 2, Z_MUELLE + lado * (ANCHO_MUELLE / 2 - 0.5)), MADERA_OSCURA, Enum.Material.Wood)
		poste:SetAttribute("Lado", lado)
		parte("Farol", Vector3.one * 0.9, poste.CFrame * CFrame.new(0, 1.8, 0), Color3.fromRGB(255, 220, 120), Enum.Material.Neon, Enum.PartType.Ball, false)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pescar"
		prompt.ObjectText = "Muelle"
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = poste
		prompt.Triggered:Connect(function(jugador)
			pescar(jugador, poste)
		end)
	end
end

-- Tienda de cañas ------------------------------------------------------------------

tienda.OnServerInvoke = function(jugador, que, id)
	if not jugador:GetAttribute("DatosCargados") then
		return false, "Todavía cargando, probá de nuevo"
	end
	if que ~= "comprar" or type(id) ~= "string" then
		return false, "Pedido inválido"
	end
	local cana
	for _, c in ConfigPesca.Canas do
		if c.id == id then
			cana = c
		end
	end
	if not cana then
		return false, "Eso no está en la tienda"
	end
	if ConfigPesca.tiene(ConfigPesca.comprados(jugador:GetAttribute("PescaCanas")), cana) then
		return false, "Ya la tenés"
	end
	local leaderstats = jugador:FindFirstChild("leaderstats")
	local monedas = leaderstats and leaderstats:FindFirstChild("Monedas")
	if not monedas or monedas.Value < cana.precio then
		return false, string.format("Te faltan %d monedas", cana.precio - (monedas and monedas.Value or 0))
	end
	monedas.Value -= cana.precio
	local actual = jugador:GetAttribute("PescaCanas") or ""
	jugador:SetAttribute("PescaCanas", actual == "" and cana.id or (actual .. "," .. cana.id))
	return true, "¡Compraste la " .. cana.nombre .. "! Ya la usás"
end

Players.PlayerRemoving:Connect(function(jugador)
	local e = estado[jugador]
	if e then
		estado[jugador] = nil
		if e.corcho then
			e.corcho:Destroy()
		end
	end
end)
