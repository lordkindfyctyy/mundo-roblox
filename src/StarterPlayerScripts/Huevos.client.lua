-- Interfaz del busca huevos (servidor: Huevos.server.lua, lista y zonas: ConfigHuevos.lua):
--   * el boton "Huevos" del costado derecho con lo que lleva encontrado, y un panel con el progreso de cada zona
--   * los huevos que ya encontraste se esconden solo para vos (los demas siguen viendolos)
--   * los que te faltan giran y suben y bajan un poquito para que se vean de lejos
--   * un sonido al encontrar uno

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ConfigHuevos = require(ReplicatedStorage:WaitForChild("ConfigHuevos"))
local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))

local jugador = Players.LocalPlayer

local COLOR_HECHA = Color3.fromRGB(0, 150, 80)
local COLOR_PENDIENTE = Color3.fromRGB(50, 50, 50)
local SONIDO = "rbxassetid://4612375051" -- el mismo de las monedas azules

-- Lo que encontro este jugador: { id = true }. Se rehace cada vez que cambia el atributo.
local hallados = ConfigHuevos.hallados(jugador:GetAttribute("HuevosHallados"))
local cargado = jugador:GetAttribute("DatosCargados") == true

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Huevos"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local function redondear(objeto, radio)
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, radio)
	esquinas.Parent = objeto
end

local function nuevoTexto(padre, tamano, fuente, color, alineacion)
	local texto = Instance.new("TextLabel")
	texto.BackgroundTransparency = 1
	texto.Font = fuente
	texto.TextSize = tamano
	texto.TextColor3 = color
	texto.TextXAlignment = alineacion or Enum.TextXAlignment.Center
	texto.Parent = padre
	return texto
end

-- Boton del costado derecho, debajo de Mascotas y Mi casa
local boton = Instance.new("TextButton")
boton.Size = UDim2.fromOffset(120, 46)
boton.BackgroundColor3 = Color3.fromRGB(255, 140, 60)
boton.Font = Enum.Font.GothamBold
boton.TextSize = 18
boton.TextColor3 = Color3.new(1, 1, 1)
boton.Parent = pantalla
redondear(boton, 10)
Interfaz.botonLateral(boton, "derecha", 2, 3)

-- Panel
local ANCHO, ALTO = 470, 100 + #ConfigHuevos.Zonas * 62
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(ANCHO, ALTO)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.Visible = false
panel.Parent = pantalla
redondear(panel, 14)
Interfaz.panel(panel, ANCHO, ALTO)

local titulo = nuevoTexto(panel, 26, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 0))
titulo.Size = UDim2.new(1, 0, 0, 50)

local subtitulo = nuevoTexto(panel, 14, Enum.Font.Gotham, Color3.fromRGB(200, 200, 200))
subtitulo.Position = UDim2.fromOffset(0, 44)
subtitulo.Size = UDim2.new(1, 0, 0, 24)
subtitulo.Text = string.format("Cada huevo paga %d monedas. ¡Fijate en los rincones!", ConfigHuevos.PREMIO)

local filas = {}
for i, zona in ConfigHuevos.Zonas do
	local marco = Instance.new("Frame")
	marco.Position = UDim2.fromOffset(15, 76 + (i - 1) * 62)
	marco.Size = UDim2.new(1, -30, 0, 56)
	marco.Parent = panel
	redondear(marco, 10)

	local nombre = nuevoTexto(marco, 17, Enum.Font.GothamBold, Color3.new(1, 1, 1), Enum.TextXAlignment.Left)
	nombre.Position = UDim2.fromOffset(12, 5)
	nombre.Size = UDim2.new(0.68, 0, 0, 24)
	nombre.Text = zona.icono .. " " .. zona.nombre

	local pista = nuevoTexto(marco, 12, Enum.Font.Gotham, Color3.fromRGB(205, 205, 205), Enum.TextXAlignment.Left)
	pista.Position = UDim2.fromOffset(12, 30)
	pista.Size = UDim2.new(0.76, 0, 0, 20)
	pista.TextTruncate = Enum.TextTruncate.AtEnd
	pista.Text = zona.pista

	local estado = nuevoTexto(marco, 18, Enum.Font.GothamBold, Color3.new(1, 1, 1), Enum.TextXAlignment.Right)
	estado.AnchorPoint = Vector2.new(1, 0)
	estado.Position = UDim2.new(1, -12, 0, 14)
	estado.Size = UDim2.new(0.25, 0, 0, 26)

	filas[zona.id] = { marco = marco, estado = estado, pista = pista, textoPista = zona.pista }
end

local function cantidadHallados()
	local cuenta = 0
	for _ in hallados do
		cuenta += 1
	end
	return cuenta
end

local function actualizarPanel()
	local cuenta = cantidadHallados()
	local total = ConfigHuevos.total()
	boton.Text = string.format("🥚 %d/%d", cuenta, total)
	titulo.Text = string.format("🥚 Busca huevos  (%d/%d)", cuenta, total)
	local porZona = ConfigHuevos.porZona(hallados)
	for id, fila in filas do
		local datos = porZona[id]
		local completa = datos.hallados >= datos.total
		fila.marco.BackgroundColor3 = completa and COLOR_HECHA or COLOR_PENDIENTE
		fila.estado.Text = completa and "¡Completa!" or string.format("%d / %d", datos.hallados, datos.total)
		fila.pista.Text = completa and "Ya encontraste todos los de esta zona" or fila.textoPista
	end
end

boton.Activated:Connect(function()
	Interfaz.alternar(panel)
	actualizarPanel()
end)

-- Los huevos del mundo --------------------------------------------------------------------------------------

-- Hasta que no cargan los datos no se sabe cuales ya encontro: mientras tanto estan todos escondidos
local huevos = {} -- modelo -> { fase = numero, escondido = booleano }

local function mostrar(modelo, visible)
	for _, d in modelo:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = visible and 0 or 1
		elseif d:IsA("ProximityPrompt") or d:IsA("PointLight") or d:IsA("ParticleEmitter") then
			d.Enabled = visible
		end
	end
end

local function aplicar(modelo)
	local estado = huevos[modelo]
	if not estado then
		return
	end
	local deberiaVerse = cargado and not hallados[modelo:GetAttribute("Id")]
	if estado.escondido == deberiaVerse or estado.escondido == nil then
		estado.escondido = not deberiaVerse
		mostrar(modelo, deberiaVerse)
	end
end

local carpeta = Workspace:WaitForChild("Huevos")

local function agregar(modelo)
	if not modelo:IsA("Model") or huevos[modelo] then
		return
	end
	-- el Id llega con el modelo; por las dudas se espera un instante si todavia no esta
	if not modelo:GetAttribute("Id") then
		task.wait(0.2)
	end
	huevos[modelo] = { fase = math.random() * 6.28 }
	aplicar(modelo)
end

carpeta.ChildAdded:Connect(agregar)
carpeta.ChildRemoved:Connect(function(modelo)
	huevos[modelo] = nil
end)
for _, modelo in carpeta:GetChildren() do
	task.spawn(agregar, modelo)
end

local function aplicarATodos()
	for modelo in huevos do
		aplicar(modelo)
	end
end

-- Gira y sube y baja solo el que esta a la vista y lo bastante cerca como para notarlo
RunService.RenderStepped:Connect(function()
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if not raiz then
		return
	end
	local ahora = os.clock()
	for modelo, estado in huevos do
		if not estado.escondido then
			local base = modelo:GetAttribute("Base")
			if base and (base.Position - raiz.Position).Magnitude < 250 then
				modelo:PivotTo(base * CFrame.new(0, math.sin(ahora * 2 + estado.fase) * 0.25, 0) * CFrame.Angles(0, ahora * 1.4 + estado.fase, 0))
			end
		end
	end
end)

-- Cuando cambia lo encontrado -------------------------------------------------------------------------------

local sonido = Instance.new("Sound")
sonido.SoundId = SONIDO
sonido.Volume = 0.7
sonido.Parent = pantalla

jugador:GetAttributeChangedSignal("HuevosHallados"):Connect(function()
	local antes = cantidadHallados()
	hallados = ConfigHuevos.hallados(jugador:GetAttribute("HuevosHallados"))
	if cargado and cantidadHallados() > antes then
		sonido:Play()
	end
	actualizarPanel()
	aplicarATodos()
end)

jugador:GetAttributeChangedSignal("DatosCargados"):Connect(function()
	cargado = jugador:GetAttribute("DatosCargados") == true
	hallados = ConfigHuevos.hallados(jugador:GetAttribute("HuevosHallados"))
	actualizarPanel()
	aplicarATodos()
end)

actualizarPanel()
