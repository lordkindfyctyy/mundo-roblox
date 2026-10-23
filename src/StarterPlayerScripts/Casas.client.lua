-- Boton "Mi casa" (lleva a la puerta de tu casa del Barrio) y el panel para comprar
-- muebles, que se abre desde el atril "Decorar" adentro de la casa (Casas.server.lua).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigCasas = require(ReplicatedStorage:WaitForChild("ConfigCasas"))
local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local abrirMuebles = ReplicatedStorage:WaitForChild("AbrirMuebles")
local comprarMueble = ReplicatedStorage:WaitForChild("ComprarMueble")
local irAMiCasa = ReplicatedStorage:WaitForChild("IrAMiCasa")

local jugador = Players.LocalPlayer
local monedas = jugador:WaitForChild("leaderstats"):WaitForChild("Monedas")

local COLOR_VERDE = Color3.fromRGB(0, 170, 80)
local COLOR_GRIS = Color3.fromRGB(90, 90, 90)
local ALTO_FILA = 50

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Casas"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local function redondear(objeto, radio)
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, radio)
	esquinas.Parent = objeto
end

local function texto(padre, tamano, letra, color, alineacion)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = letra
	t.TextSize = tamano
	t.TextColor3 = color
	t.TextXAlignment = alineacion or Enum.TextXAlignment.Center
	t.Parent = padre
	return t
end

-- Boton "Mi casa", debajo de Mascotas
local botonCasa = Instance.new("TextButton")
botonCasa.Size = UDim2.fromOffset(120, 46)
botonCasa.BackgroundColor3 = Color3.fromRGB(200, 120, 60)
botonCasa.Font = Enum.Font.GothamBold
botonCasa.TextSize = 19
botonCasa.TextColor3 = Color3.new(1, 1, 1)
botonCasa.Text = "🏠 Mi casa"
botonCasa.Parent = pantalla
redondear(botonCasa, 10)
Interfaz.botonLateral(botonCasa, "derecha", 1, 2)
botonCasa.Activated:Connect(function()
	irAMiCasa:FireServer()
end)

-- Panel de muebles
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(420, 120 + #ConfigCasas.Muebles * ALTO_FILA)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.Visible = false
panel.Parent = pantalla
redondear(panel, 14)
Interfaz.panel(panel, 420, 120 + #ConfigCasas.Muebles * ALTO_FILA)

local titulo = texto(panel, 26, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 0))
titulo.Size = UDim2.new(1, 0, 0, 44)
titulo.Text = "🛋️ Muebles"

local ayuda = texto(panel, 13, Enum.Font.Gotham, Color3.fromRGB(200, 200, 200))
ayuda.Position = UDim2.fromOffset(10, 40)
ayuda.Size = UDim2.new(1, -20, 0, 18)
ayuda.Text = "Cada mueble aparece en su lugar de la casa"

local mensaje = texto(panel, 15, Enum.Font.GothamBold, Color3.new(1, 1, 1))
mensaje.AnchorPoint = Vector2.new(0, 1)
mensaje.Position = UDim2.new(0, 10, 1, -8)
mensaje.Size = UDim2.new(1, -20, 0, 22)

local filas = {}
for i, mueble in ConfigCasas.Muebles do
	local marco = Instance.new("Frame")
	marco.Position = UDim2.fromOffset(15, 64 + (i - 1) * ALTO_FILA)
	marco.Size = UDim2.new(1, -30, 0, ALTO_FILA - 6)
	marco.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	marco.Parent = panel
	redondear(marco, 10)

	local nombre = texto(marco, 16, Enum.Font.GothamBold, Color3.new(1, 1, 1), Enum.TextXAlignment.Left)
	nombre.Position = UDim2.fromOffset(12, 0)
	nombre.Size = UDim2.new(0.6, 0, 1, 0)
	nombre.Text = mueble.nombre

	local boton = Instance.new("TextButton")
	boton.AnchorPoint = Vector2.new(1, 0.5)
	boton.Position = UDim2.new(1, -8, 0.5, 0)
	boton.Size = UDim2.fromOffset(130, 32)
	boton.Font = Enum.Font.GothamBold
	boton.TextSize = 14
	boton.TextColor3 = Color3.new(1, 1, 1)
	boton.Parent = marco
	redondear(boton, 8)

	filas[mueble.id] = { boton = boton, mueble = mueble }
	boton.Activated:Connect(function()
		if ConfigCasas.muebles(jugador)[mueble.id] then
			return
		end
		local ok, respuesta = comprarMueble:InvokeServer(mueble.id)
		mensaje.Text = respuesta or ""
		mensaje.TextColor3 = ok and Color3.fromRGB(0, 220, 100) or Color3.fromRGB(255, 100, 100)
	end)
end

local function actualizar()
	local tengo = ConfigCasas.muebles(jugador)
	for id, fila in filas do
		if tengo[id] then
			fila.boton.Text = "En tu casa ✓"
			fila.boton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		else
			fila.boton.Text = string.format("Comprar · %d", fila.mueble.precio)
			fila.boton.BackgroundColor3 = monedas.Value >= fila.mueble.precio and COLOR_VERDE or COLOR_GRIS
		end
	end
end

abrirMuebles.OnClientEvent:Connect(function()
	mensaje.Text = ""
	actualizar()
	if not panel.Visible then
		Interfaz.alternar(panel)
	end
end)

monedas.Changed:Connect(actualizar)
jugador:GetAttributeChangedSignal("Muebles"):Connect(actualizar)
actualizar()
