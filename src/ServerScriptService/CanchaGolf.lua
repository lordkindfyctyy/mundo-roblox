-- Construye la cancha de golf al sur de la ciudad: terreno, los hoyos (tee, calle con franjas,
-- fringe, green, bandera, bunkers, lagos, monticulos, arboles y tuneles), la caseta donde se
-- empieza, la tienda y el arco de entrada. Golf.server.lua llama a CanchaGolf.construir() y la maneja.
-- Cada parte donde puede quedar la pelota tiene el atributo "Superficie"
-- (Rough, Fairway, Tee, Green, Bunker o Agua); ConfigGolf dice como se porta cada una.
--
-- Alturas (de abajo hacia arriba, para que no se encimen): el pasto de fondo llega a
-- SUELO, la calle un poco mas arriba, y asi el bunker, el agua, el green y el tee.
--
-- Los monticulos y los tuneles se arman con placas inclinadas (un cuadro de roblox no tiene
-- lomas): la pelota las recorre como cualquier piso, y la superficie sale del atributo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))
local ConfigGolf = require(ReplicatedStorage:WaitForChild("ConfigGolf"))

local CanchaGolf = {}

local G = Plano.GOLF
local LIMITE = Plano.LIMITE
local SUELO = G.SUELO
local ALTO_CALLE = SUELO + 0.04
local ALTO_ARENA = SUELO + 0.06
local ALTO_AGUA = SUELO + 0.08
local ALTO_GREEN = SUELO + 0.1
local ALTO_TEE = SUELO + 0.12
local ANCHO_CALLE = 26
local LARGO_FRANJA = 10 -- las franjas del corte de pasto en la calle

local COLOR_ROUGH = Color3.fromRGB(62, 128, 56)
local COLOR_CALLE = Color3.fromRGB(105, 182, 84)
local COLOR_CALLE_OSCURA = Color3.fromRGB(92, 166, 74)
local COLOR_FRINGE = Color3.fromRGB(112, 202, 92)
local COLOR_GREEN = Color3.fromRGB(125, 218, 100)
local COLOR_ARENA = Color3.fromRGB(236, 216, 152)
local COLOR_AGUA = Color3.fromRGB(45, 125, 225)
local COLOR_BARRO = Color3.fromRGB(105, 82, 55)
local COLOR_ROCA = Color3.fromRGB(125, 122, 116)
local MADERA = Color3.fromRGB(120, 85, 55)

function CanchaGolf.construir()
	local golf = Instance.new("Folder")
	golf.Name = "Golf"
	golf.Parent = Workspace

	-- Aca viven las pelotas de los jugadores (las crea Golf.server.lua)
	local bolas = Instance.new("Folder")
	bolas.Name = "Bolas"
	bolas.Parent = golf

	local azar = Random.new(G.SEMILLA)

	-- soloVista: adorno que no choca ni se detecta (la pelota lo atraviesa)
	local function parte(nombre, tamano, cframe, color, material, forma, colisiona, soloVista)
		local p = Instance.new("Part")
		p.Name = nombre
		p.Size = tamano
		p.CFrame = cframe
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Shape = forma or Enum.PartType.Block
		p.Anchored = true
		p.CanCollide = colisiona ~= false and not soloVista
		if soloVista then
			p.CanQuery = false
			p.CanTouch = false
		end
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = golf
		return p
	end

	-- Disco plano (cilindro parado) cuya cara de arriba queda en la altura "alto"
	local function disco(nombre, x, z, radio, alto, grosor, color, material, superficie, colisiona)
		local p = parte(
			nombre,
			Vector3.new(grosor, radio * 2, radio * 2),
			CFrame.new(x, alto - grosor / 2, z) * CFrame.Angles(0, 0, math.rad(90)),
			color,
			material,
			Enum.PartType.Cylinder,
			colisiona
		)
		if superficie then
			p:SetAttribute("Superficie", superficie)
		end
		return p
	end

	-- Placa de madera con texto en las dos caras
	local function cartel(cframe, ancho, alto, texto, color)
		local tabla = parte("Cartel", Vector3.new(ancho, alto, 0.4), cframe, color, Enum.Material.Wood)
		for _, cara in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local gui = Instance.new("SurfaceGui")
			gui.Face = cara
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 30
			gui.Parent = tabla
			local etiqueta = Instance.new("TextLabel")
			etiqueta.Size = UDim2.fromScale(1, 1)
			etiqueta.BackgroundTransparency = 1
			etiqueta.Font = Enum.Font.GothamBlack
			etiqueta.TextScaled = true
			etiqueta.TextColor3 = Color3.new(1, 1, 1)
			etiqueta.Text = texto
			etiqueta.Parent = gui
		end
		return tabla
	end

	-- Adornos ---------------------------------------------------------------------

	local function variar(color, cantidad)
		local d = azar:NextNumber(-cantidad, cantidad)
		return Color3.new(
			math.clamp(color.R + d, 0, 1),
			math.clamp(color.G + d, 0, 1),
			math.clamp(color.B + d, 0, 1)
		)
	end

	-- El tronco choca (la pelota rebota); las hojas son solo para mirar
	-- grande: los de la calle, mas anchos y altos
	local function arbol(x, z, grande)
		local alto = grande and azar:NextNumber(9, 12) or azar:NextNumber(7, 11)
		local grosor = grande and 2 or 1.6
		parte(
			"Tronco",
			Vector3.new(alto, grosor, grosor),
			CFrame.new(x, SUELO + alto / 2, z) * CFrame.Angles(0, 0, math.rad(90)),
			variar(Color3.fromRGB(105, 72, 44), 0.05),
			Enum.Material.Wood,
			Enum.PartType.Cylinder
		)
		if azar:NextNumber() < 0.35 then
			-- Pino: tres bolas apiladas, cada vez mas chicas
			local verde = variar(Color3.fromRGB(30, 100, 52), 0.05)
			for i, tamano in { 11, 8.5, 6 } do
				parte(
					"Hojas",
					Vector3.new(tamano, tamano * 0.9, tamano),
					CFrame.new(x, SUELO + alto * 0.55 + (i - 1) * 3.4, z),
					verde,
					Enum.Material.Grass,
					Enum.PartType.Ball,
					false,
					true
				)
			end
		else
			local copa = (grande and 1.15 or 1) * azar:NextNumber(8, 11)
			local verde = variar(Color3.fromRGB(46, 128, 52), 0.06)
			parte("Hojas", Vector3.one * copa, CFrame.new(x, SUELO + alto + copa / 3, z), verde, Enum.Material.Grass, Enum.PartType.Ball, false, true)
			parte(
				"Hojas",
				Vector3.one * copa * 0.65,
				CFrame.new(x + copa * 0.28, SUELO + alto + copa / 3 + copa * 0.2, z - copa * 0.2),
				variar(verde, 0.04),
				Enum.Material.Grass,
				Enum.PartType.Ball,
				false,
				true
			)
		end
	end

	local function arbusto(x, z)
		local verde = variar(Color3.fromRGB(38, 112, 46), 0.05)
		for _ = 1, 3 do
			local t = azar:NextNumber(2.2, 3.6)
			parte(
				"Arbusto",
				Vector3.new(t, t * 0.8, t),
				CFrame.new(x + azar:NextNumber(-1.2, 1.2), SUELO + t * 0.35, z + azar:NextNumber(-1.2, 1.2)),
				variar(verde, 0.04),
				Enum.Material.Grass,
				Enum.PartType.Ball,
				false,
				true
			)
		end
	end

	local function flores(x, z, cantidad)
		local colores = {
			Color3.fromRGB(255, 90, 120),
			Color3.fromRGB(255, 210, 60),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(190, 110, 255),
		}
		for _ = 1, cantidad do
			parte(
				"Flor",
				Vector3.one * 0.55,
				CFrame.new(x + azar:NextNumber(-3, 3), SUELO + 0.3, z + azar:NextNumber(-2, 2)),
				colores[azar:NextInteger(1, #colores)],
				Enum.Material.SmoothPlastic,
				Enum.PartType.Ball,
				false,
				true
			)
		end
	end

	local function roca(x, z)
		local t = azar:NextNumber(1.6, 3.2)
		parte(
			"Roca",
			Vector3.new(t, t * 0.6, t * azar:NextNumber(0.8, 1.2)),
			CFrame.new(x, SUELO + t * 0.2, z) * CFrame.Angles(0, azar:NextNumber(0, 6.28), 0),
			variar(COLOR_ROCA, 0.08),
			Enum.Material.Slate,
			Enum.PartType.Ball,
			false,
			true
		)
	end

	local function banco(x, z)
		parte("Banco", Vector3.new(1.8, 0.4, 5), CFrame.new(x, SUELO + 1.3, z), MADERA, Enum.Material.Wood)
		parte("Banco", Vector3.new(0.4, 1.6, 5), CFrame.new(x + 0.9, SUELO + 2.1, z), MADERA, Enum.Material.Wood)
		for _, dz in { -2, 2 } do
			parte("Banco", Vector3.new(0.4, 1.2, 0.4), CFrame.new(x, SUELO + 0.6, z + dz), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
		end
	end

	-- Una placa inclinada que va de p1 (abajo, afuera) a p2 (arriba, adentro); su cara de
	-- arriba pasa justo por esa recta. Es la pieza con la que se arman lomas y colinas.
	local function placa(p1, p2, ancho, grosor, color, material, superficie, jugable)
		local medio = (p1 + p2) / 2
		local largo = (p1 - p2).Magnitude + 0.5
		local cframe = CFrame.lookAt(medio, medio + (p1 - p2)) * CFrame.new(0, -grosor / 2, 0)
		local p = parte("Placa", Vector3.new(ancho, grosor, largo), cframe, color, material, nil, jugable, not jugable)
		if jugable then
			p:SetAttribute("Superficie", superficie)
		end
		return p
	end

	-- Loma redonda de dos tramos (suave abajo, mas empinada arriba) con la cima plana.
	-- jugable = false: solo adorno de fondo
	local function monticulo(x, z, radio, alto, jugable)
		local centro = Vector3.new(x, SUELO + 0.04, z)
		local lados = radio >= 11 and 20 or 16
		local color = variar(Color3.fromRGB(78, 150, 66), 0.05)
		-- Una pelota que queda en una loma se juega como desde el rough
		local superficie = "Rough"
		local tramos = {
			{ r1 = radio, h1 = 0, r2 = radio * 0.6, h2 = alto * 0.4 },
			{ r1 = radio * 0.6, h1 = alto * 0.4, r2 = radio * 0.28, h2 = alto },
		}
		for _, tramo in tramos do
			local ancho = 2 * tramo.r1 * math.tan(math.pi / lados) * 1.25
			for i = 0, lados - 1 do
				local angulo = i / lados * math.pi * 2
				local direccion = Vector3.new(math.sin(angulo), 0, math.cos(angulo))
				local p1 = centro + direccion * tramo.r1 + Vector3.new(0, tramo.h1, 0)
				local p2 = centro + direccion * tramo.r2 + Vector3.new(0, tramo.h2, 0)
				placa(p1, p2, ancho, 0.8, color, Enum.Material.Grass, superficie, jugable)
			end
		end
		local cima = disco("Cima", x, z, radio * 0.28 + 0.4, SUELO + 0.04 + alto, 0.6, color, Enum.Material.Grass, jugable and superficie or nil, jugable)
		if not jugable then
			cima.CanQuery = false
			cima.CanTouch = false
		end
	end

	-- Colina de roca con un paso en el medio. La pelota la cruza por el tunel (mas bien
	-- apuntado), la pasa volando por arriba o la rodea por el rough de los costados.
	local function tunel(x, z, ancho)
		local profundidad, alto, abertura, altoAbertura = 16, 11, 8.5, 6.5
		local lado = (ancho - abertura) / 2
		local pasto = variar(Color3.fromRGB(70, 140, 60), 0.04)

		for _, signo in { -1, 1 } do
			local muro = parte(
				"TunelMuro",
				Vector3.new(lado, alto, profundidad),
				CFrame.new(x + signo * (abertura / 2 + lado / 2), SUELO + alto / 2, z),
				COLOR_ROCA,
				Enum.Material.Slate
			)
			muro:SetAttribute("Superficie", "Rough")
		end
		local techo = parte(
			"TunelTecho",
			Vector3.new(abertura, alto - altoAbertura, profundidad),
			CFrame.new(x, SUELO + altoAbertura + (alto - altoAbertura) / 2, z),
			COLOR_ROCA,
			Enum.Material.Slate
		)
		techo:SetAttribute("Superficie", "Rough")

		-- Arriba, pasto; si la pelota cae ahi se juega desde ahi
		local cima = parte(
			"TunelCima",
			Vector3.new(ancho + 2, 1, profundidad + 2),
			CFrame.new(x, SUELO + alto + 0.5, z),
			pasto,
			Enum.Material.Grass
		)
		cima:SetAttribute("Superficie", "Rough")

		-- Rampas de pasto en las dos puntas, para que parezca una colina (y se pueda subir)
		for _, signo in { -1, 1 } do
			local arriba = Vector3.new(x + signo * (ancho / 2 + 1), SUELO + alto + 1, z)
			local abajo = Vector3.new(x + signo * (ancho / 2 + 17), SUELO + 0.04, z)
			placa(abajo, arriba, profundidad + 2, 1, pasto, Enum.Material.Grass, "Rough", true)
		end

		-- Una luz adentro y un cartel arriba de cada boca
		local luz = parte("TunelLuz", Vector3.one * 0.5, CFrame.new(x, SUELO + altoAbertura - 0.6, z), Color3.new(1, 1, 1), nil, nil, false, true)
		luz.Transparency = 1
		local foco = Instance.new("PointLight")
		foco.Color = Color3.fromRGB(255, 220, 160)
		foco.Brightness = 1.5
		foco.Range = 14
		foco.Parent = luz
		for _, signo in { -1, 1 } do
			cartel(
				CFrame.new(x, SUELO + altoAbertura + 2, z + signo * (profundidad / 2 + 0.25)),
				7,
				2.2,
				"🕳️ TÚNEL",
				Color3.fromRGB(35, 80, 140)
			)
		end
	end

	-- Terreno ---------------------------------------------------------------------

	local largoZ = G.Z_CERCA - G.Z_LEJOS
	local centroZ = (G.Z_CERCA + G.Z_LEJOS) / 2
	local suelo = parte("Suelo", Vector3.new(G.X * 2, 4, largoZ), CFrame.new(0, SUELO - 2, centroZ), COLOR_ROUGH, Enum.Material.Grass)
	suelo:SetAttribute("Superficie", "Rough")

	-- Manchas de pasto un poco mas claro u oscuro, para que el rough no sea una sola pared verde
	for _ = 1, 70 do
		disco(
			"Mancha",
			azar:NextNumber(-G.X + 10, G.X - 10),
			azar:NextNumber(G.Z_LEJOS + 10, G.TEE_Z + 10),
			azar:NextNumber(6, 16),
			SUELO + 0.02,
			0.1,
			variar(COLOR_ROUGH, 0.05),
			Enum.Material.Grass,
			"Rough",
			false
		)
	end

	-- Paredes invisibles alrededor (el frente lo cierra la pared de la ciudad, con su puerta)
	local function pared(x, z, ancho, fondo)
		local p = parte("Limite", Vector3.new(ancho, 60, fondo), CFrame.new(x, 30, z), Color3.new(1, 1, 1))
		p.Transparency = 1
	end
	pared(-G.X - 1, centroZ, 2, largoZ)
	pared(G.X + 1, centroZ, 2, largoZ)
	pared(0, G.Z_LEJOS - 1, G.X * 2 + 4, 2)

	-- Arboles: en los costados de la cancha, entre los hoyos y al fondo (nunca sobre las calles)
	local hoyosCfg = ConfigGolf.Hoyos
	local columnas = { -(G.X - 6), G.X - 6 }
	for i = 1, #hoyosCfg - 1 do
		local entre = (hoyosCfg[i].x + hoyosCfg[i + 1].x) / 2
		if math.abs(entre) > 20 then -- en el medio, detras de la caseta, no
			table.insert(columnas, entre)
		end
	end
	for _, x in columnas do
		local z = G.TEE_Z + 8
		while z > G.Z_LEJOS + 8 do
			arbol(x + azar:NextNumber(-4, 4), z + azar:NextNumber(-3, 3))
			z -= azar:NextNumber(20, 28)
		end
	end
	for x = -(G.X - 14), G.X - 14, 24 do
		arbol(x + azar:NextNumber(-3, 3), G.Z_LEJOS + 7)
	end

	-- Colinas de fondo a los costados (solo para mirar)
	for _, lado in { -1, 1 } do
		for _, dato in { { -240, 14, 7 }, { -320, 16, 9 }, { -400, 14, 7 } } do
			monticulo(lado * (G.X - 12), dato[1], dato[2], dato[3], false)
		end
	end

	-- Los hoyos -------------------------------------------------------------------

	local hoyos = {}

	for _, cfg in hoyosCfg do
		local x = cfg.x
		local zTee = G.TEE_Z
		local zCopa = zTee - cfg.largo

		-- Calle: del tee a un poco antes del green, con franjas claras y oscuras como si la
		-- hubieran cortado con la cortadora
		local zInicio = zTee - 8
		local zFin = zCopa + 6
		local franja = 0
		local z = zInicio
		while z > zFin do
			local largo = math.min(LARGO_FRANJA, z - zFin)
			local pedazo = parte(
				"Calle",
				Vector3.new(ANCHO_CALLE, 1, largo + 0.02),
				CFrame.new(x, ALTO_CALLE - 0.5, z - largo / 2),
				franja % 2 == 0 and COLOR_CALLE or COLOR_CALLE_OSCURA,
				Enum.Material.Grass
			)
			pedazo:SetAttribute("Superficie", "Fairway")
			z -= LARGO_FRANJA
			franja += 1
		end

		-- Camino de carritos al costado, del tee al green
		local camino = parte(
			"CaminoCarritos",
			Vector3.new(3, 0.2, cfg.largo + 6),
			CFrame.new(x - 26, SUELO + 0.05 - 0.1, zTee - cfg.largo / 2 + 3),
			Color3.fromRGB(165, 158, 145),
			Enum.Material.Concrete
		)
		camino:SetAttribute("Superficie", "Otro")

		-- Tee
		local tee = parte("Tee", Vector3.new(10, 1, 14), CFrame.new(x, ALTO_TEE - 0.5, zTee), COLOR_CALLE, Enum.Material.Grass)
		tee:SetAttribute("Superficie", "Tee")
		for _, lado in { -1, 1 } do
			parte(
				"Marca",
				Vector3.one * 0.9,
				CFrame.new(x + lado * 4.5, ALTO_TEE + 0.45, zTee + 5),
				lado < 0 and Color3.fromRGB(240, 60, 60) or Color3.fromRGB(245, 245, 245),
				Enum.Material.SmoothPlastic,
				Enum.PartType.Ball,
				false
			)
		end
		banco(x + 9, zTee + 2)
		arbusto(x - 7, zTee + 10)
		arbusto(x + 7, zTee + 11)
		flores(x + 12, zTee + 8, 8)

		-- Bunkers (con un borde de pasto) y lagos (con barro al fondo y rocas en la orilla);
		-- van antes del green para que el green los tape si se superponen
		for _, b in cfg.bunkers do
			disco("BordeBunker", x + b.dx, zTee - b.avance, b.radio + 0.9, ALTO_ARENA - 0.01, 1, COLOR_FRINGE, Enum.Material.Grass, "Rough")
			disco("Bunker", x + b.dx, zTee - b.avance, b.radio, ALTO_ARENA, 1, COLOR_ARENA, Enum.Material.Sand, "Bunker")
		end
		for _, l in cfg.lagos do
			local lx, lz = x + l.dx, zTee - l.avance
			disco("Orilla", lx, lz, l.radio + 2, ALTO_ARENA + 0.005, 1, COLOR_BARRO, Enum.Material.Ground, "Rough")
			-- El agua no es solida: la pelota la cruza y Golf.server.lua la detecta por la superficie
			local agua = disco("Lago", lx, lz, l.radio, ALTO_AGUA, 1, COLOR_AGUA, Enum.Material.Glass, "Agua", false)
			agua.Transparency = 0.3
			agua.Reflectance = 0.15
			for _ = 1, 7 do
				local angulo = azar:NextNumber(0, math.pi * 2)
				local distancia = l.radio + azar:NextNumber(1.2, 3)
				roca(lx + math.cos(angulo) * distancia, lz + math.sin(angulo) * distancia)
			end
		end

		-- Green (con su fringe, un anillo de pasto mas corto), hoyo y bandera con el numero
		disco("Fringe", x, zCopa, cfg.radioGreen + 2.6, ALTO_GREEN - 0.01, 1, COLOR_FRINGE, Enum.Material.Grass, "Fairway")
		disco("Green", x, zCopa, cfg.radioGreen, ALTO_GREEN, 1, COLOR_GREEN, Enum.Material.Grass, "Green")
		disco("Hoyo", x, zCopa, 1.15, ALTO_GREEN + 0.03, 0.06, Color3.fromRGB(15, 15, 15), Enum.Material.SmoothPlastic, "Green", false)

		local alturaPalo = 10
		parte(
			"Palo",
			Vector3.new(alturaPalo, 0.35, 0.35),
			CFrame.new(x, ALTO_GREEN + alturaPalo / 2, zCopa) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(245, 245, 245),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Cylinder,
			false
		)
		parte("PuntaPalo", Vector3.one * 0.6, CFrame.new(x, ALTO_GREEN + alturaPalo + 0.2, zCopa), Color3.fromRGB(255, 200, 40), Enum.Material.Metal, Enum.PartType.Ball, false)
		local bandera = parte(
			"Bandera",
			Vector3.new(3.4, 2, 0.1),
			CFrame.new(x + 1.9, ALTO_GREEN + alturaPalo - 1.2, zCopa),
			Color3.fromRGB(235, 50, 50),
			Enum.Material.SmoothPlastic,
			nil,
			false
		)
		for _, cara in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local gui = Instance.new("SurfaceGui")
			gui.Face = cara
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 30
			gui.Parent = bandera
			local numero = Instance.new("TextLabel")
			numero.Size = UDim2.fromScale(1, 1)
			numero.BackgroundTransparency = 1
			numero.Font = Enum.Font.GothamBlack
			numero.TextScaled = true
			numero.TextColor3 = Color3.new(1, 1, 1)
			numero.Text = tostring(cfg.numero)
			numero.Parent = gui
		end
		arbusto(x - cfg.radioGreen - 6, zCopa - 6)
		arbusto(x + cfg.radioGreen + 6, zCopa + 4)
		flores(x + cfg.radioGreen + 5, zCopa + 10, 6)

		-- Monticulos, arboles en la calle y tunel (la dificultad del hoyo)
		for _, m in cfg.monticulos or {} do
			monticulo(x + m.dx, zTee - m.avance, m.radio, m.alto, true)
		end
		for _, a in cfg.arboles or {} do
			arbol(x + a.dx, zTee - a.avance, true)
		end
		if cfg.tunel then
			tunel(x, zTee - cfg.tunel.avance, cfg.tunel.ancho)
		end

		-- Postes de distancia a la bandera, al borde izquierdo de la calle: 150 azul, 100 blanco, 50 rojo
		for _, marca in {
			{ 150, Color3.fromRGB(60, 120, 230) },
			{ 100, Color3.fromRGB(245, 245, 245) },
			{ 50, Color3.fromRGB(230, 60, 60) },
		} do
			if cfg.largo - marca[1] > 20 then
				parte(
					"MarcaDistancia",
					Vector3.new(0.5, 1.8, 0.5),
					CFrame.new(x - ANCHO_CALLE / 2 - 0.6, SUELO + 0.9, zCopa + marca[1]),
					marca[2],
					Enum.Material.SmoothPlastic,
					nil,
					false,
					true
				)
			end
		end

		-- Cartel junto al tee con el numero, el par y la distancia
		cartel(
			CFrame.new(x - 9, SUELO + 3, zTee + 2) * CFrame.Angles(0, math.rad(-90), 0),
			9,
			3.4,
			string.format("HOYO %d · PAR %d · %d m", cfg.numero, cfg.par, cfg.largo),
			Color3.fromRGB(30, 100, 60)
		)
		parte("Poste", Vector3.new(0.5, 3.4, 0.5), CFrame.new(x - 9, SUELO + 1.7, zTee + 5.5), MADERA, Enum.Material.Wood)
		parte("Poste", Vector3.new(0.5, 3.4, 0.5), CFrame.new(x - 9, SUELO + 1.7, zTee - 1.5), MADERA, Enum.Material.Wood)

		table.insert(hoyos, {
			numero = cfg.numero,
			par = cfg.par,
			tee = Vector3.new(x, ALTO_TEE, zTee),
			copa = Vector3.new(x, ALTO_GREEN, zCopa),
		})
	end

	-- Entrada: un arco con cartel y un caminito hasta la caseta -------------------------

	parte("Camino", Vector3.new(8, 1, 12), CFrame.new(0, ALTO_CALLE - 0.5, -LIMITE - 7), Color3.fromRGB(170, 160, 140), Enum.Material.Slate)
	for _, lado in { -1, 1 } do
		parte(
			"Columna",
			Vector3.new(2.5, 16, 2.5),
			CFrame.new(lado * (G.PUERTA + 1.25), 8, -LIMITE - 1),
			Color3.fromRGB(235, 235, 225),
			Enum.Material.Concrete
		)
		-- canteros con flores a los lados del camino
		arbusto(lado * 8, -LIMITE - 14)
		flores(lado * 9, -LIMITE - 5, 8)
	end
	cartel(CFrame.new(0, 18, -LIMITE - 1), G.PUERTA * 2 + 5, 4, "⛳ GOLF", Color3.fromRGB(30, 110, 60))

	-- Caseta: techo, mostrador con el cartel de "Jugar" y un letrero con las instrucciones
	local zCaseta = -172
	parte("Piso", Vector3.new(16, 1, 10), CFrame.new(0, SUELO - 0.1, zCaseta), Color3.fromRGB(150, 110, 70), Enum.Material.WoodPlanks)
	for _, px in { -7, 7 } do
		for _, pz in { zCaseta - 4, zCaseta + 4 } do
			parte("Pilar", Vector3.new(0.8, 7, 0.8), CFrame.new(px, SUELO + 3.5, pz), MADERA, Enum.Material.Wood)
		end
	end
	parte("Techo", Vector3.new(18, 0.8, 12), CFrame.new(0, SUELO + 7.4, zCaseta), Color3.fromRGB(165, 55, 45), Enum.Material.Wood)

	local mostrador = parte("Mostrador", Vector3.new(8, 3, 1.6), CFrame.new(0, SUELO + 1.9, zCaseta - 3), MADERA, Enum.Material.Wood)
	local jugar = Instance.new("ProximityPrompt")
	jugar.ActionText = "Jugar al golf"
	jugar.ObjectText = string.format("%d hoyos · par %d", #hoyosCfg, ConfigGolf.parTotal())
	jugar.MaxActivationDistance = 12
	jugar.RequiresLineOfSight = false
	jugar.Parent = mostrador

	cartel(
		CFrame.new(0, SUELO + 6, zCaseta - 3.2) * CFrame.Angles(0, math.rad(180), 0),
		9,
		2.2,
		"⛳ Jugar al golf",
		Color3.fromRGB(30, 110, 60)
	)
	cartel(
		CFrame.new(11, SUELO + 3.5, zCaseta + 1) * CFrame.Angles(0, math.rad(-90), 0),
		9,
		5,
		"Elegí palo, apuntá y mantené GOLPEAR para cargar la fuerza",
		Color3.fromRGB(35, 80, 140)
	)

	-- Tienda de golf: un kiosco a la izquierda de la caseta (TiendaGolf.server.lua abre el panel)
	local xTienda = -17
	parte("Piso", Vector3.new(8, 1, 6), CFrame.new(xTienda, SUELO - 0.1, zCaseta), Color3.fromRGB(150, 110, 70), Enum.Material.WoodPlanks)
	for _, pz in { zCaseta - 2.6, zCaseta + 2.6 } do
		for _, dx in { -3.4, 3.4 } do
			parte("Pilar", Vector3.new(0.6, 7, 0.6), CFrame.new(xTienda + dx, SUELO + 3.5, pz), MADERA, Enum.Material.Wood)
		end
	end
	parte("Techo", Vector3.new(9, 0.8, 7), CFrame.new(xTienda, SUELO + 7.4, zCaseta), Color3.fromRGB(35, 80, 140), Enum.Material.Wood)
	local mostradorTienda = parte("Mostrador", Vector3.new(6, 3, 1.4), CFrame.new(xTienda, SUELO + 1.9, zCaseta - 1.5), MADERA, Enum.Material.Wood)
	cartel(
		CFrame.new(xTienda, SUELO + 6, zCaseta - 2.8) * CFrame.Angles(0, math.rad(180), 0),
		8,
		2,
		"🏌️ Tienda de golf",
		Color3.fromRGB(35, 80, 140)
	)
	-- Palos y pelotas de muestra sobre el mostrador
	for i, estilo in { ConfigGolf.pelota("Fuego"), ConfigGolf.pelota("LuzCeleste"), ConfigGolf.pelota("Dorada") } do
		local muestra = parte(
			"Muestra",
			Vector3.one * 1.2,
			CFrame.new(xTienda + (i - 2) * 1.8, SUELO + 3.9, zCaseta - 1.5),
			estilo.color,
			estilo.material,
			Enum.PartType.Ball,
			false
		)
		if estilo.luz then
			local luz = Instance.new("PointLight")
			luz.Color = estilo.luz.color
			luz.Brightness = 2
			luz.Range = 10
			luz.Parent = muestra
		end
		if estilo.fuego then
			local fuego = Instance.new("Fire")
			fuego.Color = estilo.fuego.color
			fuego.SecondaryColor = estilo.fuego.secundario
			fuego.Size = 3
			fuego.Heat = 0
			fuego.Parent = muestra
		end
	end
	local tienda = Instance.new("ProximityPrompt")
	tienda.ActionText = "Tienda de golf"
	tienda.ObjectText = "Palos y pelotas"
	tienda.MaxActivationDistance = 8
	tienda.RequiresLineOfSight = false
	tienda.Parent = mostradorTienda

	return {
		hoyos = hoyos,
		bolas = bolas,
		jugar = jugar,
		tienda = tienda,
		caseta = Vector3.new(0, SUELO + 3.5, zCaseta + 1), -- donde vuelve el jugador al terminar o salir
	}
end

return CanchaGolf
