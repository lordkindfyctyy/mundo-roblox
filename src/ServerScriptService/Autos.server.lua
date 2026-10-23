-- Autos que andan por las calles de la ciudad (PlanoCiudad), por la mano derecha.
-- Frenan con el semaforo en rojo o amarillo (Semaforos.server.lua) y si tienen
-- un jugador o un auto adelante, asi nunca atropellan a nadie.
-- En los cruces, los que van a lo largo de X le dan paso a los que van a lo largo
-- de Z (si no, dos autos podrian quedarse esperandose para siempre).
-- Al llegar al borde de la ciudad vuelven a entrar por el otro lado.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))

local SEMILLA = 777
local CANTIDAD_AUTOS = 14
local VELOCIDAD = 22 -- studs por segundo
local CARRIL = 4 -- distancia del centro de la calle al centro del carril
local DISTANCIA_FRENO = 14 -- frena si hay algo adelante a esta distancia o menos
local ANCHO_REVISION = 3.5 -- cuanto mira para los costados al buscar algo adelante
local SUELO = 0.3 -- altura del asfalto (Ciudad.server.lua)
local LARGO, ANCHO, ALTO = 8, 4.4, 2

local COLORES = {
	Color3.fromRGB(220, 40, 40),
	Color3.fromRGB(40, 90, 220),
	Color3.fromRGB(250, 200, 0),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(30, 30, 30),
	Color3.fromRGB(40, 170, 80),
	Color3.fromRGB(255, 130, 0),
	Color3.fromRGB(150, 60, 200),
}

local azar = Random.new(SEMILLA)

local carpeta = Instance.new("Folder")
carpeta.Name = "Autos"
carpeta.Parent = Workspace

local function parte(modelo, nombre, tamano, cframe, color, material, forma)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = forma or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = modelo
	return p
end

-- Arma un auto mirando hacia -Z (el frente de Roblox) con centro en el origen
local function crearAuto(color)
	local modelo = Instance.new("Model")
	modelo.Name = "Auto"

	local altoRueda = 1.6
	local cuerpo = parte(
		modelo,
		"Cuerpo",
		Vector3.new(ANCHO, ALTO, LARGO),
		CFrame.new(0, altoRueda / 2 + ALTO / 2, 0),
		color,
		Enum.Material.SmoothPlastic
	)
	modelo.PrimaryPart = cuerpo
	-- El punto de apoyo del auto queda en el piso, entre las ruedas
	cuerpo.PivotOffset = CFrame.new(0, -(altoRueda / 2 + ALTO / 2), 0)

	parte(
		modelo,
		"Cabina",
		Vector3.new(ANCHO - 0.6, 1.6, LARGO * 0.5),
		CFrame.new(0, altoRueda / 2 + ALTO + 0.8, 0.4),
		Color3.fromRGB(150, 200, 230),
		Enum.Material.Glass
	)

	-- Ruedas: el cilindro mide su largo en X, que es justo el eje de la rueda
	for _, x in { -ANCHO / 2, ANCHO / 2 } do
		for _, z in { -LARGO / 2 + 1.5, LARGO / 2 - 1.5 } do
			parte(
				modelo,
				"Rueda",
				Vector3.new(0.8, altoRueda, altoRueda),
				CFrame.new(x, altoRueda / 2, z),
				Color3.fromRGB(25, 25, 25),
				Enum.Material.SmoothPlastic,
				Enum.PartType.Cylinder
			)
		end
	end

	-- Faros adelante (-Z) y luces de freno atras (+Z)
	for _, x in { -ANCHO / 2 + 0.7, ANCHO / 2 - 0.7 } do
		local faro = parte(modelo, "Faro", Vector3.new(0.8, 0.5, 0.2), CFrame.new(x, altoRueda / 2 + ALTO * 0.7, -LARGO / 2 - 0.1), Color3.fromRGB(255, 250, 210), Enum.Material.Neon)
		-- De noche alumbran la calle (DiaNoche.server.lua)
		local luz = Instance.new("SpotLight")
		luz.Face = Enum.NormalId.Front
		luz.Range = 28
		luz.Angle = 70
		luz.Brightness = 2
		luz.Color = Color3.fromRGB(255, 245, 210)
		luz.Parent = faro
		CollectionService:AddTag(faro, "LuzDeNoche")
		parte(modelo, "LuzFreno", Vector3.new(0.8, 0.5, 0.2), CFrame.new(x, altoRueda / 2 + ALTO * 0.7, LARGO / 2 + 0.1), Color3.fromRGB(120, 0, 0), Enum.Material.SmoothPlastic)
	end

	modelo.Parent = carpeta
	return modelo
end

-- Un carril: calle, sentido y eje. Recorre desde -limite hasta +limite.
-- enX: la calle corre a lo largo de X. sentido: 1 o -1.
local carriles = {}
for _, centro in Plano.CALLES do
	for _, enX in { true, false } do
		for _, sentido in { 1, -1 } do
			table.insert(carriles, { centro = centro, enX = enX, sentido = sentido })
		end
	end
end

local LIMITE = Plano.LIMITE - LARGO

local function direccion(carril)
	return carril.enX and Vector3.new(carril.sentido, 0, 0) or Vector3.new(0, 0, carril.sentido)
end

-- Posicion en el carril para un avance (-LIMITE..LIMITE en el sentido de marcha)
local function posicionEn(carril, avance)
	local dir = direccion(carril)
	-- Por la mano derecha: a la derecha de la direccion de marcha
	local derecha = Vector3.new(-dir.Z, 0, dir.X)
	local sobreCalle = carril.enX and Vector3.new(0, 0, carril.centro) or Vector3.new(carril.centro, 0, 0)
	return sobreCalle + dir * avance + derecha * CARRIL + Vector3.new(0, SUELO, 0)
end

local autos = {}

for i = 1, CANTIDAD_AUTOS do
	local carril = carriles[(i - 1) % #carriles + 1]
	local auto = {
		modelo = crearAuto(COLORES[azar:NextInteger(1, #COLORES)]),
		carril = carril,
		avance = azar:NextNumber(-LIMITE, LIMITE),
		frenado = false,
	}
	table.insert(autos, auto)
end

local function ubicar(auto)
	local pos = posicionEn(auto.carril, auto.avance)
	local dir = direccion(auto.carril)
	auto.posicion = pos
	auto.modelo:PivotTo(CFrame.lookAt(pos, pos + dir))
end

for _, auto in autos do
	ubicar(auto)
end

-- Hay algo en el camino? Mira un rectangulo adelante del auto.
local function hayAlgoAdelante(auto, punto)
	local dir = direccion(auto.carril)
	local delta = punto - auto.posicion
	local adelante = delta:Dot(dir)
	if adelante <= 0 or adelante > DISTANCIA_FRENO + LARGO / 2 then
		return false
	end
	local costado = (delta - dir * adelante)
	return Vector3.new(costado.X, 0, costado.Z).Magnitude <= ANCHO_REVISION
end

-- Semaforo: si la luz de su calle no esta en verde, frena antes de entrar al
-- proximo cruce. Si ya estaba cruzando, termina de pasar.
local ZONA_SEMAFORO = 6 -- cuanto antes de la linea de freno empieza a mirar la luz

local function semaforoEnRojo(auto)
	local luz = Workspace:GetAttribute(Plano.ATRIBUTO_LUZ[auto.carril.enX])
	if luz == nil or luz == "verde" then
		return false
	end
	local sentido = auto.carril.sentido
	local donde = auto.carril.enX and auto.posicion.X or auto.posicion.Z
	for _, cruce in Plano.CALLES do
		-- Donde queda el centro del auto con la trompa justo antes del cruce
		local lineaFreno = cruce - sentido * (Plano.MEDIO_ANCHO_CALLE + 1 + LARGO / 2)
		local falta = (lineaFreno - donde) * sentido
		if falta >= 0 and falta <= ZONA_SEMAFORO then
			return true
		end
	end
	return false
end

local function debeFrenar(auto)
	if semaforoEnRojo(auto) then
		return true
	end
	for _, jugador in Players:GetPlayers() do
		local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
		if raiz and hayAlgoAdelante(auto, raiz.Position) then
			return true
		end
	end
	for _, otro in autos do
		if otro ~= auto then
			local mismaCalle = otro.carril == auto.carril
			-- En los cruces: el que va en X espera al que va en Z
			local cedePaso = auto.carril.enX and not otro.carril.enX
			if (mismaCalle or cedePaso) and hayAlgoAdelante(auto, otro.posicion) then
				return true
			end
		end
	end
	return false
end

local function luzFreno(auto, prendida)
	if auto.frenado == prendida then
		return
	end
	auto.frenado = prendida
	for _, p in auto.modelo:GetChildren() do
		if p.Name == "LuzFreno" then
			p.Material = prendida and Enum.Material.Neon or Enum.Material.SmoothPlastic
			p.Color = prendida and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(120, 0, 0)
		end
	end
end

RunService.Heartbeat:Connect(function(dt)
	for _, auto in autos do
		local frenar = debeFrenar(auto)
		luzFreno(auto, frenar)
		if not frenar then
			auto.avance += VELOCIDAD * dt
			if auto.avance > LIMITE then
				auto.avance = -LIMITE -- vuelve a entrar por el otro lado de la ciudad
			end
			ubicar(auto)
		end
	end
end)
