-- El programa paralelo que se ejecuta con el programa principal puede establecer E/S, variables, etc., y no puede llamar a instrucciones de movimiento.
--*********************************************************************
-- ROBOT TYPE : #DOBOT CR 30H
-- FUNCTION   : INICIACIÓN DE VARIABLES
-- Work Type  : ATORNILLADO
-- Copyright  : GRUPRO SA
--            : EL TALAR, BUENOS AIRES ARGENTINA
-- MODULO PARA ADMINISTRAR EL ALIMENTADOR AUTOMÁTICO
--*********************************************************************
-- =================================================================
-- MÓDULO ALIMENTADOR AUTOMÁTICO CON HISTÉRESIS
-- =================================================================
-- Variable global que compartiremos con el hilo principal
local tornillos_en_rampa = 0
-- Variable local para recordar el estado físico del motor
local alimentador_activo = false


while true do
	while (DETENER_ALIMENTADOR == 1) do
		if alimentador_activo then
			DO(2, OFF)
			-- HL0_AL
			alimentador_activo = false
		end
		Wait(50)
		-- Vital para no bloquear el procesador del controlador
	end
	if (cuentaTornillo > 0) then
		tornillos_en_rampa = tornillos_en_rampa - cuentaTornillo
	end
	-- 2. Lectura simultánea de sensores
	presencia_tornillo_AL = DI(1)
	-- SQ1_AL1 (Sensor de salida)
	presencia_tornillo_ALS = DI(2)
	-- SQ2_AL2 (Sensor de tope / 4 tornillos)
	Wait(10)
	local rampa_llena = (DI(1) + DI(2))
	-- 3. Sincronización del contador con la realidad (Hardware)
	-- Si el sensor superior detecta material, sabemos con certeza que hay 4
	if rampa_llena == 2 then
		tornillos_en_rampa = 4
	end
	-- 4. LÓGICA DE HISTÉRESIS (Encendido y Apagado)
	-- A. Límite superior: Si la rampa se llenó (4), apagamos

if presencia_tornillo_AL == 1 then
		cont_reint_llen = 0
		-- Reseteamos los reintentos porque se llenó con éxito
		SetOutputBool(DO_Alim_VACIO, 0)
end

	if tornillos_en_rampa >= 4 and alimentador_activo then
		DO(2, OFF)
		-- HL0_AL
		alimentador_activo = false
		cont_reint_llen = 0
		-- Reseteamos los reintentos porque se llenó con éxito
		SetOutputBool(DO_Alim_VACIO, 0)
		-- Limpiamos la alarma si existía
	end
	-- B. Límite inferior: Si quedan 3 o menos (se extrajeron 3 de los 4), encendemos
	if tornillos_en_rampa <= 3 and not alimentador_activo then
		DO(2, ON)
		-- HL0_AL
		alimentador_activo = true
	end
	-- 5. Control de atascos o vacío (Opcional)
	-- Si el alimentador lleva mucho tiempo encendido y el sensor superior no se activa
	if alimentador_activo and presencia_tornillo_ALS == 0 then
		cont_reint_llen = cont_reint_llen + 1
		if cont_reint_llen > reintentos_llenado_cartucho then
			SetOutputBool(DO_Alim_VACIO, 1)
			-- Enviar alarma al PLC/Sistema
			DO(2, OFF)
			-- HL0_AL
			alimentador_activo = false
		end
	end
	-- Pausa para ceder recursos de procesamiento a los demás hilos
	Wait(1000)
end