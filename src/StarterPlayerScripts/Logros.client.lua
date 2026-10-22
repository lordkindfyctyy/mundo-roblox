-- Interfaz de logros: boton "Logros", panel con el progreso de cada uno
-- y un aviso en pantalla cuando se desbloquea uno nuevo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ConfigLogros = require(ReplicatedStorage:WaitForChild("ConfigLogros"))
local aviso = ReplicatedStorage:WaitForChild("LogroDesbloqueado")

local jugador = Players.LocalPlayer
local carpeta = jugador:WaitForChild("Logros")

local COLOR_HECHO = Color3.fromRGB(0, 150, 80)
local COLOR_PENDIENTE = Color3.fromRGB(50, 50, 50)

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Logros"
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

-- Boton debajo de Tienda y Regalo
local botonAbrir = Instance.new("TextButton")
botonAbrir.AnchorPoint = Vector2.new(0, 0.5)
botonAbrir.Position = UDim2.new(0, 20, 0.5, 112)
botonAbrir.Size = UDim2.fromOffset(120, 46)
botonAbrir.BackgroundColor3 = Color3.fromRGB(150, 70, 220)
botonAbrir.Font = Enum.Font.GothamBold
botonAbrir.TextSize = 20
botonAbrir.TextColor3 = Color3.new(1, 1, 1)
botonAbrir.Text = "Logros"
botonAbrir.Parent = pantalla
redondear(botonAbrir, 10)

-- Panel
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(460, 460)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.Visible = false
panel.Parent = pantalla
redondear(panel, 14)

local titulo = nuevoTexto(panel, 26, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 0))
titulo.Size = UDim2.new(1, 0, 0, 50)

local lista = Instance.new("ScrollingFrame")
lista.Position = UDim2.fromOffset(0, 55)
lista.Size = UDim2.new(1, 0, 1, -65)
lista.BackgroundTransparency = 1
lista.BorderSizePixel = 0
lista.ScrollBarThickness = 6
lista.CanvasSize = UDim2.fromOffset(0, #ConfigLogros.Lista * 72)
lista.Parent = panel

-- Una fila por logro
local filas = {}

for i, logro in ConfigLogros.Lista do
	local marco = Instance.new("Frame")
	marco.Position = UDim2.fromOffset(15, (i - 1) * 72)
	marco.Size = UDim2.new(1, -36, 0, 64)
	marco.Parent = lista
	redondear(marco, 10)

	local nombre = nuevoTexto(marco, 17, Enum.Font.GothamBold, Color3.new(1, 1, 1), Enum.TextXAlignment.Left)
	nombre.Position = UDim2.fromOffset(12, 6)
	nombre.Size = UDim2.new(0.6, 0, 0, 24)
	nombre.Text = logro.nombre

	local descripcion = nuevoTexto(marco, 13, Enum.Font.Gotham, Color3.fromRGB(200, 200, 200), Enum.TextXAlignment.Left)
	descripcion.Position = UDim2.fromOffset(12, 32)
	descripcion.Size = UDim2.new(0.6, 0, 0, 22)
	descripcion.Text = logro.descripcion

	local estado = nuevoTexto(marco, 16, Enum.Font.GothamBold, Color3.new(1, 1, 1), Enum.TextXAlignment.Right)
	estado.AnchorPoint = Vector2.new(1, 0)
	estado.Position = UDim2.new(1, -12, 0, 8)
	estado.Size = UDim2.new(0.38, 0, 0, 24)

	local premio = nuevoTexto(marco, 13, Enum.Font.Gotham, Color3.fromRGB(255, 205, 0), Enum.TextXAlignment.Right)
	premio.AnchorPoint = Vector2.new(1, 0)
	premio.Position = UDim2.new(1, -12, 0, 34)
	premio.Size = UDim2.new(0.38, 0, 0, 22)
	premio.Text = "Premio: " .. logro.premio .. " monedas"

	filas[logro.id] = { marco = marco, estado = estado }
end

local function actualizar()
	local hechos = 0
	for _, logro in ConfigLogros.Lista do
		local fila = filas[logro.id]
		if carpeta:FindFirstChild(logro.id) then
			hechos += 1
			fila.marco.BackgroundColor3 = COLOR_HECHO
			fila.estado.Text = "¡Completado!"
		else
			local actual = math.min(logro.valor(jugador), logro.meta)
			fila.marco.BackgroundColor3 = COLOR_PENDIENTE
			fila.estado.Text = string.format("%d / %d", actual, logro.meta)
		end
	end
	titulo.Text = string.format("Logros  (%d/%d)", hechos, #ConfigLogros.Lista)
end

botonAbrir.Activated:Connect(function()
	panel.Visible = not panel.Visible
	actualizar()
end)

carpeta.ChildAdded:Connect(actualizar)
actualizar()

-- Mientras el panel esta abierto el progreso se refresca solo
task.spawn(function()
	while true do
		task.wait(1)
		if panel.Visible then
			actualizar()
		end
	end
end)

-- Aviso al desbloquear un logro
local toast = Instance.new("Frame")
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, -80)
toast.Size = UDim2.fromOffset(420, 64)
toast.BackgroundColor3 = Color3.fromRGB(150, 70, 220)
toast.Parent = pantalla
redondear(toast, 12)

local textoToast = nuevoTexto(toast, 20, Enum.Font.GothamBold, Color3.new(1, 1, 1))
textoToast.Size = UDim2.fromScale(1, 1)

local contador = 0 -- evita que un aviso viejo esconda a uno nuevo

aviso.OnClientEvent:Connect(function(nombre, monedas)
	contador += 1
	local mio = contador
	textoToast.Text = string.format("¡Logro: %s!  +%d monedas", nombre, monedas)

	local info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(toast, info, { Position = UDim2.new(0.5, 0, 0, 150) }):Play()

	task.delay(4, function()
		if mio == contador then
			TweenService:Create(toast, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0, -80) }):Play()
		end
	end)
end)
