-- Tienda de golf (el kiosco junto a la caseta de CanchaGolf.lua). Con "Tienda de golf" se
-- abre el panel de TiendaGolf.client.lua; las compras pasan por aca.
--
-- Del jugador (los guarda GuardadoMonedas.server.lua):
--   GolfCosas: ids comprados separados por coma ("Driver,Fuego")
--   GolfBola: la pelota que usa ("" = la clasica)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConfigGolf = require(ReplicatedStorage:WaitForChild("ConfigGolf"))

local tienda = Instance.new("RemoteFunction")
tienda.Name = "TiendaGolf"
tienda.Parent = ReplicatedStorage

local abrir = Instance.new("RemoteEvent")
abrir.Name = "AbrirTiendaGolf"
abrir.Parent = ReplicatedStorage

local function anotarCompra(jugador, id)
	local actual = jugador:GetAttribute("GolfCosas") or ""
	jugador:SetAttribute("GolfCosas", actual == "" and id or (actual .. "," .. id))
end

-- tipo: "palo" o "pelota"
local function buscar(tipo, id)
	if tipo == "palo" then
		return ConfigGolf.palo(id)
	elseif tipo == "pelota" then
		for _, pelota in ConfigGolf.Pelotas do
			if pelota.id == id then
				return pelota
			end
		end
	end
	return nil
end

tienda.OnServerInvoke = function(jugador, accion, tipo, id)
	if not jugador:GetAttribute("DatosCargados") then
		return false, "Todavía cargando, probá de nuevo"
	end
	local cosa = type(tipo) == "string" and type(id) == "string" and buscar(tipo, id)
	if not cosa then
		return false, "Eso no está en la tienda"
	end
	local tengo = ConfigGolf.tiene(ConfigGolf.comprados(jugador:GetAttribute("GolfCosas")), cosa)

	if accion == "comprar" then
		if tengo then
			return false, "Ya lo tenés"
		end
		local leaderstats = jugador:FindFirstChild("leaderstats")
		local monedas = leaderstats and leaderstats:FindFirstChild("Monedas")
		if not monedas or monedas.Value < cosa.precio then
			return false, string.format("Te faltan %d monedas", cosa.precio - (monedas and monedas.Value or 0))
		end
		monedas.Value -= cosa.precio
		anotarCompra(jugador, cosa.id)
		if tipo == "pelota" then
			jugador:SetAttribute("GolfBola", cosa.id)
			return true, "¡Compraste la pelota " .. cosa.nombre .. "! Ya la usás"
		end
		return true, "¡Compraste el palo " .. cosa.nombre .. "!"
	elseif accion == "poner" and tipo == "pelota" then
		if not tengo then
			return false, "Primero tenés que comprarla"
		end
		jugador:SetAttribute("GolfBola", cosa.id)
		return true, "Pelota " .. cosa.nombre .. " puesta"
	end
	return false, "Pedido inválido"
end

-- El kiosco lo arma CanchaGolf.construir() (corre en Golf.server.lua): conectamos su
-- prompt ahora si ya esta, o apenas aparezca
local function conectar(prompt)
	if prompt:IsA("ProximityPrompt") and prompt.ActionText == "Tienda de golf" then
		prompt.Triggered:Connect(function(jugador)
			abrir:FireClient(jugador)
		end)
	end
end

local golf = Workspace:WaitForChild("Golf")
for _, descendiente in golf:GetDescendants() do
	conectar(descendiente)
end
golf.DescendantAdded:Connect(conectar)
