-- Panel de la tienda de golf: se abre desde el kiosco junto a la caseta (TiendaGolf.server.lua).
-- Dos secciones: palos (se compran una vez) y pelotas (se compran y se elige cual usar).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigGolf = require(ReplicatedStorage:WaitForChild("ConfigGolf"))
local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local tienda = ReplicatedStorage:WaitForChild("TiendaGolf")
local abrir = ReplicatedStorage:WaitForChild("AbrirTiendaGolf")

local jugador = Players.LocalPlayer
local monedas = jugador:WaitForChild("leaderstats"):WaitForChild("Monedas")

local COLOR_VERDE = Color3.fromRGB(0, 170, 80)
local COLOR_GRIS = Color3.fromRGB(90, 90, 90)
local COLOR_AZUL = Color3.fromRGB(40, 110, 220)
local COLOR_NARANJA = Color3.fromRGB(220, 120, 0)
local ALTO_FILA = 56

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "TiendaGolf"
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

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(460, 540)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.Visible = false
panel.Parent = pantalla
redondear(panel, 14)
Interfaz.panel(panel, 460, 540)

local titulo = texto(panel, 26, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 0))
titulo.Size = UDim2.new(1, 0, 0, 44)
titulo.Text = "🏌️ Tienda de golf"

local ayuda = texto(panel, 13, Enum.Font.Gotham, Color3.fromRGB(200, 200, 200))
ayuda.Position = UDim2.fromOffset(10, 40)
ayuda.Size = UDim2.new(1, -20, 0, 18)
ayuda.Text = "Los palos nuevos aparecen en la barra cuando jugás"

local mensaje = texto(panel, 15, Enum.Font.GothamBold, Color3.new(1, 1, 1))
mensaje.AnchorPoint = Vector2.new(0, 1)
mensaje.Position = UDim2.new(0, 10, 1, -8)
mensaje.Size = UDim2.new(1, -20, 0, 22)

local lista = Instance.new("ScrollingFrame")
lista.Position = UDim2.fromOffset(0, 64)
lista.Size = UDim2.new(1, 0, 1, -100)
lista.BackgroundTransparency = 1
lista.BorderSizePixel = 0
lista.ScrollBarThickness = 6
lista.Parent = panel

local filas = {} -- { boton, tipo, cosa }
local y = 0

local function encabezado(nombre)
	local e = texto(lista, 16, Enum.Font.GothamBlack, Color3.fromRGB(255, 205, 0), Enum.TextXAlignment.Left)
	e.Position = UDim2.fromOffset(18, y)
	e.Size = UDim2.new(1, -36, 0, 24)
	e.Text = nombre
	y += 26
end

local function fila(tipo, cosa, icono, color, descripcion)
	local marco = Instance.new("Frame")
	marco.Position = UDim2.fromOffset(15, y)
	marco.Size = UDim2.new(1, -36, 0, ALTO_FILA - 6)
	marco.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	marco.Parent = lista
	redondear(marco, 10)

	local muestra = Instance.new("TextLabel")
	muestra.Position = UDim2.fromOffset(8, 7)
	muestra.Size = UDim2.fromOffset(36, 36)
	muestra.BackgroundColor3 = color
	muestra.Font = Enum.Font.GothamBold
	muestra.TextSize = 20
	muestra.Text = icono
	muestra.Parent = marco
	redondear(muestra, 18)

	local nombre = texto(marco, 15, Enum.Font.GothamBold, Color3.new(1, 1, 1), Enum.TextXAlignment.Left)
	nombre.Position = UDim2.fromOffset(52, 4)
	nombre.Size = UDim2.new(0.55, 0, 0, 20)
	nombre.Text = cosa.nombre

	local detalle = texto(marco, 11, Enum.Font.Gotham, Color3.fromRGB(200, 200, 200), Enum.TextXAlignment.Left)
	detalle.Position = UDim2.fromOffset(52, 24)
	detalle.Size = UDim2.new(0.55, 0, 0, 20)
	detalle.TextWrapped = true
	detalle.Text = descripcion

	local boton = Instance.new("TextButton")
	boton.AnchorPoint = Vector2.new(1, 0.5)
	boton.Position = UDim2.new(1, -8, 0.5, 0)
	boton.Size = UDim2.fromOffset(120, 34)
	boton.Font = Enum.Font.GothamBold
	boton.TextSize = 14
	boton.TextColor3 = Color3.new(1, 1, 1)
	boton.Parent = marco
	redondear(boton, 8)

	table.insert(filas, { boton = boton, tipo = tipo, cosa = cosa })
	y += ALTO_FILA
end

encabezado("Palos")
for _, palo in ConfigGolf.Palos do
	local descripcion = palo.detalle or string.format("Fuerza %d", palo.velocidad)
	fila("palo", palo, "🏌️", Color3.fromRGB(70, 110, 70), descripcion)
end
y += 6

encabezado("Pelotas")
for _, pelota in ConfigGolf.Pelotas do
	local extras = {}
	if pelota.fuego then
		table.insert(extras, "fuego")
	end
	if pelota.luz then
		table.insert(extras, "luz")
	end
	if pelota.estela then
		table.insert(extras, "estela")
	end
	if pelota.arcoiris then
		table.insert(extras, "cambia de color")
	end
	local descripcion = #extras > 0 and table.concat(extras, " · ") or "Sin efectos"
	fila("pelota", pelota, pelota.icono, pelota.color, descripcion)
end
lista.CanvasSize = UDim2.fromOffset(0, y + 6)

local function accionDe(f, tengo)
	local tiene = ConfigGolf.tiene(tengo, f.cosa)
	if f.tipo == "pelota" then
		local puesta = ConfigGolf.pelota(jugador:GetAttribute("GolfBola")).id == f.cosa.id
		if puesta then
			return "puesta"
		elseif tiene then
			return "poner"
		end
	elseif tiene then
		return "tenes"
	end
	return "comprar"
end

local function actualizar()
	local tengo = ConfigGolf.comprados(jugador:GetAttribute("GolfCosas"))
	for _, f in filas do
		local accion = accionDe(f, tengo)
		if accion == "puesta" then
			f.boton.Text = "Puesta ✓"
			f.boton.BackgroundColor3 = COLOR_NARANJA
		elseif accion == "poner" then
			f.boton.Text = "Usar"
			f.boton.BackgroundColor3 = COLOR_AZUL
		elseif accion == "tenes" then
			f.boton.Text = "Lo tenés ✓"
			f.boton.BackgroundColor3 = COLOR_GRIS
		else
			f.boton.Text = string.format("Comprar · %d", f.cosa.precio)
			f.boton.BackgroundColor3 = monedas.Value >= f.cosa.precio and COLOR_VERDE or COLOR_GRIS
		end
	end
end

for _, f in filas do
	f.boton.Activated:Connect(function()
		local accion = accionDe(f, ConfigGolf.comprados(jugador:GetAttribute("GolfCosas")))
		if accion == "puesta" or accion == "tenes" then
			return
		end
		local ok, respuesta = tienda:InvokeServer(accion, f.tipo, f.cosa.id)
		mensaje.Text = respuesta or ""
		mensaje.TextColor3 = ok and Color3.fromRGB(0, 220, 100) or Color3.fromRGB(255, 100, 100)
		actualizar()
	end)
end

abrir.OnClientEvent:Connect(function()
	mensaje.Text = ""
	actualizar()
	if not panel.Visible then
		Interfaz.alternar(panel)
	end
end)

monedas.Changed:Connect(actualizar)
jugador:GetAttributeChangedSignal("GolfCosas"):Connect(actualizar)
jugador:GetAttributeChangedSignal("GolfBola"):Connect(actualizar)
actualizar()
