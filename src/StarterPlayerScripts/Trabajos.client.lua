-- Tarjeta del trabajo (abajo, en el medio) y una columna de luz naranja, que solo ve
-- este jugador, en el lugar al que tiene que ir. Lee los atributos que pone
-- Trabajos.server.lua: TrabajoId, TrabajoTexto, TrabajoDestino, TrabajoFin,
-- TrabajoGanado y TrabajoViajes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConfigTrabajos = require(ReplicatedStorage:WaitForChild("ConfigTrabajos"))
local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local dejar = ReplicatedStorage:WaitForChild("DejarTrabajo")

local jugador = Players.LocalPlayer
local COLOR_MARCA = Color3.fromRGB(255, 140, 0)
local COLOR_APURO = Color3.fromRGB(255, 90, 90)

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Trabajos"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local tarjeta = Instance.new("Frame")
tarjeta.AnchorPoint = Vector2.new(0.5, 1)
tarjeta.Size = UDim2.fromOffset(380, 84)
tarjeta.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tarjeta.BackgroundTransparency = 0.15
tarjeta.Visible = false
tarjeta.Parent = pantalla
Interfaz.escalar(tarjeta)
-- Encima del cartel del alimento de las mascotas (Alimentos.client.lua)
Interfaz.alCambiarPantalla(function()
	tarjeta.Position = UDim2.new(0.5, 0, 1, -(20 + 56 * Interfaz.escala()))
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
local descripcion = texto(UDim2.fromOffset(10, 28), UDim2.new(1, -20, 0, 34), Enum.Font.GothamBold, Color3.new(1, 1, 1), 15)
local detalle = texto(UDim2.fromOffset(10, 62), UDim2.new(1, -20, 0, 18), Enum.Font.Gotham, Color3.fromRGB(200, 230, 200), 13)

local botonDejar = Instance.new("TextButton")
botonDejar.AnchorPoint = Vector2.new(1, 0)
botonDejar.Position = UDim2.new(1, -8, 0, 6)
botonDejar.Size = UDim2.fromOffset(74, 22)
botonDejar.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
botonDejar.Font = Enum.Font.GothamBold
botonDejar.TextSize = 13
botonDejar.TextColor3 = Color3.new(1, 1, 1)
botonDejar.Text = "Dejar"
botonDejar.Parent = tarjeta
local esquinasBoton = Instance.new("UICorner")
esquinasBoton.CornerRadius = UDim.new(0, 6)
esquinasBoton.Parent = botonDejar
botonDejar.Activated:Connect(function()
	dejar:FireServer()
end)

-- Columna de luz en el destino: una parte local (no existe para los demas)
local marca = Instance.new("Part")
marca.Name = "MarcaTrabajo"
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
cartelMarca.Parent = marca
local textoMarca = Instance.new("TextLabel")
textoMarca.Size = UDim2.fromScale(1, 1)
textoMarca.BackgroundTransparency = 1
textoMarca.Font = Enum.Font.GothamBlack
textoMarca.TextScaled = true
textoMarca.TextStrokeTransparency = 0.3
textoMarca.TextColor3 = COLOR_MARCA
textoMarca.Parent = cartelMarca

local function trabajoActual()
	local id = jugador:GetAttribute("TrabajoId")
	return id and ConfigTrabajos.buscar(id)
end

local function actualizar()
	local trabajo = trabajoActual()
	tarjeta.Visible = trabajo ~= nil
	if not trabajo then
		marca.Parent = nil
		return
	end
	descripcion.Text = jugador:GetAttribute("TrabajoTexto") or ""
	detalle.Text = string.format("Ganaste %d monedas · %d viajes", jugador:GetAttribute("TrabajoGanado") or 0, jugador:GetAttribute("TrabajoViajes") or 0)
	textoMarca.Text = trabajo.emoji

	local destino = jugador:GetAttribute("TrabajoDestino")
	if destino then
		marca.CFrame = CFrame.new(destino + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90))
		marca.Parent = Workspace
	else
		marca.Parent = nil
	end
end

for _, nombre in { "TrabajoId", "TrabajoTexto", "TrabajoDestino", "TrabajoGanado", "TrabajoViajes" } do
	jugador:GetAttributeChangedSignal(nombre):Connect(actualizar)
end
actualizar()

-- Titulo con el tiempo que queda (si hay apuro) y la distancia en la marca
while true do
	local trabajo = trabajoActual()
	if trabajo then
		local partes = { trabajo.emoji .. " " .. trabajo.nombre }
		local fin = jugador:GetAttribute("TrabajoFin")
		titulo.TextColor3 = Color3.fromRGB(255, 205, 0)
		if fin then
			local quedan = math.max(0, math.ceil(fin - Workspace:GetServerTimeNow()))
			table.insert(partes, string.format("⏱ %d:%02d", quedan // 60, quedan % 60))
			if quedan <= 10 then
				titulo.TextColor3 = COLOR_APURO
			end
		end
		local destino = jugador:GetAttribute("TrabajoDestino")
		local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
		if destino and raiz then
			local metros = math.floor(((raiz.Position - destino) * Vector3.new(1, 0, 1)).Magnitude)
			textoMarca.Text = string.format("%s %d m", trabajo.emoji, metros)
		end
		titulo.Text = table.concat(partes, " · ")
	end
	task.wait(0.2)
end
