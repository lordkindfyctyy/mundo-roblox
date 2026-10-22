-- Saltos extra en el aire, segun el nivel de la mejora "Salto extra" (SaltoDoble).
-- Nivel 1 = salto doble, nivel 2 = salto triple.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local jugador = Players.LocalPlayer
local nivel = jugador:WaitForChild("Mejoras"):WaitForChild("SaltoDoble")

local ESPERA = 0.2 -- evita que el mismo toque gaste el salto normal y uno extra a la vez

local usados = 0
local ultimoSalto = 0

local function humanoide()
	local personaje = jugador.Character
	return personaje and personaje:FindFirstChildOfClass("Humanoid")
end

-- Al volver al suelo se recuperan los saltos extra
local function conectarPersonaje(personaje)
	usados = 0
	local h = personaje:WaitForChild("Humanoid")
	h.StateChanged:Connect(function(_, nuevo)
		if nuevo == Enum.HumanoidStateType.Landed or nuevo == Enum.HumanoidStateType.Running then
			usados = 0
		elseif nuevo == Enum.HumanoidStateType.Jumping then
			ultimoSalto = os.clock()
		end
	end)
end

if jugador.Character then
	conectarPersonaje(jugador.Character)
end
jugador.CharacterAdded:Connect(conectarPersonaje)

UserInputService.JumpRequest:Connect(function()
	local h = humanoide()
	if not h or usados >= nivel.Value then
		return
	end
	if os.clock() - ultimoSalto < ESPERA then
		return
	end

	-- Solo cuenta si estamos en el aire
	if h:GetState() == Enum.HumanoidStateType.Freefall then
		usados += 1
		h:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)
