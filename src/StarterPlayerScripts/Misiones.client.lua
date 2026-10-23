-- Tarjeta con la mision activa (arriba a la derecha) y una columna de luz amarilla,
-- que solo ve este jugador, en el lugar al que tiene que ir. Lee los atributos
-- que pone Misiones.server.lua: MisionTexto, MisionDetalle, MisionPremio y MisionDestino.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local cambiar = ReplicatedStorage:WaitForChild("CambiarMision")

local jugador = Players.LocalPlayer
local COLOR_MARCA = Color3.fromRGB(255, 220, 0)

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Misiones"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local tarjeta = Instance.new("Frame")
tarjeta.AnchorPoint = Vector2.new(1, 0)
tarjeta.Size = UDim2.fromOffset(300, 92)
tarjeta.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tarjeta.BackgroundTransparency = 0.15
tarjeta.Parent = pantalla
Interfaz.escalar(tarjeta)
-- En la compu va arriba a la derecha; en el celular, debajo de los botones Mascotas y Mi casa
Interfaz.alCambiarPantalla(function()
	local y = Interfaz.esTactil() and 10 + 112 * Interfaz.escala() or 10
	tarjeta.Position = UDim2.new(1, -12, 0, y)
end)

local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(0, 12)
esquinas.Parent = tarjeta

local function texto(posicion, tamano, letra, color, alto)
	local t = Instance.new("TextLabel")
	t.Position = posicion
	t.Size = tamano
	t.BackgroundTransparency = 1
	t.Font = letra
	t.TextSize = alto
	t.TextWrapped = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Top
	t.TextColor3 = color
	t.Parent = tarjeta
	return t
end

local titulo = texto(UDim2.fromOffset(10, 6), UDim2.new(1, -90, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(255, 205, 0), 16)
titulo.Text = "🎯 Misión"
local descripcion = texto(UDim2.fromOffset(10, 26), UDim2.new(1, -20, 0, 38), Enum.Font.GothamBold, Color3.new(1, 1, 1), 15)
local detalle = texto(UDim2.fromOffset(10, 66), UDim2.new(1, -20, 0, 20), Enum.Font.Gotham, Color3.fromRGB(200, 230, 200), 14)

local botonCambiar = Instance.new("TextButton")
botonCambiar.AnchorPoint = Vector2.new(1, 0)
botonCambiar.Position = UDim2.new(1, -8, 0, 6)
botonCambiar.Size = UDim2.fromOffset(74, 22)
botonCambiar.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
botonCambiar.Font = Enum.Font.GothamBold
botonCambiar.TextSize = 13
botonCambiar.TextColor3 = Color3.new(1, 1, 1)
botonCambiar.Text = "Cambiar"
botonCambiar.Parent = tarjeta
local esquinasBoton = Instance.new("UICorner")
esquinasBoton.CornerRadius = UDim.new(0, 6)
esquinasBoton.Parent = botonCambiar
botonCambiar.Activated:Connect(function()
	cambiar:FireServer()
end)

-- Columna de luz en el destino: una parte local (no existe para los demas)
local marca = Instance.new("Part")
marca.Name = "MarcaMision"
marca.Anchored = true
marca.CanCollide = false
marca.CanQuery = false
marca.CanTouch = false
marca.Shape = Enum.PartType.Cylinder
marca.Size = Vector3.new(80, 6, 6) -- el cilindro mide su largo en X: se lo para con la rotacion
marca.Material = Enum.Material.Neon
marca.Color = COLOR_MARCA
marca.Transparency = 0.55

local cartelMarca = Instance.new("BillboardGui")
cartelMarca.Size = UDim2.fromOffset(120, 40)
cartelMarca.AlwaysOnTop = true
cartelMarca.StudsOffset = Vector3.new(0, 0, 0)
cartelMarca.Parent = marca
local textoMarca = Instance.new("TextLabel")
textoMarca.Size = UDim2.fromScale(1, 1)
textoMarca.BackgroundTransparency = 1
textoMarca.Font = Enum.Font.GothamBlack
textoMarca.TextScaled = true
textoMarca.TextStrokeTransparency = 0.3
textoMarca.TextColor3 = COLOR_MARCA
textoMarca.Text = "🎯"
textoMarca.Parent = cartelMarca

local function actualizar()
	descripcion.Text = jugador:GetAttribute("MisionTexto") or "Buscando misión..."
	local premio = jugador:GetAttribute("MisionPremio")
	local avance = jugador:GetAttribute("MisionDetalle") or ""
	local partes = {}
	if avance ~= "" then
		table.insert(partes, avance)
	end
	if premio and avance ~= "Ya viene la próxima..." then
		table.insert(partes, "Premio: " .. premio)
	end
	detalle.Text = table.concat(partes, " · ")

	local destino = jugador:GetAttribute("MisionDestino")
	if destino then
		marca.CFrame = CFrame.new(destino + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90))
		marca.Parent = Workspace
	else
		marca.Parent = nil
	end
end

for _, nombre in { "MisionTexto", "MisionDetalle", "MisionPremio", "MisionDestino" } do
	jugador:GetAttributeChangedSignal(nombre):Connect(actualizar)
end
actualizar()

-- Distancia al destino, en la tarjeta y sobre la marca
while true do
	local destino = jugador:GetAttribute("MisionDestino")
	local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
	if destino and raiz then
		local metros = math.floor(((raiz.Position - destino) * Vector3.new(1, 0, 1)).Magnitude)
		textoMarca.Text = string.format("🎯 %d m", metros)
		titulo.Text = string.format("🎯 Misión · a %d m", metros)
	else
		titulo.Text = "🎯 Misión"
	end
	task.wait(0.2)
end
