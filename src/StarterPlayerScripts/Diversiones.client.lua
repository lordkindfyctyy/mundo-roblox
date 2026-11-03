-- Parque de diversiones, del lado del jugador (Diversiones.server.lua arma todo):
--   * Montaña rusa y tobogan: cuando el servidor avisa con SubirAtraccion, mueve al
--     personaje sentado por el recorrido de Recorridos.lua. El personaje es de este
--     jugador, asi que lo que se mueve aca lo ven todos.
--   * Trampolines: las partes con la etiqueta "Trampolin" te tiran para arriba con
--     la fuerza de su atributo "Potencia".

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Recorridos = require(ReplicatedStorage:WaitForChild("Recorridos"))
local subir = ReplicatedStorage:WaitForChild("SubirAtraccion")

local jugador = Players.LocalPlayer
local ESPERA_REBOTE = 0.4 -- segundos entre dos rebotes

local enJuego = false

local function partes()
	local personaje = jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	return humanoide, raiz
end

---------------------------------------------------------------- Montaña rusa y tobogan

subir.OnClientEvent:Connect(function(id)
	local humanoide, raiz = partes()
	local recorrido = Recorridos.Lista[id]
	if not humanoide or not raiz or not recorrido or enJuego then
		return
	end
	enJuego = true
	local muestras = Recorridos.muestras(id)
	local arriba = Vector3.yAxis * recorrido.alturaJugador

	-- Sentado y sin poder saltar hasta que termina
	humanoide:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoide.Sit = true

	local inicio = os.clock()
	local indice = 1
	local direccion = Vector3.new(0, 0, -1)
	local conexion
	conexion = RunService.PreSimulation:Connect(function()
		local t = os.clock() - inicio
		if t >= muestras.duracion or not raiz.Parent or humanoide.Health <= 0 then
			conexion:Disconnect()
			enJuego = false
			humanoide:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			humanoide.Sit = false
			if not raiz.Parent then
				return
			end
			if recorrido.salida then
				raiz.CFrame = CFrame.new(recorrido.salida)
				raiz.AssemblyLinearVelocity = Vector3.zero
			else
				-- Sale disparado hacia adelante desde el final
				local final = muestras.puntos[#muestras.puntos]
				local plano = (direccion * Vector3.new(1, 0, 1)).Unit
				raiz.CFrame = CFrame.lookAt(final + Vector3.new(0, 3, 0), final + Vector3.new(0, 3, 0) + plano)
				raiz.AssemblyLinearVelocity = plano * (recorrido.empujonFinal or 0)
			end
			return
		end

		local posicion
		posicion, direccion, indice = Recorridos.en(muestras, t, indice)
		local centro = posicion + arriba
		raiz.CFrame = CFrame.lookAt(centro, centro + direccion)
		raiz.AssemblyLinearVelocity = Vector3.zero
		raiz.AssemblyAngularVelocity = Vector3.zero
		if not humanoide.Sit then
			humanoide.Sit = true
		end
	end)
end)

---------------------------------------------------------------- Trampolines

local ultimoRebote = 0

local function conectarTrampolin(lona)
	lona.Touched:Connect(function(otra)
		local personaje = jugador.Character
		if enJuego or not personaje or not otra:IsDescendantOf(personaje) then
			return
		end
		if os.clock() - ultimoRebote < ESPERA_REBOTE then
			return
		end
		local humanoide, raiz = partes()
		if not humanoide or not raiz or humanoide.Health <= 0 then
			return
		end
		ultimoRebote = os.clock()
		humanoide:ChangeState(Enum.HumanoidStateType.Jumping)
		local velocidad = raiz.AssemblyLinearVelocity
		raiz.AssemblyLinearVelocity = Vector3.new(velocidad.X, lona:GetAttribute("Potencia") or 90, velocidad.Z)
	end)
end

for _, lona in CollectionService:GetTagged("Trampolin") do
	conectarTrampolin(lona)
end
CollectionService:GetInstanceAddedSignal("Trampolin"):Connect(conectarTrampolin)
