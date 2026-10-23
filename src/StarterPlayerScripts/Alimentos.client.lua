-- Cartelito abajo al medio para el alimento de las mascotas (Lo De Lalo Pet Shop):
-- muestra el resultado de cada compra y, mientras dura, cuanto le queda al efecto.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigAlimentos = require(ReplicatedStorage:WaitForChild("ConfigAlimentos"))
local Interfaz = require(ReplicatedStorage:WaitForChild("Interfaz"))
local aviso = ReplicatedStorage:WaitForChild("AvisoTienda")

local jugador = Players.LocalPlayer

local COLOR_OK = Color3.fromRGB(0, 150, 80)
local COLOR_ERROR = Color3.fromRGB(190, 50, 50)
local COLOR_EFECTO = Color3.fromRGB(220, 40, 50)
local DURACION_MENSAJE = 3

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Alimentos"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local marco = Instance.new("Frame")
marco.AnchorPoint = Vector2.new(0.5, 1)
marco.Position = UDim2.new(0.5, 0, 1, -20)
marco.Size = UDim2.fromOffset(420, 46)
marco.Visible = false
marco.Parent = pantalla
Interfaz.escalar(marco)

local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(0, 12)
esquinas.Parent = marco

local texto = Instance.new("TextLabel")
texto.Size = UDim2.new(1, -16, 1, 0)
texto.Position = UDim2.fromOffset(8, 0)
texto.BackgroundTransparency = 1
texto.Font = Enum.Font.GothamBold
texto.TextScaled = true
texto.TextColor3 = Color3.new(1, 1, 1)
texto.Parent = marco

local mensajeHasta = 0

aviso.OnClientEvent:Connect(function(mensaje, ok)
	texto.Text = mensaje
	marco.BackgroundColor3 = ok and COLOR_OK or COLOR_ERROR
	marco.Visible = true
	mensajeHasta = os.clock() + DURACION_MENSAJE
end)

-- Fuera de los mensajes, muestra el efecto activo con su cuenta regresiva
while true do
	if os.clock() >= mensajeHasta then
		local restante = ConfigAlimentos.restante(jugador)
		if restante > 0 then
			local factor = jugador:GetAttribute("AlimentoFactor") or 1
			texto.Text = string.format("🐾 Mascotas alimentadas: bonus x%s · %d:%02d", tostring(factor), math.floor(restante / 60), math.floor(restante % 60))
			marco.BackgroundColor3 = COLOR_EFECTO
			marco.Visible = true
		else
			marco.Visible = false
		end
	end
	task.wait(0.25)
end
