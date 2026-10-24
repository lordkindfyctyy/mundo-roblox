-- Trabajos de la ciudad (Trabajos.server.lua). Se eligen en el puesto "TRABAJOS",
-- enfrente de la salida norte del parque. Cada trabajo se repite hasta que lo dejás:
--   Pizza: buscar la pizza en la Pizzería y llevarla a una dirección a tiempo
--   Bombero: llegar a un edificio que se incendia y apagarlo (mantener apretado)
--   Taxi: manejando un auto, levantar a un pasajero y llevarlo a donde pide
--
-- Pago de cada viaje: pagoBase + distancia * pagoPorStud. Si llegás antes de que
-- pase la mitad del tiempo, se multiplica por BONUS_RAPIDO.
-- Tiempo de cada viaje: segundosBase + distancia / studsPorSegundo.

local ConfigTrabajos = {}

ConfigTrabajos.BONUS_RAPIDO = 1.5
ConfigTrabajos.DISTANCIA_LLEGADA = 10 -- a esta distancia de un lugar ya se cuenta que llegaste
ConfigTrabajos.ESPERA_SIGUIENTE = 2 -- segundos entre un viaje y el siguiente

ConfigTrabajos.Lista = {
	{
		id = "Pizza",
		nombre = "Repartidor de pizza",
		emoji = "🍕",
		color = Color3.fromRGB(220, 60, 40), -- gorra y cartel
		pagoBase = 40,
		pagoPorStud = 0.4,
		segundosBase = 15,
		studsPorSegundo = 11, -- caminando se llega; en auto sobra
	},
	{
		id = "Bombero",
		nombre = "Bombero",
		emoji = "🚒",
		color = Color3.fromRGB(200, 30, 30),
		pagoBase = 60,
		pagoPorStud = 0.4,
		segundosBase = 20,
		studsPorSegundo = 11,
		segundosApagar = 2.5, -- cuanto hay que mantener apretado para apagar el fuego
	},
	{
		id = "Taxi",
		nombre = "Taxista",
		emoji = "🚕",
		color = Color3.fromRGB(255, 200, 0),
		pagoBase = 50,
		pagoPorStud = 0.6,
		segundosBase = 12,
		studsPorSegundo = 18, -- hay que ir en auto
	},
}

local porId = {}
for _, trabajo in ConfigTrabajos.Lista do
	porId[trabajo.id] = trabajo
end

function ConfigTrabajos.buscar(id)
	return porId[id]
end

-- Cuanto se cobra por un viaje de esa distancia (rapido = llego antes de la mitad del tiempo)
function ConfigTrabajos.pago(trabajo, distancia, rapido)
	local pago = trabajo.pagoBase + distancia * trabajo.pagoPorStud
	if rapido then
		pago *= ConfigTrabajos.BONUS_RAPIDO
	end
	return math.floor(pago + 0.5)
end

function ConfigTrabajos.tiempo(trabajo, distancia)
	return trabajo.segundosBase + distancia / trabajo.studsPorSegundo
end

return ConfigTrabajos
