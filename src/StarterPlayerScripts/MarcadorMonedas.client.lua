-- Marcador en pantalla con las monedas del jugador.
-- Se lee del leaderstats que crea JuegoMonedas.server.lua.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))

local jugador = Players.LocalPlayer

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "MarcadorMonedas"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local marco = Instance.new("Frame")
marco.AnchorPoint = Vector2.new(0.5, 0)
marco.Position = UDim2.new(0.5, 0, 0, 20)
marco.Size = UDim2.fromOffset(200, 50)
marco.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
marco.BackgroundTransparency = 0.2
marco.Parent = pantalla
Interfaz.escalar(marco)
Interfaz.alCambiarPantalla(function()
	marco.Position = UDim2.new(0.5, 0, 0, 20 * Interfaz.escala())
end)

local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(0, 12)
esquinas.Parent = marco

local texto = Instance.new("TextLabel")
texto.Size = UDim2.fromScale(1, 1)
texto.BackgroundTransparency = 1
texto.Font = Enum.Font.GothamBold
texto.TextSize = 28
texto.TextColor3 = Color3.fromRGB(255, 205, 0)
texto.Text = "Monedas: 0"
texto.Parent = marco

local monedas = jugador:WaitForChild("leaderstats"):WaitForChild("Monedas")

local function actualizar()
	texto.Text = "Monedas: " .. monedas.Value

	-- Efecto de "rebote" cada vez que cambia el puntaje
	marco.Size = UDim2.fromOffset(230, 58)
	TweenService:Create(marco, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(200, 50),
	}):Play()
end

monedas.Changed:Connect(actualizar)
texto.Text = "Monedas: " .. monedas.Value
