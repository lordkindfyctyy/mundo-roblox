-- Jefe gigante: cada tanto cae del cielo al parque del centro el Monstruo de Monedas.
-- Todos le pegan juntos tocandolo (clic o tap) antes de que se escape.
--   * Tiene mas vida cuantos mas jugadores hay en el servidor.
--   * Camina por el parque y cada tanto da un pisoton que empuja a los que estan cerca.
--   * Cada vez que pierde un cuarto de la vida larga monedas.
--   * Si lo derrotan, llueven monedas y cada uno que le pego cobra: un premio fijo
--     mas una parte del premio grande segun cuanto le pego.
-- El estado se publica en Workspace (JefeEstado, JefeVida, JefeVidaMax, JefeFin) para
-- que Jefe.client.lua muestre la barra de vida; cada jugador lleva su "DanioJefe".
-- Las veces que alguien lo derroto se guardan en el atributo "Jefes" (para los logros).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PRIMERA_VEZ = 90 -- segundos hasta que aparece la primera vez
local ESPERA_MIN = 420 -- segundos entre una aparicion y la siguiente
local ESPERA_MAX = 600
local AVISO_ANTES = 10 -- segundos de aviso antes de que caiga
local DURACION = 90 -- segundos que tienen para derrotarlo
local VIDA_POR_JUGADOR = 150
local ESPERA_GOLPE = 0.15 -- segundos minimos entre dos golpes del mismo jugador
local DISTANCIA_GOLPE = 60
local VELOCIDAD = 7
local RADIO_PASEO = 34 -- camina dentro del parque del centro (que va de -50 a 50)
local PISOTON_CADA = 7
local RADIO_PISOTON = 22
local GOLPES_MINIMOS = 3 -- para cobrar hay que haberle pegado al menos esto
local PREMIO_BASE = 100 -- para cada uno que le pego
local PREMIO_REPARTIDO = 400 -- se reparte segun cuanto le pego cada uno
local MONEDAS_POR_CUARTO = 6
local MONEDAS_AL_CAER = 30
local NOMBRE = "👹 Monstruo de Monedas"

if RunService:IsStudio() then
	PRIMERA_VEZ = 20 -- para probarlo sin esperar
end

local crearMonedasExtra = ServerStorage:WaitForChild("CrearMonedasExtra")

local empuje = Instance.new("RemoteEvent")
empuje.Name = "EmpujeJefe"
empuje.Parent = ReplicatedStorage

local aviso -- RemoteEvent AvisoTienda de Negocios.lua (cartelito abajo)
local function avisar(jugador, texto, ok)
	aviso = aviso or ReplicatedStorage:FindFirstChild("AvisoTienda")
	if aviso then
		aviso:FireClient(jugador, texto, ok)
	end
end

local function avisarATodos(texto, ok)
	for _, jugador in Players:GetPlayers() do
		avisar(jugador, texto, ok)
	end
end

local function monedasDe(jugador)
	local leaderstats = jugador:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Monedas")
end

---------------------------------------------------------------- El modelo

local DORADO = Color3.fromRGB(255, 195, 40)
local DORADO_OSCURO = Color3.fromRGB(205, 140, 20)
local NEGRO = Color3.fromRGB(30, 25, 25)
local BLANCO = Color3.fromRGB(250, 250, 250)
local ROJO = Color3.fromRGB(200, 40, 40)
local PARADO = CFrame.Angles(0, 0, math.rad(90)) -- los cilindros van a lo largo de X

-- Arma el monstruo con los pies en y = 0, mirando hacia -Z
local function crearMonstruo()
	local modelo = Instance.new("Model")
	modelo.Name = "MonstruoMonedas"

	local function parte(nombre, tamano, cframe, color, material, forma)
		local p = Instance.new("Part")
		p.Name = nombre
		p.Size = tamano
		p.CFrame = cframe
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Shape = forma or Enum.PartType.Block
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = true
		p.Parent = modelo
		return p
	end

	local raiz = parte("Raiz", Vector3.new(1, 1, 1), CFrame.new(), DORADO)
	raiz.Transparency = 1
	raiz.CanQuery = false
	modelo.PrimaryPart = raiz

	local cuerpo = parte("Cuerpo", Vector3.new(16, 16, 16), CFrame.new(0, 12, 0), DORADO, Enum.Material.Foil, Enum.PartType.Ball)

	-- Ojos enojados
	for _, lado in { -1, 1 } do
		parte("Ojo", Vector3.new(3.4, 3.4, 3.4), CFrame.new(3 * lado, 14, -6.9), BLANCO, nil, Enum.PartType.Ball)
		parte("Pupila", Vector3.new(1.6, 1.6, 1.6), CFrame.new(3 * lado, 14, -8.4), NEGRO, nil, Enum.PartType.Ball)
		-- La punta de adentro de la ceja va mas abajo
		parte("Ceja", Vector3.new(4.2, 0.8, 0.8), CFrame.new(3 * lado, 16.4, -7.6) * CFrame.Angles(0, 0, math.rad(-22 * lado)), NEGRO)
		-- Cuernos rojos, para afuera
		parte("Cuerno", Vector3.new(4.5, 1.6, 1.6), CFrame.new(5 * lado, 19.2, 0) * CFrame.Angles(0, 0, math.rad(35 * -lado)) * PARADO, ROJO, nil, Enum.PartType.Cylinder)
		-- Brazos, piernas y pies
		parte("Brazo", Vector3.new(4.4, 4.4, 4.4), CFrame.new(8.8 * lado, 10.5, -1), DORADO_OSCURO, Enum.Material.Foil, Enum.PartType.Ball)
		parte("Pierna", Vector3.new(5, 3.4, 3.4), CFrame.new(3.5 * lado, 3, 0) * PARADO, DORADO_OSCURO, Enum.Material.Foil, Enum.PartType.Cylinder)
		parte("Pie", Vector3.new(4, 1.4, 5.4), CFrame.new(3.5 * lado, 0.7, -0.7), DORADO_OSCURO, Enum.Material.Foil)
	end

	-- Boca con dientes
	parte("Boca", Vector3.new(7, 1.8, 1), CFrame.new(0, 9.6, -7.3), NEGRO)
	for i = -1, 1 do
		parte("Diente", Vector3.new(1, 0.9, 0.5), CFrame.new(i * 2.2, 10.1, -7.85), BLANCO)
	end

	-- Corona arriba de la cabeza
	parte("Corona", Vector3.new(2, 7, 7), CFrame.new(0, 20.3, 0) * PARADO, Color3.fromRGB(255, 225, 60), Enum.Material.Neon, Enum.PartType.Cylinder)
	for i = 0, 4 do
		local angulo = i / 5 * math.pi * 2
		parte("Punta", Vector3.new(1.4, 1.4, 1.4), CFrame.new(math.cos(angulo) * 2.8, 21.8, math.sin(angulo) * 2.8) * CFrame.Angles(math.rad(45), 0, math.rad(45)), Color3.fromRGB(255, 225, 60), Enum.Material.Neon)
	end

	local brillo = Instance.new("ParticleEmitter")
	brillo.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	brillo.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120))
	brillo.Size = NumberSequence.new(1.2)
	brillo.Rate = 12
	brillo.Lifetime = NumberRange.new(1, 1.6)
	brillo.Speed = NumberRange.new(2, 4)
	brillo.SpreadAngle = Vector2.new(180, 180)
	brillo.Parent = cuerpo

	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 210, 90)
	luz.Range = 24
	luz.Brightness = 1.5
	luz.Parent = cuerpo

	-- Se pone rojo un momento cuando le pegan
	local destello = Instance.new("Highlight")
	destello.FillColor = Color3.fromRGB(255, 60, 60)
	destello.FillTransparency = 0.4
	destello.OutlineTransparency = 1
	destello.Enabled = false
	destello.Parent = modelo

	-- Nombre y barra de vida arriba (se ve de lejos para encontrarlo)
	local cartel = Instance.new("BillboardGui")
	cartel.Name = "Cartel"
	cartel.Adornee = cuerpo
	cartel.Size = UDim2.fromOffset(240, 54)
	cartel.StudsOffset = Vector3.new(0, 13, 0)
	cartel.AlwaysOnTop = true
	cartel.MaxDistance = 600
	cartel.Parent = cuerpo

	local nombre = Instance.new("TextLabel")
	nombre.Size = UDim2.new(1, 0, 0, 26)
	nombre.BackgroundTransparency = 1
	nombre.Font = Enum.Font.FredokaOne
	nombre.TextSize = 24
	nombre.TextColor3 = Color3.fromRGB(255, 220, 60)
	nombre.TextStrokeTransparency = 0
	nombre.Text = NOMBRE
	nombre.Parent = cartel

	local fondo = Instance.new("Frame")
	fondo.Name = "Fondo"
	fondo.Position = UDim2.fromOffset(10, 32)
	fondo.Size = UDim2.new(1, -20, 0, 16)
	fondo.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	fondo.BorderSizePixel = 0
	fondo.Parent = cartel
	Instance.new("UICorner").Parent = fondo

	local barra = Instance.new("Frame")
	barra.Name = "Barra"
	barra.Size = UDim2.fromScale(1, 1)
	barra.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
	barra.BorderSizePixel = 0
	barra.Parent = fondo
	Instance.new("UICorner").Parent = barra

	local golpe = Instance.new("Sound")
	golpe.Name = "Golpe"
	golpe.SoundId = "rbxassetid://4612374807" -- el de la moneda dorada
	golpe.PlaybackSpeed = 0.6
	golpe.Volume = 0.6
	golpe.RollOffMaxDistance = 120
	golpe.Parent = cuerpo

	local clic = Instance.new("ClickDetector")
	clic.MaxActivationDistance = DISTANCIA_GOLPE
	clic.Parent = modelo

	return modelo, barra, destello, clic
end

---------------------------------------------------------------- Efectos

-- Un anillo que se agranda en el piso donde cae el pisoton
local function ondaExpansiva(centro)
	local anillo = Instance.new("Part")
	anillo.Name = "Onda"
	anillo.Shape = Enum.PartType.Cylinder
	anillo.Size = Vector3.new(0.3, 4, 4)
	anillo.CFrame = CFrame.new(centro.X, 0.6, centro.Z) * PARADO
	anillo.Color = Color3.fromRGB(255, 220, 90)
	anillo.Material = Enum.Material.Neon
	anillo.Transparency = 0.3
	anillo.Anchored = true
	anillo.CanCollide = false
	anillo.CanQuery = false
	anillo.Parent = Workspace

	task.spawn(function()
		local pasos = 15
		for i = 1, pasos do
			local f = i / pasos
			anillo.Size = Vector3.new(0.3, 4 + RADIO_PISOTON * 2 * f, 4 + RADIO_PISOTON * 2 * f)
			anillo.Transparency = 0.3 + 0.7 * f
			task.wait(0.03)
		end
		anillo:Destroy()
	end)
end

-- Empuja para afuera a los que estan cerca y en el piso
local function pisoton(centro)
	ondaExpansiva(centro)
	for _, jugador in Players:GetPlayers() do
		local personaje = jugador.Character
		local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
		if raiz then
			local diferencia = (raiz.Position - centro) * Vector3.new(1, 0, 1)
			if diferencia.Magnitude < RADIO_PISOTON and raiz.Position.Y < 14 then
				local direccion = diferencia.Magnitude > 0.1 and diferencia.Unit or Vector3.new(0, 0, 1)
				empuje:FireClient(jugador, direccion)
			end
		end
	end
end

---------------------------------------------------------------- La pelea

local function puntoAlAzar()
	local angulo = math.random() * math.pi * 2
	local distancia = math.sqrt(math.random()) * RADIO_PASEO
	return Vector3.new(math.cos(angulo) * distancia, 0, math.sin(angulo) * distancia)
end

local function publicar(estado, vida, vidaMax, fin)
	Workspace:SetAttribute("JefeEstado", estado)
	Workspace:SetAttribute("JefeVida", vida)
	Workspace:SetAttribute("JefeVidaMax", vidaMax)
	Workspace:SetAttribute("JefeFin", fin)
end

local function pagar(danio)
	local total = 0
	for _, golpes in danio do
		total += golpes
	end
	for jugador, golpes in danio do
		local monedas = monedasDe(jugador)
		if jugador.Parent and monedas and golpes >= GOLPES_MINIMOS then
			local premio = PREMIO_BASE + math.floor(PREMIO_REPARTIDO * golpes / total)
			monedas.Value += premio
			jugador:SetAttribute("Jefes", (jugador:GetAttribute("Jefes") or 0) + 1)
			avisar(jugador, string.format("¡Derrotaron al monstruo! Le pegaste %d veces: +%d monedas", golpes, premio), true)
		elseif jugador.Parent then
			avisar(jugador, "¡Derrotaron al monstruo! Pegale más la próxima para cobrar", false)
		end
	end
end

local function pelea()
	avisarATodos("👹 ¡Se acerca el Monstruo de Monedas al parque del centro!", true)
	publicar("llega", nil, nil, Workspace:GetServerTimeNow() + AVISO_ANTES)
	task.wait(AVISO_ANTES)

	local vidaMax = VIDA_POR_JUGADOR * math.max(1, #Players:GetPlayers())
	local vida = vidaMax
	local danio = {} -- jugador -> golpes
	local ultimoGolpe = {}
	local fin = Workspace:GetServerTimeNow() + DURACION
	local cuartosLargados = 0

	local modelo, barra, destello, clic = crearMonstruo()
	local posicion = puntoAlAzar()
	local mirando = CFrame.new()
	local altura = 120 -- cae del cielo
	modelo:PivotTo(CFrame.new(posicion + Vector3.new(0, altura, 0)))
	modelo.Parent = Workspace
	publicar("pelea", vida, vidaMax, fin)

	local destelloHasta = 0
	clic.MouseClick:Connect(function(jugador)
		if vida <= 0 or altura > 1 then
			return
		end
		local ahora = os.clock()
		if ultimoGolpe[jugador] and ahora - ultimoGolpe[jugador] < ESPERA_GOLPE then
			return
		end
		ultimoGolpe[jugador] = ahora
		vida -= 1
		danio[jugador] = (danio[jugador] or 0) + 1
		jugador:SetAttribute("DanioJefe", danio[jugador])
		Workspace:SetAttribute("JefeVida", vida)
		barra.Size = UDim2.fromScale(vida / vidaMax, 1)
		destelloHasta = ahora + 0.1
		local golpe = modelo:FindFirstChild("Cuerpo") and modelo.Cuerpo:FindFirstChild("Golpe")
		if golpe then
			golpe:Play()
		end

		-- Cada cuarto de vida que pierde larga monedas
		local cuartos = math.floor((1 - vida / vidaMax) * 4)
		if cuartos > cuartosLargados and vida > 0 then
			cuartosLargados = cuartos
			crearMonedasExtra:Fire(MONEDAS_POR_CUARTO)
		end
	end)

	-- Cae del cielo
	local cayendo = 0
	while cayendo < 1.2 do
		cayendo += RunService.Heartbeat:Wait()
		altura = 120 * (1 - math.min(cayendo / 1.2, 1)) ^ 2
		modelo:PivotTo(CFrame.new(posicion + Vector3.new(0, altura, 0)))
	end
	altura = 0
	pisoton(posicion)

	-- Camina y da pisotones hasta que lo derrotan o se acaba el tiempo
	local objetivo = puntoAlAzar()
	local proximoPisoton = os.clock() + PISOTON_CADA
	local saltando = nil -- os.clock() en que empezo el salto del pisoton
	local reloj = 0
	while vida > 0 and Workspace:GetServerTimeNow() < fin do
		local dt = RunService.Heartbeat:Wait()
		reloj += dt
		destello.Enabled = os.clock() < destelloHasta

		local balanceo = 0
		if saltando then
			local f = (os.clock() - saltando) / 0.8
			if f >= 1 then
				saltando = nil
				altura = 0
				pisoton(posicion)
				proximoPisoton = os.clock() + PISOTON_CADA
			else
				altura = math.sin(f * math.pi) * 9
			end
		else
			local hacia = (objetivo - posicion) * Vector3.new(1, 0, 1)
			if hacia.Magnitude < 2 then
				objetivo = puntoAlAzar()
			else
				posicion += hacia.Unit * math.min(VELOCIDAD * dt, hacia.Magnitude)
				mirando = CFrame.lookAt(Vector3.zero, hacia.Unit)
			end
			altura = math.abs(math.sin(reloj * 5)) * 0.8 -- pasitos
			balanceo = math.sin(reloj * 5) * math.rad(5)
			if os.clock() >= proximoPisoton then
				saltando = os.clock()
			end
		end

		modelo:PivotTo(CFrame.new(posicion + Vector3.new(0, altura, 0)) * mirando * CFrame.Angles(0, 0, balanceo))
	end

	for jugador in danio do
		if jugador.Parent then
			jugador:SetAttribute("DanioJefe", nil)
		end
	end

	if vida <= 0 then
		-- Derrotado: gira, se achica y llueven monedas
		publicar("derrotado", 0, vidaMax, nil)
		destello.Enabled = false
		local centro = modelo:GetPivot()
		for i = 1, 30 do
			modelo:ScaleTo(math.max(1 - i / 30, 0.05))
			modelo:PivotTo(centro * CFrame.Angles(0, i * 0.4, 0))
			task.wait(0.03)
		end
		modelo:Destroy()
		pagar(danio)
		crearMonedasExtra:Fire(MONEDAS_AL_CAER)
	else
		-- Se escapa saltando para arriba
		publicar("escapa", vida, vidaMax, nil)
		avisarATodos("👹 ¡El Monstruo de Monedas se escapó! La próxima vez peguenle más rápido", false)
		local centro = modelo:GetPivot()
		for i = 1, 40 do
			modelo:PivotTo(centro + Vector3.new(0, i * i * 0.1, 0))
			task.wait(0.03)
		end
		modelo:Destroy()
	end

	task.wait(3)
	publicar(nil, nil, nil, nil)
end

Players.PlayerRemoving:Connect(function(jugador)
	jugador:SetAttribute("DanioJefe", nil)
end)

task.wait(PRIMERA_VEZ)
while true do
	local ok, error = pcall(pelea)
	if not ok then
		warn("Jefe: " .. tostring(error))
		publicar(nil, nil, nil, nil)
		local quedo = Workspace:FindFirstChild("MonstruoMonedas")
		if quedo then
			quedo:Destroy()
		end
	end
	task.wait(math.random(ESPERA_MIN, ESPERA_MAX))
end
