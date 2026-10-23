-- Le pone a un auto de Vehiculos.server.lua el estilo del jugador que lo maneja
-- (ConfigAutos: pintura, rayas, ruedas y motor deportivo) y se lo saca cuando se baja.
--   SkinsAutos.aplicar(auto, jugador)
--   SkinsAutos.restaurar(auto)
-- auto es la tabla de Vehiculos (modelo, colorBase, ...). Las piezas que se agregan
-- (rayas, aleron) van soldadas al cuerpo y sin peso, como el resto del auto.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigAutos = require(ReplicatedStorage:WaitForChild("ConfigAutos"))

local SkinsAutos = {}

local COLOR_RUEDA = Color3.fromRGB(25, 25, 25)

local function pieza(auto, nombre, tamano, cframe, color, material)
	local cuerpo = auto.modelo.Cuerpo
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cuerpo.CFrame * cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = auto.modelo
	local soldadura = Instance.new("WeldConstraint")
	soldadura.Part0 = cuerpo
	soldadura.Part1 = p
	soldadura.Parent = p
	table.insert(auto.extras, p)
	return p
end

local function pintar(auto, color, material)
	for _, nombre in { "Cuerpo", "Techo" } do
		local p = auto.modelo:FindFirstChild(nombre)
		if p then
			p.Color = color
			p.Material = material or Enum.Material.SmoothPlastic
		end
	end
end

local function ruedas(auto, color, material)
	for _, p in auto.modelo:GetChildren() do
		if p.Name == "Llanta" then
			p.Color = color
			p.Material = material or Enum.Material.SmoothPlastic
		end
	end
end

function SkinsAutos.restaurar(auto)
	for _, p in auto.extras or {} do
		p:Destroy()
	end
	auto.extras = {}
	pintar(auto, auto.colorBase)
	ruedas(auto, COLOR_RUEDA)
	auto.maxima = nil
	auto.aceleracion = nil
end

function SkinsAutos.aplicar(auto, jugador)
	SkinsAutos.restaurar(auto)

	local color = ConfigAutos.puesto(jugador, "color")
	if color then
		pintar(auto, color.color, color.material)
	end

	local rayas = ConfigAutos.puesto(jugador, "rayas")
	if rayas then
		-- Dos rayas a lo largo, arriba del capot y del baul (el cuerpo mide 5 x 1.6 x 9)
		for _, x in { -0.7, 0.7 } do
			pieza(auto, "Raya", Vector3.new(0.55, 0.06, 9.02), CFrame.new(x, 0.82, 0), rayas.color, rayas.material)
		end
	end

	local llantas = ConfigAutos.puesto(jugador, "ruedas")
	if llantas then
		ruedas(auto, llantas.color, llantas.material)
	end

	local motor = ConfigAutos.puesto(jugador, "motor")
	if motor then
		auto.maxima = motor.velocidad
		auto.aceleracion = motor.aceleracion
		-- Aleron atras (+Z es la cola del auto)
		local colorAleron = color and color.color or Color3.fromRGB(30, 30, 30)
		pieza(auto, "Aleron", Vector3.new(4.8, 0.25, 1.2), CFrame.new(0, 1.9, 4), colorAleron)
		for _, x in { -1.6, 1.6 } do
			pieza(auto, "PataAleron", Vector3.new(0.25, 1.1, 0.25), CFrame.new(x, 1.3, 4), Color3.fromRGB(30, 30, 30))
		end
	end
end

return SkinsAutos
