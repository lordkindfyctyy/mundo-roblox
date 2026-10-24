-- Vehiculos para manejar, estacionados en la avenida norte (ahi no pasan los autos
-- de Autos.server.lua): deportivos, un sedan, una camioneta, un taxi y un tractor
-- (los modelos son de ModelosAutos.lua; cada tipo tiene su velocidad). Con "Manejar"
-- te sentas al volante y con "Subir" de acompañante. Se maneja con W/S y A/D (o el
-- joystick en el celular) y se baja saltando.
--
-- El auto no usa ruedas con motor: el servidor lo empuja con un LinearVelocity
-- (solo en horizontal, la gravedad sigue actuando) y lo mantiene derecho con un
-- AlignOrientation que gira segun el volante. Las ruedas son esferas sin rozamiento
-- para que pase por los cordones sin trabarse.
-- Si queda solo y lejos de su lugar, vuelve al estacionamiento.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ModelosAutos = require(script.Parent:WaitForChild("ModelosAutos"))
-- Estilo del jugador que maneja (pintura, rayas, ruedas y motor de la tienda de autos)
local SkinsAutos = require(script.Parent:WaitForChild("SkinsAutos"))

local VELOCIDAD_MAXIMA = 45 -- si el modelo no dice otra
local VELOCIDAD_REVERSA = 18
local ACELERACION = 22
local FRENADO = 50 -- al soltar o al ir para el otro lado
local GIRO = 1.7 -- radianes por segundo a fondo con el volante
local ESPERA_VOLVER = 45 -- segundos solo y lejos antes de volver a su lugar
local SUELO = 0.3 -- altura del asfalto
local ALTO_CHASIS = 1.2

-- Lugares en la avenida norte (x = 0, del lado de +Z), mirando hacia afuera
local LUGARES = {
	{ x = -4, z = 84, tipo = "deportivo", color = Color3.fromRGB(220, 30, 30) },
	{ x = 4, z = 84, tipo = "sedan", color = Color3.fromRGB(30, 90, 220) },
	{ x = -4, z = 100, tipo = "camioneta", color = Color3.fromRGB(245, 245, 245) },
	{ x = 4, z = 100, tipo = "deportivo", color = Color3.fromRGB(255, 190, 0) },
	{ x = -4, z = 116, tipo = "tractor", color = Color3.fromRGB(40, 150, 60) },
	{ x = 4, z = 116, tipo = "taxi" },
}

local SIN_ROCE = PhysicalProperties.new(0.7, 0, 0, 100, 1)

local carpeta = Instance.new("Folder")
carpeta.Name = "AutosParaManejar"
carpeta.Parent = Workspace

local function parte(modelo, nombre, tamano, cframe, color, material, forma)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = forma or Enum.PartType.Block
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = modelo
	return p
end

local function soldar(a, b)
	local soldadura = Instance.new("WeldConstraint")
	soldadura.Part0 = a
	soldadura.Part1 = b
	soldadura.Parent = a
end

-- Boton para sentarse en un asiento; se esconde mientras esta ocupado
local function botonAsiento(asiento, texto, nombre)
	local boton = Instance.new("ProximityPrompt")
	boton.ActionText = texto
	boton.ObjectText = nombre
	boton.MaxActivationDistance = 10
	boton.RequiresLineOfSight = false
	boton.Parent = asiento
	boton.Triggered:Connect(function(jugador)
		local humanoide = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
		if humanoide and not asiento.Occupant and not humanoide.SeatPart then
			asiento:Sit(humanoide)
		end
	end)
	asiento:GetPropertyChangedSignal("Occupant"):Connect(function()
		boton.Enabled = asiento.Occupant == nil
	end)
end

-- Asiento invisible (el que se ve lo trae el modelo)
local function asiento(modelo, clase, nombre, posicion)
	local a = Instance.new(clase)
	a.Name = nombre
	a.Size = Vector3.new(1.8, 0.6, 1.8)
	a.CFrame = CFrame.new(posicion)
	a.Transparency = 1
	a.CanCollide = false
	a.Parent = modelo
	return a
end

-- Arma el vehiculo mirando hacia -Z con el piso en y = 0; despues se lo ubica con PivotTo
local function crearAuto(tipo, color)
	local modelo, datos = ModelosAutos.crear(tipo, color)
	modelo.Name = "AutoParaManejar"

	-- Chasis: la parte principal, invisible; lleva la fisica
	local chasis = parte(modelo, "Chasis", Vector3.new(datos.ancho - 0.4, 1, datos.largo - 1), CFrame.new(0, ALTO_CHASIS, 0), Color3.new())
	chasis.Transparency = 1
	modelo.PrimaryPart = chasis
	chasis.PivotOffset = CFrame.new(0, -ALTO_CHASIS, 0)

	-- Ruedas de verdad: esferas invisibles sin rozamiento que tocan el piso, una
	-- por cada rueda del modelo (las que se ven son de adorno)
	for _, rueda in datos.ruedas do
		local x, z, radio = rueda[1], rueda[2], rueda[3]
		local bola = parte(modelo, "Rueda", Vector3.one * radio * 2, CFrame.new(x, radio, z), Color3.new(), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		bola.CustomPhysicalProperties = SIN_ROCE
		bola.Transparency = 1
	end

	-- Asientos: el conductor a la izquierda y el acompañante a la derecha
	local volante = asiento(modelo, "VehicleSeat", "Volante", datos.conductor)
	volante.HeadsUpDisplay = false
	volante.Disabled = false
	local acompanante = datos.acompanante and asiento(modelo, "Seat", "Acompanante", datos.acompanante)

	-- Todo pegado al chasis y sin peso, salvo las ruedas que apoyan. Solo chocan
	-- la carroceria y las ruedas.
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = p.Name == "Cuerpo" or p.Name == "Rueda"
			if p ~= chasis then
				soldar(chasis, p)
				p.Massless = p.Name ~= "Rueda"
			end
		end
	end

	-- Empuje horizontal y orientacion
	local punto = Instance.new("Attachment")
	punto.Parent = chasis
	local empuje = Instance.new("LinearVelocity")
	empuje.Attachment0 = punto
	empuje.RelativeTo = Enum.ActuatorRelativeTo.World
	empuje.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	empuje.MaxAxesForce = Vector3.new(60000, 0, 60000)
	empuje.VectorVelocity = Vector3.zero
	empuje.Parent = chasis
	local derecho = Instance.new("AlignOrientation")
	derecho.Mode = Enum.OrientationAlignmentMode.OneAttachment
	derecho.Attachment0 = punto
	derecho.MaxTorque = 1e7
	derecho.Responsiveness = 40
	derecho.Parent = chasis

	botonAsiento(volante, "Manejar", datos.nombre)
	if acompanante then
		botonAsiento(acompanante, "Subir", datos.nombre)
	end

	modelo.Parent = carpeta
	return {
		modelo = modelo,
		chasis = chasis,
		volante = volante,
		acompanante = acompanante,
		empuje = empuje,
		derecho = derecho,
		velocidad = 0,
		rumbo = 0,
		soloDesde = nil,
		-- Velocidad propia del tipo; el motor deportivo de la tienda pone auto.maxima
		maximaBase = datos.maxima,
		aceleracionBase = datos.aceleracion,
		extras = {},
	}
end

local autos = {}

local function estacionar(auto)
	local lugar = auto.lugar
	-- Mirando hacia +Z (hacia afuera de la ciudad): el frente del auto es -Z, se gira 180
	auto.rumbo = math.pi
	auto.velocidad = 0
	auto.empuje.VectorVelocity = Vector3.zero
	auto.modelo:PivotTo(CFrame.new(lugar.x, SUELO + 0.05, lugar.z) * CFrame.Angles(0, auto.rumbo, 0))
	auto.derecho.CFrame = CFrame.Angles(0, auto.rumbo, 0)
	auto.chasis.AssemblyLinearVelocity = Vector3.zero
	auto.chasis.AssemblyAngularVelocity = Vector3.zero
	auto.soloDesde = nil
end

for _, lugar in LUGARES do
	local auto = crearAuto(lugar.tipo, lugar.color)
	auto.lugar = lugar
	estacionar(auto)
	-- El servidor maneja la fisica (lee el volante del jugador), asi no salta de dueño
	auto.chasis:SetNetworkOwner(nil)
	table.insert(autos, auto)

	-- Al sentarse al volante el auto toma el estilo del jugador; al bajarse, vuelve a ser el de siempre
	auto.volante:GetPropertyChangedSignal("Occupant"):Connect(function()
		local ocupante = auto.volante.Occupant
		local jugador = ocupante and Players:GetPlayerFromCharacter(ocupante.Parent)
		if jugador then
			SkinsAutos.aplicar(auto, jugador)
		else
			SkinsAutos.restaurar(auto)
		end
	end)
end

local function acercarA(valor, objetivo, paso)
	if valor < objetivo then
		return math.min(valor + paso, objetivo)
	end
	return math.max(valor - paso, objetivo)
end

RunService.Heartbeat:Connect(function(dt)
	for _, auto in autos do
		local conductor = auto.volante.Occupant
		local acelerador = conductor and auto.volante.ThrottleFloat or 0
		local volante = conductor and auto.volante.SteerFloat or 0

		-- Velocidad: acelera hacia donde pide el acelerador, frena si se suelta
		local maxima = auto.maxima or auto.maximaBase or VELOCIDAD_MAXIMA
		local objetivo = acelerador > 0 and acelerador * maxima or acelerador * VELOCIDAD_REVERSA
		local aceleracion = auto.aceleracion or auto.aceleracionBase or ACELERACION
		local paso = (math.abs(objetivo) < math.abs(auto.velocidad) or objetivo * auto.velocidad < 0) and FRENADO or aceleracion
		auto.velocidad = acercarA(auto.velocidad, objetivo, paso * dt)

		-- Doblar: solo si se mueve, y al reves cuando va marcha atras
		local rapidez = math.clamp(math.abs(auto.velocidad) / 10, 0, 1)
		local sentido = auto.velocidad >= 0 and 1 or -1
		auto.rumbo -= volante * GIRO * rapidez * sentido * dt

		local orientacion = CFrame.Angles(0, auto.rumbo, 0)
		auto.derecho.CFrame = orientacion
		auto.empuje.VectorVelocity = orientacion.LookVector * auto.velocidad

		-- Si se cae del mapa, vuelve a su lugar
		if auto.chasis.Position.Y < -20 then
			estacionar(auto)
			continue
		end

		-- Solo y lejos de su lugar por un rato: vuelve al estacionamiento
		local vacio = not conductor and not (auto.acompanante and auto.acompanante.Occupant)
		local lejos = (Vector3.new(auto.lugar.x, 0, auto.lugar.z) - auto.chasis.Position * Vector3.new(1, 0, 1)).Magnitude > 6
		if vacio and lejos then
			auto.soloDesde = auto.soloDesde or os.clock()
			if os.clock() - auto.soloDesde > ESPERA_VOLVER then
				estacionar(auto)
			end
		else
			auto.soloDesde = nil
		end
	end
end)
