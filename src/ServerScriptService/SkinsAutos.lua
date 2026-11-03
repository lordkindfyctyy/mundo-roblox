-- Le pone a un auto de Vehiculos.server.lua el estilo del jugador que lo maneja
-- (ConfigAutos: pintura, rayas, ruedas y motor deportivo) y se lo saca cuando se baja.
--   SkinsAutos.aplicar(auto, jugador)
--   SkinsAutos.restaurar(auto)
-- auto es la tabla de Vehiculos (modelo, extras, ...). Las piezas que se agregan
-- (rayas, aleron) van soldadas al cuerpo y sin peso, como el resto del auto.
-- Se pintan las partes con el atributo "Pintura" y se cambian las "Llanta"; para
-- volver al original se usa el atributo "ColorBase" (ModelosAutos.lua).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigAutos = require(ReplicatedStorage:WaitForChild("ConfigAutos"))

local SkinsAutos = {}

-- Una pieza pegada a base (por defecto la carroceria); cframe es relativo a base
local function pieza(auto, nombre, tamano, cframe, color, material, base)
	local cuerpo = base or auto.modelo.Cuerpo
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

-- color nil = el color original de cada parte
local function pintar(auto, color, material)
	for _, p in auto.modelo:GetChildren() do
		if p:GetAttribute("Pintura") then
			p.Color = color or p:GetAttribute("ColorBase")
			p.Material = material or Enum.Material.SmoothPlastic
		end
	end
end

local function ruedas(auto, color, material)
	for _, p in auto.modelo:GetChildren() do
		if p.Name == "Llanta" then
			p.Color = color or p:GetAttribute("ColorBase")
			p.Material = material or Enum.Material.Metal
		end
	end
end

function SkinsAutos.restaurar(auto)
	for _, p in auto.extras or {} do
		p:Destroy()
	end
	auto.extras = {}
	pintar(auto, nil)
	ruedas(auto, nil)
	auto.maxima = nil
	auto.aceleracion = nil
end

function SkinsAutos.aplicar(auto, jugador)
	SkinsAutos.restaurar(auto)

	local color = ConfigAutos.puesto(jugador, "color")
	if color then
		pintar(auto, color.color, color.material)
	end

	local tamano = auto.modelo.Cuerpo.Size
	local arriba = tamano.Y / 2 -- la cara de arriba de la carroceria
	local rayas = ConfigAutos.puesto(jugador, "rayas")
	if rayas then
		-- Dos rayas a lo largo, arriba de cada parte marcada con "Raya" (capot, techo...)
		for _, base in auto.modelo:GetChildren() do
			if base:GetAttribute("Raya") then
				local t = base.Size
				local largo, donde = t.Z + 0.02, CFrame.new(0, t.Y / 2 + 0.02, 0)
				if base:IsA("WedgePart") then
					-- Sobre la cara inclinada: pasa por el centro de la cuña, subiendo hacia +Z
					largo = math.sqrt(t.Y ^ 2 + t.Z ^ 2)
					local normal = Vector3.new(0, t.Z, -t.Y) / largo
					donde = CFrame.new(normal * 0.03) * CFrame.Angles(-math.atan2(t.Y, t.Z), 0, 0)
				end
				for _, x in { -0.7, 0.7 } do
					pieza(auto, "Raya", Vector3.new(0.55, 0.06, largo), donde * CFrame.new(x, 0, 0), rayas.color, rayas.material, base)
				end
			end
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
		local cola = tamano.Z / 2 - 0.6
		pieza(auto, "Aleron", Vector3.new(tamano.X - 0.2, 0.25, 1.2), CFrame.new(0, arriba + 1.1, cola), colorAleron)
		for _, x in { -1.6, 1.6 } do
			pieza(auto, "PataAleron", Vector3.new(0.25, 1.1, 0.25), CFrame.new(x, arriba + 0.5, cola), Color3.fromRGB(30, 30, 30))
		end
	end
end

return SkinsAutos
