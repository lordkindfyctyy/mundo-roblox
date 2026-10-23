-- Durante una carrera (Carreras.server.lua): cronometro arriba al medio con el
-- arco que sigue, y una columna de luz celeste (solo para este jugador) en ese arco.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))

local jugador = Players.LocalPlayer
local COLOR_MARCA = Color3.fromRGB(0, 200, 255)

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Carrera"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local marco = Instance.new("Frame")
marco.AnchorPoint = Vector2.new(0.5, 0)
marco.Size = UDim2.fromOffset(340, 50)
marco.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
marco.BackgroundTransparency = 0.15
marco.Visible = false
marco.Parent = pantalla
Interfaz.escalar(marco)
-- Debajo del marcador de monedas y del cartel de eventos
Interfaz.alCambiarPantalla(function()
	marco.Position = UDim2.new(0.5, 0, 0, 142 * Interfaz.escala())
end)

local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(0, 12)
esquinas.Parent = marco

local texto = Instance.new("TextLabel")
texto.Size = UDim2.new(1, -16, 1, 0)
texto.Position = UDim2.fromOffset(8, 0)
texto.BackgroundTransparency = 1
texto.Font = Enum.Font.GothamBlack
texto.TextScaled = true
texto.TextColor3 = Color3.new(1, 1, 1)
texto.Parent = marco

-- Columna de luz en el proximo arco (parte local)
local marca = Instance.new("Part")
marca.Name = "MarcaCarrera"
marca.Anchored = true
marca.CanCollide = false
marca.CanQuery = false
marca.CanTouch = false
marca.Shape = Enum.PartType.Cylinder
marca.Size = Vector3.new(60, 5, 5) -- largo en X: se lo para con la rotacion
marca.Material = Enum.Material.Neon
marca.Color = COLOR_MARCA
marca.Transparency = 0.5

while true do
	local inicio = jugador:GetAttribute("CarreraInicio")
	if inicio then
		local tiempo = Workspace:GetServerTimeNow() - inicio
		local control = jugador:GetAttribute("CarreraControl") or 1
		local total = jugador:GetAttribute("CarreraTotal") or 1
		local siguiente = control >= total and "¡a la llegada!" or string.format("arco %d de %d", control, total - 1)
		local mejor = jugador:GetAttribute("CarreraMejor")
		texto.Text = string.format("⏱ %.1f s · %s%s", tiempo, siguiente, mejor and string.format(" · récord %.1f", mejor) or "")
		marco.Visible = true

		local destino = jugador:GetAttribute("CarreraDestino")
		if destino then
			marca.CFrame = CFrame.new(destino + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
			marca.Parent = Workspace
		end
	else
		marco.Visible = false
		marca.Parent = nil
	end
	task.wait(0.1)
end
