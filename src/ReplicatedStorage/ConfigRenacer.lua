-- Reglas de "Renacer" (prestigio). Las usan el servidor (validar y dar el bonus)
-- y el cliente (mostrar costo y bonus).
-- Renacer cuesta monedas, reinicia monedas y mejoras, y suma un bonus permanente.

local ConfigRenacer = {}

ConfigRenacer.COSTO_BASE = 2000
ConfigRenacer.BONUS_POR_NIVEL = 0.2 -- +20% de monedas por cada renacimiento

-- El primer renacimiento cuesta COSTO_BASE, el segundo el doble, etc.
function ConfigRenacer.costo(renacimientos)
	return ConfigRenacer.COSTO_BASE * (renacimientos + 1)
end

-- Multiplicador de monedas: 1 sin renacer, 1.2 con uno, 1.4 con dos...
function ConfigRenacer.multiplicador(renacimientos)
	return 1 + ConfigRenacer.BONUS_POR_NIVEL * renacimientos
end

return ConfigRenacer
