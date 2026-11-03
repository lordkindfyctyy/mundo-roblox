-- Mueve los autos que andan solos por las calles (Autos.server.lua).
-- El servidor decide cuando frena o arranca cada uno, pero ya no les mueve las partes: solo publica en atributos
-- del modelo donde estaba (Origen), hacia donde iba (Direccion), a que velocidad (Velocidad) y a que hora
-- del servidor (Desde). Con eso cada cliente calcula la posicion del auto en cada frame, igual que el servidor.
-- Si el aviso de un cambio (frenar, arrancar) llega con retraso, el auto se corrige de a poco en vez de dar un salto.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SUAVIZADO = 12 -- mas alto = se corrige mas rapido
local SALTO_MAXIMO = 8 -- si la diferencia es mayor (dio la vuelta al mapa, o recien aparecio), se coloca de una

local carpeta = Workspace:WaitForChild("Autos")
local autos = {} -- modelo -> { pos = posicion que se esta mostrando, puesto = posicion donde se dejo el modelo }

carpeta.ChildAdded:Connect(function(modelo)
	if modelo:IsA("Model") then
		autos[modelo] = {}
	end
end)
carpeta.ChildRemoved:Connect(function(modelo)
	autos[modelo] = nil
end)
for _, modelo in carpeta:GetChildren() do
	if modelo:IsA("Model") then
		autos[modelo] = {}
	end
end

RunService.RenderStepped:Connect(function(dt)
	local ahora = Workspace:GetServerTimeNow()
	local factor = 1 - math.exp(-SUAVIZADO * dt)
	for modelo, estado in autos do
		local origen = modelo:GetAttribute("Origen")
		local direccion = modelo:GetAttribute("Direccion")
		if origen and direccion then
			local velocidad = modelo:GetAttribute("Velocidad") or 0
			local desde = modelo:GetAttribute("Desde") or ahora
			local objetivo = origen + direccion * (velocidad * math.max(0, ahora - desde))

			local pos = estado.pos
			if not pos or (objetivo - pos).Magnitude > SALTO_MAXIMO then
				pos = objetivo
			elseif (objetivo - pos).Magnitude < 0.005 then
				pos = objetivo -- ya llego: si no, el suavizado se acercaria para siempre sin terminar de parar
			else
				pos = pos:Lerp(objetivo, factor)
			end
			estado.pos = pos

			-- Parado y ya en su lugar: no hace falta volver a mover las partes
			if estado.puesto ~= pos then
				estado.puesto = pos
				modelo:PivotTo(CFrame.lookAt(pos, pos + direccion))
			end
		end
	end
end)
