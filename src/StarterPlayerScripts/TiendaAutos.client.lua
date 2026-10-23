-- Panel de la tienda de autos: se abre desde el taller del estacionamiento
-- (TiendaAutos.server.lua). Una fila por cosa, agrupadas por categoria, con el
-- boton de comprar, poner o sacar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigAutos = require(ReplicatedStorage:WaitForChild("ConfigAutos"))
local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local tienda = ReplicatedStorage:WaitForChild("TiendaAutos")
local abrir = ReplicatedStorage:WaitForChild("AbrirTiendaAutos")

local jugador = Players.LocalPlayer
local monedas = jugador:WaitForChild("leaderstats"):WaitForChild("Monedas")

local COLOR_VERDE = Color3.fromRGB(0, 170, 80)
local COLOR_NARANJA = Color3.fromRGB(220, 120, 0)
local COLOR_GRIS = Color3.fromRGB(90, 90, 90)
local COLOR_AZUL = Color3.fromRGB(40, 110, 220)
local ALTO_FILA = 52

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "TiendaAutos"
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
panel.Size = UDim2.fromOffset(460, 520)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.Visible = false
panel.Parent = pantalla
redondear(panel, 14)
Interfaz.panel(panel, 460, 520)

local titulo = texto(panel, 26, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 0))
titulo.Size = UDim2.new(1, 0, 0, 44)
titulo.Text = "🚗 Tienda de autos"

local ayuda = texto(panel, 13, Enum.Font.Gotham, Color3.fromRGB(200, 200, 200))
ayuda.Position = UDim2.fromOffset(10, 40)
ayuda.Size = UDim2.new(1, -20, 0, 18)
ayuda.Text = "Lo que tengas puesto lo lleva cualquier auto que manejes"

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

local filas = {}
local y = 0
for _, categoria in ConfigAutos.Categorias do
	local encabezado = texto(lista, 16, Enum.Font.GothamBlack, Color3.fromRGB(255, 205, 0), Enum.TextXAlignment.Left)
	encabezado.Position = UDim2.fromOffset(18, y)
	encabezado.Size = UDim2.new(1, -36, 0, 24)
	encabezado.Text = categoria.nombre
	y += 26

	for _, cosa in ConfigAutos.Lista do
		if cosa.categoria == categoria.id then
			local marco = Instance.new("Frame")
			marco.Position = UDim2.fromOffset(15, y)
			marco.Size = UDim2.new(1, -36, 0, ALTO_FILA - 6)
			marco.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			marco.Parent = lista
			redondear(marco, 10)

			local muestra = Instance.new("Frame")
			muestra.Position = UDim2.fromOffset(10, 9)
			muestra.Size = UDim2.fromOffset(28, 28)
			muestra.BackgroundColor3 = cosa.color or Color3.fromRGB(200, 60, 60)
			muestra.Parent = marco
			redondear(muestra, 14)

			local nombre = texto(marco, 15, Enum.Font.GothamBold, Color3.new(1, 1, 1), Enum.TextXAlignment.Left)
			nombre.Position = UDim2.fromOffset(48, 4)
			nombre.Size = UDim2.new(0.55, 0, 0, 20)
			nombre.Text = cosa.nombre

			local detalle = texto(marco, 12, Enum.Font.Gotham, Color3.fromRGB(200, 200, 200), Enum.TextXAlignment.Left)
			detalle.Position = UDim2.fromOffset(48, 24)
			detalle.Size = UDim2.new(0.55, 0, 0, 18)
			detalle.Text = cosa.velocidad and string.format("Más rápido (%d) y alerón", cosa.velocidad) or ""

			local boton = Instance.new("TextButton")
			boton.AnchorPoint = Vector2.new(1, 0.5)
			boton.Position = UDim2.new(1, -8, 0.5, 0)
			boton.Size = UDim2.fromOffset(120, 34)
			boton.Font = Enum.Font.GothamBold
			boton.TextSize = 14
			boton.TextColor3 = Color3.new(1, 1, 1)
			boton.Parent = marco
			redondear(boton, 8)

			filas[cosa.id] = { boton = boton, detalle = detalle, cosa = cosa }
			y += ALTO_FILA
		end
	end
	y += 6
end
lista.CanvasSize = UDim2.fromOffset(0, y)

local function comprados()
	local tengo = {}
	for id in string.gmatch(jugador:GetAttribute("AutoCosas") or "", "[^,]+") do
		tengo[id] = true
	end
	return tengo
end

local function accionDe(cosa, tengo)
	local puesto = jugador:GetAttribute(ConfigAutos.ATRIBUTO[cosa.categoria]) == cosa.id
	if puesto then
		return "sacar"
	elseif tengo[cosa.id] then
		return "poner"
	end
	return "comprar"
end

local function actualizar()
	local tengo = comprados()
	for _, fila in filas do
		local accion = accionDe(fila.cosa, tengo)
		if accion == "sacar" then
			fila.boton.Text = "Puesto ✓ (sacar)"
			fila.boton.BackgroundColor3 = COLOR_NARANJA
		elseif accion == "poner" then
			fila.boton.Text = "Poner"
			fila.boton.BackgroundColor3 = COLOR_AZUL
		else
			fila.boton.Text = string.format("Comprar · %d", fila.cosa.precio)
			fila.boton.BackgroundColor3 = monedas.Value >= fila.cosa.precio and COLOR_VERDE or COLOR_GRIS
		end
	end
end

for id, fila in filas do
	fila.boton.Activated:Connect(function()
		local accion = accionDe(fila.cosa, comprados())
		local ok, respuesta = tienda:InvokeServer(accion, id)
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
for _, atributo in ConfigAutos.ATRIBUTO do
	jugador:GetAttributeChangedSignal(atributo):Connect(actualizar)
end
jugador:GetAttributeChangedSignal("AutoCosas"):Connect(actualizar)
actualizar()
