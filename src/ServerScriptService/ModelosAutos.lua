-- Modelos de los vehiculos de la ciudad: sedan, taxi, deportivo (descapotable),
-- camioneta y tractor. Los usan Autos.server.lua (los que andan solos por la calle)
-- y Vehiculos.server.lua (los que se manejan).
--
--   local modelo, datos = ModelosAutos.crear(tipo, color)
--
-- El modelo mira hacia -Z (el frente de Roblox), centrado en el origen y con las
-- ruedas apoyadas en y = 0 (ahi queda su WorldPivot). Todas las partes vienen
-- ancladas. datos tiene: tipo, nombre, largo, ancho, ruedas = { {x, z, radio} },
-- conductor y acompanante (donde van los asientos; el tractor no tiene acompañante),
-- maxima y aceleracion (para manejarlo).
--
-- Nombres que usan otros scripts:
--   Cuerpo: la carroceria (es la parte que choca)
--   Faro: con SpotLight y la etiqueta LuzDeNoche (DiaNoche.server.lua las prende)
--   LuzFreno: Autos.server.lua la prende al frenar
--   Llanta: la que pinta la tienda de autos (SkinsAutos.lua)
-- Las partes con el atributo "Pintura" son las que pinta la tienda; "ColorBase"
-- guarda el color original de las pintadas y de las llantas.

local CollectionService = game:GetService("CollectionService")

local ModelosAutos = {}

ModelosAutos.NOMBRES = {
	sedan = "Sedán",
	taxi = "Taxi",
	deportivo = "Deportivo",
	camioneta = "Camioneta",
	tractor = "Tractor",
}

local NEGRO = Color3.fromRGB(25, 25, 25)
local GRIS = Color3.fromRGB(60, 60, 65)
local CROMO = Color3.fromRGB(200, 200, 205)
local VIDRIO = Color3.fromRGB(120, 170, 210)
local LUZ_FARO = Color3.fromRGB(255, 250, 215)
local LUZ_FRENO = Color3.fromRGB(120, 0, 0)
local AMARILLO_TAXI = Color3.fromRGB(255, 200, 0)
local AMARILLO_TRACTOR = Color3.fromRGB(250, 190, 20)

local CILINDRO = Enum.PartType.Cylinder
local DE_FRENTE = CFrame.Angles(0, math.pi / 2, 0) -- un cilindro con el eje a lo largo de Z
local PARADO = CFrame.Angles(0, 0, math.pi / 2) -- un cilindro con el eje vertical

-- Herramientas para armar un vehiculo dentro de modelo; color es el de la pintura
local function armador(modelo, color)
	local a = {}

	function a.parte(clase, nombre, tamano, cframe, colorParte, material)
		local p = Instance.new(clase)
		p.Name = nombre
		p.Size = tamano
		p.CFrame = cframe
		p.Color = colorParte
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = modelo
		return p
	end

	function a.bloque(nombre, tamano, posicion, colorParte, material)
		return a.parte("Part", nombre, tamano, CFrame.new(posicion), colorParte, material)
	end

	-- Cilindro: por defecto el eje va a lo largo de X (como una rueda); giro lo cambia
	function a.cilindro(nombre, tamano, posicion, colorParte, material, giro)
		local p = a.parte("Part", nombre, tamano, CFrame.new(posicion) * (giro or CFrame.new()), colorParte, material)
		p.Shape = CILINDRO
		return p
	end

	-- Cuña: la cara inclinada mira hacia adelante (-Z); con haciaAtras, hacia atras (+Z)
	function a.cuna(nombre, tamano, posicion, haciaAtras, colorParte, material)
		local giro = haciaAtras and CFrame.Angles(0, math.pi, 0) or CFrame.new()
		return a.parte("WedgePart", nombre, tamano, CFrame.new(posicion) * giro, colorParte, material)
	end

	-- Marca una parte como pintura del auto (brilla un poco y la pinta la tienda)
	function a.pintar(p)
		p.Color = color
		p.Reflectance = 0.08
		p:SetAttribute("Pintura", true)
		p:SetAttribute("ColorBase", color)
		return p
	end

	function a.pintura(nombre, tamano, posicion)
		return a.pintar(a.bloque(nombre, tamano, posicion, color))
	end

	-- Las rayas de la tienda de autos van arriba de estas partes (SkinsAutos.lua)
	function a.conRayas(p)
		p:SetAttribute("Raya", true)
		return p
	end

	function a.vidrio(tamano, posicion)
		local p = a.bloque("Vidrio", tamano, posicion, VIDRIO, Enum.Material.Glass)
		p.Transparency = 0.35
		return p
	end

	function a.vidrioInclinado(tamano, posicion, haciaAtras)
		local p = a.cuna("Vidrio", tamano, posicion, haciaAtras, VIDRIO, Enum.Material.Glass)
		p.Transparency = 0.35
		return p
	end

	-- Rueda: neumatico, llanta (del lado de afuera) y tapa del centro
	function a.rueda(datos, x, z, radio, ancho, colorLlanta)
		local afuera = x > 0 and 1 or -1
		a.cilindro("Neumatico", Vector3.new(ancho, radio * 2, radio * 2), Vector3.new(x, radio, z), NEGRO)
		local llanta = a.cilindro("Llanta", Vector3.new(0.1, radio * 1.2, radio * 1.2), Vector3.new(x + afuera * ancho / 2, radio, z), colorLlanta or CROMO, Enum.Material.Metal)
		llanta:SetAttribute("ColorBase", llanta.Color)
		a.cilindro("Tapa", Vector3.new(0.14, radio * 0.4, radio * 0.4), Vector3.new(x + afuera * (ancho / 2 + 0.03), radio, z), GRIS)
		table.insert(datos.ruedas, { x, z, radio })
	end

	function a.faro(x, y, z, tamano)
		local faro = a.bloque("Faro", tamano, Vector3.new(x, y, z), LUZ_FARO, Enum.Material.Neon)
		local luz = Instance.new("SpotLight")
		luz.Face = Enum.NormalId.Front
		luz.Range = 30
		luz.Angle = 70
		luz.Brightness = 2
		luz.Color = Color3.fromRGB(255, 245, 210)
		luz.Parent = faro
		CollectionService:AddTag(faro, "LuzDeNoche")
		return faro
	end

	function a.freno(x, y, z, tamano)
		return a.bloque("LuzFreno", tamano, Vector3.new(x, y, z), LUZ_FRENO)
	end

	-- Patente blanca con letras: "BC 123" (de Benja City)
	function a.patente(y, z, numero)
		local patente = a.bloque("Patente", Vector3.new(1.5, 0.45, 0.05), Vector3.new(0, y, z), Color3.new(1, 1, 1))
		local gui = Instance.new("SurfaceGui")
		gui.Face = z > 0 and Enum.NormalId.Back or Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 60
		gui.Parent = patente
		local texto = Instance.new("TextLabel")
		texto.Size = UDim2.fromScale(1, 1)
		texto.BackgroundTransparency = 1
		texto.Font = Enum.Font.GothamBlack
		texto.TextScaled = true
		texto.TextColor3 = Color3.fromRGB(20, 30, 90)
		texto.Text = "BC " .. numero
		texto.Parent = gui
	end

	function a.asiento(x, y, z)
		a.bloque("Asiento", Vector3.new(1.4, 0.4, 1.4), Vector3.new(x, y, z), NEGRO)
		a.bloque("Respaldo", Vector3.new(1.4, 1.3, 0.3), Vector3.new(x, y + 0.85, z + 0.7), NEGRO)
	end

	return a
end

-------------------------------------------------------------------- Sedan

local function sedan(a, numero)
	local datos = {
		largo = 9,
		ancho = 4.6,
		ruedas = {},
		conductor = Vector3.new(-1, 1.4, 0.5),
		acompanante = Vector3.new(1, 1.4, 0.5),
		maxima = 45,
		aceleracion = 22,
	}
	a.conRayas(a.pintura("Cuerpo", Vector3.new(4.6, 1.4, 9), Vector3.new(0, 1.4, 0))) -- de 0.7 a 2.1

	-- Cabina: vidrios con parabrisas y luneta inclinados, techo y parantes
	a.vidrio(Vector3.new(4.2, 1.7, 3.6), Vector3.new(0, 2.95, 0.6))
	a.vidrioInclinado(Vector3.new(4.2, 1.7, 1.4), Vector3.new(0, 2.95, -1.9), false)
	a.vidrioInclinado(Vector3.new(4.2, 1.7, 1.2), Vector3.new(0, 2.95, 3), true)
	a.conRayas(a.pintura("Techo", Vector3.new(4.3, 0.25, 3.7), Vector3.new(0, 3.92, 0.6)))
	for _, x in { -2.1, 2.1 } do
		a.pintura("Parante", Vector3.new(0.12, 1.7, 0.35), Vector3.new(x, 2.95, 0.6))
		a.pintura("Espejo", Vector3.new(0.5, 0.3, 0.35), Vector3.new(x * 1.2, 2.3, -1.3))
		-- Lineas de las puertas y manijas
		for _, z in { -1.2, 0.6, 2.4 } do
			a.bloque("LineaPuerta", Vector3.new(0.04, 1.2, 0.06), Vector3.new(x * 1.1, 1.4, z), GRIS)
		end
		for _, z in { -0.5, 1.3 } do
			a.bloque("Manija", Vector3.new(0.06, 0.12, 0.45), Vector3.new(x * 1.115, 1.8, z), CROMO, Enum.Material.Metal)
		end
	end
	a.asiento(-1, 1.5, 0.3)
	a.asiento(1, 1.5, 0.3)

	-- Frente y cola
	for _, z in { -4.6, 4.6 } do
		a.bloque("Paragolpes", Vector3.new(4.7, 0.5, 0.4), Vector3.new(0, 0.95, z), GRIS)
	end
	a.bloque("Parrilla", Vector3.new(2, 0.5, 0.1), Vector3.new(0, 1.6, -4.55), NEGRO)
	for _, x in { -1.55, 1.55 } do
		a.faro(x, 1.65, -4.55, Vector3.new(1.1, 0.45, 0.15))
		a.freno(x, 1.65, 4.55, Vector3.new(1.1, 0.45, 0.15))
	end
	a.patente(0.95, -4.83, numero)
	a.patente(0.95, 4.83, numero)

	for _, x in { -2, 2 } do
		for _, z in { -3, 3 } do
			a.rueda(datos, x, z, 0.85, 0.7)
		end
	end
	return datos
end

-- Taxi: un sedan amarillo con cartel en el techo y una franja a cuadros
local function taxi(a, numero)
	local datos = sedan(a, numero)
	local cartel = a.bloque("CartelTaxi", Vector3.new(1.8, 0.55, 0.7), Vector3.new(0, 4.32, 0.6), Color3.new(1, 1, 1), Enum.Material.Neon)
	for _, cara in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = cara
		gui.Parent = cartel
		local texto = Instance.new("TextLabel")
		texto.Size = UDim2.fromScale(1, 1)
		texto.BackgroundTransparency = 1
		texto.Font = Enum.Font.GothamBlack
		texto.TextScaled = true
		texto.TextColor3 = NEGRO
		texto.Text = "TAXI"
		texto.Parent = gui
	end
	-- Franja a cuadros (dos filas, cuadrito negro por medio) a los costados
	for _, x in { -2.32, 2.32 } do
		for i = 0, 11 do
			for fila = 0, 1 do
				if (i + fila) % 2 == 0 then
					a.bloque("Cuadro", Vector3.new(0.04, 0.3, 0.7), Vector3.new(x, 1.6 + fila * 0.3, -4.1 + i * 0.75), NEGRO)
				end
			end
		end
	end
	return datos
end

-------------------------------------------------------------------- Deportivo

local function deportivo(a, numero)
	local datos = {
		largo = 9.4,
		ancho = 4.8,
		ruedas = {},
		conductor = Vector3.new(-1, 1.1, 0.8),
		acompanante = Vector3.new(1, 1.1, 0.8),
		maxima = 52,
		aceleracion = 30,
	}
	a.pintura("Cuerpo", Vector3.new(4.8, 1, 9.4), Vector3.new(0, 1.1, 0)) -- de 0.6 a 1.6

	-- Capot que baja hacia la trompa, costados del habitaculo y cola que baja
	a.conRayas(a.pintar(a.cuna("Capot", Vector3.new(4.8, 0.45, 3.4), Vector3.new(0, 1.825, -2.9), false, Color3.new())))
	for _, x in { -2.25, 2.25 } do
		a.pintura("Lateral", Vector3.new(0.3, 0.45, 5), Vector3.new(x, 1.825, 1.3))
		a.bloque("Toma", Vector3.new(0.06, 0.35, 1.4), Vector3.new(x * 1.07, 1.15, 1.6), NEGRO)
		a.pintura("Espejo", Vector3.new(0.45, 0.28, 0.35), Vector3.new(x * 1.12, 2.25, -0.8))
	end
	a.conRayas(a.pintura("Tapa", Vector3.new(4.2, 0.45, 1.5), Vector3.new(0, 1.825, 3)))
	a.conRayas(a.pintar(a.cuna("Cola", Vector3.new(4.8, 0.45, 0.9), Vector3.new(0, 1.825, 4.2), true, Color3.new())))

	-- Habitaculo abierto: parabrisas bajito, asientos, volante y arco de seguridad
	a.vidrioInclinado(Vector3.new(4.2, 0.9, 0.8), Vector3.new(0, 2.5, -1), false)
	a.asiento(-1, 1.6, 0.6)
	a.asiento(1, 1.6, 0.6)
	a.cilindro("Volante", Vector3.new(0.15, 0.75, 0.75), Vector3.new(-1, 2.35, -0.3), NEGRO, nil, DE_FRENTE)
	for _, x in { -1.6, 1.6 } do
		a.bloque("Arco", Vector3.new(0.2, 1.1, 0.2), Vector3.new(x, 2.6, 2.1), CROMO, Enum.Material.Metal)
	end
	a.bloque("Arco", Vector3.new(3.4, 0.2, 0.2), Vector3.new(0, 3.1, 2.1), CROMO, Enum.Material.Metal)

	-- Faros finitos, luces de freno, difusor y dos escapes
	for _, x in { -1.6, 1.6 } do
		a.faro(x, 1.5, -4.72, Vector3.new(1.3, 0.25, 0.15))
		a.freno(x, 1.4, 4.72, Vector3.new(1.4, 0.3, 0.15))
		a.cilindro("Escape", Vector3.new(0.35, 0.35, 0.35), Vector3.new(x * 0.4, 0.8, 4.75), CROMO, Enum.Material.Metal, DE_FRENTE)
	end
	a.bloque("Difusor", Vector3.new(3, 0.3, 0.3), Vector3.new(0, 0.75, 4.6), NEGRO)
	a.bloque("Labio", Vector3.new(4.9, 0.15, 0.6), Vector3.new(0, 0.62, -4.5), NEGRO)
	a.patente(1.05, 4.73, numero)

	for _, x in { -2.05, 2.05 } do
		for _, z in { -3.1, 3.1 } do
			a.rueda(datos, x, z, 0.8, 0.9)
		end
	end
	return datos
end

-------------------------------------------------------------------- Camioneta

local function camioneta(a, numero)
	local datos = {
		largo = 10.4,
		ancho = 5,
		ruedas = {},
		conductor = Vector3.new(-1.1, 1.7, -0.9),
		acompanante = Vector3.new(1.1, 1.7, -0.9),
		maxima = 42,
		aceleracion = 20,
	}
	a.conRayas(a.pintura("Cuerpo", Vector3.new(5, 1.7, 10), Vector3.new(0, 1.95, 0))) -- de 1.1 a 2.8

	-- Cabina adelante
	a.vidrio(Vector3.new(4.6, 1.8, 3), Vector3.new(0, 3.7, -1))
	a.vidrioInclinado(Vector3.new(4.6, 1.8, 1), Vector3.new(0, 3.7, -3), false)
	a.conRayas(a.pintura("Techo", Vector3.new(4.8, 0.25, 4), Vector3.new(0, 4.72, -1.3)))
	a.pintura("Cabina", Vector3.new(4.8, 1.8, 0.3), Vector3.new(0, 3.7, 0.65))
	for _, x in { -2.36, 2.36 } do
		a.pintura("Parante", Vector3.new(0.12, 1.8, 0.35), Vector3.new(x, 3.7, -0.9))
		a.pintura("Espejo", Vector3.new(0.6, 0.4, 0.35), Vector3.new(x * 1.12, 3.3, -2.3))
		a.bloque("Estribo", Vector3.new(0.5, 0.2, 4), Vector3.new(x * 1.14, 1, -0.4), NEGRO)
		a.bloque("Manija", Vector3.new(0.06, 0.15, 0.5), Vector3.new(x * 1.065, 2.5, -1.2), CROMO, Enum.Material.Metal)
	end
	a.asiento(-1.1, 2.2, -1.2)
	a.asiento(1.1, 2.2, -1.2)

	-- Caja de carga atras
	for _, x in { -2.35, 2.35 } do
		a.pintura("Caja", Vector3.new(0.3, 1, 4.2), Vector3.new(x, 3.3, 2.9))
	end
	a.pintura("Compuerta", Vector3.new(5, 1, 0.3), Vector3.new(0, 3.3, 4.85))
	a.bloque("PisoCaja", Vector3.new(4.4, 0.05, 4), Vector3.new(0, 2.83, 2.9), GRIS)

	-- Frente cromado, faros grandes y luces de freno paradas
	for _, z in { -5.15, 5.15 } do
		a.bloque("Paragolpes", Vector3.new(5.1, 0.6, 0.5), Vector3.new(0, 1.3, z), CROMO, Enum.Material.Metal)
	end
	a.bloque("Parrilla", Vector3.new(3.4, 0.9, 0.1), Vector3.new(0, 2.2, -5.03), CROMO, Enum.Material.Metal)
	for _, y in { 2, 2.4 } do
		a.bloque("Barra", Vector3.new(3.2, 0.12, 0.12), Vector3.new(0, y, -5.07), NEGRO)
	end
	for _, x in { -2, 2 } do
		a.faro(x, 2.3, -5.03, Vector3.new(1, 0.6, 0.15))
		a.freno(x * 1.1, 2.3, 5.03, Vector3.new(0.4, 0.9, 0.15))
	end
	a.patente(1.3, -5.43, numero)
	a.patente(1.3, 5.43, numero)

	for _, x in { -2.05, 2.05 } do
		for _, z in { -3.3, 3.4 } do
			a.rueda(datos, x, z, 1.1, 0.9)
		end
	end
	return datos
end

-------------------------------------------------------------------- Tractor

local function tractor(a)
	local datos = {
		largo = 8,
		ancho = 5,
		ruedas = {},
		conductor = Vector3.new(0, 2.6, 1.8),
		acompanante = nil, -- en el tractor va uno solo
		maxima = 24,
		aceleracion = 12,
	}
	a.bloque("Viga", Vector3.new(1.8, 0.7, 6.2), Vector3.new(0, 1.35, -0.6), GRIS)
	a.conRayas(a.pintura("Cuerpo", Vector3.new(2.6, 1.7, 4.4), Vector3.new(0, 2.55, -1.9))) -- el capot del motor
	a.bloque("Parrilla", Vector3.new(2.3, 1.3, 0.1), Vector3.new(0, 2.5, -4.13), NEGRO)
	for _, x in { -0.85, 0.85 } do
		a.faro(x, 3.05, -4.14, Vector3.new(0.5, 0.4, 0.15))
	end
	-- Caño de escape parado arriba del motor
	a.cilindro("Escape", Vector3.new(2.2, 0.35, 0.35), Vector3.new(0.8, 4.4, -3.2), NEGRO, nil, PARADO)
	a.cilindro("PuntaEscape", Vector3.new(0.3, 0.45, 0.45), Vector3.new(0.8, 5.55, -3.2), GRIS, nil, PARADO)

	-- Cabina abierta con techito: piso, asiento, volante y cuatro postes
	a.bloque("Piso", Vector3.new(3.2, 0.3, 2.8), Vector3.new(0, 2.15, 1.7), GRIS)
	a.asiento(0, 2.5, 1.7)
	a.bloque("Columna", Vector3.new(0.15, 0.9, 0.15), Vector3.new(0, 2.75, 0.7), NEGRO)
	a.cilindro("Volante", Vector3.new(0.15, 0.8, 0.8), Vector3.new(0, 3.25, 0.75), NEGRO, nil, DE_FRENTE)
	for _, x in { -1.4, 1.4 } do
		for _, z in { 0.45, 3 } do
			a.bloque("Poste", Vector3.new(0.2, 3, 0.2), Vector3.new(x, 3.8, z), NEGRO)
		end
	end
	a.conRayas(a.pintura("Techo", Vector3.new(3.2, 0.25, 3), Vector3.new(0, 5.42, 1.72)))

	-- Guardabarros de las ruedas grandes, luces atras y el enganche
	for _, x in { -2.05, 2.05 } do
		a.pintura("Guardabarros", Vector3.new(1.4, 0.25, 3.4), Vector3.new(x, 4, 2))
		a.freno(x, 3.75, 3.72, Vector3.new(0.4, 0.3, 0.15))
	end
	a.bloque("Enganche", Vector3.new(0.6, 0.4, 0.8), Vector3.new(0, 1.3, 3.4), GRIS)

	-- Ruedas grandes atras y chicas adelante, con llantas amarillas
	for _, x in { -2, 2 } do
		a.rueda(datos, x, 2, 1.9, 1.2, AMARILLO_TRACTOR)
	end
	for _, x in { -1.55, 1.55 } do
		a.rueda(datos, x, -3, 0.95, 0.7, AMARILLO_TRACTOR)
	end
	return datos
end

local CONSTRUCTORES = {
	sedan = sedan,
	taxi = taxi,
	deportivo = deportivo,
	camioneta = camioneta,
	tractor = tractor,
}

function ModelosAutos.crear(tipo, color)
	if tipo == "taxi" then
		color = AMARILLO_TAXI
	end
	local modelo = Instance.new("Model")
	modelo.Name = "Auto"
	local a = armador(modelo, color)
	local datos = CONSTRUCTORES[tipo](a, math.random(100, 999))
	datos.tipo = tipo
	datos.nombre = ModelosAutos.NOMBRES[tipo]
	modelo.WorldPivot = CFrame.new()
	return modelo, datos
end

return ModelosAutos
