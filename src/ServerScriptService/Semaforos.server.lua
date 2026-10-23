-- Semaforos en los cruces de la ciudad. Hay uno en cada esquina con dos
-- cabezales: uno mira hacia la calle que corre en X y otro hacia la que corre en Z.
-- Todos cambian juntos: verde para X, amarillo, todo rojo un segundo para que se
-- libere el cruce, y lo mismo para Z. Los autos (Autos.server.lua) leen las luces
-- de los atributos LuzX y LuzZ de Workspace.

local Workspace = game:GetService("Workspace")

local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))

local TIEMPO_VERDE = 8
local TIEMPO_AMARILLO = 2
local TIEMPO_TODO_ROJO = 1
local VEREDA = 0.5 -- altura de las veredas (Ciudad.server.lua)
local ESQUINA = Plano.MEDIO_ANCHO_CALLE + 1.5 -- distancia del centro del cruce al poste
local ALTO_POSTE = 10

local COLORES = {
	roja = Color3.fromRGB(255, 40, 30),
	amarilla = Color3.fromRGB(255, 200, 0),
	verde = Color3.fromRGB(40, 230, 70),
}
local APAGADA = Color3.fromRGB(45, 45, 45)
local ORDEN = { "roja", "amarilla", "verde" } -- de arriba hacia abajo

local carpeta = Instance.new("Folder")
carpeta.Name = "Semaforos"
carpeta.Parent = Workspace

local function parte(nombre, tamano, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = nombre == "Poste"
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = carpeta
	return p
end

-- Lamparas de cada eje: lamparas.X.verde = { partes... }
local lamparas = {
	[true] = { roja = {}, amarilla = {}, verde = {} },
	[false] = { roja = {}, amarilla = {}, verde = {} },
}

-- Un cabezal en lo alto del poste que mira hacia mirada (los autos que vienen
-- de ese lado lo ven de frente). enX: es la luz de la calle que corre en X.
local function cabezal(base, mirada, enX)
	local centro = base + Vector3.new(0, ALTO_POSTE - 1.5, 0) + mirada * 0.6
	local orientacion = CFrame.lookAt(centro, centro + mirada)
	parte("Cabezal", Vector3.new(1.2, 3.6, 0.8), orientacion, Color3.fromRGB(30, 30, 30))
	for i, color in ORDEN do
		local lampara = parte(
			"Luz",
			Vector3.new(0.8, 0.8, 0.2),
			orientacion * CFrame.new(0, 1.15 - (i - 1) * 1.15, -0.45),
			APAGADA
		)
		table.insert(lamparas[enX][color], lampara)
	end
end

for _, cruce in Plano.cruces() do
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x = cruce.X + sx * ESQUINA
			local z = cruce.Z + sz * ESQUINA
			-- Las esquinas de afuera de las calles del borde quedan fuera de la ciudad
			if math.abs(x) < Plano.LIMITE - 1 and math.abs(z) < Plano.LIMITE - 1 then
				local base = Vector3.new(x, VEREDA, z)
				parte("Poste", Vector3.new(0.5, ALTO_POSTE, 0.5), CFrame.new(base + Vector3.new(0, ALTO_POSTE / 2, 0)), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
				-- Mira hacia afuera del cruce, al encuentro de los autos que se acercan
				cabezal(base, Vector3.new(sx, 0, 0), true)
				cabezal(base, Vector3.new(0, 0, sz), false)
			end
		end
	end
end

local function prender(enX, luz)
	Workspace:SetAttribute(Plano.ATRIBUTO_LUZ[enX], luz)
	for color, lista in lamparas[enX] do
		local encendida = color == luz
		for _, lampara in lista do
			lampara.Color = encendida and COLORES[color] or APAGADA
			lampara.Material = encendida and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end
end

prender(true, "roja")
prender(false, "roja")

-- Ciclo: le toca a un eje, despues al otro
local turno = true
while true do
	local otro = not turno
	prender(otro, "roja")
	prender(turno, "verde")
	task.wait(TIEMPO_VERDE)
	prender(turno, "amarilla")
	task.wait(TIEMPO_AMARILLO)
	prender(turno, "roja")
	task.wait(TIEMPO_TODO_ROJO)
	turno = otro
end
