-- Misiones de la ciudad (ConfigMisiones). Cada jugador tiene una activa y se la
-- muestra Misiones.client.lua con estos atributos del jugador:
--   MisionTexto (que hacer), MisionDetalle (como va, ej. "12/25"), MisionPremio,
--   MisionDestino (Vector3, a donde ir; no esta si no hay que ir a ningun lado).
-- Al cumplirla cobra el premio y despues de unos segundos le toca otra.
--
-- El avance se mide aca (entregas, cima, manejar) o llega por el BindableEvent
-- ServerStorage.ProgresoMision (monedas de la calle desde JuegoMonedas y compra de
-- alimento desde Negocios).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local ConfigMisiones = require(ReplicatedStorage:WaitForChild("ConfigMisiones"))
local Negocios = require(script.Parent:WaitForChild("Negocios"))
local Torre = require(script.Parent:WaitForChild("Torre"))

local REVISAR_CADA = 0.25

local progreso = Instance.new("BindableEvent")
progreso.Name = "ProgresoMision"
progreso.Parent = ServerStorage

local cambiar = Instance.new("RemoteEvent")
cambiar.Name = "CambiarMision"
cambiar.Parent = ReplicatedStorage

-- Los lugares de los negocios y la Torre los anota Ciudad.server.lua al armarse
while not Workspace:GetAttribute("CiudadLista") do
	task.wait(0.5)
end

local aviso = ReplicatedStorage:WaitForChild("AvisoTienda")

local function lugar(nombre)
	if nombre == "Parque" then
		return Vector3.new(0, 0.5, 0)
	elseif nombre == "Torre" then
		return Torre.lugar
	end
	return Negocios.lugares[nombre]
end

-- estado[jugador] = { mision, avance, etapa, ultimaPosicion, ultimoCambio, cumplida }
local estado = {}

local function mostrar(jugador)
	local e = estado[jugador]
	if not e or not e.mision then
		return
	end
	local m = e.mision
	local texto, detalle, destino = m.texto, "", nil

	if m.tipo == "entrega" then
		texto = e.etapa == 1 and m.buscar or m.llevar
		destino = lugar(e.etapa == 1 and m.desde or m.hasta)
	elseif m.tipo == "cima" then
		destino = Torre.lugar
	elseif m.tipo == "alimento" then
		destino = lugar("Lo De Lalo Pet Shop")
	elseif m.tipo == "manejar" then
		detalle = string.format("%d/%d m", math.floor(e.avance), m.meta)
	elseif m.meta then
		detalle = string.format("%d/%d", math.floor(e.avance), m.meta)
	end

	jugador:SetAttribute("MisionTexto", texto)
	jugador:SetAttribute("MisionDetalle", detalle)
	jugador:SetAttribute("MisionPremio", m.premio)
	jugador:SetAttribute("MisionDestino", destino)
end

local function asignar(jugador)
	local e = estado[jugador]
	if not e then
		return
	end
	-- Una al azar, distinta de la anterior (y que tenga sus lugares en la ciudad)
	local opciones = {}
	for _, m in ConfigMisiones.Lista do
		local lugaresOk = m.tipo ~= "entrega" or (lugar(m.desde) and lugar(m.hasta))
		if m ~= e.mision and lugaresOk then
			table.insert(opciones, m)
		end
	end
	e.mision = opciones[math.random(#opciones)]
	e.avance = 0
	e.etapa = 1
	e.cumplida = false
	e.ultimaPosicion = nil
	mostrar(jugador)
end

local function cumplir(jugador)
	local e = estado[jugador]
	if not e or e.cumplida then
		return
	end
	e.cumplida = true
	local monedas = jugador:FindFirstChild("leaderstats") and jugador.leaderstats:FindFirstChild("Monedas")
	if monedas then
		monedas.Value += e.mision.premio
	end
	aviso:FireClient(jugador, string.format("¡Misión cumplida! +%d monedas", e.mision.premio), true)
	jugador:SetAttribute("MisionTexto", "¡Misión cumplida!")
	jugador:SetAttribute("MisionDetalle", "Ya viene la próxima...")
	jugador:SetAttribute("MisionDestino", nil)
	task.delay(ConfigMisiones.ESPERA_PROXIMA, function()
		if estado[jugador] == e then
			asignar(jugador)
		end
	end)
end

local function sumar(jugador, cantidad)
	local e = estado[jugador]
	e.avance += cantidad
	if e.avance >= e.mision.meta then
		cumplir(jugador)
	else
		mostrar(jugador)
	end
end

progreso.Event:Connect(function(jugador, tipo, cantidad)
	local e = estado[jugador]
	if e and e.mision and not e.cumplida and e.mision.tipo == tipo then
		sumar(jugador, cantidad)
	end
end)

cambiar.OnServerEvent:Connect(function(jugador)
	local e = estado[jugador]
	if not e or e.cumplida then
		return
	end
	if os.clock() - (e.ultimoCambio or 0) < ConfigMisiones.ESPERA_CAMBIAR then
		aviso:FireClient(jugador, "Esperá un poquito para cambiar de misión", false)
		return
	end
	e.ultimoCambio = os.clock()
	asignar(jugador)
end)

local function llego(raiz, destino)
	local delta = (raiz.Position - destino) * Vector3.new(1, 0, 1)
	return delta.Magnitude <= ConfigMisiones.DISTANCIA_LLEGADA
end

-- Revisa lo que se mide por posicion: entregas, cima y manejar
local function revisar(jugador)
	local e = estado[jugador]
	local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
	if not e or not e.mision or e.cumplida or not raiz then
		return
	end
	local m = e.mision

	if m.tipo == "entrega" then
		if e.etapa == 1 and llego(raiz, lugar(m.desde)) then
			e.etapa = 2
			aviso:FireClient(jugador, "¡Lo tenés! " .. m.llevar, true)
			mostrar(jugador)
		elseif e.etapa == 2 and llego(raiz, lugar(m.hasta)) then
			cumplir(jugador)
		end
	elseif m.tipo == "cima" then
		local arriba = raiz.Position.Y >= Torre.cima.Y - 2
		local cerca = ((raiz.Position - Torre.cima) * Vector3.new(1, 0, 1)).Magnitude < 12
		if arriba and cerca then
			cumplir(jugador)
		end
	elseif m.tipo == "manejar" then
		local humanoide = jugador.Character:FindFirstChildOfClass("Humanoid")
		local manejando = humanoide and humanoide.SeatPart and humanoide.SeatPart:IsA("VehicleSeat")
		local posicion = raiz.Position * Vector3.new(1, 0, 1)
		if manejando and e.ultimaPosicion then
			local recorrido = (posicion - e.ultimaPosicion).Magnitude
			-- Un salto enorme es un teletransporte, no manejo
			if recorrido < 30 then
				sumar(jugador, recorrido)
			end
		end
		e.ultimaPosicion = manejando and posicion or nil
	end
end

Players.PlayerAdded:Connect(function(jugador)
	estado[jugador] = {}
	asignar(jugador)
end)
for _, jugador in Players:GetPlayers() do
	estado[jugador] = {}
	asignar(jugador)
end
Players.PlayerRemoving:Connect(function(jugador)
	estado[jugador] = nil
end)

while true do
	for jugador in estado do
		revisar(jugador)
	end
	task.wait(REVISAR_CADA)
end
