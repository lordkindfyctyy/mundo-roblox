-- Hace girar la rueda gigante del parque de diversiones (Diversiones.server.lua) en el cliente.
-- Antes la giraba el servidor, moviendo unas 75 piezas en cada frame, y eso se replicaba a todos los jugadores.
-- Como la rueda gira a velocidad constante, el angulo en cualquier momento se calcula con la hora del servidor
-- (Desde = hora en que arranco): todos los clientes la ven en el mismo punto y el servidor no hace nada por frame.
-- Solo se mueve cuando el jugador esta cerca (lejos no se ve, y con streaming ni siquiera llega).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DISTANCIA_MAXIMA = 400 -- mas lejos que esto no se mueve

local jugador = Players.LocalPlayer
local rueda = Workspace:WaitForChild("Diversiones"):WaitForChild("RuedaGigante")

local giran = {} -- parte -> CFrame relativo al eje
local cabinas = {} -- modelo -> angulo de partida

local function registrar(objeto)
	if objeto:IsA("BasePart") then
		local relativo = objeto:GetAttribute("Relativo")
		if relativo then
			giran[objeto] = relativo
		end
	elseif objeto:IsA("Model") and objeto.Name == "Cabina" then
		local angulo = objeto:GetAttribute("Angulo")
		if angulo then
			cabinas[objeto] = angulo
		end
	end
end

rueda.DescendantAdded:Connect(registrar)
rueda.DescendantRemoving:Connect(function(objeto)
	giran[objeto] = nil
	cabinas[objeto] = nil
end)
for _, objeto in rueda:GetDescendants() do
	registrar(objeto)
end

RunService.RenderStepped:Connect(function()
	local eje = rueda:GetAttribute("Eje")
	local velocidad = rueda:GetAttribute("Velocidad")
	local desde = rueda:GetAttribute("Desde")
	local radio = rueda:GetAttribute("Radio")
	local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
	if not (eje and velocidad and desde and radio and raiz) then
		return
	end
	if (raiz.Position - eje).Magnitude > DISTANCIA_MAXIMA then
		return
	end

	local giro = velocidad * (Workspace:GetServerTimeNow() - desde)
	local centro = CFrame.new(eje) * CFrame.Angles(0, 0, giro)
	for parte, relativo in giran do
		parte.CFrame = centro * relativo
	end
	for modelo, angulo in cabinas do
		local a = angulo + giro
		modelo:PivotTo(CFrame.new(eje + Vector3.new(-math.sin(a) * radio, math.cos(a) * radio, 0)))
	end
end)
