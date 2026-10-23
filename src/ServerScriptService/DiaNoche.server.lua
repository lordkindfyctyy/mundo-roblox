-- Ciclo de dia y noche. El dia (de 6 a 18) dura DURACION_DIA segundos y la noche
-- (de 18 a 6) DURACION_NOCHE, mas corta. De noche se prenden las partes con la
-- etiqueta "LuzDeNoche" (faroles de Ciudad.server.lua y faros de Autos.server.lua):
-- se ven como neon y se encienden sus luces. Workspace queda con el atributo
-- EsDeNoche por si otro script lo necesita.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local DURACION_DIA = 6 * 60
local DURACION_NOCHE = 3 * 60
local HORA_INICIO = 14 -- como arrancaba el mapa
local ANOCHECE = 18.5
local AMANECER = 6.2
local PASO = 0.1 -- cada cuanto se actualiza la hora (segundos)

-- Un poco de luz ambiente para que de noche se vea por donde se camina
Lighting.OutdoorAmbient = Color3.fromRGB(110, 110, 130)
Lighting.ClockTime = HORA_INICIO

local function prenderLuz(parte, prendida)
	parte.Material = prendida and Enum.Material.Neon or Enum.Material.SmoothPlastic
	for _, luz in parte:GetChildren() do
		if luz:IsA("Light") then
			luz.Enabled = prendida
		end
	end
end

local esDeNoche
local function actualizarLuces(noche)
	if noche == esDeNoche then
		return
	end
	esDeNoche = noche
	Workspace:SetAttribute("EsDeNoche", noche)
	for _, parte in CollectionService:GetTagged("LuzDeNoche") do
		prenderLuz(parte, noche)
	end
end

-- Las luces que aparecen despues (por ejemplo, si Ciudad termina de armarse mas tarde)
CollectionService:GetInstanceAddedSignal("LuzDeNoche"):Connect(function(parte)
	prenderLuz(parte, esDeNoche == true)
end)

local function deNoche(hora)
	return hora >= ANOCHECE or hora < AMANECER
end

actualizarLuces(deNoche(HORA_INICIO))

while true do
	local hora = Lighting.ClockTime
	-- 12 horas pasan en DURACION_DIA o DURACION_NOCHE segundos, segun que sea
	local duracion = (hora >= 6 and hora < 18) and DURACION_DIA or DURACION_NOCHE
	Lighting.ClockTime = (hora + 12 / duracion * PASO) % 24
	actualizarLuces(deNoche(Lighting.ClockTime))
	task.wait(PASO)
end
