-- Guarda y carga las monedas de cada jugador con DataStore.
-- Necesita que el juego este publicado y, para probar en Studio,
-- activar Game Settings > Security > "Enable Studio Access to API Services".

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigGolf = require(ReplicatedStorage:WaitForChild("ConfigGolf"))

local ALMACEN = DataStoreService:GetDataStore("MundoRoblox_Monedas_v1")
local RANKING = DataStoreService:GetOrderedDataStore("MundoRoblox_Ranking_v1") -- lo lee Ranking.server.lua
local INTENTOS = 3
local AUTOGUARDADO = 60 -- segundos

-- Jugadores cuyos datos se cargaron bien. Si la carga fallo, no guardamos
-- para no pisar el progreso real con un 0.
local cargados = {}

-- Jugadores que se estan guardando ahora, y cuantos son. Sirve para dos cosas: no lanzar dos escrituras a la misma
-- clave a la vez (el autoguardado, la salida y el cierre del servidor pueden coincidir) y que el cierre espere a
-- que terminen todas en vez de cortar los guardados que siguen en curso.
local guardandose = {}
local guardadosEnCurso = 0
local ESPERA_MAXIMA_CIERRE = 25 -- segundos; el servidor da hasta 30 para BindToClose

local function conReintentos(funcion)
	local ok, resultado
	for intento = 1, INTENTOS do
		ok, resultado = pcall(funcion)
		if ok then
			return true, resultado
		end
		task.wait(intento) -- espera cada vez mas antes de reintentar
	end
	warn("DataStore fallo:", resultado)
	return false, resultado
end

local function cargar(jugador)
	local leaderstats = jugador:WaitForChild("leaderstats")
	local monedas = leaderstats:WaitForChild("Monedas")
	local total = leaderstats:WaitForChild("Total")
	local renacimientos = leaderstats:WaitForChild("Renacimientos")
	local logros = jugador:WaitForChild("Logros")
	local mascotas = jugador:WaitForChild("Mascotas")
	local mascotasEquipadas = jugador:WaitForChild("MascotasEquipadas")
	local mejoras = jugador:WaitForChild("Mejoras")

	local ok, guardado = conReintentos(function()
		return ALMACEN:GetAsync(tostring(jugador.UserId))
	end)

	if not jugador.Parent then
		return
	end
	-- En Studio sin "Enable Studio Access to API Services" la carga siempre falla: se juega
	-- igual con datos vacios, pero sin guardar (nada de lo de esta partida queda).
	local sinGuardar = false
	if not ok then
		if not RunService:IsStudio() then
			return
		end
		warn("DataStore no disponible en Studio: se juega sin guardar. Activa Game Settings > Security > Enable Studio Access to API Services")
		guardado = nil
		sinGuardar = true
	end

	-- Los datos viejos eran solo un numero (las monedas); los nuevos son una tabla
	if type(guardado) == "number" then
		guardado = { Monedas = guardado }
	end
	guardado = guardado or {}

	monedas.Value = guardado.Monedas or 0
	-- Quien jugaba antes del ranking no tiene Total: arranca con las monedas que ya tenia
	total.Value = guardado.Total or monedas.Value
	renacimientos.Value = guardado.Renacimientos or 0
	jugador:SetAttribute("UltimoDia", guardado.UltimoDia or 0)
	jugador:SetAttribute("Racha", guardado.Racha or 0)
	jugador:SetAttribute("Gigantes", guardado.Gigantes or 0)
	jugador:SetAttribute("Jefes", guardado.Jefes or 0) -- veces que derroto al Monstruo de Monedas (Jefe.server.lua)
	jugador:SetAttribute("HuevosHallados", guardado.HuevosHallados or "") -- busca huevos: ids separados por coma (Huevos.server.lua)
	-- Tienda de autos: lo comprado y lo que tiene puesto (TiendaAutos.server.lua)
	for _, atributo in { "AutoCosas", "AutoColor", "AutoRayas", "AutoRuedas", "AutoMotor" } do
		jugador:SetAttribute(atributo, guardado[atributo] or "")
	end
	-- Casa del Barrio y sus muebles (Casas.server.lua)
	jugador:SetAttribute("TieneCasa", guardado.TieneCasa == true)
	jugador:SetAttribute("Muebles", guardado.Muebles or "")
	-- Golf: recorridos terminados, mejor recorrido (menos golpes; 0 = ninguno) y hoyos en uno (Golf.server.lua)
	jugador:SetAttribute("GolfRondas", guardado.GolfRondas or 0)
	-- El mejor recorrido solo vale si se hizo con la cantidad de hoyos de ahora (antes eran 3)
	local mejorValido = (guardado.GolfMejorHoyos or 3) == #ConfigGolf.Hoyos
	jugador:SetAttribute("GolfMejor", mejorValido and guardado.GolfMejor or 0)
	jugador:SetAttribute("GolfHoyosEnUno", guardado.GolfHoyosEnUno or 0)
	-- Tienda de golf: palos y pelotas comprados, y la pelota que usa (TiendaGolf.server.lua)
	jugador:SetAttribute("GolfCosas", guardado.GolfCosas or "")
	jugador:SetAttribute("GolfBola", guardado.GolfBola or "")
	-- Pesca: cañas compradas, peces atrapados y total (Pesca.server.lua)
	jugador:SetAttribute("PescaCanas", guardado.PescaCanas or "")
	jugador:SetAttribute("PescaPeces", guardado.PescaPeces or "")
	jugador:SetAttribute("PescaTotal", guardado.PescaTotal or 0)
	-- Primero las que tiene y despues las equipadas, para que el modelo se arme una sola vez
	-- Cada mascota se guarda con su nivel (antes se guardaba true = nivel 1)
	for id, nivel in guardado.Mascotas or {} do
		local marca = Instance.new("BoolValue")
		marca.Name = id
		marca.Value = true
		if type(nivel) == "number" and nivel > 1 then
			marca:SetAttribute("Nivel", nivel)
		end
		marca.Parent = mascotas
	end
	for id in guardado.MascotasEquipadas or {} do
		local marca = Instance.new("BoolValue")
		marca.Name = id
		marca.Value = true
		marca.Parent = mascotasEquipadas
	end
	for id in guardado.Logros or {} do
		local desbloqueado = Instance.new("BoolValue")
		desbloqueado.Name = id
		desbloqueado.Value = true
		desbloqueado.Parent = logros
	end
	for _, nivel in mejoras:GetChildren() do
		nivel.Value = (guardado.Mejoras and guardado.Mejoras[nivel.Name]) or 0
	end
	if not sinGuardar then
		cargados[jugador] = true
	end
	jugador:SetAttribute("DatosCargados", true) -- Recompensa.server.lua y el cliente esperan esto
end

local function guardar(jugador)
	-- Si ya se esta guardando, se espera a que termine antes de escribir (nunca dos a la vez en la misma clave).
	-- Despues se revisa todo y se arma de nuevo: mientras tanto el jugador pudo comprar algo o irse, y lo ultimo
	-- tiene que quedar guardado.
	while guardandose[jugador] do
		task.wait(0.1)
	end

	if not cargados[jugador] then
		return
	end

	local leaderstats = jugador:FindFirstChild("leaderstats")
	local monedas = leaderstats and leaderstats:FindFirstChild("Monedas")
	local mejoras = jugador:FindFirstChild("Mejoras")
	if not monedas or not mejoras then
		return
	end

	local datos = {
		Monedas = monedas.Value,
		Total = leaderstats.Total.Value,
		Renacimientos = leaderstats.Renacimientos.Value,
		UltimoDia = jugador:GetAttribute("UltimoDia") or 0,
		Racha = jugador:GetAttribute("Racha") or 0,
		Gigantes = jugador:GetAttribute("Gigantes") or 0,
		Jefes = jugador:GetAttribute("Jefes") or 0,
		HuevosHallados = jugador:GetAttribute("HuevosHallados") or "",
		AutoCosas = jugador:GetAttribute("AutoCosas") or "",
		AutoColor = jugador:GetAttribute("AutoColor") or "",
		AutoRayas = jugador:GetAttribute("AutoRayas") or "",
		AutoRuedas = jugador:GetAttribute("AutoRuedas") or "",
		AutoMotor = jugador:GetAttribute("AutoMotor") or "",
		TieneCasa = jugador:GetAttribute("TieneCasa") == true,
		Muebles = jugador:GetAttribute("Muebles") or "",
		GolfRondas = jugador:GetAttribute("GolfRondas") or 0,
		GolfMejor = jugador:GetAttribute("GolfMejor") or 0,
		GolfMejorHoyos = #ConfigGolf.Hoyos,
		GolfHoyosEnUno = jugador:GetAttribute("GolfHoyosEnUno") or 0,
		GolfCosas = jugador:GetAttribute("GolfCosas") or "",
		GolfBola = jugador:GetAttribute("GolfBola") or "",
		PescaCanas = jugador:GetAttribute("PescaCanas") or "",
		PescaPeces = jugador:GetAttribute("PescaPeces") or "",
		PescaTotal = jugador:GetAttribute("PescaTotal") or 0,
		Logros = {},
		Mascotas = {},
		MascotasEquipadas = {},
		Mejoras = {},
	}
	for nombre, carpeta in { Mascotas = "Mascotas", MascotasEquipadas = "MascotasEquipadas" } do
		local origen = jugador:FindFirstChild(carpeta)
		if origen then
			for _, marca in origen:GetChildren() do
				-- Las que tiene se guardan con su nivel; las equipadas, solo la marca
				datos[nombre][marca.Name] = nombre == "Mascotas" and (marca:GetAttribute("Nivel") or 1) or true
			end
		end
	end
	local logros = jugador:FindFirstChild("Logros")
	if logros then
		for _, desbloqueado in logros:GetChildren() do
			datos.Logros[desbloqueado.Name] = true
		end
	end
	for _, nivel in mejoras:GetChildren() do
		datos.Mejoras[nivel.Name] = nivel.Value
	end

	-- Desde aca no hay nada que pueda fallar fuera de conReintentos (que usa pcall): el marcador siempre se libera.
	-- No hay ninguna pausa entre la espera de arriba y este marcador, asi que dos guardados no se cruzan.
	guardandose[jugador] = true
	guardadosEnCurso += 1
	conReintentos(function()
		ALMACEN:SetAsync(tostring(jugador.UserId), datos)
	end)
	conReintentos(function()
		RANKING:SetAsync(tostring(jugador.UserId), datos.Total)
	end)

	guardandose[jugador] = nil
	guardadosEnCurso -= 1
end

Players.PlayerAdded:Connect(cargar)
for _, jugador in Players:GetPlayers() do
	task.spawn(cargar, jugador)
end

Players.PlayerRemoving:Connect(function(jugador)
	guardar(jugador)
	cargados[jugador] = nil
end)

-- Al cerrar el servidor guardamos a todos los que quedan
game:BindToClose(function()
	if RunService:IsStudio() then
		task.wait(1)
	end
	for _, jugador in Players:GetPlayers() do
		task.spawn(guardar, jugador)
	end
	task.wait() -- deja que arranquen (los que se estan yendo ya empezaron en PlayerRemoving)
	-- Se espera a que TODOS terminen: cada uno hace dos escrituras con reintentos, y con pocos segundos fijos los
	-- ultimos se cortaban cuando el servidor se cerraba.
	local limite = os.clock() + ESPERA_MAXIMA_CIERRE
	while guardadosEnCurso > 0 and os.clock() < limite do
		task.wait(0.1)
	end
end)

-- Autoguardado periodico
task.spawn(function()
	while true do
		task.wait(AUTOGUARDADO)
		for _, jugador in Players:GetPlayers() do
			task.spawn(guardar, jugador)
		end
	end
end)
