-- Reglas de la recompensa diaria. Las usan el servidor (validar y pagar)
-- y el cliente (mostrar los premios de cada dia).
-- Los dias se cuentan en hora UTC: el reloj cambia de dia a las 00:00 UTC
-- (21:00 en Argentina), igual para todos los jugadores.

local ConfigRecompensa = {}

ConfigRecompensa.PREMIO_BASE = 50 -- monedas del dia 1 de la racha
ConfigRecompensa.DIAS_CICLO = 7 -- despues del dia 7 la racha sigue, pero el premio vuelve a empezar

-- Numero de dia desde 1970, a partir de un timestamp en segundos
function ConfigRecompensa.dia(ahora)
	return math.floor(ahora / 86400)
end

-- Premio segun cuantos dias seguidos lleva el jugador (racha 1 = primer dia)
function ConfigRecompensa.premio(racha)
	local posicion = (racha - 1) % ConfigRecompensa.DIAS_CICLO + 1
	return ConfigRecompensa.PREMIO_BASE * posicion
end

-- En que casillero del ciclo (1 a DIAS_CICLO) cae una racha
function ConfigRecompensa.posicion(racha)
	return (racha - 1) % ConfigRecompensa.DIAS_CICLO + 1
end

return ConfigRecompensa
