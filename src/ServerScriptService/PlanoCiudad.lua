-- Plano de la ciudad: donde van las calles. Lo usan Ciudad.server.lua para
-- construirla y JuegoMonedas.server.lua para poner monedas sobre las calles
-- (nunca adentro de un edificio).

local Plano = {}

Plano.LIMITE = 158 -- la ciudad llega hasta +-LIMITE; ahi hay una pared invisible
Plano.CALLES = { -150, -63, 63, 150 } -- centro de cada calle (iguales en X y en Z)
Plano.AVENIDA = 0 -- avenida central, solo fuera del parque
Plano.MEDIO_ANCHO_CALLE = 8 -- las calles miden 16 de ancho
Plano.ANILLO = 63 -- la calle que rodea al parque

-- Un punto al azar sobre alguna calle o avenida (y = 0).
-- azar: un Random. Deja un margen para que la moneda no quede en el cordon.
function Plano.puntoEnCalle(azar)
	local margen = Plano.MEDIO_ANCHO_CALLE - 2
	local limite = Plano.LIMITE - 4

	-- Las calles de la cuadricula pesan mas que las avenidas porque son mas largas
	local opciones = #Plano.CALLES * 2 + 4
	local eleccion = azar:NextInteger(1, opciones)
	local corrido = azar:NextNumber(-margen, margen)

	if eleccion <= #Plano.CALLES * 2 then
		local centro = Plano.CALLES[(eleccion - 1) % #Plano.CALLES + 1] + corrido
		local largo = azar:NextNumber(-limite, limite)
		if eleccion <= #Plano.CALLES then
			return Vector3.new(largo, 0, centro) -- calle a lo largo de X
		end
		return Vector3.new(centro, 0, largo) -- calle a lo largo de Z
	end

	-- Avenidas: desde la calle del parque hacia afuera, en las cuatro direcciones
	local desde = Plano.ANILLO + Plano.MEDIO_ANCHO_CALLE + 2
	local largo = azar:NextNumber(desde, limite) * (azar:NextInteger(0, 1) == 0 and -1 or 1)
	local centro = Plano.AVENIDA + corrido
	if eleccion % 2 == 0 then
		return Vector3.new(largo, 0, centro)
	end
	return Vector3.new(centro, 0, largo)
end

return Plano
