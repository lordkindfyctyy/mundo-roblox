-- Golf: la cancha de CanchaGolf.lua y el recorrido por todos sus hoyos (ConfigGolf.Hoyos).
-- El jugador empieza en la caseta, y por cada hoyo le damos una pelota en el tee.
-- Golpea con GolfGolpe (palo, potencia, direccion); la fisica de la pelota la maneja el
-- servidor (nadie le puede dar velocidad desde el cliente) y aca se frena, se detecta el
-- agua, el hoyo y cuando se detuvo.
--
-- Atributos del jugador que lee Golf.client.lua:
--   GolfActivo, GolfHoyo, GolfHoyos, GolfPar, GolfGolpes, GolfTotal, GolfCopa (posicion de
--   la bandera) y GolfContador (sube con cada pelota nueva, para volver a apuntar).
-- Se guardan (GuardadoMonedas.server.lua): GolfRondas, GolfMejor, GolfHoyosEnUno, y lo de
-- la tienda (TiendaGolf.server.lua): GolfCosas (palos y pelotas comprados) y GolfBola (la que usa).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Plano = require(script.Parent:WaitForChild("PlanoCiudad"))
local ConfigGolf = require(ReplicatedStorage:WaitForChild("ConfigGolf"))
local CanchaGolf = require(script.Parent:WaitForChild("CanchaGolf"))
local EfectosBola = require(script.Parent:WaitForChild("EfectosBola"))

local G = Plano.GOLF
local RADIO_BOLA = 0.6
local UMBRAL_QUIETA = 3 -- por debajo de esta velocidad (studs/s) la pelota se considera detenida
local DISTANCIA_HOYO = 1.4 -- a esta distancia de la bandera, y despacio, entra
local VELOCIDAD_MAXIMA_HOYO = 30 -- mas rapido que esto pasa de largo
local ESPERA_MAXIMA = 25 -- segundos maximos con la pelota en movimiento antes de darla por detenida
local PAUSA_ENTRE_HOYOS = 3

local cancha = CanchaGolf.construir()
local HOYOS = cancha.hoyos
local PAR_TOTAL = ConfigGolf.parTotal()

local golpeRemoto = Instance.new("RemoteEvent")
golpeRemoto.Name = "GolfGolpe"
golpeRemoto.Parent = ReplicatedStorage

local salirRemoto = Instance.new("RemoteEvent")
salirRemoto.Name = "GolfSalir"
salirRemoto.Parent = ReplicatedStorage

local partidas = {} -- jugador -> estado de su recorrido

local paramsRayo = RaycastParams.new()
paramsRayo.FilterType = Enum.RaycastFilterType.Exclude
paramsRayo.FilterDescendantsInstances = { cancha.bolas }

local aviso -- RemoteEvent AvisoTienda (cartelito de abajo, de Negocios.lua)
local function avisar(jugador, texto, ok)
	aviso = aviso or ReplicatedStorage:FindFirstChild("AvisoTienda")
	if aviso then
		aviso:FireClient(jugador, texto, ok)
	end
end

local function sumarAtributo(jugador, nombre, cantidad)
	jugador:SetAttribute(nombre, (jugador:GetAttribute(nombre) or 0) + cantidad)
end

local function raizDe(jugador)
	return jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
end

local function plano(vector)
	return Vector3.new(vector.X, 0, vector.Z)
end

local function actualizarAtributos(jugador, p)
	local hoyo = HOYOS[p.hoyo]
	jugador:SetAttribute("GolfActivo", true)
	jugador:SetAttribute("GolfHoyo", p.hoyo)
	jugador:SetAttribute("GolfHoyos", #HOYOS)
	jugador:SetAttribute("GolfPar", hoyo.par)
	jugador:SetAttribute("GolfGolpes", p.golpes)
	jugador:SetAttribute("GolfTotal", p.total)
	jugador:SetAttribute("GolfCopa", hoyo.copa)
end

local function limpiarAtributos(jugador)
	for _, nombre in { "GolfActivo", "GolfHoyo", "GolfHoyos", "GolfPar", "GolfGolpes", "GolfTotal", "GolfCopa" } do
		jugador:SetAttribute(nombre, nil)
	end
end

-- Pone al jugador unos pasos detras de la pelota, mirando hacia la bandera
local function ponerJunto(jugador, posicion, copa)
	local personaje = jugador.Character
	if not personaje or not raizDe(jugador) then
		return
	end
	local direccion = plano(copa - posicion)
	direccion = direccion.Magnitude > 0.1 and direccion.Unit or Vector3.new(0, 0, -1)
	-- Un poco arriba de la pelota (puede estar en una loma o arriba del tunel)
	local donde = Vector3.new(posicion.X, posicion.Y + 3, posicion.Z) - direccion * 4
	personaje:PivotTo(CFrame.lookAt(donde, donde + direccion))
end

local function destruirBola(p)
	if p.bola then
		p.bola:Destroy()
		p.bola = nil
	end
end

local function crearBola(jugador, p)
	destruirBola(p)

	local bola = Instance.new("Part")
	bola.Name = "Bola_" .. jugador.UserId
	bola.Shape = Enum.PartType.Ball
	bola.Size = Vector3.one * RADIO_BOLA * 2
	-- El estilo que eligio en la tienda de golf (si no lo tiene, la clasica)
	local estilo = ConfigGolf.pelota(jugador:GetAttribute("GolfBola"))
	if not ConfigGolf.tiene(ConfigGolf.comprados(jugador:GetAttribute("GolfCosas")), estilo) then
		estilo = ConfigGolf.Pelotas[1]
	end
	p.estilo = estilo
	EfectosBola.aplicar(bola, estilo)
	-- Sin friccion propia (la frenamos nosotros) y con rebote moderado; los pesos altos
	-- hacen que estos valores ganen contra los del piso.
	bola.CustomPhysicalProperties = PhysicalProperties.new(1, 0.02, 0.35, 100, 100)
	bola.TopSurface = Enum.SurfaceType.Smooth
	bola.BottomSurface = Enum.SurfaceType.Smooth
	bola.Position = HOYOS[p.hoyo].tee + Vector3.new(0, RADIO_BOLA + 0.1, 0)
	bola:SetAttribute("EnMovimiento", false)
	bola:SetAttribute("Superficie", "Tee")
	bola.Parent = cancha.bolas
	pcall(function()
		bola:SetNetworkOwner(nil) -- la fisica la calcula el servidor
	end)

	p.bola = bola
	p.ultimaPos = bola.Position
	p.enMovimiento = false
	p.vuelo = 0
	p.contador += 1
	jugador:SetAttribute("GolfContador", p.contador)
end

local function colocarHoyo(jugador, p, numero)
	p.hoyo = numero
	p.golpes = 0
	p.esperando = false
	crearBola(jugador, p)
	actualizarAtributos(jugador, p)
	ponerJunto(jugador, p.bola.Position, HOYOS[numero].copa)
	avisar(jugador, string.format("⛳ Hoyo %d · Par %d · %d m", numero, HOYOS[numero].par, ConfigGolf.Hoyos[numero].largo), true)
end

-- Termina el recorrido (completo o no) y devuelve al jugador a la caseta
local function cerrarPartida(jugador, p, llevarACaseta)
	destruirBola(p)
	partidas[jugador] = nil
	limpiarAtributos(jugador)
	if llevarACaseta then
		local personaje = jugador.Character
		if personaje and raizDe(jugador) then
			personaje:PivotTo(CFrame.new(cancha.caseta) * CFrame.Angles(0, math.rad(180), 0))
		end
	end
end

local function nombreDelResultado(golpes, diferencia)
	if golpes == 1 then
		return "¡HOYO EN UNO!"
	elseif diferencia <= -3 then
		return "¡Albatros!"
	elseif diferencia == -2 then
		return "¡Águila!"
	elseif diferencia == -1 then
		return "¡Birdie!"
	elseif diferencia == 0 then
		return "Par"
	elseif diferencia == 1 then
		return "Bogey"
	elseif diferencia == 2 then
		return "Doble bogey"
	end
	return string.format("+%d", diferencia)
end

local function terminarRecorrido(jugador, p)
	local diferencia = p.total - PAR_TOTAL
	local monedas = jugador:FindFirstChild("leaderstats") and jugador.leaderstats:FindFirstChild("Monedas")
	local texto = string.format("🏆 Recorrido completo: %d golpes (par %d)", p.total, PAR_TOTAL)

	if monedas and p.total <= PAR_TOTAL then
		monedas.Value += ConfigGolf.Premios.RECORRIDO_BAJO_PAR
		texto ..= string.format(" · +%d monedas de bonus", ConfigGolf.Premios.RECORRIDO_BAJO_PAR)
	elseif diferencia > 0 then
		texto ..= string.format(" · +%d", diferencia)
	end

	sumarAtributo(jugador, "GolfRondas", 1)
	local mejor = jugador:GetAttribute("GolfMejor") or 0
	if mejor == 0 or p.total < mejor then
		jugador:SetAttribute("GolfMejor", p.total)
		if mejor ~= 0 then
			texto ..= " · ¡nuevo récord!"
		end
	end

	avisar(jugador, texto, true)
	cerrarPartida(jugador, p, true)
end

-- La pelota entro al hoyo (o se llego al limite de golpes)
local function cerrarHoyo(jugador, p, embocada)
	local hoyo = HOYOS[p.hoyo]
	local golpes = p.golpes
	local premios = ConfigGolf.Premios
	local premio = 0
	local nombre

	if embocada then
		premio = math.max(premios.MINIMO, premios.BASE + premios.POR_GOLPE * (hoyo.par - golpes))
		if golpes == 1 then
			premio += premios.HOYO_EN_UNO
			sumarAtributo(jugador, "GolfHoyosEnUno", 1)
		end
		nombre = nombreDelResultado(golpes, golpes - hoyo.par)
	else
		nombre = "Límite de golpes"
	end

	local monedas = jugador:FindFirstChild("leaderstats") and jugador.leaderstats:FindFirstChild("Monedas")
	if monedas and premio > 0 then
		monedas.Value += premio
	end

	p.total += golpes
	p.esperando = true
	p.enMovimiento = false
	destruirBola(p)
	actualizarAtributos(jugador, p)

	if premio > 0 then
		avisar(jugador, string.format("⛳ Hoyo %d: %s (%d golpes) · +%d monedas", p.hoyo, nombre, golpes, premio), true)
	else
		avisar(jugador, string.format("⛳ Hoyo %d: %s (%d golpes)", p.hoyo, nombre, golpes), false)
	end

	task.delay(PAUSA_ENTRE_HOYOS, function()
		if partidas[jugador] ~= p then
			return -- se fue o cancelo mientras esperaba
		end
		if p.hoyo < #HOYOS then
			colocarHoyo(jugador, p, p.hoyo + 1)
		else
			terminarRecorrido(jugador, p)
		end
	end)
end

-- La pelota queda quieta (o vuelve a su lugar tras un castigo)
local function detener(jugador, p, bola)
	bola.AssemblyLinearVelocity = Vector3.zero
	bola.AssemblyAngularVelocity = Vector3.zero
	p.enMovimiento = false
	p.vuelo = 0
	bola:SetAttribute("EnMovimiento", false)
	p.ultimaPos = bola.Position

	if p.golpes >= ConfigGolf.LIMITE_GOLPES then
		cerrarHoyo(jugador, p, false)
		return
	end

	local raiz = raizDe(jugador)
	if raiz and (raiz.Position - bola.Position).Magnitude > 12 then
		ponerJunto(jugador, bola.Position, HOYOS[p.hoyo].copa)
	end
end

-- Agua o fuera de la cancha: un golpe de castigo y la pelota vuelve de donde se pego
local function penalizar(jugador, p, bola, motivo)
	p.golpes += 1
	bola.AssemblyLinearVelocity = Vector3.zero
	bola.AssemblyAngularVelocity = Vector3.zero
	bola.Position = p.ultimaPos + Vector3.new(0, 0.5, 0)
	detener(jugador, p, bola)
	actualizarAtributos(jugador, p)
	avisar(jugador, motivo .. " · +1 golpe", false)
	if partidas[jugador] == p and p.bola then
		ponerJunto(jugador, p.bola.Position, HOYOS[p.hoyo].copa)
	end
end

local function empezarMovimiento(p, bola)
	p.enMovimiento = true
	p.inicioMovimiento = os.clock()
	bola:SetAttribute("EnMovimiento", true)
end

local function fueraDeLaCancha(posicion)
	return posicion.Y < -15 or math.abs(posicion.X) > G.X or posicion.Z < G.Z_LEJOS or posicion.Z > G.Z_CERCA + 10
end

-- Una pelota, cada cuadro
local function actualizarBola(jugador, p, bola, dt)
	local posicion = bola.Position
	local velocidad = bola.AssemblyLinearVelocity
	local rapidez = plano(velocidad).Magnitude

	local rayo = Workspace:Raycast(posicion, Vector3.new(0, -6, 0), paramsRayo)
	local enSuelo = rayo ~= nil and (posicion.Y - rayo.Position.Y) < RADIO_BOLA + 0.4
	local nombreSuperficie = rayo and rayo.Instance:GetAttribute("Superficie") or "Otro"
	bola:SetAttribute("Superficie", enSuelo and nombreSuperficie or "Aire")

	if fueraDeLaCancha(posicion) then
		penalizar(jugador, p, bola, "🚫 Fuera de la cancha")
		return
	end

	-- Si algo la empujo sin que la golpeen, se trata igual que un tiro
	if not p.enMovimiento then
		if rapidez > 4 or math.abs(velocidad.Y) > 6 then
			empezarMovimiento(p, bola)
		else
			return
		end
	end

	local superficie = ConfigGolf.superficie(nombreSuperficie)

	-- Vuelo: 1 = recien golpeada, todavia pegada al piso; 2 = en el aire. Al caer se pierde
	-- parte de la velocidad (la pelota "muerde" el pasto) segun la superficie.
	if p.vuelo == 1 and not enSuelo then
		p.vuelo = 2
	elseif p.vuelo == 2 and enSuelo then
		p.vuelo = 0
		velocidad = Vector3.new(velocidad.X * superficie.aterrizaje, velocidad.Y, velocidad.Z * superficie.aterrizaje)
		rapidez = plano(velocidad).Magnitude
	end

	-- Frenado al rodar
	if enSuelo and p.vuelo ~= 1 then
		local nueva = math.max(0, rapidez - (superficie.friccion + superficie.arrastre * rapidez) * dt)
		local factor = rapidez > 0 and nueva / rapidez or 0
		velocidad = Vector3.new(velocidad.X * factor, velocidad.Y, velocidad.Z * factor)
		rapidez = nueva
		bola.AssemblyAngularVelocity = Vector3.zero
	end
	bola.AssemblyLinearVelocity = velocidad

	if enSuelo and nombreSuperficie == "Agua" then
		penalizar(jugador, p, bola, "💦 ¡Al agua!")
		return
	end

	-- Hoyo: cerca de la bandera, pegada al piso y no muy rapido
	local copa = HOYOS[p.hoyo].copa
	if p.golpes >= 1 and enSuelo and plano(posicion - copa).Magnitude < DISTANCIA_HOYO and rapidez < VELOCIDAD_MAXIMA_HOYO then
		cerrarHoyo(jugador, p, true)
		return
	end

	-- Detenida
	local quieta = enSuelo and p.vuelo == 0 and rapidez < UMBRAL_QUIETA and math.abs(velocidad.Y) < 3
	if quieta or os.clock() - p.inicioMovimiento > ESPERA_MAXIMA then
		detener(jugador, p, bola)
	end
end

RunService.Heartbeat:Connect(function(dt)
	for jugador, p in partidas do
		local bola = p.bola
		if bola and bola.Parent then
			actualizarBola(jugador, p, bola, dt)
			EfectosBola.animar(bola, p.estilo)
		end
	end
end)

-- Golpe ---------------------------------------------------------------------------

golpeRemoto.OnServerEvent:Connect(function(jugador, paloId, potencia, direccion)
	local p = partidas[jugador]
	local bola = p and p.bola
	if not bola or p.enMovimiento or p.esperando then
		return
	end
	if type(paloId) ~= "string" or type(potencia) ~= "number" or typeof(direccion) ~= "Vector3" then
		return
	end
	if potencia ~= potencia or direccion.X ~= direccion.X or direccion.Z ~= direccion.Z then
		return -- NaN
	end

	local palo = ConfigGolf.palo(paloId)
	if not palo then
		return
	end
	if not ConfigGolf.tiene(ConfigGolf.comprados(jugador:GetAttribute("GolfCosas")), palo) then
		avisar(jugador, "Ese palo se compra en la tienda de golf", false)
		return
	end
	potencia = math.clamp(potencia, 0, 1)
	if potencia < 0.05 then
		return
	end

	local horizontal = plano(direccion)
	if horizontal.Magnitude < 0.1 then
		return
	end
	horizontal = horizontal.Unit

	local ahora = os.clock()
	if p.ultimoGolpe and ahora - p.ultimoGolpe < ConfigGolf.ESPERA_GOLPE then
		return
	end

	local raiz = raizDe(jugador)
	if not raiz or (raiz.Position - bola.Position).Magnitude > ConfigGolf.DISTANCIA_MAXIMA then
		avisar(jugador, "Acercate a la pelota para pegarle", false)
		return
	end
	p.ultimoGolpe = ahora

	-- Desde el rough o un bunker sale con menos fuerza
	local superficie = ConfigGolf.superficie(bola:GetAttribute("Superficie"))
	local rapidez = palo.velocidad * potencia * (palo.ignoraTerreno and 1 or superficie.potencia)

	p.ultimaPos = bola.Position
	p.golpes += 1
	p.vuelo = palo.elevacion > 0 and 1 or 0
	empezarMovimiento(p, bola)
	bola.AssemblyAngularVelocity = Vector3.zero
	bola.AssemblyLinearVelocity = horizontal * rapidez + Vector3.new(0, rapidez * palo.elevacion, 0)
	jugador:SetAttribute("GolfGolpes", p.golpes)
end)

-- Empezar y salir -------------------------------------------------------------------

cancha.jugar.Triggered:Connect(function(jugador)
	if partidas[jugador] then
		avisar(jugador, "Ya estás jugando", false)
		return
	end
	if not jugador:GetAttribute("DatosCargados") or not raizDe(jugador) then
		avisar(jugador, "Todavía cargando, probá de nuevo", false)
		return
	end

	local p = { hoyo = 1, golpes = 0, total = 0, contador = 0 }
	partidas[jugador] = p
	colocarHoyo(jugador, p, 1)
end)

salirRemoto.OnServerEvent:Connect(function(jugador)
	local p = partidas[jugador]
	if p then
		cerrarPartida(jugador, p, true)
		avisar(jugador, "Saliste del golf", false)
	end
end)

local function alIrseOMorir(jugador)
	local p = partidas[jugador]
	if p then
		cerrarPartida(jugador, p, false)
	end
end

local function vigilar(jugador)
	jugador.CharacterRemoving:Connect(function()
		alIrseOMorir(jugador)
	end)
end

Players.PlayerAdded:Connect(vigilar)
for _, jugador in Players:GetPlayers() do
	vigilar(jugador)
end
Players.PlayerRemoving:Connect(alIrseOMorir)
