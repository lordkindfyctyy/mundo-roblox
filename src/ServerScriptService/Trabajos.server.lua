-- Trabajos de la ciudad (ConfigTrabajos): repartidor de pizza, bombero y taxista.
-- Se eligen en el puesto "TRABAJOS", enfrente de la salida norte del parque (al lado
-- del Taller). Cada trabajo se repite viaje tras viaje hasta que el jugador lo deja.
--
-- Trabajos.client.lua lo muestra con estos atributos del jugador:
--   TrabajoId (nil = sin trabajo), TrabajoTexto (que hacer), TrabajoDestino (Vector3),
--   TrabajoFin (hora del servidor en que se termina el tiempo; nil = sin apuro),
--   TrabajoGanado y TrabajoViajes (lo que lleva hecho desde que empezo).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConfigTrabajos = require(ReplicatedStorage:WaitForChild("ConfigTrabajos"))
local Negocios = require(script.Parent:WaitForChild("Negocios"))
local PlanoCiudad = require(script.Parent:WaitForChild("PlanoCiudad"))
local Torre = require(script.Parent:WaitForChild("Torre"))

local VEREDA = 0.5
-- Enfrente de la salida norte del parque, del otro lado de la avenida que el Taller;
-- mira hacia el parque (-Z)
local PUESTO = CFrame.lookAt(Vector3.new(12.5, VEREDA, 73), Vector3.new(12.5, VEREDA, 0))
local ESTACIONAMIENTO = Vector3.new(0, VEREDA, 92) -- los autos para manejar (Vehiculos.server.lua)
local REVISAR_CADA = 0.25
local DISTANCIA_MINIMA = 40 -- los viajes son al menos asi de largos

local dejar = Instance.new("RemoteEvent")
dejar.Name = "DejarTrabajo"
dejar.Parent = ReplicatedStorage

-- Los lugares de los negocios y la Torre los anota Ciudad.server.lua al armarse
while not Workspace:GetAttribute("CiudadLista") do
	task.wait(0.5)
end

local aviso = ReplicatedStorage:WaitForChild("AvisoTienda")

local carpeta = Instance.new("Folder")
carpeta.Name = "Trabajos"
carpeta.Parent = Workspace

local function parte(padre, nombre, tamano, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = padre
	return p
end

local function distanciaPlana(a, b)
	return ((a - b) * Vector3.new(1, 0, 1)).Magnitude
end

-- Direcciones a donde llevar pizzas y pasajeros: { texto = "a la Heladería", posicion }
local DIRECCIONES = {}
for nombre, posicion in Negocios.lugares do
	local texto = "a la " .. nombre
	if nombre == "Kiosco" then
		texto = "al Kiosco"
	elseif nombre == "Lo De Lalo Pet Shop" then
		texto = "a Lo De Lalo Pet Shop"
	end
	table.insert(DIRECCIONES, { texto = texto, posicion = posicion, nombre = nombre })
end
table.insert(DIRECCIONES, { texto = "a la Torre", posicion = Torre.lugar })
table.insert(DIRECCIONES, { texto = "a la entrada del parque", posicion = Vector3.new(0, VEREDA, -57) })
table.insert(DIRECCIONES, { texto = "a la Playa", posicion = Vector3.new(PlanoCiudad.PLAYA.ESCALONES_X1 + 6, VEREDA, 0) })
for i, terreno in PlanoCiudad.BARRIO.TERRENOS do
	-- La vereda frente al terreno, del lado de la calle del Barrio
	local z = terreno.Z > 0 and 12 or -12
	table.insert(DIRECCIONES, { texto = "a la casa " .. i .. " del Barrio", posicion = Vector3.new(terreno.X, VEREDA, z) })
end

-- Una direccion al azar lejos de desde (y que no sea la del lugar evitado)
local function elegirDireccion(desde, evitar)
	local opciones = {}
	for _, direccion in DIRECCIONES do
		if direccion.nombre ~= evitar and distanciaPlana(direccion.posicion, desde) >= DISTANCIA_MINIMA then
			table.insert(opciones, direccion)
		end
	end
	return opciones[math.random(#opciones)]
end

-- estado[jugador] = { trabajo, etapa, destino, inicio, duracion, distancia, ganado, viajes, objeto, esperando }
local estado = {}

local function ahora()
	return Workspace:GetServerTimeNow()
end

local function mostrar(jugador, texto)
	local e = estado[jugador]
	jugador:SetAttribute("TrabajoId", e and e.trabajo.id or nil)
	jugador:SetAttribute("TrabajoTexto", e and texto or nil)
	jugador:SetAttribute("TrabajoDestino", e and e.destino or nil)
	jugador:SetAttribute("TrabajoFin", e and e.duracion and (e.inicio + e.duracion) or nil)
	jugador:SetAttribute("TrabajoGanado", e and e.ganado or nil)
	jugador:SetAttribute("TrabajoViajes", e and e.viajes or nil)
end

-- Gorra del color del trabajo (y la caja de pizza en las manos), pegadas al personaje
local function quitar(personaje, nombre)
	local cosa = personaje and personaje:FindFirstChild(nombre)
	if cosa then
		cosa:Destroy()
	end
end

local function pegar(personaje, nombre, ancla, tamano, desplazamiento, color)
	local base = personaje and personaje:FindFirstChild(ancla)
	if not base then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.Color = color
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = base.CFrame * desplazamiento
	local soldadura = Instance.new("WeldConstraint")
	soldadura.Part0 = base
	soldadura.Part1 = p
	soldadura.Parent = p
	p.Parent = personaje
	return p
end

local function ponerGorra(jugador, trabajo)
	local personaje = jugador.Character
	quitar(personaje, "GorraTrabajo")
	local gorra = pegar(personaje, "GorraTrabajo", "Head", Vector3.new(1.3, 0.45, 1.3), CFrame.new(0, 0.72, 0), trabajo.color)
	if gorra then
		local visera = pegar(personaje, "GorraTrabajo", "Head", Vector3.new(1.2, 0.12, 0.6), CFrame.new(0, 0.55, -0.85), trabajo.color)
		if visera then
			visera.Parent = gorra
		end
	end
end

local function ponerCaja(jugador)
	local personaje = jugador.Character
	quitar(personaje, "CajaPizza")
	local caja = pegar(personaje, "CajaPizza", "HumanoidRootPart", Vector3.new(2, 0.4, 2), CFrame.new(0, 0.2, -1.4), Color3.fromRGB(200, 160, 110))
	if caja then
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Top
		gui.Parent = caja
		local texto = Instance.new("TextLabel")
		texto.Size = UDim2.fromScale(1, 1)
		texto.BackgroundTransparency = 1
		texto.TextScaled = true
		texto.Text = "🍕"
		texto.Parent = gui
	end
end

local function borrarObjeto(e)
	if e.objeto then
		e.objeto:Destroy()
		e.objeto = nil
	end
end

local function manejando(jugador)
	local humanoide = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
	return humanoide ~= nil and humanoide.SeatPart ~= nil and humanoide.SeatPart:IsA("VehicleSeat")
end

-- Arranca un viaje con apuro: destino, tiempo segun la distancia
local function viaje(e, destino, desde)
	e.destino = destino
	e.distancia = distanciaPlana(destino, desde)
	e.inicio = ahora()
	e.duracion = ConfigTrabajos.tiempo(e.trabajo, e.distancia)
end

local function sinApuro(e, destino)
	e.destino = destino
	e.duracion = nil
end

local function cobrar(jugador, e, que)
	local rapido = ahora() - e.inicio <= e.duracion / 2
	local pago = ConfigTrabajos.pago(e.trabajo, e.distancia, rapido)
	local monedas = jugador:FindFirstChild("leaderstats") and jugador.leaderstats:FindFirstChild("Monedas")
	if monedas then
		monedas.Value += pago
	end
	e.ganado += pago
	e.viajes += 1
	local texto = string.format("¡%s! +%d monedas", que, pago)
	if rapido then
		texto ..= " (¡bonus por rápido!)"
	end
	aviso:FireClient(jugador, texto, true)
end

----------------------------------------------------------------- Pizza

local function pizzaBuscar(jugador, e)
	local pizzeria = Negocios.lugares["Pizzería"]
	e.etapa = "buscar"
	sinApuro(e, pizzeria)
	quitar(jugador.Character, "CajaPizza")
	mostrar(jugador, "Buscá la pizza en la Pizzería")
end

----------------------------------------------------------------- Bombero

-- Punto en la pared del edificio que da a la calle mas cercana (para poder llegar)
local function puntoDeIncendio(edificio)
	local cuerpo = edificio:FindFirstChild("Cuerpo")
	local c, t = cuerpo.Position, cuerpo.Size
	local caras = {
		{ Vector3.new(c.X + t.X / 2, 0, c.Z), Vector3.new(1, 0, 0) },
		{ Vector3.new(c.X - t.X / 2, 0, c.Z), Vector3.new(-1, 0, 0) },
		{ Vector3.new(c.X, 0, c.Z + t.Z / 2), Vector3.new(0, 0, 1) },
		{ Vector3.new(c.X, 0, c.Z - t.Z / 2), Vector3.new(0, 0, -1) },
	}
	local mejor, mejorDistancia = caras[1], math.huge
	for _, cara in caras do
		local p, normal = cara[1], cara[2]
		local distancia = math.huge
		for _, calle in PlanoCiudad.CALLES do
			-- solo cuenta la calle que queda del lado hacia donde mira la cara
			if normal.X ~= 0 and (calle - p.X) * normal.X > 0 then
				distancia = math.min(distancia, math.abs(calle - p.X))
			elseif normal.Z ~= 0 and (calle - p.Z) * normal.Z > 0 then
				distancia = math.min(distancia, math.abs(calle - p.Z))
			end
		end
		if distancia < mejorDistancia then
			mejor, mejorDistancia = cara, distancia
		end
	end
	return mejor[1] + Vector3.new(0, VEREDA, 0), mejor[2]
end

local bomberoApagar -- se define abajo; el fuego la llama al apagarse

local function crearFuego(jugador, e, posicion, normal)
	local fuego = parte(carpeta, "Incendio", Vector3.new(6, 6, 1), CFrame.lookAt(posicion + normal * 1 + Vector3.new(0, 3, 0), posicion + normal * 2 + Vector3.new(0, 3, 0)), Color3.fromRGB(255, 120, 0))
	fuego.Transparency = 1
	fuego.CanCollide = false
	local llamas = Instance.new("Fire")
	llamas.Size = 14
	llamas.Heat = 18
	llamas.Parent = fuego
	local humo = Instance.new("Smoke")
	humo.RiseVelocity = 8
	humo.Size = 6
	humo.Color = Color3.fromRGB(70, 70, 70)
	humo.Parent = fuego
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 140, 40)
	luz.Range = 24
	luz.Brightness = 3
	luz.Parent = fuego

	local boton = Instance.new("ProximityPrompt")
	boton.ActionText = "Apagar el fuego"
	boton.ObjectText = "🚒 Incendio de " .. jugador.DisplayName
	boton.HoldDuration = e.trabajo.segundosApagar
	boton.MaxActivationDistance = 14
	boton.RequiresLineOfSight = false
	boton.Parent = fuego
	boton.Triggered:Connect(function(quien)
		if quien ~= jugador then
			aviso:FireClient(quien, "Ese incendio es de otro bombero", false)
			return
		end
		if estado[jugador] == e and e.objeto == fuego then
			bomberoApagar(jugador, e)
		end
	end)
	e.objeto = fuego
end

local function bomberoNuevo(jugador, e)
	borrarObjeto(e)
	local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
	local edificios = Workspace:FindFirstChild("Ciudad") and Workspace.Ciudad:FindFirstChild("Edificios")
	if not raiz or not edificios then
		return
	end
	-- Un edificio al azar que no este pegado al jugador
	local opciones = {}
	for _, edificio in edificios:GetChildren() do
		local cuerpo = edificio:FindFirstChild("Cuerpo")
		if cuerpo and distanciaPlana(cuerpo.Position, raiz.Position) >= DISTANCIA_MINIMA then
			table.insert(opciones, edificio)
		end
	end
	if #opciones == 0 then
		return
	end
	local posicion, normal = puntoDeIncendio(opciones[math.random(#opciones)])
	e.etapa = "apagar"
	viaje(e, posicion + normal * 4, raiz.Position)
	crearFuego(jugador, e, posicion, normal)
	mostrar(jugador, "¡Incendio! Andá y mantené apretado para apagarlo")
end

----------------------------------------------------------------- Taxi

local function crearPasajero(posicion)
	local modelo = Instance.new("Model")
	modelo.Name = "Pasajero"
	local color = Color3.fromHSV(math.random(), 0.6, 0.9)
	local base = CFrame.new(posicion)
	parte(modelo, "Piernas", Vector3.new(1.6, 2, 0.8), base * CFrame.new(0, 1, 0), Color3.fromRGB(50, 60, 110))
	parte(modelo, "Cuerpo", Vector3.new(2, 2, 1), base * CFrame.new(0, 3, 0), color)
	parte(modelo, "BrazoLevantado", Vector3.new(0.6, 2, 0.6), base * CFrame.new(1.3, 4.6, 0), color)
	local cabeza = parte(modelo, "Cabeza", Vector3.new(1.2, 1.2, 1.2), base * CFrame.new(0, 4.6, 0), Color3.fromRGB(240, 200, 160))
	for _, p in modelo:GetChildren() do
		p.CanCollide = false
	end
	local cartel = Instance.new("BillboardGui")
	cartel.Size = UDim2.fromOffset(120, 40)
	cartel.StudsOffset = Vector3.new(0, 2.5, 0)
	cartel.AlwaysOnTop = true
	cartel.Parent = cabeza
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.GothamBlack
	texto.TextScaled = true
	texto.TextColor3 = Color3.fromRGB(255, 200, 0)
	texto.TextStrokeTransparency = 0.3
	texto.Text = "🙋 ¡TAXI!"
	texto.Parent = cartel
	modelo.Parent = carpeta
	return modelo
end

local azarCalle = Random.new()

local function taxiBuscar(jugador, e)
	borrarObjeto(e)
	if not manejando(jugador) then
		e.etapa = "auto"
		sinApuro(e, ESTACIONAMIENTO)
		mostrar(jugador, "Subite a un auto para trabajar de taxista")
		return
	end
	local raiz = jugador.Character.HumanoidRootPart
	-- Un pasajero en alguna calle, ni muy cerca ni del otro lado de la ciudad
	local punto
	for _ = 1, 20 do
		punto = PlanoCiudad.puntoEnCalle(azarCalle)
		local distancia = distanciaPlana(punto, raiz.Position)
		if distancia >= DISTANCIA_MINIMA and distancia <= 180 then
			break
		end
	end
	e.etapa = "buscar"
	sinApuro(e, punto)
	e.objeto = crearPasajero(punto)
	mostrar(jugador, "Un pasajero te espera: andá a buscarlo con el auto")
end

----------------------------------------------------------------- Comun

local SIGUIENTE = {
	Pizza = pizzaBuscar,
	Bombero = bomberoNuevo,
	Taxi = taxiBuscar,
}

-- Despues de un viaje (cumplido o no), espera un poquito y arranca el siguiente
local function siguiente(jugador, e)
	e.esperando = true
	e.destino = nil
	e.duracion = nil
	mostrar(jugador, "¡Ya viene el próximo viaje!")
	task.delay(ConfigTrabajos.ESPERA_SIGUIENTE, function()
		if estado[jugador] == e then
			e.esperando = false
			SIGUIENTE[e.trabajo.id](jugador, e)
		end
	end)
end

bomberoApagar = function(jugador, e)
	local fuego = e.objeto
	if fuego then
		-- Un chorro de agua cortito antes de que desaparezca
		local agua = Instance.new("ParticleEmitter")
		agua.Color = ColorSequence.new(Color3.fromRGB(120, 200, 255))
		agua.Speed = NumberRange.new(10)
		agua.Lifetime = NumberRange.new(0.6)
		agua.Rate = 0
		agua.Parent = fuego
		agua:Emit(60)
		for _, cosa in fuego:GetChildren() do
			if cosa:IsA("Fire") or cosa:IsA("Smoke") or cosa:IsA("PointLight") or cosa:IsA("ProximityPrompt") then
				cosa:Destroy()
			end
		end
		e.objeto = nil
		task.delay(1, function()
			fuego:Destroy()
		end)
	end
	cobrar(jugador, e, "Apagaste el incendio")
	siguiente(jugador, e)
end

local function terminar(jugador, avisar)
	local e = estado[jugador]
	if not e then
		return
	end
	borrarObjeto(e)
	estado[jugador] = nil
	quitar(jugador.Character, "GorraTrabajo")
	quitar(jugador.Character, "CajaPizza")
	mostrar(jugador)
	if avisar and e.ganado > 0 then
		aviso:FireClient(jugador, string.format("Dejaste de trabajar. Ganaste %d monedas en %d viajes", e.ganado, e.viajes), true)
	end
end

local function empezar(jugador, trabajo)
	if not jugador:GetAttribute("DatosCargados") then
		aviso:FireClient(jugador, "Todavía cargando, probá de nuevo", false)
		return
	end
	local actual = estado[jugador]
	if actual and actual.trabajo == trabajo then
		aviso:FireClient(jugador, "Ya estás trabajando de " .. string.lower(trabajo.nombre), false)
		return
	end
	terminar(jugador, true)
	local e = { trabajo = trabajo, ganado = 0, viajes = 0 }
	estado[jugador] = e
	ponerGorra(jugador, trabajo)
	aviso:FireClient(jugador, string.format("¡Empezaste a trabajar de %s! %s", string.lower(trabajo.nombre), trabajo.emoji), true)
	SIGUIENTE[trabajo.id](jugador, e)
end

dejar.OnServerEvent:Connect(function(jugador)
	terminar(jugador, true)
end)

-- Revisa llegadas y tiempos de todos los que trabajan
local function revisar(jugador, e)
	local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
	if not raiz or e.esperando then
		return
	end
	local llego = e.destino and distanciaPlana(raiz.Position, e.destino) <= ConfigTrabajos.DISTANCIA_LLEGADA
	local seAcabo = e.duracion and ahora() > e.inicio + e.duracion
	local id = e.trabajo.id

	if id == "Pizza" then
		if e.etapa == "buscar" and llego then
			local direccion = elegirDireccion(raiz.Position, "Pizzería")
			e.etapa = "llevar"
			viaje(e, direccion.posicion, raiz.Position)
			ponerCaja(jugador)
			mostrar(jugador, "Llevá la pizza " .. direccion.texto)
		elseif e.etapa == "llevar" and llego then
			quitar(jugador.Character, "CajaPizza")
			cobrar(jugador, e, "Pizza entregada")
			siguiente(jugador, e)
		elseif e.etapa == "llevar" and seAcabo then
			aviso:FireClient(jugador, "¡Se enfrió la pizza! Volvé a la Pizzería por otra", false)
			siguiente(jugador, e)
		end
	elseif id == "Bombero" then
		if seAcabo then
			aviso:FireClient(jugador, "Llegaste tarde: otro bombero apagó el fuego", false)
			borrarObjeto(e)
			siguiente(jugador, e)
		end
	elseif id == "Taxi" then
		if e.etapa == "auto" then
			if manejando(jugador) then
				taxiBuscar(jugador, e)
			end
		elseif e.etapa == "buscar" and llego and manejando(jugador) then
			borrarObjeto(e)
			local direccion = elegirDireccion(raiz.Position)
			e.etapa = "llevar"
			viaje(e, direccion.posicion, raiz.Position)
			aviso:FireClient(jugador, "¡Subió el pasajero!", true)
			mostrar(jugador, "Llevá al pasajero " .. direccion.texto)
		elseif e.etapa == "llevar" and llego and manejando(jugador) then
			cobrar(jugador, e, "Viaje terminado")
			siguiente(jugador, e)
		elseif e.etapa == "llevar" and seAcabo then
			aviso:FireClient(jugador, "El pasajero se cansó de esperar y se bajó", false)
			siguiente(jugador, e)
		end
	end
end

Players.PlayerAdded:Connect(function(jugador)
	-- Si se muere o reaparece, deja el trabajo (la gorra y la caja se van con el personaje)
	jugador.CharacterRemoving:Connect(function()
		terminar(jugador, true)
	end)
end)
for _, jugador in Players:GetPlayers() do
	jugador.CharacterRemoving:Connect(function()
		terminar(jugador, true)
	end)
end
Players.PlayerRemoving:Connect(function(jugador)
	terminar(jugador, false)
end)

----------------------------------------------------------------- El puesto

-- Mostrador largo con techito y cartel, con un lugar por trabajo (cada uno con su boton)
local puesto = Instance.new("Folder")
puesto.Name = "PuestoTrabajos"
puesto.Parent = carpeta

local ANCHO = 4 * #ConfigTrabajos.Lista + 1
for i, trabajo in ConfigTrabajos.Lista do
	local x = (i - (#ConfigTrabajos.Lista + 1) / 2) * 4
	local mostrador = parte(puesto, "Mostrador" .. trabajo.id, Vector3.new(3.8, 3.5, 2), PUESTO * CFrame.new(x, 1.75, 0), trabajo.color, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = mostrador
	local etiqueta = Instance.new("TextLabel")
	etiqueta.Size = UDim2.fromScale(1, 1)
	etiqueta.BackgroundTransparency = 1
	etiqueta.TextScaled = true
	etiqueta.Font = Enum.Font.GothamBlack
	etiqueta.TextColor3 = Color3.new(1, 1, 1)
	etiqueta.Text = trabajo.emoji
	etiqueta.Parent = gui

	local boton = Instance.new("ProximityPrompt")
	boton.ActionText = "Trabajar"
	boton.ObjectText = trabajo.emoji .. " " .. trabajo.nombre
	boton.MaxActivationDistance = 8
	boton.RequiresLineOfSight = false
	boton.Parent = mostrador
	boton.Triggered:Connect(function(jugador)
		empezar(jugador, trabajo)
	end)
end
for _, x in { -ANCHO / 2 + 0.3, ANCHO / 2 - 0.3 } do
	parte(puesto, "Poste", Vector3.new(0.4, 9, 0.4), PUESTO * CFrame.new(x, 4.5, 0.6), Color3.fromRGB(200, 200, 200), Enum.Material.Metal)
end
parte(puesto, "Techo", Vector3.new(ANCHO + 1, 0.4, 2.6), PUESTO * CFrame.new(0, 9, 0), Color3.fromRGB(40, 110, 220), Enum.Material.Metal)

local cartel = parte(puesto, "Cartel", Vector3.new(ANCHO, 2.4, 0.3), PUESTO * CFrame.new(0, 7.4, -1.2), Color3.fromRGB(25, 25, 30))
local guiCartel = Instance.new("SurfaceGui")
guiCartel.Face = Enum.NormalId.Front -- mira hacia el parque
guiCartel.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
guiCartel.PixelsPerStud = 40
guiCartel.Parent = cartel
local textoCartel = Instance.new("TextLabel")
textoCartel.Size = UDim2.fromScale(1, 1)
textoCartel.BackgroundTransparency = 1
textoCartel.Font = Enum.Font.GothamBlack
textoCartel.TextScaled = true
textoCartel.TextColor3 = Color3.fromRGB(255, 205, 0)
textoCartel.Text = "💼 TRABAJOS"
textoCartel.Parent = guiCartel

while true do
	for jugador, e in estado do
		revisar(jugador, e)
	end
	task.wait(REVISAR_CADA)
end
