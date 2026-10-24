-- Interfaz del golf (Golf.server.lua): mientras se juega aparece una barra abajo con el
-- hoyo, los golpes, los palos, los botones para girar la punteria y la barra de fuerza.
-- Se golpea manteniendo apretado GOLPEAR (la fuerza sube y baja) y soltando.
-- Una flecha celeste en el piso muestra hacia donde va a salir la pelota (solo la ves vos).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local ConfigGolf = require(ReplicatedStorage:WaitForChild("ConfigGolf"))
local golpeRemoto = ReplicatedStorage:WaitForChild("GolfGolpe")
local salirRemoto = ReplicatedStorage:WaitForChild("GolfSalir")

local jugador = Players.LocalPlayer

local VELOCIDAD_CARGA = 0.9 -- ciclos de la barra de fuerza por segundo (sube y baja)
local VELOCIDAD_GIRO = math.rad(55) -- grados por segundo al girar la punteria
local COLOR_ACTIVO = Color3.fromRGB(0, 150, 100)
local COLOR_INACTIVO = Color3.fromRGB(70, 70, 80)

-- Estado
local paloActual = ConfigGolf.Palos[1].id
local angulo = math.pi -- direccion de la punteria; math.pi mira hacia -Z (el sur, hacia donde van los hoyos)
local cargando = false
local entradaDeCarga = nil
local inicioCarga = 0
local potencia = 0
local giro = 0 -- botones: -1, 0 o 1
local teclaIzquierda, teclaDerecha = false, false
local confirmandoSalir = false
local ultimoContador = nil

local function direccion()
	return Vector3.new(math.sin(angulo), 0, math.cos(angulo))
end

local function plano(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function buscarBola()
	local golf = Workspace:FindFirstChild("Golf")
	local bolas = golf and golf:FindFirstChild("Bolas")
	return bolas and bolas:FindFirstChild("Bola_" .. jugador.UserId)
end

-- Interfaz ---------------------------------------------------------------------

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Golf"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local barra = Instance.new("Frame")
barra.AnchorPoint = Vector2.new(0.5, 1)
barra.Position = UDim2.new(0.5, 0, 1, -14)
barra.Size = UDim2.fromOffset(520, 186)
barra.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
barra.BackgroundTransparency = 0.12
barra.Visible = false
barra.Parent = pantalla
Interfaz.escalar(barra)

local function redondear(objeto, radio)
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, radio)
	esquinas.Parent = objeto
end
redondear(barra, 12)

local function boton(texto, x, y, ancho, alto, color, tamano)
	local b = Instance.new("TextButton")
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(ancho, alto)
	b.BackgroundColor3 = color
	b.Font = Enum.Font.GothamBold
	b.TextSize = tamano or 16
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = texto
	b.AutoButtonColor = true
	b.Parent = barra
	redondear(b, 8)
	return b
end

local info = Instance.new("TextLabel")
info.Position = UDim2.fromOffset(10, 6)
info.Size = UDim2.new(1, -20, 0, 24)
info.BackgroundTransparency = 1
info.Font = Enum.Font.GothamBold
info.TextSize = 16
info.TextColor3 = Color3.new(1, 1, 1)
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = barra

-- Palos: un boton por palo, y solo se ven los que el jugador tiene (los otros se compran
-- en la tienda de golf). Se reparten el ancho de la barra.
local botonesPalo = {}
for _, palo in ConfigGolf.Palos do
	local b = boton(palo.nombre, 10, 36, 60, 34, COLOR_INACTIVO, 14)
	botonesPalo[palo.id] = b
	b.Activated:Connect(function()
		paloActual = palo.id
	end)
end

local function acomodarPalos()
	local tengo = ConfigGolf.comprados(jugador:GetAttribute("GolfCosas"))
	local propios = {}
	for _, palo in ConfigGolf.Palos do
		local visible = ConfigGolf.tiene(tengo, palo)
		botonesPalo[palo.id].Visible = visible
		if visible then
			table.insert(propios, palo)
		end
	end
	local separacion = 6
	local ancho = math.min(90, (500 - separacion * (#propios - 1)) / #propios)
	for i, palo in propios do
		local b = botonesPalo[palo.id]
		b.Position = UDim2.fromOffset(10 + (i - 1) * (ancho + separacion), 36)
		b.Size = UDim2.fromOffset(ancho, 34)
	end
	if not botonesPalo[paloActual].Visible then
		paloActual = propios[1].id
	end
end
jugador:GetAttributeChangedSignal("GolfCosas"):Connect(acomodarPalos)
acomodarPalos()

-- Girar la punteria, apuntar al hoyo y salir
local botonIzquierda = boton("◀", 10, 76, 60, 34, Color3.fromRGB(60, 90, 140), 20)
local botonDerecha = boton("▶", 76, 76, 60, 34, Color3.fromRGB(60, 90, 140), 20)
local botonHoyo = boton("Apuntar al hoyo", 142, 76, 220, 34, Color3.fromRGB(60, 90, 140), 14)
local botonSalir = boton("Salir", 368, 76, 142, 34, Color3.fromRGB(170, 60, 60), 14)

-- Barra de fuerza
local fondoFuerza = Instance.new("Frame")
fondoFuerza.Position = UDim2.fromOffset(10, 118)
fondoFuerza.Size = UDim2.new(1, -20, 0, 18)
fondoFuerza.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
fondoFuerza.Parent = barra
redondear(fondoFuerza, 9)

local relleno = Instance.new("Frame")
relleno.Size = UDim2.fromScale(0, 1)
relleno.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
relleno.Parent = fondoFuerza
redondear(relleno, 9)

local botonGolpe = boton("GOLPEAR", 10, 142, 500, 34, COLOR_ACTIVO, 20)

-- Flecha de punteria (parte local, solo la ve este jugador)
local flecha = Instance.new("Part")
flecha.Name = "FlechaGolf"
flecha.Anchored = true
flecha.CanCollide = false
flecha.CanQuery = false
flecha.CanTouch = false
flecha.Material = Enum.Material.Neon
flecha.Color = Color3.fromRGB(0, 220, 255)
flecha.Transparency = 0.2

-- Acciones -----------------------------------------------------------------------

local function apuntarAlHoyo()
	local bola = buscarBola()
	local copa = jugador:GetAttribute("GolfCopa")
	if bola and copa then
		local d = plano(copa - bola.Position)
		if d.Magnitude > 0.1 then
			angulo = math.atan2(d.X, d.Z)
		end
	end
end

local function puedeGolpear()
	local bola = buscarBola()
	return bola ~= nil and bola:GetAttribute("EnMovimiento") ~= true
end

local function soltar()
	if not cargando then
		return
	end
	cargando = false
	entradaDeCarga = nil
	local fuerza = potencia
	potencia = 0
	if puedeGolpear() then
		golpeRemoto:FireServer(paloActual, fuerza, direccion())
	end
end

botonHoyo.Activated:Connect(apuntarAlHoyo)

botonSalir.Activated:Connect(function()
	if not confirmandoSalir then
		confirmandoSalir = true
		botonSalir.Text = "¿Seguro?"
		task.delay(3, function()
			confirmandoSalir = false
			botonSalir.Text = "Salir"
		end)
		return
	end
	confirmandoSalir = false
	botonSalir.Text = "Salir"
	salirRemoto:FireServer()
end)

local function esToque(entrada)
	return entrada.UserInputType == Enum.UserInputType.MouseButton1 or entrada.UserInputType == Enum.UserInputType.Touch
end

-- Mantener apretado un boton de giro
local function mantenerGiro(b, valor)
	b.InputBegan:Connect(function(entrada)
		if esToque(entrada) then
			giro = valor
		end
	end)
end
mantenerGiro(botonIzquierda, 1) -- sumar angulo gira hacia la izquierda cuando se mira al sur
mantenerGiro(botonDerecha, -1)

-- Mantener apretado GOLPEAR: la fuerza sube y baja hasta que se suelta
botonGolpe.InputBegan:Connect(function(entrada)
	if esToque(entrada) and not cargando and puedeGolpear() then
		cargando = true
		entradaDeCarga = entrada
		inicioCarga = os.clock()
	end
end)

UserInputService.InputEnded:Connect(function(entrada)
	if esToque(entrada) then
		giro = 0
		if cargando and (entrada == entradaDeCarga or entrada.UserInputType == Enum.UserInputType.MouseButton1) then
			soltar()
		end
	end
end)

-- Q y E tambien giran la punteria (A y D mueven al personaje)
UserInputService.InputBegan:Connect(function(entrada, procesado)
	if procesado then
		return
	end
	if entrada.KeyCode == Enum.KeyCode.Q then
		teclaIzquierda = true
	elseif entrada.KeyCode == Enum.KeyCode.E then
		teclaDerecha = true
	end
end)
UserInputService.InputEnded:Connect(function(entrada)
	if entrada.KeyCode == Enum.KeyCode.Q then
		teclaIzquierda = false
	elseif entrada.KeyCode == Enum.KeyCode.E then
		teclaDerecha = false
	end
end)

-- Cada cuadro ----------------------------------------------------------------------

RunService.RenderStepped:Connect(function(dt)
	local activo = jugador:GetAttribute("GolfActivo") == true
	barra.Visible = activo
	if not activo then
		flecha.Parent = nil
		cargando = false
		potencia = 0
		return
	end

	local bola = buscarBola()

	-- Cada pelota nueva (cada hoyo) arranca apuntando a la bandera
	local contador = jugador:GetAttribute("GolfContador") or 0
	if bola and contador ~= ultimoContador then
		ultimoContador = contador
		apuntarAlHoyo()
	end

	local sentido = giro + (teclaIzquierda and 1 or 0) - (teclaDerecha and 1 or 0)
	angulo += sentido * VELOCIDAD_GIRO * dt

	if cargando then
		local t = (os.clock() - inicioCarga) * VELOCIDAD_CARGA
		potencia = 1 - math.abs(t % 2 - 1) -- 0 -> 1 -> 0 -> ...
	end
	relleno.Size = UDim2.fromScale(potencia, 1)
	relleno.BackgroundColor3 = Color3.fromRGB(80, 220, 120):Lerp(Color3.fromRGB(240, 70, 60), potencia)

	for id, b in botonesPalo do
		b.BackgroundColor3 = id == paloActual and COLOR_ACTIVO or COLOR_INACTIVO
	end

	-- Texto de arriba
	local copa = jugador:GetAttribute("GolfCopa")
	local texto = string.format(
		"Hoyo %d/%d · Par %d · Golpes %d",
		jugador:GetAttribute("GolfHoyo") or 1,
		jugador:GetAttribute("GolfHoyos") or 3,
		jugador:GetAttribute("GolfPar") or 0,
		jugador:GetAttribute("GolfGolpes") or 0
	)
	if bola and copa then
		texto ..= string.format(" · Bandera a %d m", math.floor(plano(copa - bola.Position).Magnitude + 0.5))
		local superficie = bola:GetAttribute("Superficie")
		if superficie and superficie ~= "Aire" then
			texto ..= " · " .. ConfigGolf.superficie(superficie).nombre
		end
	end
	info.Text = texto

	local listo = bola ~= nil and bola:GetAttribute("EnMovimiento") ~= true
	botonGolpe.Text = listo and (cargando and "¡SOLTÁ PARA GOLPEAR!" or "GOLPEAR (mantené apretado)") or "Esperá a que pare la pelota…"
	botonGolpe.BackgroundColor3 = listo and COLOR_ACTIVO or COLOR_INACTIVO

	-- Flecha: sale de la pelota hacia donde se apunta; crece con la fuerza
	if bola and listo then
		local largo = 8 + 14 * potencia
		local inicio = bola.Position + Vector3.new(0, 0.2, 0) + direccion() * 2
		flecha.Size = Vector3.new(0.5, 0.12, largo)
		flecha.CFrame = CFrame.lookAt(inicio + direccion() * (largo / 2), inicio + direccion() * largo)
		flecha.Parent = Workspace
	else
		flecha.Parent = nil
	end
end)
