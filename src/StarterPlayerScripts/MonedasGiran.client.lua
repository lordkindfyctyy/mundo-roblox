-- Hace girar las monedas en el cliente. Antes las giraba el servidor (cambiaba el atributo Angulo y el CFrame de
-- las ~85 monedas en cada frame), lo que replicaba unos 5.000 cambios por segundo a todos los jugadores.
-- Aca el giro es local: el servidor solo manda la posicion (y la mueve cuando un iman atrae la moneda).

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local VELOCIDAD_GIRO = math.rad(120) -- grados por segundo, igual que el giro de siempre

local carpeta = Workspace:WaitForChild("Monedas")
local monedas = {} -- parte -> angulo con que arranca

local function agregar(parte)
	local angulo = parte:IsA("BasePart") and parte:GetAttribute("Angulo")
	if angulo then
		monedas[parte] = angulo
	end
end

carpeta.ChildAdded:Connect(function(parte)
	-- Los atributos llegan junto con la parte, pero por las dudas se espera un frame si todavia no estan
	if not parte:GetAttribute("Angulo") then
		task.wait()
	end
	agregar(parte)
end)
carpeta.ChildRemoved:Connect(function(parte)
	monedas[parte] = nil
end)
for _, parte in carpeta:GetChildren() do
	agregar(parte)
end

RunService.RenderStepped:Connect(function()
	local giro = os.clock() * VELOCIDAD_GIRO
	for parte, inicio in monedas do
		-- La que ya se recogio la anima el servidor (sube y se desvanece): no se toca
		if parte.Parent and not parte:GetAttribute("Recogida") then
			parte.CFrame = CFrame.new(parte.Position) * CFrame.Angles(0, inicio + giro, 0)
		end
	end
end)
