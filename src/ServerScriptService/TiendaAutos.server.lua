-- Taller de autos enfrente de la salida norte del parque (avenida norte). Con "Tienda de
-- autos" se abre el panel de TiendaAutos.client.lua; las compras pasan por aca.
--
-- Del jugador (los guarda GuardadoMonedas.server.lua):
--   AutoCosas: ids comprados separados por coma ("Rojo,RuedasNeon")
--   AutoColor, AutoRayas, AutoRuedas, AutoMotor: lo que tiene puesto ("" = nada)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConfigAutos = require(ReplicatedStorage:WaitForChild("ConfigAutos"))

local VEREDA = 0.5
-- Enfrente de la salida norte del parque (la del cartel del ranking), cruzando la
-- calle, en la esquina de la vereda; mira hacia el parque (-Z)
local TALLER = CFrame.lookAt(Vector3.new(-12.5, VEREDA, 73), Vector3.new(-12.5, VEREDA, 0))

local tienda = Instance.new("RemoteFunction")
tienda.Name = "TiendaAutos"
tienda.Parent = ReplicatedStorage

local abrir = Instance.new("RemoteEvent")
abrir.Name = "AbrirTiendaAutos"
abrir.Parent = ReplicatedStorage

local function comprados(jugador)
	local lista = {}
	for id in string.gmatch(jugador:GetAttribute("AutoCosas") or "", "[^,]+") do
		lista[id] = true
	end
	return lista
end

local function anotarCompra(jugador, id)
	local actual = jugador:GetAttribute("AutoCosas") or ""
	jugador:SetAttribute("AutoCosas", actual == "" and id or (actual .. "," .. id))
end

local function poner(jugador, cosa)
	jugador:SetAttribute(ConfigAutos.ATRIBUTO[cosa.categoria], cosa.id)
end

tienda.OnServerInvoke = function(jugador, accion, id)
	if not jugador:GetAttribute("DatosCargados") then
		return false, "Todavía cargando, probá de nuevo"
	end
	local cosa = type(id) == "string" and ConfigAutos.buscar(id)
	if not cosa then
		return false, "Eso no está en la tienda"
	end
	local tengo = comprados(jugador)[cosa.id]

	if accion == "comprar" then
		if tengo then
			poner(jugador, cosa)
			return true, cosa.nombre .. " puesto"
		end
		local leaderstats = jugador:FindFirstChild("leaderstats")
		local monedas = leaderstats and leaderstats:FindFirstChild("Monedas")
		if not monedas or monedas.Value < cosa.precio then
			return false, string.format("Te faltan %d monedas", cosa.precio - (monedas and monedas.Value or 0))
		end
		monedas.Value -= cosa.precio
		anotarCompra(jugador, cosa.id)
		poner(jugador, cosa)
		return true, "¡Compraste " .. cosa.nombre .. "! Ya está puesto"
	elseif accion == "poner" then
		if not tengo then
			return false, "Primero tenés que comprarlo"
		end
		poner(jugador, cosa)
		return true, cosa.nombre .. " puesto"
	elseif accion == "sacar" then
		jugador:SetAttribute(ConfigAutos.ATRIBUTO[cosa.categoria], "")
		return true, cosa.nombre .. " sacado"
	end
	return false, "Pedido inválido"
end

-- El taller: un mostrador con techito y cartel, mirando hacia el parque
local carpeta = Instance.new("Folder")
carpeta.Name = "TallerAutos"
carpeta.Parent = Workspace

local function parte(nombre, tamano, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = carpeta
	return p
end

-- En coordenadas del taller: el frente es -Z (hacia el parque), el ancho va en X
local mostrador = parte("Mostrador", Vector3.new(7, 3.5, 2), TALLER * CFrame.new(0, 1.75, 0), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
for _, x in { -3.3, 3.3 } do
	parte("Poste", Vector3.new(0.4, 9, 0.4), TALLER * CFrame.new(x, 4.5, 0.6), Color3.fromRGB(200, 200, 200), Enum.Material.Metal)
end
parte("Techo", Vector3.new(8, 0.4, 2.6), TALLER * CFrame.new(0, 9, 0), Color3.fromRGB(230, 60, 40), Enum.Material.Metal)

local cartel = parte("Cartel", Vector3.new(7.6, 2.4, 0.3), TALLER * CFrame.new(0, 7.4, -1.2), Color3.fromRGB(25, 25, 30))
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front -- mira hacia el parque
gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 40
gui.Parent = cartel
local texto = Instance.new("TextLabel")
texto.Size = UDim2.fromScale(1, 1)
texto.BackgroundTransparency = 1
texto.Font = Enum.Font.GothamBlack
texto.TextScaled = true
texto.TextColor3 = Color3.fromRGB(255, 205, 0)
texto.Text = "🚗 TALLER"
texto.Parent = gui

local boton = Instance.new("ProximityPrompt")
boton.ActionText = "Tienda de autos"
boton.ObjectText = "Pintura, rayas, ruedas y motor"
boton.MaxActivationDistance = 10
boton.RequiresLineOfSight = false
boton.Parent = mostrador
boton.Triggered:Connect(function(jugador)
	abrir:FireClient(jugador)
end)
