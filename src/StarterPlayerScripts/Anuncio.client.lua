-- Cartel que anuncia el evento activo, con cuenta regresiva.
-- Lee los atributos EventoNombre y EventoFin que pone Eventos.server.lua en Workspace.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local jugador = Players.LocalPlayer

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "AnuncioEvento"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local marco = Instance.new("Frame")
marco.AnchorPoint = Vector2.new(0.5, 0)
marco.Position = UDim2.new(0.5, 0, 0, 80) -- justo debajo del marcador de monedas
marco.Size = UDim2.fromOffset(440, 56)
marco.BackgroundColor3 = Color3.fromRGB(255, 205, 0)
marco.Visible = false
marco.Parent = pantalla

local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(0, 12)
esquinas.Parent = marco

local texto = Instance.new("TextLabel")
texto.Size = UDim2.fromScale(1, 1)
texto.BackgroundTransparency = 1
texto.Font = Enum.Font.GothamBold
texto.TextSize = 24
texto.TextColor3 = Color3.fromRGB(40, 30, 0)
texto.Parent = marco

local conexion

local function ocultar()
	marco.Visible = false
	if conexion then
		conexion:Disconnect()
		conexion = nil
	end
end

local function mostrar()
	local nombre = Workspace:GetAttribute("EventoNombre")
	local fin = Workspace:GetAttribute("EventoFin")
	if not nombre or not fin then
		ocultar()
		return
	end

	if conexion then
		conexion:Disconnect()
	end

	-- Aparece con un rebote
	marco.Size = UDim2.fromOffset(500, 66)
	marco.Visible = true
	TweenService:Create(marco, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(440, 56),
	}):Play()

	conexion = RunService.Heartbeat:Connect(function()
		local restante = fin - Workspace:GetServerTimeNow()
		if restante <= 0 then
			ocultar()
			return
		end
		texto.Text = string.format("%s  (%ds)", nombre, math.ceil(restante))
	end)
end

Workspace:GetAttributeChangedSignal("EventoFin"):Connect(mostrar)
mostrar() -- por si entramos con un evento en marcha
