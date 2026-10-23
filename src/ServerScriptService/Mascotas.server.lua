-- Mascotas: abrir huevos, equipar, y modelos que siguen al jugador.
-- Las mascotas que tiene un jugador son BoolValue en su carpeta "Mascotas";
-- las equipadas, en "MascotasEquipadas". GuardadoMonedas.server.lua las carga y las guarda.
-- El bonus de monedas lo aplica JuegoMonedas.server.lua con ConfigMascotas.multiplicador().

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ConfigMascotas = require(ReplicatedStorage:WaitForChild("ConfigMascotas"))
local ModelosMascotas = require(script.Parent:WaitForChild("ModelosMascotas"))

-- Donde se coloca cada mascota equipada, relativo al jugador (X a un lado, Z hacia atras)
local POSICIONES = {
	Vector3.new(-3, 0, 4),
	Vector3.new(3, 0, 4),
	Vector3.new(0, 0, 7),
}
local SUAVIZADO = 8 -- cuanto mas alto, mas rapido alcanzan al jugador
local ALTURA_VUELO = 1.5 -- las que vuelan (Buho, Dragon, Fenix) van a la altura del jugador

local abrirHuevo = Instance.new("RemoteFunction")
abrirHuevo.Name = "AbrirHuevo"
abrirHuevo.Parent = ReplicatedStorage

local equipar = Instance.new("RemoteFunction")
equipar.Name = "EquiparMascota"
equipar.Parent = ReplicatedStorage

local carpetaModelos = Instance.new("Folder")
carpetaModelos.Name = "Mascotas"
carpetaModelos.Parent = Workspace

local seguidores = {} -- jugador -> lista de modelos, en el orden de POSICIONES
local pendiente = {} -- jugador -> true si ya hay una reconstruccion en espera

-- El modelo de cada especie lo arma ModelosMascotas.lua
local function crearModelo(mascota)
	return ModelosMascotas.crear(mascota, ConfigMascotas.Rarezas[mascota.rareza])
end

local function borrarModelos(jugador)
	local lista = seguidores[jugador]
	if lista then
		for _, modelo in lista do
			modelo:Destroy()
		end
	end
	seguidores[jugador] = nil
end

-- Vuelve a crear los modelos de las mascotas equipadas
local function reconstruir(jugador)
	borrarModelos(jugador)

	local equipadas = jugador:FindFirstChild("MascotasEquipadas")
	local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
	if not equipadas or not raiz then
		return
	end

	local lista = {}
	for i, marca in equipadas:GetChildren() do
		local mascota = ConfigMascotas.buscar(marca.Name)
		if mascota and POSICIONES[i] then
			local modelo = crearModelo(mascota)
			modelo.Parent = carpetaModelos
			modelo:PivotTo(raiz.CFrame * CFrame.new(POSICIONES[i].X, -2, POSICIONES[i].Z))
			table.insert(lista, modelo)
		end
	end
	seguidores[jugador] = lista
end

-- Agrupa varios cambios seguidos en una sola reconstruccion
local function pedirReconstruir(jugador)
	if pendiente[jugador] then
		return
	end
	pendiente[jugador] = true
	task.defer(function()
		pendiente[jugador] = nil
		if jugador.Parent then
			reconstruir(jugador)
		end
	end)
end

local function prepararJugador(jugador)
	local mascotas = Instance.new("Folder")
	mascotas.Name = "Mascotas"
	mascotas.Parent = jugador

	local equipadas = Instance.new("Folder")
	equipadas.Name = "MascotasEquipadas"
	equipadas.Parent = jugador

	equipadas.ChildAdded:Connect(function()
		pedirReconstruir(jugador)
	end)
	equipadas.ChildRemoved:Connect(function()
		pedirReconstruir(jugador)
	end)

	jugador.CharacterAdded:Connect(function()
		pedirReconstruir(jugador)
	end)
	jugador.CharacterRemoving:Connect(function()
		borrarModelos(jugador)
	end)
end

abrirHuevo.OnServerInvoke = function(jugador)
	local leaderstats = jugador:FindFirstChild("leaderstats")
	local mascotas = jugador:FindFirstChild("Mascotas")
	if not jugador:GetAttribute("DatosCargados") or not leaderstats or not mascotas then
		return false, "Todavía cargando, probá de nuevo"
	end

	local monedas = leaderstats.Monedas
	if monedas.Value < ConfigMascotas.COSTO_HUEVO then
		return false, "Necesitás " .. ConfigMascotas.COSTO_HUEVO .. " monedas para abrir un huevo"
	end
	monedas.Value -= ConfigMascotas.COSTO_HUEVO

	local mascota = ConfigMascotas.sortear()
	local rareza = ConfigMascotas.Rarezas[mascota.rareza]

	if mascotas:FindFirstChild(mascota.id) then
		-- Repetida: devolvemos parte de lo que costo el huevo
		local reembolso = math.floor(ConfigMascotas.COSTO_HUEVO * ConfigMascotas.REEMBOLSO_REPETIDA)
		monedas.Value += reembolso
		return true, string.format("¡%s (%s) repetida! +%d monedas", mascota.nombre, rareza.nombre, reembolso), mascota.id
	end

	local marca = Instance.new("BoolValue")
	marca.Name = mascota.id
	marca.Value = true
	marca.Parent = mascotas
	return true, string.format("¡Nueva mascota: %s (%s)!", mascota.nombre, rareza.nombre), mascota.id
end

equipar.OnServerInvoke = function(jugador, id, quiereEquipar)
	local mascotas = jugador:FindFirstChild("Mascotas")
	local equipadas = jugador:FindFirstChild("MascotasEquipadas")
	if type(id) ~= "string" or not mascotas or not equipadas then
		return false, "Pedido inválido"
	end
	if not mascotas:FindFirstChild(id) then
		return false, "Todavía no tenés esa mascota"
	end

	local actual = equipadas:FindFirstChild(id)
	if quiereEquipar then
		if actual then
			return true, ""
		end
		if #equipadas:GetChildren() >= ConfigMascotas.MAX_EQUIPADAS then
			return false, "Ya llevás " .. ConfigMascotas.MAX_EQUIPADAS .. " mascotas, quitá una primero"
		end
		local marca = Instance.new("BoolValue")
		marca.Name = id
		marca.Value = true
		marca.Parent = equipadas
	elseif actual then
		actual:Destroy()
	end
	return true, ""
end

Players.PlayerAdded:Connect(prepararJugador)
for _, jugador in Players:GetPlayers() do
	prepararJugador(jugador)
end

Players.PlayerRemoving:Connect(function(jugador)
	borrarModelos(jugador)
	pendiente[jugador] = nil
end)

-- Las mascotas se acercan al jugador con suavidad y flotan un poquito
RunService.Heartbeat:Connect(function(dt)
	local reloj = os.clock()
	for jugador, lista in seguidores do
		local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
		if raiz then
			for i, modelo in lista do
				-- Las que vuelan van mas alto y suben y bajan mas
				local vuela = modelo:GetAttribute("Vuela")
				local rebote = math.sin(reloj * 3 + i * 2) * (vuela and 0.6 or 0.3)
				local altura = vuela and ALTURA_VUELO or -2
				local objetivo = raiz.CFrame * CFrame.new(POSICIONES[i].X, altura + rebote, POSICIONES[i].Z)
				modelo:PivotTo(modelo:GetPivot():Lerp(objetivo, math.min(1, dt * SUAVIZADO)))
			end
		end
	end
end)
