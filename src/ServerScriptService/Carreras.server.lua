-- Carreras contra reloj por la calle de afuera de la ciudad, manejando uno de los
-- autos de Vehiculos.server.lua. Se larga pasando con el auto por el arco de la
-- avenida norte (mirando hacia afuera), hay que pasar por los arcos numerados en
-- orden y se llega de nuevo a la largada. Premio por terminar y extra por record.
-- Los records quedan guardados (OrderedDataStore) y el cartel de la largada
-- muestra los 5 mejores de todos los tiempos.
--
-- Al jugador le deja estos atributos (los muestra Carreras.client.lua):
--   CarreraInicio (hora del servidor; no esta si no corre), CarreraControl (numero
--   del proximo arco), CarreraTotal, CarreraDestino (Vector3) y CarreraMejor.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local VEREDA = 0.5
local RADIO_ARCO = 13 -- a esta distancia del centro del arco cuenta que pasaste
local TIEMPO_MAXIMO = 120 -- despues de esto se cancela (y no hay premio)
local PREMIO_LLEGADA = 100
local PREMIO_RECORD = 200
local ESPERA_REPETIR = 5 -- segundos despues de llegar antes de poder largar otra vez
local REVISAR_CADA = 0.1

-- Largada y llegada: en la avenida norte, adelante del estacionamiento de autos
local LARGADA = Vector3.new(0, 0, 135)
local DIRECCION_LARGADA = Vector3.new(0, 0, 1)

-- Arcos en orden: una vuelta por la calle de afuera (centro y hacia donde se va)
local ARCOS = {
	{ Vector3.new(75, 0, 150), Vector3.new(1, 0, 0) },
	{ Vector3.new(150, 0, 75), Vector3.new(0, 0, -1) },
	{ Vector3.new(150, 0, -75), Vector3.new(0, 0, -1) },
	{ Vector3.new(75, 0, -150), Vector3.new(-1, 0, 0) },
	{ Vector3.new(-75, 0, -150), Vector3.new(-1, 0, 0) },
	{ Vector3.new(-150, 0, -75), Vector3.new(0, 0, 1) },
	{ Vector3.new(-150, 0, 75), Vector3.new(0, 0, 1) },
	{ Vector3.new(-75, 0, 150), Vector3.new(1, 0, 0) },
}

local carpeta = Instance.new("Folder")
carpeta.Name = "Carrera"
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

-- Texto en las dos caras de un cartel
local function escribir(tabla, texto, color)
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
		etiqueta.TextColor3 = color
		etiqueta.Text = texto
		etiqueta.Parent = gui
	end
end

-- Arco que cruza la calle: dos postes en las veredas y un cartel arriba
local function arco(centro, direccion, texto, color)
	local costado = Vector3.new(-direccion.Z, 0, direccion.X)
	local base = CFrame.lookAt(centro, centro + direccion)
	for _, lado in { -1, 1 } do
		local pie = centro + costado * lado * 9.5
		parte("Poste", Vector3.new(0.8, 12, 0.8), CFrame.new(pie + Vector3.new(0, VEREDA + 6, 0)), Color3.fromRGB(240, 240, 240), Enum.Material.Metal)
	end
	local cartel = parte("Cartel", Vector3.new(19.8, 3, 0.4), base + Vector3.new(0, VEREDA + 11, 0), color)
	escribir(cartel, texto, Color3.new(1, 1, 1))
end

arco(LARGADA, DIRECCION_LARGADA, "🏁 LARGADA / LLEGADA", Color3.fromRGB(30, 30, 30))
for i, a in ARCOS do
	arco(a[1], a[2], tostring(i), Color3.fromRGB(0, 150, 220))
end

-- Cartel con los mejores tiempos, en la vereda al lado de la largada
local tablero = parte("MejoresTiempos", Vector3.new(0.4, 9, 12), CFrame.new(10, VEREDA + 6, LARGADA.Z - 12), Color3.fromRGB(25, 25, 35))
local guiTablero = Instance.new("SurfaceGui")
guiTablero.Face = Enum.NormalId.Left -- mira hacia la avenida (-X)
guiTablero.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
guiTablero.PixelsPerStud = 30
guiTablero.Parent = tablero
local textoTablero = Instance.new("TextLabel")
textoTablero.Size = UDim2.fromScale(1, 1)
textoTablero.BackgroundTransparency = 1
textoTablero.Font = Enum.Font.GothamBold
textoTablero.TextScaled = true
textoTablero.TextColor3 = Color3.fromRGB(255, 220, 80)
textoTablero.Parent = guiTablero
for _, poste in { -5, 5 } do
	parte("Poste", Vector3.new(0.5, 6, 0.5), CFrame.new(10, VEREDA + 1, LARGADA.Z - 12 + poste), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
end

-- Records guardados: el mejor tiempo de cada jugador, en milesimas, en un
-- OrderedDataStore (de menor a mayor es del mas rapido al mas lento). Si no se
-- puede usar (por ejemplo en Studio sin "Enable Studio Access to API Services"),
-- el cartel muestra los tiempos de esta partida.
local RECORDS = DataStoreService:GetOrderedDataStore("MundoRoblox_Carrera_v1")
local PUESTOS = 5
local ACTUALIZAR_TABLERO = 60

local mejoresPartida = {} -- { nombre, tiempo }, del mas rapido al mas lento (de esta partida)
local mejoresGuardados = nil -- igual, leidos del DataStore; nil si no se pudo
local nombres = {} -- UserId -> nombre, para no pedirlo cada vez

local function nombreDe(userId)
	if not nombres[userId] then
		local ok, nombre = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		nombres[userId] = ok and nombre or ("Jugador " .. userId)
	end
	return nombres[userId]
end

local function actualizarTablero()
	local lista = mejoresGuardados or mejoresPartida
	local lineas = { "🏁 CARRERA", "Subí a un auto y pasá", "por la largada", "", "Récords:" }
	if #lista == 0 then
		table.insert(lineas, "¡Nadie todavía!")
	end
	for i = 1, math.min(PUESTOS, #lista) do
		table.insert(lineas, string.format("%d. %s  %.1f s", i, lista[i].nombre, lista[i].tiempo))
	end
	textoTablero.Text = table.concat(lineas, "\n")
end

local function leerRecords()
	local ok, pagina = pcall(function()
		return RECORDS:GetSortedAsync(true, PUESTOS):GetCurrentPage()
	end)
	if not ok then
		mejoresGuardados = nil
		return
	end
	local lista = {}
	for _, fila in pagina do
		table.insert(lista, { nombre = nombreDe(tonumber(fila.key)), tiempo = fila.value / 1000 })
	end
	mejoresGuardados = lista
end

local function anotarTiempo(jugador, tiempo)
	for i, m in mejoresPartida do
		if m.nombre == jugador.Name then
			if tiempo >= m.tiempo then
				return
			end
			table.remove(mejoresPartida, i)
			break
		end
	end
	table.insert(mejoresPartida, { nombre = jugador.Name, tiempo = tiempo })
	table.sort(mejoresPartida, function(a, b)
		return a.tiempo < b.tiempo
	end)
	actualizarTablero()
end

-- Guarda el record del jugador si es mejor que el que ya tenia guardado
local function guardarRecord(jugador, tiempo)
	local milesimas = math.floor(tiempo * 1000)
	task.spawn(function()
		local ok, problema = pcall(function()
			RECORDS:UpdateAsync(tostring(jugador.UserId), function(anterior)
				if anterior == nil or milesimas < anterior then
					return milesimas
				end
				return nil -- no cambia
			end)
		end)
		if not ok then
			warn("No se pudo guardar el récord de carrera:", problema)
			return
		end
		leerRecords()
		actualizarTablero()
	end)
end

-- Al entrar, se le carga su record guardado
local function cargarRecord(jugador)
	local ok, milesimas = pcall(function()
		return RECORDS:GetAsync(tostring(jugador.UserId))
	end)
	if ok and milesimas and jugador.Parent then
		local actual = jugador:GetAttribute("CarreraMejor")
		if not actual or milesimas / 1000 < actual then
			jugador:SetAttribute("CarreraMejor", milesimas / 1000)
		end
	end
end

Players.PlayerAdded:Connect(cargarRecord)
for _, jugador in Players:GetPlayers() do
	task.spawn(cargarRecord, jugador)
end

-- El cartel se refresca solo cada tanto (otros servidores tambien guardan records)
task.spawn(function()
	while true do
		leerRecords()
		actualizarTablero()
		task.wait(ACTUALIZAR_TABLERO)
	end
end)

local aviso -- RemoteEvent AvisoTienda de Negocios.lua (cartelito abajo)
local function avisar(jugador, texto, ok)
	aviso = aviso or ReplicatedStorage:FindFirstChild("AvisoTienda")
	if aviso then
		aviso:FireClient(jugador, texto, ok)
	end
end

local corriendo = {} -- [jugador] = { control, inicio }
local ultimaLlegada = {}

local function cerca(raiz, punto)
	return ((raiz.Position - punto) * Vector3.new(1, 0, 1)).Magnitude <= RADIO_ARCO
end

local function terminar(jugador)
	corriendo[jugador] = nil
	jugador:SetAttribute("CarreraInicio", nil)
	jugador:SetAttribute("CarreraDestino", nil)
end

local function siguiente(jugador, control)
	corriendo[jugador].control = control
	jugador:SetAttribute("CarreraControl", control)
	jugador:SetAttribute("CarreraTotal", #ARCOS + 1)
	local destino = ARCOS[control] and ARCOS[control][1] or LARGADA
	jugador:SetAttribute("CarreraDestino", destino)
end

local function llegar(jugador)
	local datos = corriendo[jugador]
	local tiempo = Workspace:GetServerTimeNow() - datos.inicio
	terminar(jugador)
	ultimaLlegada[jugador] = os.clock()

	local leaderstats = jugador:FindFirstChild("leaderstats")
	local monedas = leaderstats and leaderstats:FindFirstChild("Monedas")
	local mejor = jugador:GetAttribute("CarreraMejor")
	local record = not mejor or tiempo < mejor
	local premio = PREMIO_LLEGADA + (record and PREMIO_RECORD or 0)
	if monedas then
		monedas.Value += premio
	end
	if record then
		jugador:SetAttribute("CarreraMejor", tiempo)
		guardarRecord(jugador, tiempo)
	end
	anotarTiempo(jugador, tiempo)
	avisar(jugador, string.format("🏁 ¡Llegaste en %.1f s!%s +%d monedas", tiempo, record and " ¡Récord!" or "", premio), true)
end

local function manejando(jugador)
	local humanoide = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
	return humanoide and humanoide.SeatPart and humanoide.SeatPart:IsA("VehicleSeat")
end

Players.PlayerRemoving:Connect(function(jugador)
	corriendo[jugador] = nil
	ultimaLlegada[jugador] = nil
end)

while true do
	for _, jugador in Players:GetPlayers() do
		local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
		local datos = corriendo[jugador]
		if raiz and datos then
			if not manejando(jugador) then
				terminar(jugador)
				avisar(jugador, "Carrera cancelada: te bajaste del auto", false)
			elseif Workspace:GetServerTimeNow() - datos.inicio > TIEMPO_MAXIMO then
				terminar(jugador)
				avisar(jugador, "Carrera cancelada: se terminó el tiempo", false)
			elseif datos.control <= #ARCOS then
				if cerca(raiz, ARCOS[datos.control][1]) then
					siguiente(jugador, datos.control + 1)
				end
			elseif cerca(raiz, LARGADA) then
				llegar(jugador)
			end
		elseif raiz and manejando(jugador) and cerca(raiz, LARGADA) then
			-- Larga si pasa por el arco yendo hacia afuera (no al volver al estacionamiento)
			local yendo = raiz.AssemblyLinearVelocity:Dot(DIRECCION_LARGADA) > 5
			local descanso = os.clock() - (ultimaLlegada[jugador] or 0) > ESPERA_REPETIR
			if yendo and descanso then
				corriendo[jugador] = { inicio = Workspace:GetServerTimeNow() }
				jugador:SetAttribute("CarreraInicio", corriendo[jugador].inicio)
				siguiente(jugador, 1)
				avisar(jugador, "🏁 ¡Largaste! Pasá por los arcos en orden", true)
			end
		end
	end
	task.wait(REVISAR_CADA)
end
