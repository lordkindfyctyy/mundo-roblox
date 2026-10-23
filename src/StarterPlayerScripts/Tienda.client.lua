-- Interfaz de la tienda: boton "Tienda" que abre una lista de mejoras.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigMejoras = require(ReplicatedStorage:WaitForChild("ConfigMejoras"))
local ConfigRenacer = require(ReplicatedStorage:WaitForChild("ConfigRenacer"))
local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local comprar = ReplicatedStorage:WaitForChild("ComprarMejora")
local renacer = ReplicatedStorage:WaitForChild("Renacer")

local jugador = Players.LocalPlayer
local monedas = jugador:WaitForChild("leaderstats"):WaitForChild("Monedas")
local renacimientos = jugador.leaderstats:WaitForChild("Renacimientos")
local mejoras = jugador:WaitForChild("Mejoras")

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Tienda"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local function redondear(objeto, radio)
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, radio)
	esquinas.Parent = objeto
end

-- Boton para abrir/cerrar
local botonAbrir = Instance.new("TextButton")
botonAbrir.Size = UDim2.fromOffset(120, 46)
botonAbrir.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
botonAbrir.Font = Enum.Font.GothamBold
botonAbrir.TextSize = 22
botonAbrir.TextColor3 = Color3.new(1, 1, 1)
botonAbrir.Text = "Tienda"
botonAbrir.Parent = pantalla
redondear(botonAbrir, 10)
Interfaz.botonLateral(botonAbrir, "izquierda", 1, 4)

-- Ventana de la tienda
local ventana = Instance.new("Frame")
ventana.AnchorPoint = Vector2.new(0.5, 0.5)
ventana.Position = UDim2.fromScale(0.5, 0.5)
ventana.Size = UDim2.fromOffset(420, 520)
ventana.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ventana.Visible = false
ventana.Parent = pantalla
redondear(ventana, 14)
Interfaz.panel(ventana, 420, 520)

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 50)
titulo.BackgroundTransparency = 1
titulo.Font = Enum.Font.GothamBold
titulo.TextSize = 26
titulo.TextColor3 = Color3.fromRGB(255, 205, 0)
titulo.Text = "Tienda de mejoras"
titulo.Parent = ventana

local mensaje = Instance.new("TextLabel")
mensaje.AnchorPoint = Vector2.new(0, 1)
mensaje.Position = UDim2.new(0, 0, 1, -6)
mensaje.Size = UDim2.new(1, 0, 0, 24)
mensaje.BackgroundTransparency = 1
mensaje.Font = Enum.Font.Gotham
mensaje.TextSize = 16
mensaje.TextColor3 = Color3.new(1, 1, 1)
mensaje.Text = ""
mensaje.Parent = ventana

-- Lista con scroll: entran todas las mejoras aunque la pantalla sea chica
local lista = Instance.new("ScrollingFrame")
lista.Position = UDim2.fromOffset(0, 55)
lista.Size = UDim2.new(1, 0, 1, -170) -- deja lugar abajo para la fila de Renacer y el mensaje
lista.BackgroundTransparency = 1
lista.BorderSizePixel = 0
lista.ScrollBarThickness = 6
lista.CanvasSize = UDim2.fromOffset(0, #ConfigMejoras.Lista * 80)
lista.Parent = ventana

botonAbrir.Activated:Connect(function()
	Interfaz.alternar(ventana)
	mensaje.Text = ""
end)

-- Una fila por cada mejora
local filas = {}

local function actualizarFila(mejora)
	local fila = filas[mejora.id]
	local nivel = mejoras[mejora.id].Value

	fila.nombre.Text = string.format("%s  (nivel %d/%d)", mejora.nombre, nivel, mejora.nivelMaximo)

	if nivel >= mejora.nivelMaximo then
		fila.boton.Text = "MAX"
		fila.boton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	else
		local costo = ConfigMejoras.costo(mejora, nivel)
		fila.boton.Text = costo .. " monedas"
		local alcanza = monedas.Value >= costo
		fila.boton.BackgroundColor3 = alcanza and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(150, 60, 60)
	end
end

for i, mejora in ConfigMejoras.Lista do
	local marco = Instance.new("Frame")
	marco.Position = UDim2.new(0, 15, 0, (i - 1) * 80)
	marco.Size = UDim2.new(1, -36, 0, 70)
	marco.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	marco.Parent = lista
	redondear(marco, 10)

	local nombre = Instance.new("TextLabel")
	nombre.Position = UDim2.fromOffset(12, 6)
	nombre.Size = UDim2.new(0.6, 0, 0, 28)
	nombre.BackgroundTransparency = 1
	nombre.Font = Enum.Font.GothamBold
	nombre.TextSize = 18
	nombre.TextXAlignment = Enum.TextXAlignment.Left
	nombre.TextColor3 = Color3.new(1, 1, 1)
	nombre.Parent = marco

	local descripcion = Instance.new("TextLabel")
	descripcion.Position = UDim2.fromOffset(12, 36)
	descripcion.Size = UDim2.new(0.6, 0, 0, 24)
	descripcion.BackgroundTransparency = 1
	descripcion.Font = Enum.Font.Gotham
	descripcion.TextSize = 14
	descripcion.TextXAlignment = Enum.TextXAlignment.Left
	descripcion.TextColor3 = Color3.fromRGB(200, 200, 200)
	descripcion.Text = mejora.descripcion
	descripcion.Parent = marco

	local boton = Instance.new("TextButton")
	boton.AnchorPoint = Vector2.new(1, 0.5)
	boton.Position = UDim2.new(1, -12, 0.5, 0)
	boton.Size = UDim2.fromOffset(120, 40)
	boton.Font = Enum.Font.GothamBold
	boton.TextSize = 16
	boton.TextColor3 = Color3.new(1, 1, 1)
	boton.Parent = marco
	redondear(boton, 8)

	filas[mejora.id] = { nombre = nombre, boton = boton }

	boton.Activated:Connect(function()
		local ok, texto = comprar:InvokeServer(mejora.id)
		mensaje.Text = texto or ""
		mensaje.TextColor3 = ok and Color3.fromRGB(0, 220, 100) or Color3.fromRGB(255, 100, 100)
	end)

	mejoras[mejora.id].Changed:Connect(function()
		actualizarFila(mejora)
	end)
end

local function actualizarTodas()
	for _, mejora in ConfigMejoras.Lista do
		actualizarFila(mejora)
	end
end

monedas.Changed:Connect(actualizarTodas)
actualizarTodas()

-- Fila fija de "Renacer" al pie de la tienda
local marcoRenacer = Instance.new("Frame")
marcoRenacer.AnchorPoint = Vector2.new(0, 1)
marcoRenacer.Position = UDim2.new(0, 15, 1, -36)
marcoRenacer.Size = UDim2.new(1, -30, 0, 70)
marcoRenacer.BackgroundColor3 = Color3.fromRGB(70, 40, 100)
marcoRenacer.Parent = ventana
redondear(marcoRenacer, 10)

local nombreRenacer = Instance.new("TextLabel")
nombreRenacer.Position = UDim2.fromOffset(12, 6)
nombreRenacer.Size = UDim2.new(0.6, 0, 0, 28)
nombreRenacer.BackgroundTransparency = 1
nombreRenacer.Font = Enum.Font.GothamBold
nombreRenacer.TextSize = 18
nombreRenacer.TextXAlignment = Enum.TextXAlignment.Left
nombreRenacer.TextColor3 = Color3.fromRGB(230, 190, 255)
nombreRenacer.Parent = marcoRenacer

local descripcionRenacer = Instance.new("TextLabel")
descripcionRenacer.Position = UDim2.fromOffset(12, 36)
descripcionRenacer.Size = UDim2.new(0.6, 0, 0, 24)
descripcionRenacer.BackgroundTransparency = 1
descripcionRenacer.Font = Enum.Font.Gotham
descripcionRenacer.TextSize = 13
descripcionRenacer.TextXAlignment = Enum.TextXAlignment.Left
descripcionRenacer.TextColor3 = Color3.fromRGB(210, 200, 220)
descripcionRenacer.Text = "Reinicia monedas y mejoras"
descripcionRenacer.Parent = marcoRenacer

local botonRenacer = Instance.new("TextButton")
botonRenacer.AnchorPoint = Vector2.new(1, 0.5)
botonRenacer.Position = UDim2.new(1, -12, 0.5, 0)
botonRenacer.Size = UDim2.fromOffset(120, 40)
botonRenacer.Font = Enum.Font.GothamBold
botonRenacer.TextSize = 16
botonRenacer.TextColor3 = Color3.new(1, 1, 1)
botonRenacer.Parent = marcoRenacer
redondear(botonRenacer, 8)

local confirmando = false -- el primer toque pide confirmar, el segundo renace

local function actualizarRenacer()
	local n = renacimientos.Value
	local bonus = math.floor((ConfigRenacer.multiplicador(n) - 1) * 100 + 0.5)
	nombreRenacer.Text = string.format("Renacer  (x%d, bonus +%d%%)", n, bonus)

	local costo = ConfigRenacer.costo(n)
	if confirmando then
		botonRenacer.Text = "¿Seguro? Tocá"
		botonRenacer.BackgroundColor3 = Color3.fromRGB(220, 120, 0)
	else
		botonRenacer.Text = costo .. " monedas"
		local alcanza = monedas.Value >= costo
		botonRenacer.BackgroundColor3 = alcanza and Color3.fromRGB(150, 70, 220) or Color3.fromRGB(90, 70, 110)
	end
end

botonRenacer.Activated:Connect(function()
	if not confirmando then
		confirmando = true
		actualizarRenacer()
		task.delay(3, function()
			confirmando = false
			actualizarRenacer()
		end)
		return
	end

	confirmando = false
	local ok, texto = renacer:InvokeServer()
	mensaje.Text = texto or ""
	mensaje.TextColor3 = ok and Color3.fromRGB(0, 220, 100) or Color3.fromRGB(255, 100, 100)
	actualizarRenacer()
end)

monedas.Changed:Connect(actualizarRenacer)
renacimientos.Changed:Connect(actualizarRenacer)
actualizarRenacer()
