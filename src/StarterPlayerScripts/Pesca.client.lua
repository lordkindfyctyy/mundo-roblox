-- Pesca, lado del jugador: la barra de abajo (esperando / ¡TIRAR! / resultado) y el panel de la
-- tienda de pesca, que tambien muestra los peces atrapados (se abre desde el kiosco del muelle).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ConfigPesca = require(ReplicatedStorage:WaitForChild("ConfigPesca"))
local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local evento = ReplicatedStorage:WaitForChild("PescaEvento")
local accion = ReplicatedStorage:WaitForChild("PescaAccion")
local tienda = ReplicatedStorage:WaitForChild("TiendaPesca")
local abrir = ReplicatedStorage:WaitForChild("AbrirTiendaPesca")

local jugador = Players.LocalPlayer
local monedas = jugador:WaitForChild("leaderstats"):WaitForChild("Monedas")

local COLOR_VERDE = Color3.fromRGB(0, 170, 80)
local COLOR_GRIS = Color3.fromRGB(90, 90, 90)
local COLOR_NARANJA = Color3.fromRGB(220, 120, 0)
local ALTO_FILA = 56

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Pesca"
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

-- Barra de pesca -------------------------------------------------------------------

local barra = Instance.new("Frame")
barra.AnchorPoint = Vector2.new(0.5, 1)
barra.Position = UDim2.new(0.5, 0, 1, -110)
barra.Size = UDim2.fromOffset(340, 120)
barra.BackgroundTransparency = 1
barra.Visible = false
barra.Parent = pantalla
Interfaz.escalar(barra)

local estado = texto(barra, 20, Enum.Font.GothamBold, Color3.new(1, 1, 1))
estado.Size = UDim2.new(1, 0, 0, 34)
estado.TextStrokeTransparency = 0.4

local tirar = Instance.new("TextButton")
tirar.AnchorPoint = Vector2.new(0.5, 0)
tirar.Position = UDim2.new(0.5, 0, 0, 38)
tirar.Size = UDim2.fromOffset(240, 52)
tirar.BackgroundColor3 = Color3.fromRGB(235, 60, 60)
tirar.Font = Enum.Font.GothamBlack
tirar.TextSize = 26
tirar.TextColor3 = Color3.new(1, 1, 1)
tirar.Text = "¡TIRAR!"
tirar.Visible = false
tirar.Parent = barra
redondear(tirar, 12)

local cancelar = Instance.new("TextButton")
cancelar.AnchorPoint = Vector2.new(0.5, 0)
cancelar.Position = UDim2.new(0.5, 0, 0, 92)
cancelar.Size = UDim2.fromOffset(120, 26)
cancelar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
cancelar.Font = Enum.Font.GothamBold
cancelar.TextSize = 14
cancelar.TextColor3 = Color3.new(1, 1, 1)
cancelar.Text = "Recoger"
cancelar.Parent = barra
redondear(cancelar, 8)

local fase = nil -- nil | "espera" | "picada"
local version = 0 -- para que un cartel de resultado viejo no tape al siguiente

local function mostrarResultado(mensaje, color)
	fase = nil
	version += 1
	local esta = version
	tirar.Visible = false
	cancelar.Visible = false
	estado.Text = mensaje
	estado.TextColor3 = color
	barra.Visible = true
	task.delay(3, function()
		if version == esta then
			barra.Visible = false
		end
	end)
end

local function tirarLinea()
	if fase then
		accion:FireServer("tirar")
	end
end

tirar.Activated:Connect(tirarLinea)
cancelar.Activated:Connect(function()
	if fase then
		accion:FireServer("cancelar")
	end
end)
UserInputService.InputBegan:Connect(function(entrada, procesado)
	if procesado or fase ~= "picada" then
		return
	end
	if entrada.UserInputType == Enum.UserInputType.MouseButton1 or entrada.KeyCode == Enum.KeyCode.Space then
		tirarLinea()
	end
end)

evento.OnClientEvent:Connect(function(que, a, b, c)
	if que == "espera" then
		fase = "espera"
		version += 1
		estado.Text = "🎣 Esperando que pique..."
		estado.TextColor3 = Color3.new(1, 1, 1)
		tirar.Visible = false
		cancelar.Visible = true
		barra.Visible = true
	elseif que == "picada" then
		fase = "picada"
		estado.Text = "¡Picó! ¡Tirá ya!"
		estado.TextColor3 = Color3.fromRGB(255, 220, 60)
		tirar.Visible = true
	elseif que == "fin" then
		mostrarResultado(a or "", b and Color3.fromRGB(0, 220, 100) or Color3.fromRGB(255, 130, 130))
	elseif que == "pez" then
		local pez = ConfigPesca.pez(a)
		if not pez then
			return
		end
		local rareza = ConfigPesca.Rarezas[pez.rareza]
		local nuevo = c and " · ¡NUEVO!" or ""
		mostrarResultado(string.format("%s %s (%s) +%d%s", pez.icono, pez.nombre, rareza.nombre, b, nuevo), rareza.color)
	end
end)

-- Panel: cañas y peces -----------------------------------------------------------------

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
titulo.Text = "🎣 Tienda de pesca"

local ayuda = texto(panel, 13, Enum.Font.Gotham, Color3.fromRGB(200, 200, 200))
ayuda.Position = UDim2.fromOffset(10, 40)
ayuda.Size = UDim2.new(1, -20, 0, 18)
ayuda.Text = "Usás siempre la mejor caña que tengas"

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

local y = 0

local function encabezado(nombre)
	local e = texto(lista, 16, Enum.Font.GothamBlack, Color3.fromRGB(255, 205, 0), Enum.TextXAlignment.Left)
	e.Position = UDim2.fromOffset(18, y)
	e.Size = UDim2.new(1, -36, 0, 24)
	e.Text = nombre
	y += 26
	return e
end

-- Devuelve el marco con el nombre y el detalle; el llamador agrega lo que falte a la derecha
local function fila(icono, color, nombreTexto, detalleTexto)
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
	nombre.Text = nombreTexto

	local detalle = texto(marco, 11, Enum.Font.Gotham, Color3.fromRGB(200, 200, 200), Enum.TextXAlignment.Left)
	detalle.Position = UDim2.fromOffset(52, 24)
	detalle.Size = UDim2.new(0.55, 0, 0, 20)
	detalle.TextWrapped = true
	detalle.Text = detalleTexto

	y += ALTO_FILA
	return marco, nombre, detalle
end

local filasCanas = {} -- { boton, cana }
encabezado("Cañas")
for _, cana in ConfigPesca.Canas do
	local marco = fila(cana.icono, Color3.fromRGB(70, 110, 150), cana.nombre, cana.detalle)
	local boton = Instance.new("TextButton")
	boton.AnchorPoint = Vector2.new(1, 0.5)
	boton.Position = UDim2.new(1, -8, 0.5, 0)
	boton.Size = UDim2.fromOffset(120, 34)
	boton.Font = Enum.Font.GothamBold
	boton.TextSize = 14
	boton.TextColor3 = Color3.new(1, 1, 1)
	boton.Parent = marco
	redondear(boton, 8)
	table.insert(filasCanas, { boton = boton, cana = cana })
end
y += 6

local encabezadoPeces = encabezado("Peces")
local filasPeces = {} -- { pez, nombre, detalle, cantidad }
for _, pez in ConfigPesca.Peces do
	local rareza = ConfigPesca.Rarezas[pez.rareza]
	local marco, nombre, detalle = fila(pez.icono, rareza.color, pez.nombre, "")
	local cantidad = texto(marco, 18, Enum.Font.GothamBlack, Color3.new(1, 1, 1))
	cantidad.AnchorPoint = Vector2.new(1, 0.5)
	cantidad.Position = UDim2.new(1, -12, 0.5, 0)
	cantidad.Size = UDim2.fromOffset(60, 30)
	table.insert(filasPeces, { pez = pez, nombre = nombre, detalle = detalle, cantidad = cantidad })
end
lista.CanvasSize = UDim2.fromOffset(0, y + 6)

local function actualizar()
	local tengo = ConfigPesca.comprados(jugador:GetAttribute("PescaCanas"))
	local usada = ConfigPesca.mejorCana(tengo)
	for _, f in filasCanas do
		if usada.id == f.cana.id then
			f.boton.Text = "En uso ✓"
			f.boton.BackgroundColor3 = COLOR_NARANJA
		elseif ConfigPesca.tiene(tengo, f.cana) then
			f.boton.Text = "Lo tenés ✓"
			f.boton.BackgroundColor3 = COLOR_GRIS
		else
			f.boton.Text = string.format("Comprar · %d", f.cana.precio)
			f.boton.BackgroundColor3 = monedas.Value >= f.cana.precio and COLOR_VERDE or COLOR_GRIS
		end
	end

	local atrapados = ConfigPesca.conteos(jugador:GetAttribute("PescaPeces"))
	encabezadoPeces.Text = string.format("Peces · %d de %d", ConfigPesca.especies(jugador:GetAttribute("PescaPeces")), #ConfigPesca.Peces)
	for _, f in filasPeces do
		local n = atrapados[f.pez.id]
		local rareza = ConfigPesca.Rarezas[f.pez.rareza]
		if n then
			f.nombre.Text = f.pez.nombre
			f.detalle.Text = string.format("%s · paga %d monedas", rareza.nombre, f.pez.valor)
			f.cantidad.Text = "x" .. n
		else
			f.nombre.Text = "???"
			f.detalle.Text = rareza.nombre .. " · todavía no lo atrapaste"
			f.cantidad.Text = ""
		end
	end
end

for _, f in filasCanas do
	f.boton.Activated:Connect(function()
		local tengo = ConfigPesca.comprados(jugador:GetAttribute("PescaCanas"))
		if ConfigPesca.tiene(tengo, f.cana) then
			return
		end
		local ok, respuesta = tienda:InvokeServer("comprar", f.cana.id)
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
jugador:GetAttributeChangedSignal("PescaCanas"):Connect(actualizar)
jugador:GetAttributeChangedSignal("PescaPeces"):Connect(actualizar)
actualizar()
