-- Alimentos que se compran en Lo De Lalo Pet Shop (dentro de la ciudad).
-- Alimentar a las mascotas multiplica por un rato el bonus de monedas que dan
-- las mascotas equipadas. Agregar un alimento = agregar una fila.
-- El efecto se guarda en atributos del jugador: AlimentoFactor y AlimentoHasta
-- (hora del servidor, Workspace:GetServerTimeNow()).

local Workspace = game:GetService("Workspace")

local ConfigAlimentos = {}

-- factor: el bonus de las mascotas se multiplica por esto. duracion en segundos.
ConfigAlimentos.Lista = {
	{ id = "Snack", nombre = "Snack", precio = 60, factor = 1.5, duracion = 60, color = Color3.fromRGB(240, 170, 60) },
	{ id = "Balanceado", nombre = "Alimento balanceado", precio = 200, factor = 2, duracion = 120, color = Color3.fromRGB(60, 140, 220) },
	{ id = "Premium", nombre = "Alimento premium", precio = 500, factor = 3, duracion = 180, color = Color3.fromRGB(200, 40, 60) },
}

local porId = {}
for _, alimento in ConfigAlimentos.Lista do
	porId[alimento.id] = alimento
end

function ConfigAlimentos.buscar(id)
	return porId[id]
end

-- Segundos que le quedan al efecto (0 si no hay)
function ConfigAlimentos.restante(jugador)
	local hasta = jugador:GetAttribute("AlimentoHasta") or 0
	return math.max(0, hasta - Workspace:GetServerTimeNow())
end

-- Por cuanto se multiplica ahora el bonus de las mascotas (1 sin alimento)
function ConfigAlimentos.factorActivo(jugador)
	if ConfigAlimentos.restante(jugador) <= 0 then
		return 1
	end
	return jugador:GetAttribute("AlimentoFactor") or 1
end

return ConfigAlimentos
