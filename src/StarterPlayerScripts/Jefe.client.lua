-- Jefe gigante, del lado del jugador (Jefe.server.lua maneja la pelea):
--   * Barra arriba con la vida del Monstruo de Monedas, el tiempo y tus golpes.
--     Lee los atributos JefeEstado, JefeVida, JefeVidaMax y JefeFin de Workspace.
--   * Cuando el servidor avisa con EmpujeJefe (un pisoton cerca), te tira para atras.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local empuje = ReplicatedStorage:WaitForChild("EmpujeJefe")

local jugador = Players.LocalPlayer
local FUERZA_EMPUJE = 55
local ALTURA_EMPUJE = 40

---------------------------------------------------------------- Barra de vida

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Jefe"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local marco = Instance.new("Frame")
marco.AnchorPoint = Vector2.new(0.5, 0)
marco.Size = UDim2.fromOffset(440, 74)
marco.BackgroundColor3 = Color3.fromRGB(60, 20, 30)
marco.BackgroundTransparency = 0.1
marco.Visible = false
marco.Parent = pantalla
Interfaz.escalar(marco)
Interfaz.alCambiarPantalla(function()
	marco.Position = UDim2.new(0.5, 0, 0, 144 * Interfaz.escala()) -- debajo del cartel de eventos
end)

local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(0, 12)
esquinas.Parent = marco

local borde = Instance.new("UIStroke")
borde.Color = Color3.fromRGB(255, 200, 50)
borde.Thickness = 2
borde.Parent = marco

local titulo = Instance.new("TextLabel")
titulo.Position = UDim2.fromOffset(12, 4)
titulo.Size = UDim2.new(1, -24, 0, 26)
titulo.BackgroundTransparency = 1
titulo.Font = Enum.Font.GothamBold
titulo.TextSize = 20
titulo.TextColor3 = Color3.fromRGB(255, 225, 90)
titulo.Parent = marco

local fondo = Instance.new("Frame")
fondo.Position = UDim2.fromOffset(12, 32)
fondo.Size = UDim2.new(1, -24, 0, 14)
fondo.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
fondo.BorderSizePixel = 0
fondo.Parent = marco
Instance.new("UICorner").Parent = fondo

local barra = Instance.new("Frame")
barra.Size = UDim2.fromScale(1, 1)
barra.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
barra.BorderSizePixel = 0
barra.Parent = fondo
Instance.new("UICorner").Parent = barra

local detalle = Instance.new("TextLabel")
detalle.Position = UDim2.fromOffset(12, 48)
detalle.Size = UDim2.new(1, -24, 0, 22)
detalle.BackgroundTransparency = 1
detalle.Font = Enum.Font.Gotham
detalle.TextSize = 16
detalle.TextColor3 = Color3.fromRGB(255, 255, 255)
detalle.Parent = marco

local function restante()
	local fin = Workspace:GetAttribute("JefeFin")
	return fin and math.max(0, math.ceil(fin - Workspace:GetServerTimeNow())) or 0
end

RunService.Heartbeat:Connect(function()
	local estado = Workspace:GetAttribute("JefeEstado")
	marco.Visible = estado ~= nil
	if not estado then
		return
	end

	local vida = Workspace:GetAttribute("JefeVida") or 0
	local vidaMax = Workspace:GetAttribute("JefeVidaMax") or 1
	fondo.Visible = estado ~= "llega"
	barra.Size = UDim2.fromScale(math.clamp(vida / vidaMax, 0, 1), 1)

	if estado == "llega" then
		titulo.Text = string.format("👹 ¡Llega el Monstruo de Monedas en %ds!", restante())
		detalle.Text = "Andá al parque del centro"
		detalle.Position = UDim2.fromOffset(12, 34)
	else
		detalle.Position = UDim2.fromOffset(12, 48)
		if estado == "pelea" then
			titulo.Text = string.format("👹 Monstruo de Monedas  ·  %ds", restante())
			local golpes = jugador:GetAttribute("DanioJefe") or 0
			detalle.Text = string.format("Tocalo para pegarle  ·  Tus golpes: %d  ·  Vida: %d", golpes, vida)
		elseif estado == "derrotado" then
			titulo.Text = "👹 ¡Monstruo derrotado!"
			detalle.Text = "¡Juntá las monedas que cayeron!"
		else
			titulo.Text = "👹 ¡El monstruo se escapó!"
			detalle.Text = "Va a volver más tarde..."
		end
	end
end)

---------------------------------------------------------------- Pisoton

empuje.OnClientEvent:Connect(function(direccion)
	local personaje = jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	-- Si va sentado (en un auto o un juego) no lo mueve
	if not humanoide or not raiz or humanoide.Sit or humanoide.Health <= 0 then
		return
	end
	humanoide:ChangeState(Enum.HumanoidStateType.Jumping)
	raiz.AssemblyLinearVelocity = direccion * FUERZA_EMPUJE + Vector3.new(0, ALTURA_EMPUJE, 0)
end)
