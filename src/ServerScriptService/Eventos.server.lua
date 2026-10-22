-- Eventos aleatorios del juego: cada tanto se activa uno y dura unos segundos.
--   Hora dorada:       las monedas valen el doble.
--   Lluvia de monedas: caen monedas extra del cielo.
-- El evento activo se publica como atributos de Workspace (EventoNombre, EventoFin)
-- para que Anuncio.client.lua muestre el cartel, tambien a quien entra a mitad de evento.

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PRIMER_EVENTO = 30 -- segundos hasta el primer evento
local ESPERA_MIN = 90 -- segundos entre un evento y el siguiente
local ESPERA_MAX = 150

local crearMonedasExtra = ServerStorage:WaitForChild("CrearMonedasExtra")

local EVENTOS = {
	{
		nombre = "¡HORA DORADA! Monedas x2",
		duracion = 30,
		inicio = function()
			Workspace:SetAttribute("MultiplicadorEvento", 2)
		end,
		fin = function()
			Workspace:SetAttribute("MultiplicadorEvento", nil)
		end,
	},
	{
		nombre = "¡LLUVIA DE MONEDAS!",
		duracion = 25, -- coincide con DURACION_TEMPORAL de JuegoMonedas.server.lua
		inicio = function()
			crearMonedasExtra:Fire(40)
		end,
	},
}

local function correrEvento(evento)
	Workspace:SetAttribute("EventoNombre", evento.nombre)
	Workspace:SetAttribute("EventoFin", Workspace:GetServerTimeNow() + evento.duracion)
	evento.inicio()

	task.wait(evento.duracion)

	if evento.fin then
		evento.fin()
	end
	Workspace:SetAttribute("EventoNombre", nil)
	Workspace:SetAttribute("EventoFin", nil)
end

task.wait(PRIMER_EVENTO)
while true do
	correrEvento(EVENTOS[math.random(#EVENTOS)])
	task.wait(math.random(ESPERA_MIN, ESPERA_MAX))
end
