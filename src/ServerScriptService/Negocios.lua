-- Negocios de la ciudad. Ciudad.server.lua elige el lugar y llama a:
--   Negocios.comun(padre, base, ancho, fondo, nombre, color): local con vidriera,
--     toldo y cartel (no se entra).
--   Negocios.petShop(padre, base, ancho, fondo): Lo De Lalo Pet Shop, se entra y
--     se compra alimento para las mascotas (ConfigAlimentos).
-- base es un CFrame en el piso, en el centro del lote, mirando hacia la calle
-- (el frente del local queda hacia -Z de base).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local ConfigAlimentos = require(ReplicatedStorage:WaitForChild("ConfigAlimentos"))

local Negocios = {}

-- Punto en la vereda frente a la puerta de cada negocio, por nombre (lo usan las misiones)
Negocios.lugares = {}

local function anotarLugar(nombre, base, fondo)
	Negocios.lugares[nombre] = (base * CFrame.new(0, 0, -fondo / 2 - 4)).Position
end

-- Avisa a Misiones.server.lua (si esta) que el jugador avanzo en algo
local function progresoMision(jugador, tipo, cantidad)
	local evento = ServerStorage:FindFirstChild("ProgresoMision")
	if evento then
		evento:Fire(jugador, tipo, cantidad)
	end
end

-- Aviso al jugador despues de intentar una compra (lo muestra Alimentos.client.lua)
local aviso = Instance.new("RemoteEvent")
aviso.Name = "AvisoTienda"
aviso.Parent = ReplicatedStorage

local function parte(padre, nombre, tamano, cframe, color, material, colisiona)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = colisiona ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = padre
	return p
end

-- Texto sobre la cara del frente de una parte (lineas: { {texto, alto relativo, color}, ... })
local function escribir(tabla, lineas)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = tabla

	local lista = Instance.new("UIListLayout")
	lista.VerticalAlignment = Enum.VerticalAlignment.Center
	lista.Parent = gui

	for _, linea in lineas do
		local texto = Instance.new("TextLabel")
		texto.Size = UDim2.fromScale(1, linea[2])
		texto.BackgroundTransparency = 1
		texto.Font = Enum.Font.GothamBlack
		texto.TextScaled = true
		texto.TextColor3 = linea[3]
		texto.Text = linea[1]
		texto.Parent = gui
	end
end

-- Cartel colgado arriba del frente
local function cartel(padre, base, ancho, fondo, y, alto, lineas, color)
	local tabla = parte(padre, "Cartel", Vector3.new(ancho, alto, 0.4), base * CFrame.new(0, y, -fondo / 2 - 0.25), color)
	escribir(tabla, lineas)
	return tabla
end

-- Local comun: un piso con vidriera, puerta, toldo de color y cartel con el nombre
function Negocios.comun(padre, base, ancho, fondo, nombre, color)
	local modelo = Instance.new("Model")
	modelo.Name = nombre
	modelo.Parent = padre
	anotarLugar(nombre, base, fondo)

	local alto = 10
	parte(modelo, "Cuerpo", Vector3.new(ancho, alto, fondo), base * CFrame.new(0, alto / 2, 0), Color3.fromRGB(235, 230, 220), Enum.Material.Concrete)
	-- Vidriera y puerta en el frente
	parte(modelo, "Vidriera", Vector3.new(ancho - 2, 5, 0.2), base * CFrame.new(0, 3.2, -fondo / 2 - 0.1), Color3.fromRGB(150, 210, 240), Enum.Material.Glass, false)
	parte(modelo, "Puerta", Vector3.new(3, 5.6, 0.3), base * CFrame.new(0, 2.8, -fondo / 2 - 0.2), Color3.fromRGB(90, 60, 40), Enum.Material.Wood, false)
	-- Toldo
	parte(modelo, "Toldo", Vector3.new(ancho, 0.3, 3), base * CFrame.new(0, 6.3, -fondo / 2 - 1.5) * CFrame.Angles(math.rad(-12), 0, 0), color, Enum.Material.Fabric, false)
	cartel(modelo, base, ancho - 1, fondo, 8.2, 2.4, { { nombre, 1, Color3.new(1, 1, 1) } }, color)
	parte(modelo, "Techo", Vector3.new(ancho + 0.6, 0.6, fondo + 0.6), base * CFrame.new(0, alto + 0.3, 0), color:Lerp(Color3.new(0, 0, 0), 0.4), Enum.Material.Concrete)
	return modelo
end

-- Compra de un alimento en el mostrador
local function comprar(jugador, alimento)
	local monedas = jugador:FindFirstChild("leaderstats") and jugador.leaderstats:FindFirstChild("Monedas")
	local equipadas = jugador:FindFirstChild("MascotasEquipadas")
	if not monedas then
		return
	end
	if not equipadas or #equipadas:GetChildren() == 0 then
		aviso:FireClient(jugador, "Equipá una mascota para darle de comer (botón Mascotas)", false)
		return
	end

	local activo = ConfigAlimentos.restante(jugador) > 0
	local factorActual = jugador:GetAttribute("AlimentoFactor") or 1
	if activo and factorActual > alimento.factor then
		aviso:FireClient(jugador, "Tus mascotas ya comieron algo mejor. Esperá a que se termine.", false)
		return
	end
	if monedas.Value < alimento.precio then
		aviso:FireClient(jugador, string.format("Te faltan %d monedas", alimento.precio - monedas.Value), false)
		return
	end

	monedas.Value -= alimento.precio
	local ahora = Workspace:GetServerTimeNow()
	-- El mismo alimento suma tiempo; uno mejor arranca de nuevo
	local desde = (activo and factorActual == alimento.factor) and jugador:GetAttribute("AlimentoHasta") or ahora
	jugador:SetAttribute("AlimentoFactor", alimento.factor)
	jugador:SetAttribute("AlimentoHasta", desde + alimento.duracion)
	aviso:FireClient(jugador, string.format("¡Ñam! %s: tus mascotas dan x%s de bonus", alimento.nombre, tostring(alimento.factor)), true)
	progresoMision(jugador, "alimento", 1)
end

-- Bolsa de alimento a la venta, con su precio arriba y el boton para comprar
local function bolsaEnVenta(padre, cframe, alimento)
	local bolsa = parte(padre, "Bolsa" .. alimento.id, Vector3.new(1.8, 2.6, 1), cframe, alimento.color, Enum.Material.Fabric)
	escribir(bolsa, { { "🐾", 0.5, Color3.new(1, 1, 1) }, { alimento.nombre, 0.3, Color3.new(1, 1, 1) } })

	local etiqueta = Instance.new("BillboardGui")
	etiqueta.Size = UDim2.fromOffset(160, 50)
	etiqueta.StudsOffset = Vector3.new(0, 2.4, 0)
	etiqueta.MaxDistance = 30
	etiqueta.Parent = bolsa
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 0.2
	texto.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	texto.Font = Enum.Font.GothamBold
	texto.TextScaled = true
	texto.TextColor3 = Color3.fromRGB(255, 205, 0)
	texto.Text = string.format("%s\n%d monedas · x%s %ds", alimento.nombre, alimento.precio, tostring(alimento.factor), alimento.duracion)
	texto.Parent = etiqueta

	local boton = Instance.new("ProximityPrompt")
	boton.ActionText = "Comprar"
	boton.ObjectText = string.format("%s · %d monedas", alimento.nombre, alimento.precio)
	boton.MaxActivationDistance = 9
	boton.RequiresLineOfSight = false
	boton.Parent = bolsa
	boton.Triggered:Connect(function(jugador)
		comprar(jugador, alimento)
	end)
end

-- Lo De Lalo Pet Shop: paredes con una puerta abierta, cartel grande, estanterias
-- con bolsas y un mostrador con los alimentos que se pueden comprar
function Negocios.petShop(padre, base, ancho, fondo)
	local modelo = Instance.new("Model")
	modelo.Name = "LoDeLaloPetShop"
	modelo.Parent = padre
	anotarLugar("Lo De Lalo Pet Shop", base, fondo)

	local alto = 11
	local grosor = 0.8
	local anchoPuerta = 6
	local altoPuerta = 7.5
	local paredColor = Color3.fromRGB(250, 245, 235)
	local rojo = Color3.fromRGB(220, 40, 50)

	parte(modelo, "Piso", Vector3.new(ancho, 0.3, fondo), base * CFrame.new(0, 0.15, 0), Color3.fromRGB(200, 160, 110), Enum.Material.WoodPlanks)
	parte(modelo, "Techo", Vector3.new(ancho + 0.6, 0.8, fondo + 0.6), base * CFrame.new(0, alto + 0.4, 0), rojo, Enum.Material.Concrete)

	-- Paredes: fondo, costados y frente con la puerta en el medio
	parte(modelo, "Pared", Vector3.new(ancho, alto, grosor), base * CFrame.new(0, alto / 2, fondo / 2 - grosor / 2), paredColor, Enum.Material.Concrete)
	for _, lado in { -1, 1 } do
		parte(modelo, "Pared", Vector3.new(grosor, alto, fondo), base * CFrame.new(lado * (ancho / 2 - grosor / 2), alto / 2, 0), paredColor, Enum.Material.Concrete)

		local tramo = (ancho - anchoPuerta) / 2
		local x = lado * (anchoPuerta / 2 + tramo / 2)
		parte(modelo, "Frente", Vector3.new(tramo, alto, grosor), base * CFrame.new(x, alto / 2, -fondo / 2 + grosor / 2), paredColor, Enum.Material.Concrete)
		-- Vidriera a cada lado de la puerta
		parte(modelo, "Vidriera", Vector3.new(tramo - 1.5, 4, 0.2), base * CFrame.new(x, 4, -fondo / 2 - 0.05), Color3.fromRGB(150, 210, 240), Enum.Material.Glass, false)
	end
	parte(modelo, "Frente", Vector3.new(anchoPuerta, alto - altoPuerta, grosor), base * CFrame.new(0, altoPuerta + (alto - altoPuerta) / 2, -fondo / 2 + grosor / 2), paredColor, Enum.Material.Concrete)
	-- Felpudo en la entrada
	parte(modelo, "Felpudo", Vector3.new(anchoPuerta - 1, 0.1, 2.5), base * CFrame.new(0, 0.35, -fondo / 2 + 2), Color3.fromRGB(120, 70, 40), Enum.Material.Fabric, false)

	-- Cartel grande arriba del frente
	cartel(modelo, base, ancho, fondo, alto - 1.2, 3.4, {
		{ "LO DE LALO PET SHOP", 0.62, Color3.new(1, 1, 1) },
		{ "Alimentos para mascotas", 0.38, Color3.fromRGB(255, 220, 120) },
	}, rojo)

	-- Luz adentro
	local lampara = parte(modelo, "Lampara", Vector3.new(4, 0.3, 4), base * CFrame.new(0, alto - 0.2, 0), Color3.fromRGB(255, 250, 230), Enum.Material.Neon, false)
	local luz = Instance.new("PointLight")
	luz.Range = 20
	luz.Brightness = 1.2
	luz.Parent = lampara

	-- Estanterias en los costados con bolsas de alimento de adorno
	local coloresBolsas = { Color3.fromRGB(240, 170, 60), Color3.fromRGB(60, 140, 220), Color3.fromRGB(200, 40, 60), Color3.fromRGB(60, 170, 90) }
	local largoEstante = fondo - 8
	for _, lado in { -1, 1 } do
		local x = lado * (ancho / 2 - grosor - 0.8)
		for nivel, y in { 1.2, 3.4, 5.6 } do
			parte(modelo, "Estante", Vector3.new(1.6, 0.25, largoEstante), base * CFrame.new(x, y, 0), Color3.fromRGB(150, 110, 70), Enum.Material.Wood)
			for i = 0, math.floor(largoEstante / 2) - 1 do
				local z = -largoEstante / 2 + 1 + i * 2
				local color = coloresBolsas[(i + nivel) % #coloresBolsas + 1]
				parte(modelo, "BolsaEstante", Vector3.new(0.9, 1.6, 1.4), base * CFrame.new(x, y + 0.9, z), color, Enum.Material.Fabric, false)
			end
		end
	end

	-- Mostrador al fondo con los alimentos a la venta
	local zMostrador = fondo / 2 - grosor - 2.5
	parte(modelo, "Mostrador", Vector3.new(ancho - 6, 3.4, 2), base * CFrame.new(0, 1.7, zMostrador), Color3.fromRGB(120, 80, 50), Enum.Material.Wood)
	local cantidad = #ConfigAlimentos.Lista
	for i, alimento in ConfigAlimentos.Lista do
		local x = (i - (cantidad + 1) / 2) * ((ancho - 8) / cantidad)
		-- Mirando hacia la puerta, para que se lea desde adentro
		bolsaEnVenta(modelo, base * CFrame.new(x, 3.4 + 1.3, zMostrador), alimento)
	end

	return modelo
end

return Negocios
