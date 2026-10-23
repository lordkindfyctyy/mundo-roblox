-- Modelos de las mascotas, uno distinto para cada especie (ConfigMascotas.Lista).
-- Se arman con partes: esferas estiradas (SpecialMesh), cuñas para orejas y picos,
-- cilindros para patas y colas. Todo mira hacia -Z (el frente) y el centro del
-- cuerpo queda en el origen; Mascotas.server.lua lo mueve con PivotTo.
--
-- ModelosMascotas.crear(mascota, rareza) devuelve el Model. Si la mascota vuela,
-- el modelo tiene el atributo "Vuela" (Mascotas.server.lua la hace ir mas alto).

local ModelosMascotas = {}

local NEGRO = Color3.fromRGB(20, 20, 20)
local BLANCO = Color3.fromRGB(250, 250, 250)
local ROSA = Color3.fromRGB(255, 150, 170)
local NARANJA = Color3.fromRGB(255, 150, 30)

-- Una pieza del modelo. forma: "esfera" (se estira con el tamaño), "bola",
-- "cuna", "cilindro" o "bloque". donde: CFrame relativo al centro del cuerpo.
local function pieza(modelo, escala, nombre, forma, tamano, donde, color, material)
	local parte
	if forma == "cuna" then
		parte = Instance.new("WedgePart")
	else
		parte = Instance.new("Part")
		if forma == "bola" then
			parte.Shape = Enum.PartType.Ball
		elseif forma == "cilindro" then
			parte.Shape = Enum.PartType.Cylinder
		end
	end
	parte.Name = nombre
	parte.Size = tamano * escala
	parte.CFrame = CFrame.new(donde.Position * escala) * donde.Rotation
	parte.Color = color
	parte.Material = material or Enum.Material.SmoothPlastic
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanTouch = false
	parte.CanQuery = false
	parte.CastShadow = false
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	if forma == "esfera" then
		local malla = Instance.new("SpecialMesh")
		malla.MeshType = Enum.MeshType.Sphere
		malla.Parent = parte
	end
	parte.Parent = modelo
	return parte
end

local function en(x, y, z, rx, ry, rz)
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

-- Ojos con brillito, en la cara de una cabeza centrada en (0, y, z)
local function ojos(m, e, y, z, separacion, tamano, color)
	for _, lado in { -1, 1 } do
		pieza(m, e, "Ojo", "bola", Vector3.one * tamano, en(lado * separacion, y, z), color or NEGRO)
		pieza(m, e, "Brillo", "bola", Vector3.one * tamano * 0.35, en(lado * separacion + 0.06, y + 0.07, z - tamano * 0.4), BLANCO)
	end
end

-- Cuatro patitas cortas debajo del cuerpo
local function patas(m, e, color, ancho, largo, alto)
	for _, x in { -ancho, ancho } do
		for _, z in { -largo, largo } do
			pieza(m, e, "Pata", "cilindro", Vector3.new(alto, 0.4, 0.4), en(x, -0.75, z, 0, 0, 90), color)
		end
	end
end

-- Oreja en punta: una cuña girada para que el triangulo mire al frente
local function orejaPunta(m, e, lado, x, y, z, color, alto)
	pieza(m, e, "Oreja", "cuna", Vector3.new(0.18, alto or 0.6, 0.5), en(x * lado, y, z, 0, lado * 90, 0), color)
end

local Especies = {}

function Especies.Gatito(m, e, c)
	pieza(m, e, "Cuerpo", "esfera", Vector3.new(1.5, 1.3, 1.9), en(0, 0, 0.3), c)
	pieza(m, e, "Cabeza", "esfera", Vector3.new(1.5, 1.35, 1.35), en(0, 0.75, -0.75), c)
	for _, lado in { -1, 1 } do
		orejaPunta(m, e, lado, 0.42, 1.45, -0.75, c)
		-- Bigotes
		pieza(m, e, "Bigote", "bloque", Vector3.new(0.7, 0.04, 0.04), en(lado * 0.55, 0.55, -1.38, 0, 0, lado * 8), BLANCO)
	end
	ojos(m, e, 0.9, -1.35, 0.32, 0.28, Color3.fromRGB(40, 160, 60))
	pieza(m, e, "Nariz", "bola", Vector3.one * 0.18, en(0, 0.62, -1.45), ROSA)
	patas(m, e, c, 0.45, 0.6, 0.6)
	pieza(m, e, "Cola", "cilindro", Vector3.new(1.4, 0.28, 0.28), en(0, 0.5, 1.3, 0, 90, 60), c)
end

function Especies.Perrito(m, e, c)
	local claro = c:Lerp(BLANCO, 0.45)
	pieza(m, e, "Cuerpo", "esfera", Vector3.new(1.6, 1.35, 2.1), en(0, 0, 0.3), c)
	pieza(m, e, "Cabeza", "esfera", Vector3.new(1.5, 1.4, 1.4), en(0, 0.75, -0.8), c)
	pieza(m, e, "Hocico", "esfera", Vector3.new(0.8, 0.6, 0.7), en(0, 0.5, -1.4), claro)
	pieza(m, e, "Nariz", "bola", Vector3.one * 0.25, en(0, 0.68, -1.72), NEGRO)
	pieza(m, e, "Lengua", "esfera", Vector3.new(0.25, 0.08, 0.35), en(0, 0.18, -1.55), ROSA)
	for _, lado in { -1, 1 } do
		-- Orejas caidas a los costados
		pieza(m, e, "Oreja", "esfera", Vector3.new(0.3, 0.9, 0.55), en(lado * 0.78, 0.6, -0.7, 0, 0, lado * 15), c:Lerp(NEGRO, 0.3))
	end
	ojos(m, e, 0.95, -1.38, 0.33, 0.27)
	patas(m, e, c, 0.48, 0.65, 0.6)
	pieza(m, e, "Cola", "cilindro", Vector3.new(0.9, 0.25, 0.25), en(0, 0.45, 1.35, 0, 90, 50), c)
end

function Especies.Pollito(m, e, c)
	pieza(m, e, "Cuerpo", "esfera", Vector3.new(1.6, 1.6, 1.6), en(0, 0, 0), c)
	pieza(m, e, "Cabeza", "bola", Vector3.one * 1.1, en(0, 0.95, -0.25), c)
	pieza(m, e, "Pico", "cuna", Vector3.new(0.3, 0.25, 0.35), en(0, 0.85, -0.9, 0, 180, 0), NARANJA)
	pieza(m, e, "Mechon", "esfera", Vector3.new(0.15, 0.45, 0.3), en(0, 1.6, -0.25, 0, 0, 15), c)
	ojos(m, e, 1.1, -0.72, 0.22, 0.2)
	for _, lado in { -1, 1 } do
		pieza(m, e, "Ala", "esfera", Vector3.new(0.3, 0.8, 1), en(lado * 0.82, 0.05, 0.05, 0, 0, lado * 20), c:Lerp(NARANJA, 0.2))
		pieza(m, e, "Pata", "bloque", Vector3.new(0.35, 0.1, 0.45), en(lado * 0.35, -0.82, -0.2), NARANJA)
	end
end

function Especies.Conejo(m, e, c)
	pieza(m, e, "Cuerpo", "esfera", Vector3.new(1.5, 1.4, 1.7), en(0, 0, 0.3), c)
	pieza(m, e, "Cabeza", "esfera", Vector3.new(1.3, 1.25, 1.25), en(0, 0.75, -0.6), c)
	for _, lado in { -1, 1 } do
		pieza(m, e, "Oreja", "esfera", Vector3.new(0.35, 1.5, 0.25), en(lado * 0.3, 1.9, -0.5, 0, 0, lado * -8), c)
		pieza(m, e, "OrejaAdentro", "esfera", Vector3.new(0.2, 1.1, 0.1), en(lado * 0.3, 1.9, -0.63, 0, 0, lado * -8), ROSA)
	end
	ojos(m, e, 0.85, -1.15, 0.3, 0.25)
	pieza(m, e, "Nariz", "bola", Vector3.one * 0.15, en(0, 0.6, -1.25), ROSA)
	pieza(m, e, "Dientes", "bloque", Vector3.new(0.2, 0.14, 0.05), en(0, 0.42, -1.2), BLANCO)
	patas(m, e, c, 0.42, 0.5, 0.5)
	pieza(m, e, "Cola", "bola", Vector3.one * 0.55, en(0, 0.1, 1.15), BLANCO)
end

function Especies.Zorrito(m, e, c)
	pieza(m, e, "Cuerpo", "esfera", Vector3.new(1.4, 1.25, 2.1), en(0, 0, 0.35), c)
	pieza(m, e, "Pecho", "esfera", Vector3.new(0.9, 0.9, 0.6), en(0, 0.05, -0.55), BLANCO)
	pieza(m, e, "Cabeza", "esfera", Vector3.new(1.4, 1.2, 1.3), en(0, 0.75, -0.8), c)
	pieza(m, e, "Hocico", "esfera", Vector3.new(0.55, 0.45, 0.8), en(0, 0.55, -1.45), BLANCO)
	pieza(m, e, "Nariz", "bola", Vector3.one * 0.18, en(0, 0.62, -1.85), NEGRO)
	for _, lado in { -1, 1 } do
		orejaPunta(m, e, lado, 0.42, 1.5, -0.8, c, 0.75)
		pieza(m, e, "PuntaOreja", "bola", Vector3.one * 0.18, en(lado * 0.42, 1.85, -0.8), NEGRO)
	end
	ojos(m, e, 0.9, -1.38, 0.32, 0.24)
	patas(m, e, NEGRO, 0.42, 0.7, 0.6)
	-- Cola grande y peluda con la punta blanca
	pieza(m, e, "Cola", "esfera", Vector3.new(0.75, 0.75, 1.8), en(0, 0.45, 1.75, -25, 0, 0), c)
	pieza(m, e, "PuntaCola", "esfera", Vector3.new(0.55, 0.55, 0.6), en(0, 0.85, 2.55, -25, 0, 0), BLANCO)
end

function Especies.Panda(m, e, c)
	pieza(m, e, "Cuerpo", "esfera", Vector3.new(1.8, 1.6, 1.9), en(0, 0, 0.25), BLANCO)
	pieza(m, e, "Cabeza", "esfera", Vector3.new(1.6, 1.45, 1.45), en(0, 0.9, -0.65), BLANCO)
	for _, lado in { -1, 1 } do
		pieza(m, e, "Oreja", "bola", Vector3.one * 0.5, en(lado * 0.6, 1.55, -0.6), NEGRO)
		pieza(m, e, "Mancha", "esfera", Vector3.new(0.45, 0.55, 0.2), en(lado * 0.35, 1, -1.32, 0, 0, lado * -20), NEGRO)
		pieza(m, e, "Brazo", "esfera", Vector3.new(0.5, 0.9, 0.55), en(lado * 0.85, 0.1, -0.35, 0, 0, lado * 20), NEGRO)
	end
	-- Ojos chiquitos y blancos dentro de las manchas
	for _, lado in { -1, 1 } do
		pieza(m, e, "Ojo", "bola", Vector3.one * 0.14, en(lado * 0.35, 1.03, -1.42), BLANCO)
	end
	pieza(m, e, "Nariz", "bola", Vector3.one * 0.2, en(0, 0.75, -1.4), NEGRO)
	patas(m, e, NEGRO, 0.5, 0.55, 0.6)
end

function Especies.Buho(m, e, c)
	local panza = c:Lerp(BLANCO, 0.55)
	pieza(m, e, "Cuerpo", "esfera", Vector3.new(1.6, 2, 1.5), en(0, 0, 0), c)
	pieza(m, e, "Panza", "esfera", Vector3.new(1.1, 1.3, 0.4), en(0, -0.2, -0.6), panza)
	for _, lado in { -1, 1 } do
		pieza(m, e, "Disco", "bola", Vector3.one * 0.7, en(lado * 0.36, 0.55, -0.58), BLANCO)
		pieza(m, e, "Ojo", "bola", Vector3.one * 0.35, en(lado * 0.36, 0.55, -0.88), NEGRO)
		pieza(m, e, "Brillo", "bola", Vector3.one * 0.12, en(lado * 0.36 + 0.07, 0.62, -1.02), BLANCO)
		orejaPunta(m, e, lado, 0.5, 1.15, -0.1, c, 0.5)
		pieza(m, e, "Ala", "esfera", Vector3.new(0.3, 1.3, 1.1), en(lado * 0.85, -0.05, 0.1, 0, 0, lado * 25), c:Lerp(NEGRO, 0.25))
		pieza(m, e, "Pata", "bloque", Vector3.new(0.3, 0.12, 0.35), en(lado * 0.3, -1.02, -0.2), NARANJA)
	end
	pieza(m, e, "Pico", "cuna", Vector3.new(0.22, 0.3, 0.25), en(0, 0.3, -0.85, 0, 180, 0), NARANJA)
end

function Especies.Dragon(m, e, c)
	local panza = c:Lerp(Color3.fromRGB(255, 220, 150), 0.6)
	pieza(m, e, "Cuerpo", "esfera", Vector3.new(1.5, 1.4, 2), en(0, 0, 0.3), c)
	pieza(m, e, "Panza", "esfera", Vector3.new(1, 1, 1.3), en(0, -0.15, 0.05), panza)
	pieza(m, e, "Cabeza", "esfera", Vector3.new(1.3, 1.2, 1.5), en(0, 0.8, -0.85), c)
	pieza(m, e, "Hocico", "esfera", Vector3.new(0.8, 0.55, 0.7), en(0, 0.6, -1.55), c)
	for _, lado in { -1, 1 } do
		pieza(m, e, "Cuerno", "cuna", Vector3.new(0.15, 0.6, 0.35), en(lado * 0.35, 1.55, -0.65, -20, 0, 0), panza)
		pieza(m, e, "Ojo", "bola", Vector3.one * 0.26, en(lado * 0.35, 1, -1.45), Color3.fromRGB(255, 220, 0), Enum.Material.Neon)
		-- Alas: dos cuñas grandes en la espalda
		pieza(m, e, "Ala", "cuna", Vector3.new(0.1, 1.2, 1.6), en(lado * 1.1, 0.75, 0.4, 0, 0, lado * -55), c:Lerp(NEGRO, 0.2))
	end
	patas(m, e, c, 0.45, 0.6, 0.6)
	pieza(m, e, "Cola", "cilindro", Vector3.new(1.6, 0.35, 0.35), en(0, 0, 1.7, 0, 90, 20), c)
	pieza(m, e, "Pua", "cuna", Vector3.new(0.12, 0.5, 0.5), en(0, 0.3, 2.45), panza)
end

function Especies.Fenix(m, e, c)
	local dorado = Color3.fromRGB(255, 210, 40)
	pieza(m, e, "Cuerpo", "esfera", Vector3.new(1.3, 1.4, 1.9), en(0, 0, 0.2), c)
	pieza(m, e, "Cabeza", "bola", Vector3.one * 1.05, en(0, 0.85, -0.75), c)
	pieza(m, e, "Pico", "cuna", Vector3.new(0.25, 0.3, 0.45), en(0, 0.75, -1.4, 0, 180, 0), dorado)
	ojos(m, e, 0.98, -1.18, 0.25, 0.2)
	-- Cresta dorada
	for i, z in { -0.9, -0.65, -0.4 } do
		pieza(m, e, "Cresta", "cuna", Vector3.new(0.1, 0.55 - i * 0.08, 0.3), en(0, 1.45, z, 0, 180, 0), dorado, Enum.Material.Neon)
	end
	for _, lado in { -1, 1 } do
		-- Alas abiertas que brillan
		pieza(m, e, "Ala", "cuna", Vector3.new(0.12, 1.4, 2), en(lado * 1.25, 0.6, 0.2, 0, 0, lado * -65), NARANJA, Enum.Material.Neon)
		pieza(m, e, "PuntaAla", "cuna", Vector3.new(0.1, 0.8, 1.2), en(lado * 2, 1.05, 0.4, 0, 0, lado * -75), dorado, Enum.Material.Neon)
	end
	-- Plumas largas de la cola
	for i, angulo in { -20, 0, 20 } do
		pieza(m, e, "Pluma", "esfera", Vector3.new(0.3, 0.2, 1.8), en(math.rad(angulo) * 0.8, -0.1, 1.8, 15, angulo, 0), i == 2 and dorado or NARANJA, Enum.Material.Neon)
	end
end

-- Nombre arriba de la mascota, del color de su rareza
local function cartelNombre(modelo, cuerpo, mascota, rareza, escala)
	local cartel = Instance.new("BillboardGui")
	cartel.Size = UDim2.fromOffset(110, 26)
	cartel.StudsOffset = Vector3.new(0, 2 * escala, 0)
	cartel.MaxDistance = 45
	cartel.Parent = cuerpo
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.GothamBlack
	texto.TextScaled = true
	texto.TextColor3 = rareza.color
	texto.TextStrokeTransparency = 0.4
	texto.Text = mascota.nombre
	texto.Parent = cartel
end

-- Efectos segun la rareza: destellos para las epicas, luz y fuego para la legendaria
local function efectos(cuerpo, mascota)
	if mascota.rareza == "Rara" then
		local brillitos = Instance.new("Sparkles")
		brillitos.SparkleColor = mascota.color:Lerp(BLANCO, 0.5)
		brillitos.Parent = cuerpo
	elseif mascota.rareza == "Epica" or mascota.rareza == "Legendaria" then
		local luz = Instance.new("PointLight")
		luz.Color = mascota.color
		luz.Range = 10
		luz.Brightness = 1.5
		luz.Parent = cuerpo

		local destellos = Instance.new("ParticleEmitter")
		destellos.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		destellos.Color = ColorSequence.new(mascota.color:Lerp(BLANCO, 0.4))
		destellos.Size = NumberSequence.new(0.4, 0)
		destellos.Lifetime = NumberRange.new(0.6, 1.2)
		destellos.Rate = 8
		destellos.Speed = NumberRange.new(1, 2)
		destellos.SpreadAngle = Vector2.new(180, 180)
		destellos.LightEmission = 1
		destellos.Parent = cuerpo
	end
	if mascota.rareza == "Legendaria" then
		local fuego = Instance.new("Fire")
		fuego.Color = Color3.fromRGB(255, 120, 20)
		fuego.SecondaryColor = Color3.fromRGB(255, 220, 60)
		fuego.Size = 3
		fuego.Heat = 4
		fuego.Parent = cuerpo
	end
end

local VUELAN = { Buho = true, Dragon = true, Fenix = true }

function ModelosMascotas.crear(mascota, rareza)
	local escala = rareza.escala
	local modelo = Instance.new("Model")
	modelo.Name = mascota.nombre

	local armar = Especies[mascota.id]
	if armar then
		armar(modelo, escala, mascota.color)
	else
		-- Una mascota nueva sin modelo propio: una bola con ojos
		pieza(modelo, escala, "Cuerpo", "bola", Vector3.one * 2, en(0, 0, 0), mascota.color)
		ojos(modelo, escala, 0.25, -0.85, 0.4, 0.35)
	end

	local cuerpo = modelo:FindFirstChild("Cuerpo")
	modelo.PrimaryPart = cuerpo
	-- El punto de apoyo queda en el centro del cuerpo aunque el cuerpo este corrido
	cuerpo.PivotOffset = cuerpo.CFrame:Inverse()
	cartelNombre(modelo, cuerpo, mascota, rareza, escala)
	efectos(cuerpo, mascota)
	if VUELAN[mascota.id] then
		modelo:SetAttribute("Vuela", true)
	end
	return modelo
end

return ModelosMascotas
