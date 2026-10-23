-- Genera la ciudad alrededor del parque: calles con lineas pintadas, veredas,
-- manzanas con edificios, negocios (Negocios.lua) en las manzanas que dan al
-- parque, faroles y sendas peatonales en las entradas del parque.
-- Todo se crea por codigo dentro de la carpeta "Ciudad" en Workspace y sale
-- siempre igual porque usa una semilla fija (SEMILLA).
--
-- Plano (visto desde arriba, el parque de Mapa.server.lua queda en el medio):
--   calles a lo largo de X y de Z en -150, -63, 63 y 150, y avenidas en 0
--   que salen de las entradas del parque hacia afuera. Entre las calles quedan
--   12 manzanas con edificios.

local Workspace = game:GetService("Workspace")

-- Donde van las calles (tambien lo usa JuegoMonedas para las monedas de la ciudad)
local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))
local Negocios = require(script.Parent:WaitForChild("Negocios"))

local SEMILLA = 2024
local LIMITE = Plano.LIMITE
local CALLES = Plano.CALLES
local AVENIDA = Plano.AVENIDA
local MEDIO_ANCHO_CALLE = Plano.MEDIO_ANCHO_CALLE
local SUELO = 0.3 -- altura del asfalto; el cesped del parque queda apenas arriba (0.4)
local VEREDA = 0.5 -- altura de las veredas
local ANCHO_VEREDA = 3
local SEPARACION_FAROLES = 24

local COLORES_EDIFICIOS = {
	Color3.fromRGB(200, 190, 170),
	Color3.fromRGB(170, 90, 70),
	Color3.fromRGB(110, 140, 170),
	Color3.fromRGB(230, 225, 210),
	Color3.fromRGB(150, 150, 155),
	Color3.fromRGB(215, 160, 90),
	Color3.fromRGB(120, 160, 120),
}
local COLOR_VIDRIO = Color3.fromRGB(120, 180, 220)
local COLOR_ASFALTO = Color3.fromRGB(55, 55, 60)
local COLOR_VEREDA = Color3.fromRGB(190, 190, 185)
local COLOR_LINEA = Color3.fromRGB(255, 210, 0)

-- Un negocio por cada manzana que da al parque, en el lugar mas cercano a el.
-- El primero es Lo De Lalo Pet Shop (se entra y se compra alimento).
local NEGOCIOS = {
	{ nombre = "Lo De Lalo Pet Shop", petShop = true },
	{ nombre = "Heladería", color = Color3.fromRGB(240, 120, 170) },
	{ nombre = "Pizzería", color = Color3.fromRGB(210, 50, 40) },
	{ nombre = "Kiosco", color = Color3.fromRGB(40, 110, 220) },
	{ nombre = "Farmacia", color = Color3.fromRGB(30, 160, 90) },
	{ nombre = "Panadería", color = Color3.fromRGB(170, 110, 50) },
	{ nombre = "Librería", color = Color3.fromRGB(130, 70, 190) },
	{ nombre = "Verdulería", color = Color3.fromRGB(110, 180, 40) },
}
local proximoNegocio = 1

local azar = Random.new(SEMILLA)

local ciudad = Instance.new("Folder")
ciudad.Name = "Ciudad"
ciudad.Parent = Workspace

local function carpeta(nombre)
	local f = Instance.new("Folder")
	f.Name = nombre
	f.Parent = ciudad
	return f
end

local calles = carpeta("Calles")
local veredas = carpeta("Veredas")
local edificios = carpeta("Edificios")
local negocios = carpeta("Negocios")
local faroles = carpeta("Faroles")

local function crearParte(padre, nombre, tamano, cframe, color, material, colisiona)
	local parte = Instance.new("Part")
	parte.Name = nombre
	parte.Size = tamano
	parte.CFrame = cframe
	parte.Color = color
	parte.Material = material or Enum.Material.SmoothPlastic
	parte.Anchored = true
	parte.CanCollide = colisiona ~= false
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	parte.Parent = padre
	return parte
end

-- Un rectangulo en el piso de x1..x2 por z1..z2, con su cara de arriba en altura
local function losa(padre, nombre, x1, x2, z1, z2, altura, color, material)
	return crearParte(
		padre,
		nombre,
		Vector3.new(x2 - x1, altura, z2 - z1),
		CFrame.new((x1 + x2) / 2, altura / 2, (z1 + z2) / 2),
		color,
		material
	)
end

-- Asfalto: toda la ciudad (debajo del parque tambien, el cesped queda arriba)
losa(calles, "Asfalto", -LIMITE, LIMITE, -LIMITE, LIMITE, SUELO, COLOR_ASFALTO, Enum.Material.Asphalt)

-- Lineas amarillas cortadas en el medio de una calle que va de desde a hasta.
-- enX = true si la calle corre a lo largo de X.
local function lineaCentral(enX, centro, desde, hasta)
	local largo, hueco = 5, 4
	local p = desde + hueco
	while p + largo <= hasta - hueco do
		local medio = p + largo / 2
		local tamano = enX and Vector3.new(largo, 0.05, 0.6) or Vector3.new(0.6, 0.05, largo)
		local pos = enX and Vector3.new(medio, SUELO + 0.025, centro) or Vector3.new(centro, SUELO + 0.025, medio)
		crearParte(calles, "Linea", tamano, CFrame.new(pos), COLOR_LINEA, Enum.Material.SmoothPlastic, false)
		p += largo + hueco
	end
end

for _, centro in CALLES do
	lineaCentral(true, centro, -LIMITE, LIMITE)
	lineaCentral(false, centro, -LIMITE, LIMITE)
end
-- Avenidas centrales: de la calle que rodea al parque hacia afuera
for _, signo in { -1, 1 } do
	local desde, hasta = 63 + MEDIO_ANCHO_CALLE, LIMITE
	if signo < 0 then
		desde, hasta = -LIMITE, -63 - MEDIO_ANCHO_CALLE
	end
	lineaCentral(true, AVENIDA, desde, hasta)
	lineaCentral(false, AVENIDA, desde, hasta)
end

-- Vereda alrededor del parque (entre el cerco y la calle)
local function veredaParque()
	local afuera = 63 - MEDIO_ANCHO_CALLE
	local adentro = 50
	losa(veredas, "VeredaParque", -afuera, afuera, -afuera, -adentro, VEREDA, COLOR_VEREDA, Enum.Material.Concrete)
	losa(veredas, "VeredaParque", -afuera, afuera, adentro, afuera, VEREDA, COLOR_VEREDA, Enum.Material.Concrete)
	losa(veredas, "VeredaParque", -afuera, -adentro, -adentro, adentro, VEREDA, COLOR_VEREDA, Enum.Material.Concrete)
	losa(veredas, "VeredaParque", adentro, afuera, -adentro, adentro, VEREDA, COLOR_VEREDA, Enum.Material.Concrete)
end
veredaParque()

-- Sendas peatonales (rayas blancas) frente a cada entrada del parque
local function sendaPeatonal(enX, centroCalle, lado)
	for i = -2, 2 do
		local offset = i * 2.4
		local pos, tamano
		if enX then
			-- la calle corre en X: las rayas cruzan de un lado al otro en Z
			pos = Vector3.new(lado + offset, SUELO + 0.03, centroCalle)
			tamano = Vector3.new(1.4, 0.05, MEDIO_ANCHO_CALLE * 2 - 2)
		else
			pos = Vector3.new(centroCalle, SUELO + 0.03, lado + offset)
			tamano = Vector3.new(MEDIO_ANCHO_CALLE * 2 - 2, 0.05, 1.4)
		end
		crearParte(calles, "Senda", tamano, CFrame.new(pos), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, false)
	end
end
sendaPeatonal(true, -63, 0)
sendaPeatonal(true, 63, 0)
sendaPeatonal(false, -63, 0)
sendaPeatonal(false, 63, 0)

-- Farol: poste, brazo y lampara que se prende de noche
local function farol(x, z)
	local base = CFrame.new(x, VEREDA, z)
	crearParte(faroles, "Poste", Vector3.new(0.6, 12, 0.6), base * CFrame.new(0, 6, 0), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
	local lampara = crearParte(
		faroles,
		"Lampara",
		Vector3.new(1.6, 0.8, 1.6),
		base * CFrame.new(0, 12.2, 0),
		Color3.fromRGB(255, 240, 200),
		Enum.Material.Neon,
		false
	)
	local luz = Instance.new("PointLight")
	luz.Range = 22
	luz.Brightness = 1.5
	luz.Color = Color3.fromRGB(255, 225, 170)
	luz.Parent = lampara
end

-- Faroles a lo largo de la vereda del parque (sin tapar las entradas del medio;
-- en las esquinas estan los semaforos de Semaforos.server.lua)
for _, n in { -2, -1, 1, 2 } do
	local pos = n * SEPARACION_FAROLES
	farol(pos, -53)
	farol(pos, 53)
	farol(-53, pos)
	farol(53, pos)
end

-- Edificio con ventanas: un bloque, franjas de vidrio en cada piso y una terraza
local ALTO_PISO = 5

local function edificio(x, z, ancho, fondo, pisos, color)
	local alto = pisos * ALTO_PISO
	local modelo = Instance.new("Model")
	modelo.Name = "Edificio"
	modelo.Parent = edificios

	local material = azar:NextNumber() < 0.5 and Enum.Material.Concrete or Enum.Material.Brick
	crearParte(modelo, "Cuerpo", Vector3.new(ancho, alto, fondo), CFrame.new(x, VEREDA + alto / 2, z), color, material)

	-- Una franja de ventanas por piso en las cuatro caras (apenas salida para que se vea)
	for piso = 1, pisos do
		local y = VEREDA + (piso - 1) * ALTO_PISO + ALTO_PISO * 0.55
		local alturaVentana = ALTO_PISO * 0.45
		crearParte(modelo, "Ventanas", Vector3.new(ancho - 2, alturaVentana, 0.2), CFrame.new(x, y, z - fondo / 2 - 0.1), COLOR_VIDRIO, Enum.Material.Glass, false)
		crearParte(modelo, "Ventanas", Vector3.new(ancho - 2, alturaVentana, 0.2), CFrame.new(x, y, z + fondo / 2 + 0.1), COLOR_VIDRIO, Enum.Material.Glass, false)
		crearParte(modelo, "Ventanas", Vector3.new(0.2, alturaVentana, fondo - 2), CFrame.new(x - ancho / 2 - 0.1, y, z), COLOR_VIDRIO, Enum.Material.Glass, false)
		crearParte(modelo, "Ventanas", Vector3.new(0.2, alturaVentana, fondo - 2), CFrame.new(x + ancho / 2 + 0.1, y, z), COLOR_VIDRIO, Enum.Material.Glass, false)
	end

	-- Terraza: un borde un poco mas oscuro arriba
	crearParte(
		modelo,
		"Terraza",
		Vector3.new(ancho + 0.6, 0.8, fondo + 0.6),
		CFrame.new(x, VEREDA + alto + 0.4, z),
		color:Lerp(Color3.new(0, 0, 0), 0.3),
		Enum.Material.Concrete
	)
	return modelo
end

-- Las manzanas son los espacios entre calles (sin contar el parque)
local cortes = { -LIMITE, -150, -63, AVENIDA, 63, 150, LIMITE }

-- Tramos de una direccion que quedan entre dos calles
local function tramos()
	local lista = {}
	for i = 1, #cortes - 1 do
		local a, b = cortes[i], cortes[i + 1]
		local desde = a == -LIMITE and a or a + MEDIO_ANCHO_CALLE
		local hasta = b == LIMITE and b or b - MEDIO_ANCHO_CALLE
		-- La franja de afuera de la ultima calle queda libre (es el borde)
		if a ~= -LIMITE and b ~= LIMITE then
			table.insert(lista, { desde, hasta })
		end
	end
	return lista
end

local function esParque(x1, x2, z1, z2)
	return x1 > -63 and x2 < 63 and z1 > -63 and z2 < 63
end

-- Llena una manzana: vereda alrededor y edificios en fila, dejando espacio entre ellos
-- Hacia donde mira el negocio de una manzana que da al parque (nil si no da al parque)
local function frenteAlParque(x1, x2, z1, z2)
	local adentroEnX = x1 > -Plano.ANILLO and x2 < Plano.ANILLO
	local adentroEnZ = z1 > -Plano.ANILLO and z2 < Plano.ANILLO
	if adentroEnX then
		return Vector3.new(0, 0, z1 > 0 and -1 or 1)
	elseif adentroEnZ then
		return Vector3.new(x1 > 0 and -1 or 1, 0, 0)
	end
	return nil
end

local function manzana(x1, x2, z1, z2)
	losa(veredas, "Vereda", x1, x2, z1, z2, VEREDA, COLOR_VEREDA, Enum.Material.Concrete)

	local adentroX1, adentroX2 = x1 + ANCHO_VEREDA, x2 - ANCHO_VEREDA
	local adentroZ1, adentroZ2 = z1 + ANCHO_VEREDA, z2 - ANCHO_VEREDA
	local anchoTotal = adentroX2 - adentroX1
	local fondoTotal = adentroZ2 - adentroZ1

	-- Cuantos edificios entran por lado (cada uno de 14 a 22 de ancho)
	local columnas = math.max(1, math.floor(anchoTotal / 20))
	local filas = math.max(1, math.floor(fondoTotal / 20))
	local celdaX = anchoTotal / columnas
	local celdaZ = fondoTotal / filas

	local function centroCelda(c, f)
		return adentroX1 + celdaX * (c + 0.5), adentroZ1 + celdaZ * (f + 0.5)
	end

	-- Si da al parque, el lugar mas cercano al parque es para un negocio
	local frente = frenteAlParque(x1, x2, z1, z2)
	local negocio = frente and NEGOCIOS[proximoNegocio]
	local celdaNegocio
	if negocio then
		proximoNegocio += 1
		local mejor = math.huge
		for c = 0, columnas - 1 do
			for f = 0, filas - 1 do
				local cx, cz = centroCelda(c, f)
				local distancia = Vector2.new(cx, cz).Magnitude
				if distancia < mejor then
					mejor = distancia
					celdaNegocio = Vector2.new(c, f)
				end
			end
		end
		local cx, cz = centroCelda(celdaNegocio.X, celdaNegocio.Y)
		local centro = Vector3.new(cx, VEREDA, cz)
		local base = CFrame.lookAt(centro, centro + frente)
		-- ancho: a lo largo de la calle; fondo: hacia adentro de la manzana
		local ancho, fondo = celdaX - 2, celdaZ - 2
		if frente.X ~= 0 then
			ancho, fondo = fondo, ancho
		end
		if negocio.petShop then
			Negocios.petShop(negocios, base, ancho, fondo)
		else
			Negocios.comun(negocios, base, ancho, fondo, negocio.nombre, negocio.color)
		end
	end

	for c = 0, columnas - 1 do
		for f = 0, filas - 1 do
			local esNegocio = celdaNegocio and celdaNegocio.X == c and celdaNegocio.Y == f
			-- Algunos lugares quedan libres (plazoletas) para que no sea todo igual
			if not esNegocio and azar:NextNumber() < 0.85 then
				local ancho = math.min(celdaX - 3, azar:NextNumber(12, 20))
				local fondo = math.min(celdaZ - 3, azar:NextNumber(12, 20))
				local cx, cz = centroCelda(c, f)
				local pisos = azar:NextInteger(3, 10)
				-- Los mas altos van en las manzanas de afuera, para que se vea el horizonte
				if math.max(math.abs(cx), math.abs(cz)) > 100 then
					pisos += azar:NextInteger(0, 6)
				end
				edificio(cx, cz, ancho, fondo, pisos, COLORES_EDIFICIOS[azar:NextInteger(1, #COLORES_EDIFICIOS)])
			end
		end
	end
end

for _, tx in tramos() do
	for _, tz in tramos() do
		if not esParque(tx[1], tx[2], tz[1], tz[2]) then
			manzana(tx[1], tx[2], tz[1], tz[2])
		end
	end
end

-- Pared invisible en el borde para no caerse de la ciudad
local function pared(x, z, ancho, fondo)
	local p = crearParte(ciudad, "Limite", Vector3.new(ancho, 60, fondo), CFrame.new(x, 30, z), Color3.new(1, 1, 1))
	p.Transparency = 1
end
pared(0, -LIMITE - 1, LIMITE * 2 + 4, 2)
pared(0, LIMITE + 1, LIMITE * 2 + 4, 2)
pared(-LIMITE - 1, 0, 2, LIMITE * 2 + 4)
pared(LIMITE + 1, 0, 2, LIMITE * 2 + 4)
