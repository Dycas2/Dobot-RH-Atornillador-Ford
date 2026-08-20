-- Version: Lua 5.4.4
-- Este hilo es el hilo principal, se pueden ejecutar cualquier tipo de instrucciones
-- Version: Lua 5.4.4
-- Este hilo es el hilo principal, se pueden ejecutar cualquier tipo de instrucciones
-- *********************************************************************
-- ROBOT TYPE : #DOBOT CR 30HT
-- FUNCTION   : INICIACIÓN DE VARIABLES
-- Work Type  : ATORNILLADO
-- Copyright  : GRUPRO SA
--            : EL TALAR, BUENOS AIRES ARGENTINA
-- *********************************************************************
-- ********** LIMPIAR TODAS LAS VARIABLES ***********
-- SE MANTIENEN COORDINADOS LOS PUNTOS GLOBALES Y LOCALES
-- PARA TODAS LA RUTINAS
-- SOLICITA INICIAR LA CONEXIÓN CON EL PLC
conectar_PLC = 1
while (conexion_OK ~= 1) do
	print("ESPERANDO CONEXIÓN CON EL PLC.")
	Wait(150)
end
-- CONEXION CON PLC OK
tornilloMalo = false
torqueOK = false
-- EN EL CASO QUE FALLE UN TORQUE, REINTENTA 3 VECES

-----------------------------------------------------------------------------------------

--					FUNCION CAMBIO JOB CAMARA

-----------------------------------------------------------------------------------------

function Cambio_Job_Camara(Num_Job)
 Wait(500)
		local Resultado=false						-- Variable que solo sirve para retornar un cambio de job realizado
		local N_Job = Num_Job
		local err, socket_job = TCPCreate(false, camera_ip, camera_port)    -- 2. Creamos y definimos socket a conectar con la cámara VIA USUARIO TCP/ETHERNET
		-------------------------------LOGICA CAMBIO JOBS CAMARA--------------------------------------
		if err ~= 0 then
		
			print('ERROR: No se pudo crear el socket TCP.')
			
		end

		err = TCPStart(socket_job, 10)
		if err ~= 0 then
			print('ERROR: No se pudo conectar a la cámara.')
			TCPDestroy(socket_job)
			
		end
		print('Conectado con éxito. Disparando cámara...')

		if 	   N_Job == 1  then
		
			local write_err = TCPWrite(socket_job, 'CJB001\r\n') -- DISPARA EL JOB CAM NUMERO 1
			if write_err ~= 0 then
				print('ERROR_CAMARA: Fallo en seteo de JOB CAM Nº1')
				TCPDestroy(socket_job)
				Resultado = false
			else
				print('ERROR_CAMARA: Fallo en seteo de JOB CAM Nº1')
				JOB_ACTUAL = N_Job
				resultado = true
			end
			
		elseif N_Job == 2 then
		
			local write_err = TCPWrite(socket_job, 'CJB002\r\n') -- DISPARA EL JOB CAM NUMERO 1
			if write_err ~= 0 then
				print('ERROR_CAMARA: Fallo en seteo de JOB CAM Nº2')
				TCPDestroy(socket_job)
				Resultado = false
			else
				JOB_ACTUAL= N_Job
				Resultado = true
			end
		elseif N_Job == 3 then
			local write_err = TCPWrite(socket_job, 'CJB003\r\n') -- DISPARA EL JOB CAM NUMERO 1
			if write_err ~= 0 then
				print('ERROR_CAMARA: Fallo en seteo de JOB CAM Nº3')
				TCPDestroy(socket_job)
				Resultado = false
			else
				JOB_ACTUAL = N_Job
				resultado = true
			end
		else 
			print("NUMERO DE JOB SELECCIONADO FUERA DE RANGO")
			TCPDestroy(socket_job)
			Resultado = false
			-- LE DAMOS FIN DE CANAL/COMUNICACIÓN DEL SOCKET
		end
		print(string.format("AMBIO DE JOB REALIZADO, JOB CAM ACTUAL = ",JOB_ACTUAL))
		TCPDestroy(socket_job)
		return Resultado 				-- ENVIAMOS EL RESULTADO DEL CAMBIO DE JOB (VERDAD SI FUE EFECTUADO)
		-------------------------------LOGICA CAMBIO JOBS CAMARA--------------------------------------
	end


-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------

--							FUNCION DE SACAR FOTOS

-----------------------------------------------------------------------------------------

function Sacar_foto(Num_punto)

	local Num_foto = Num_punto
	local data_raw 
	local pose_variables = {}
	local a = true
--	local fallo_disparo = false
	
	if Num_foto == JOB_ACTUAL then -- REBUNDANCIA que nos asegura que el JOB ACTUAL PERTENECE AL PUNTO DE FOTO DEL TORNILLO
		
		local err, socket_camera = TCPCreate(false, camera_ip, camera_port)
		if err ~= 0 then
			print('ERROR: No se pudo crear el socket TCP.')
		end

		err = TCPStart(socket_camera, 10)
		if err ~= 0 then
			print('ERROR: No se pudo conectar a la cámara.')
			TCPDestroy(socket_camera)
		end

		print('Conectado con éxito. Disparando cámara...')

		local write_err = TCPWrite(socket_camera, 'TRX000\r\n') 
		if write_err ~= 0 then
		
			print('ERROR: Fallo al enviar disparo.')
			TCPDestroy(socket_camera)
		--	fallo_disparo = true
		end

		-- 4. Leer respuesta de la cámara
		local read_err, response = TCPRead(socket_camera, timeout, 'string')
		Wait(30)
		TCPDestroy(socket_camera) -- Cerramos el socket inmediatamente para liberar el puerto

		if read_err ~= 0 or response == nil or response == '' then
			print('ERROR: Fallo al leer datos de la cámara.')
			Var_Delt_X = 0
			Var_Delt_Y = 0
			Var_Delt_Z = 0
		else
			print('[RAW RECIBIDO]: ' .. response)
			local i=0
			for match in string.gmatch(response, "[^_]+") do
				table.insert(pose_variables, match)
				i=i+1
			end
			print("Numero de vueltas", i)
			
			local volatile_DX= pose_variables[7]
			local volatile_DY= pose_variables[8]
			local volatile_DZ= pose_variables[9]
				
			if volatile_DX ~= nil then
				Var_Delt_X = tonumber(volatile_DX)/1000
				print('Offset X detectado: ' ..Var_Delt_X.. ' mm')
			else
				Var_Delt_X=0
				print('Aviso: No se detectó offset en X (se asume 0 mm)')
			end
			if volatile_DY ~= nil then
				Var_Delt_Y = tonumber(volatile_DY) / 1000
				print('Offset Y detectado: ' ..Var_Delt_Y..'mm')
			else
				Var_Delt_Y=0
				print('Aviso: No se detectó offset en Y (se asume 0 mm)')
			end
			if volatile_DZ ~= nil then
				Var_Delt_Z = tonumber(volatile_DZ) / 1000
				print('Offset Z detectado: ' ..Var_Delt_Z.. ' mm')
			else
				Var_Delt_Z=0
				print('Aviso: No se detectó offset en z (se asume 0 mm)')
			end				
			Camara_Disparada=true	-- GRABAMOS ESTA VARIABLE DE SEGURIDAD QUE ENCLAVA LA CAMARA PARA NUNCA SER DISPARA DOS VECES	
		end
	else

		print("FALLA GENERAL COMUNICACIÓN CAMARA")
	
	end
	
end 


-------------------------------------------------------------------------------------------------------------
function verificarTorque()
	local tor_OK = GetInputBool(DI_TorqueAT_OK)
	Wait(200)
	print(string.format("RESULTADO TORQUE: %d", tor_OK))
	if tor_OK == 0 then
		--TORQUE MALO
		return true
	else
		-- TORQUE BUENO
		return false
	end
end

-- LUEGO DE UN TORQUENO NOK. VERIFICA SI QUEDO UN TORNILLO EN LA BOCALLAVE

function verificarTornillo(ntornillo)
	MovJ(P1, {user = 0, tool = 1, a = 100, cp = 100, v = 100})
	-- P_ENTRADA
	MovJ(P9, {user = 0, tool = 1, a = 100, cp = 100, v = 100})
	-- P_prebocallave
	MovJ(P8, {user = 0, tool = 1, a = 50, cp = 0, v = 100})
	-- P_bocallave SENSA PRESENCIA DE TORNILLO EN BOCALLAVE
	presencia_tornillo_boca = DI(3)
	Wait(150)
	if presencia_tornillo_boca == ON then
		SetGlobalVariable("TORNILLO_TOMADO", 1)
		-- P_prebocallave
		MovJ(P8, {v = 100, a = 100, cp = 0, tool = 1, user = 0})
		-- P_bocallave
		MovJ(P9, {v = 100, a = 100, cp = 100, tool = 1, user = 0})
		MovJ(P1, {v = 100, a = 100, cp = 100, tool = 1, user = 0})
		-- SE QUEDA ESPERANDO QUE EL OPERARIO RETIRE EL TORNILLO DE LA BOCALLAVE
		-- PORQUE DIO RESULTADO TORQUE MAL. SE PRESUPONE TORNILLO SIN ROSCA O MALO
		offAT()
		setTask(DO_Task30)
		-- ESPERA QUE SAQUEN TORNILLO DE BCALLAVE
		Popup("RETIRAR TORNILLO DE BOCALLAVE", "prompt", 0, 0)
		waitTask(DI_Task30)
		--Reset dido retirar tornillo
		resetTask(DO_Task30)
		SetOutputBool(DO_ALARMA_TORQUE, 0)
		SetGlobalVariable("TORNILLO_TOMADO", 0)
	else
		-- SI NO SE DETECTÓ PRESENCIA DE TORNILLOS EN BOCALLAVE
		-- SE PASA AL SIGUIENTE ATORNILLADO. SE ASUME QUE EL ROBOT NO TOMO EL TORNILLO
		MovJ(P9, {v = 100, a = 100, tool = 1, cp = 100, user = 0})
		-- P_prebocallave
		--MovJ(P1, {v = 100, a = 100, cp = 100, tool = 1, user = 0})
		SetGlobalVariable("cuentaTornillo", cuenta_tornillo)
		SetGlobalVariable("TORNILLO_TOMADO", 0)
	end
	return
end

-- SEGÚN EL CICLO DISPARA LOS ATORNILLADOS

function tomaTornillo()
  		-- *********************************************************************
		-- VERIFICA PRESENCIA DE TORNILLO EN ALIMENTADOR AUTOMÁTICO
		-- *********************************************************************
		presencia_tornillo_AL = DI(1)
		Wait(150)
		if presencia_tornillo_AL == 1 and TORNILLO_TOMADO ~= 1 then
            DETENER_ALIMENTADOR = 1
			-- EJECUTAR TOMA DE TORNILLO ALIMENTADOR AUTOMÁTICO
			setTask(DO_Task10)
			-- LE AVISA EL PLC QUE ESTAMOS EN ZONA DE TOMA DE TORNILLO
			-- Nos vamos a prebocallave
			MovJ(P9, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
			-- SALIDA_AL
			local p_aproxL = RelPointTool(P19, {0, 0, -100})
			-- PUNTO DE TOMA LEJAJO
			local p_aproxC = RelPointTool(P19, {0, 0, -65})
			-- PUNTO DE TOMA CERCANO
				MovL(p_aproxC, {v = 80, a = 100, tool = 1, user = 0, cp = 50})
				SetOutputBool(DO_Reversa_AT, 1)
				-- ENCIENTE ATORNILLADOR REVERSA
				MovL(P19, {v = 1, a = 1, tool = 1, user = 0})
				Wait(200)
				-- PUNTO DE TOMA
				offAT()
				-- APAGA ATORNILLADOR
				MovL(p_aproxC, {v = 100, a = 100, tool = 1, user = 0})
				MovL(P8, {v = 90, a = 100, tool = 1, user = 0, cp = 0})
				--Posicion check presencia de tornillo
				Wait(100)
				presencia_tornillo_boca = DI(3)
				-- SQ3_Presencia en Bocallave
				Wait(20)
				SetGlobalVariable("TORNILLO_TOMADO", 1)
				-- SI LLEGÓ A ESTE PUNTO Y LA PRESENCIA DE TORNILLOS ESTÁ ENCENDIDA
				-- VERIFICAMOS SI TIENE TORNILLO EN BOCALLAVE
				if presencia_tornillo_boca == 0 then
					SetGlobalVariable("TORNILLO_TOMADO", 0)
					MovL(p_aproxC, {v = 50, a = 100, tool = 1, user = 0, cp = 50})
					SetOutputBool(DO_Reversa_AT, 1)
					-- ENCIENTE ATORNILLADOR REVERSA
					MovL(P19, {v = 1, a = 1, tool = 1, user = 0})
					offAT()
					MovL(p_aproxC, {v = 100, a = 100, tool = 1, user = 0})
					MovL(P8, {v = 90, a = 100, tool = 1, user = 0, cp = 0})
					Wait(100)
					presencia_tornillo_boca = DI(3)
					-- SQ3_Presencia en Bocallave
					presencia_tornillo_AL = DI(1)
					if presencia_tornillo_boca == ON then
						SetGlobalVariable("TORNILLO_TOMADO", 1)
						MovJ(P9, {v = 100, a = 100, tool = 1, user = 0, cp = 40})
						-- P_prebocallave
					else
						MovJ(P9, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
						-- P_prebocallave
					end
				end
			-- ESPERA QUE OTRO TORNILLO OCUPE EL LUGAR DEL QUE SALIÓ
			MovJ(P1, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
			-- SALIDA_HOME_POS
			resetTask(DO_Task10)
			-- LE AVISA EL PLC QUE SALIMOS DE ZONA DE TOMA DE TORNILLO
	return
end
end


function colocarTornillo(ntornillo)
	-- CICLO 1 CABINA DOBLE 3 TORNILLOS
	if CYCLE_CODE == 1 then
		if ntornillo == 0 then
			tor1RC(ntornillo)
		elseif ntornillo == 1 then
			tor2RC(ntornillo)
		elseif ntornillo == 2 then
			tor3RC(ntornillo)
		end
		-- CICLO 2 CABINA SIMPLE 3 TORNILLOS
	elseif CYCLE_CODE == 2 then
		if ntornillo == 0 then
			tor1CC(ntornillo)
		elseif ntornillo == 1 then
			tor2CC(ntornillo)
		elseif ntornillo == 2 then
			tor3CC(ntornillo)
		end
	end
end

function tor1RC(ntornillo)
	MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	if CAMARA_ACTIVA == true then
		MovJ(P49, {user = 0, tool = 1, a = 100, v = 100, cp = 0}) -- Punto de Foto
		Cambio_Job_Camara(1)
		Wait(600)
		Sacar_foto(1)  
		--Movimientos de APROXIMACION
		local t1rc_correjido = RelPointUser(P30,{0,-Var_Delt_Z,Var_Delt_Y})
		local t1rc_final = RelPointUser(P11,{0,-Var_Delt_Z,Var_Delt_Y})
		local t1rc_aprox = RelPointTool(t1rc_final, {0, 0, -40})	
		local t1rc_salida = RelPointTool(t1rc_final, {0, 0, -60})
		---------------------------------------------------------
		-- P15 TORNILLO 3
		MovJ(t1rc_correjido, {v = 90, a = 100, tool = 1, user = 0, cp = 100})
		MovL(t1rc_aprox, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		-- POS INICIAL ATORNILLADO
		onAT()
		-- ENCENDER EL ATORNILLADOR()
		MovL(t1rc_final, {v = speedBolt, a = 100, tool = 1, user = 0})
		-- POS FINAL ATORNILLADO
		Wait(1000)
		offAT()
		-- APAGAR EL ATORNILLADOR()
		local tornilloMalo = verificarTorque()
		MovL(t1rc_salida, {v = 50, a = 100, tool = 1, user = 0})
		MovJ(t1rc_correjido, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		SetGlobalVariable("TORNILLO_TOMADO", 0)
		
			if tornilloMalo == true then
				-- AGREGAR LÓGICA PARA SENSAR PRECENCIA DE TORNILLO EN BOCALLAVE. POSIBLE TORNILLO SIN ROSCA
				verificarTornillo(ntornillo)
			end
		
		-- RESETEAMOS LAS VARIABLES GLOBALES USADAS EN EL PROCESO PARA ELIMINAR FALSOS VALORES FUTUROS
		Var_Delt_X = 0
		Var_Delt_Y = 0
		Var_Delt_Z = 0

	else
	
		-- TRAYECTORIA COLOCACIÓN TORNILLO 1
		MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		MovJ(P30, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		local t1 = RelPointTool(P11, {0, 0, -40})
		-- P15 TORNILLO 3
		MovJ(t1, {v = 90, a = 100, tool = 1, user = 0, cp = 100})
		-- POS INICIAL ATORNILLADO
		onAT()
		-- ENCENDER EL ATORNILLADOR()
		MovL(P11, {v = speedBolt, a = 100, tool = 1, user = 0})
		-- POS FINAL ATORNILLADO
		Wait(1000)
		offAT()
		-- APAGAR EL ATORNILLADOR()
		tornilloMalo = verificarTorque()
		t1 = RelPointTool(P11, {0, 0, -10})
		MovL(t1, {v = 50, a = 100, tool = 1, user = 0})
		MovJ(P30, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		SetGlobalVariable("TORNILLO_TOMADO", 0)
		if tornilloMalo == true then
			-- AGREGAR LÓGICA PARA SENSAR PRECENCIA DE TORNILLO EN BOCALLAVE. POSIBLE TORNILLO SIN ROSCA
			verificarTornillo(ntornillo)
		end
	end
end

function tor2RC(ntornillo)

	if CAMARA_ACTIVA == true then
MovJ(P45, {user = 0, tool = 1, a = 100, v = 100, cp = 0}) -- Punto de Foto
		Cambio_Job_Camara(2)
		Wait(1000)
		Sacar_foto(2) 
		--local t2rc_correjido = RelPointUser(P31,{0,Var_Delt_Y,Var_Delt_Z})
		local t2rc_correjido = RelPointUser(P31,{0,Var_Delt_Z,Var_Delt_Y})
		local t2rc_final = RelPointUser(P12,{0,Var_Delt_Z,Var_Delt_Y})		-- Posicion (OFFSETS!!) referida a la roto-translacion de los planos!!
		--local t2rc_final = RelPointUser(P12,{0,Var_Delt_Y,Var_Delt_Z}) 		-- Al cambiar los planos, la matriz/terna queda asi referida a la terna madre/mundo!!
		local t2rc_aprox = RelPointTool(t2rc_final, {0, 0, -40})		
		local t2rc_salida = RelPointTool(t2rc_final, {0, 0, -10})

		-- P15 TORNILLO 3
		MovJ(t2rc_correjido, {v = 90, a = 100, tool = 1, user = 0, cp = 100})
		MovJ(t2rc_aprox, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		-- POS INICIAL ATORNILLADO
		onAT()
		-- ENCENDER EL ATORNILLADOR()
		MovL(t2rc_final, {v = speedBolt, a = 100, tool = 1, user = 0})
		-- POS FINAL ATORNILLADO
		Wait(500)
		offAT()
		-- APAGAR EL ATORNILLADOR()
		local tornilloMalo = verificarTorque()
		MovL(t2rc_salida, {v = 50, a = 100, tool = 1, user = 0})
		MovJ(t2rc_correjido, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		SetGlobalVariable("TORNILLO_TOMADO", 0)
		
		if tornilloMalo == true then
			-- AGREGAR LÓGICA PARA SENSAR PRECENCIA DE TORNILLO EN BOCALLAVE. POSIBLE TORNILLO SIN ROSCA
			verificarTornillo(ntornillo)
		end
		
		-- RESETEAMOS LAS VARIABLES GLOBALES USADAS EN EL PROCESO PARA ELIMINAR FALSOS VALORES FUTUROS
		Var_Delt_X = 0
		Var_Delt_Y = 0
		Var_Delt_Z = 0
		
	else
		--TRAYECTORIA COLOCACION TORNILLO 2
		MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		MovJ(P31, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		local t2 = RelPointTool(P12, {0, 0, -40})
		MovJ(t2, {v = 90, a = 100, tool = 1, user = 0, cp = 100})
		-- POS INICIAL ATORNILLADO
		onAT()
		-- ENCENDER EL ATORNILLADOR()
		MovL(P12, {v = speedBolt, a = 100, tool = 1, user = 0})
		-- POS FINAL ATORNILLADO
		Wait(500)
		offAT()
		tornilloMalo = verificarTorque()
		-- APAGAR EL ATORNILLADOR()
		t2 = RelPointTool(P12, {0, 0, -10})
		MovL(t2, {v = 50, a = 10, tool = 1, user = 0})
		MovJ(P31, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		SetGlobalVariable("TORNILLO_TOMADO", 0)
		if tornilloMalo == true then
			-- AGREGAR LÓGICA PARA SENSAR PRECENCIA DE TORNILLO EN BOCALLAVE. POSIBLE TORNILLO SIN ROSCA
			verificarTornillo(ntornillo)
		end
	end
end

function tor3RC(ntornillo)

	MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})

	if CAMARA_ACTIVA == true then

	MovJ(P60, {user = 0, tool = 1, a = 100, v = 100, cp = 0}) -- Punto de Foto
	Cambio_Job_Camara(3)
    Wait(1000)
	Sacar_foto(3)

	local t3rc_correjido = RelPointUser(P32,{0,Var_Delt_Z,Var_Delt_Y})
	
	local t3rc_final = RelPointUser(P16,{0,Var_Delt_Z,Var_Delt_Y})
	
	local t3rc_aprox = RelPointTool(t3rc_final, {0, 0, -40})
	
	local t3rc_salida = RelPointTool(t3rc_final, {0, 0, -60})
	 
	-- P15 TORNILLO 3
	MovJ(t3rc_correjido, {v = 90, a = 100, tool = 1, user = 0, cp = 100})
	MovJ(t3rc_aprox, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	-- POS INICIAL ATORNILLADO
	onAT()
	-- ENCENDER EL ATORNILLADOR()
	MovL(t3rc_final, {v = speedBolt, a = 100, tool = 1, user = 0})
	-- POS FINAL ATORNILLADO
	Wait(1000)
	offAT()
	-- APAGAR EL ATORNILLADOR()
	local tornilloMalo = verificarTorque()
	MovL(t3rc_salida, {v = 50, a = 100, tool = 1, user = 0})
	
	MovJ(t3rc_correjido, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	setTask(DO_Task11)
	Wait(200)
	SetGlobalVariable("TORNILLO_TOMADO", 0)
	resetTask(DO_Task11)
		if tornilloMalo == true then
			-- AGREGAR LÓGICA PARA SENSAR PRECENCIA DE TORNILLO EN BOCALLAVE. POSIBLE TORNILLO SIN ROSCA
			verificarTornillo()
		end	


	else
		-- PUNTO PREVIO A SENSADO
		MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		MovJ(P32, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		local t3 = RelPointTool(P16, {0, 0, -40})
		-- P16 TORNILLO 3
		MovJ(t3, {v = 90, a = 100, tool = 1, user = 0})
		-- POS INICIAL ATORNILLADO
		onAT()
		-- ENCENDER EL ATORNILLADOR
		MovL(P16, {v = speedBolt, a = 100, tool = 1, user = 0})
		-- POS FINAL ATORNILLADO
		Wait(1000)
		offAT()
		-- APAGAR EL ATORNILLADOR()
		tornilloMalo = verificarTorque()
		MovJ(P32, {user = 0, tool = 1, a = 100, v = 100, cp = 50})
		MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
		setTask(DO_Task11)
		Wait(200)
		SetGlobalVariable("TORNILLO_TOMADO", 0)
		resetTask(DO_Task11)
		if tornilloMalo == true then
			-- AGREGAR LÓGICA PARA SENSAR PRECENCIA DE TORNILLO EN BOCALLAVE. POSIBLE TORNILLO SIN ROSCA
			verificarTornillo(ntornillo)
		end
	end
end

function tor1CC(ntornillo)
	-- TRAYECTORIA COLOCACIÓN TORNILLO 1
	MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	MovJ(P30, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	local t1 = RelPointTool(P21, {0, 0, -40})
	-- P15 TORNILLO 3
	MovJ(t1, {v = 90, a = 100, tool = 1, user = 0, cp = 100})
	-- POS INICIAL ATORNILLADO
	onAT()
	-- ENCENDER EL ATORNILLADOR()
	MovL(P21, {v = speedBolt, a = 100, tool = 1, user = 0})
	-- POS FINAL ATORNILLADO
	Wait(1000)
	offAT()
	-- APAGAR EL ATORNILLADOR()
	tornilloMalo = verificarTorque()
	t1 = RelPointTool(P11, {0, 0, -60})
	MovL(t1, {v = 50, a = 100, tool = 1, user = 0})
	MovJ(P30, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	SetGlobalVariable("TORNILLO_TOMADO", 0)
	if tornilloMalo == true then
		-- AGREGAR LÓGICA PARA SENSAR PRECENCIA DE TORNILLO EN BOCALLAVE. POSIBLE TORNILLO SIN ROSCA
		verificarTornillo(ntornillo)
	end
end

function tor2CC(ntornillo)
	--TRAYECTORIA COLOCACION TORNILLO 2
	MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	MovJ(P31, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	local t2 = RelPointTool(P22, {0, 0, -40})
	MovJ(t2, {v = 90, a = 100, tool = 1, user = 0, cp = 100})
	-- POS INICIAL ATORNILLADO
	onAT()
	-- ENCENDER EL ATORNILLADOR()
	MovL(P22, {v = speedBolt, a = 100, tool = 1, user = 0})
	-- POS FINAL ATORNILLADO
	Wait(1000)
	offAT()
	tornilloMalo = verificarTorque()
	-- APAGAR EL ATORNILLADOR()
	t2 = RelPointTool(P12, {0, 0, -10})
	MovL(t2, {v = 50, a = 10, tool = 1, user = 0})
	MovJ(P31, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	SetGlobalVariable("TORNILLO_TOMADO", 0)
	if tornilloMalo == true then
		-- AGREGAR LÓGICA PARA SENSAR PRECENCIA DE TORNILLO EN BOCALLAVE. POSIBLE TORNILLO SIN ROSCA
		verificarTornillo(ntornillo)
	end
end

function tor3CC(ntornillo)
	-- PUNTO PREVIO A SENSADO
	MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	MovJ(P32, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	local t3 = RelPointTool(P26, {0, 0, -40})
	-- P16 TORNILLO 3
	MovJ(t3, {v = 90, a = 100, tool = 1, user = 0})
	-- POS INICIAL ATORNILLADO
	onAT()
	-- ENCENDER EL ATORNILLADOR
	MovL(P26, {v = speedBolt, a = 100, tool = 1, user = 0})
	-- POS FINAL ATORNILLADO
	Wait(500)
	offAT()
	-- APAGAR EL ATORNILLADOR()
	tornilloMalo = verificarTorque()
	MovJ(P32, {user = 0, tool = 1, a = 100, v = 100, cp = 50})
	MovJ(P1, {user = 0, tool = 1, a = 100, v = 100, cp = 100})
	setTask(DO_Task11)
	Wait(200)
	SetGlobalVariable("TORNILLO_TOMADO", 0)
	resetTask(DO_Task11)
	if tornilloMalo == true then
		-- AGREGAR LÓGICA PARA SENSAR PRECENCIA DE TORNILLO EN BOCALLAVE. POSIBLE TORNILLO SIN ROSCA
		verificarTornillo(ntornillo)
	end
end

function esta_en_punto(actual, punto_destino)
	local j_actual = actual.joint
	local j_destino = punto_destino.joint
	local tolerancia = 1
	-- Evaluamos los 6 motores
	-- for i = 1, 6 do
	-- Evaluamos los 3 motores
	for i = 1, 3 do
		-- Si la diferencia entre el motor actual y el guardado supera la tolerancia, retorna falso
		if math.abs(j_actual[i] - j_destino[i]) > tolerancia then
			return false
		end
	end
	-- Si termina el bucle sin fallar, es que los 3 motores coinciden
	return true
end

----------------------------------------------------------

function inicializacion()
	--offAT()
	offAlim()
	robotPOSOK = 0
	--VERIFICA QUE EL ROBOT ESTÉ EN HOME AL INICIAR
	while (robotPOSOK ~= 1) do
		print("EL ROOT NO ESTÁ EN HOME AL INICIAR LA TRAYECTORIA")
		robot_home = GetAngle()
		robot_anticipado = GetAngle()
		if esta_en_punto(robot_home, P7) then
			robotPOSOK = 1
			ROBOTHOME = 1
		elseif esta_en_punto(robot_anticipado, P1) then
			robotPOSOK = 1
			ROBOTANTICIPADO = 1
		end
		Wait(20)
	end
	--HABILITA EL MOVIMIENTO
	offsetX = 0
	offsetY = 0
	-- SETEA PARÁMETROS GLOBALES DE VELOCIDAD Y ACELERACIÓN
	VelJ(100)
	AccJ(100)
	VelL(100)
	AccL(100)
	Tool(1)
	-- APAGA ALIMENTADOR
	presencia_tornillo_AL = DI(1)
	-- SQ1_AL1
	presencia_tornillo_ALS = DI(2)
	-- SQ2_AL2
	presencia_tornillo_boca = DI(3)
	-- SQ3_AL1
	presencia_tornillo_BK1 = DI(4)
	-- SQ4_BK1
	presencia_tornillo_BK2 = DI(5)
	-- SQ4_BK2
	tornilloOK = TORNILLO_TOMADO
	if (cuentaTornillo ~= 0) then
		cuenta_tornillo = cuentaTornillo
	end
	-- OBTIENE EL NÚMERO DE TORNILLOS DEL CICLO
	TOTAL_TORNILLOS = getTornillosCiclo()
	if TOTAL_TORNILLOS > 0 then
		print(string.format("CICLO RECIBIDO: &d. TORNILLOS A COLOCAR: %d", TOTAL_TORNILLOS))
	end
	DETENER_ALIMENTADOR = 0
	return
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SyncPuntos()
inicializacion()
-- Verifica que este en home e inicializa variables
--offAT()
resetTask(DO_Task10)
-- HABILITA EL MOVIMIENTO
DETENER_ALIMENTADOR = 0
if ROBOTHOME == 1 then
	-- salida home
	MovJ(P1, {user = 0, tool = 1, a = 100, cp = 100, v = 100})
end
-- ==========================================================
-- LOOP PRINCIPAL DE ATORNILLADO
-- ==========================================================
repeat
	DETENER_ALIMENTADOR = 0
	if TORNILLO_TOMADO == 0 then
		print(string.format("TORNILLO A COLOCAR: %d", cuenta_tornillo + 1))
		-- *********************************************************************
		-- VERIFICA PRESENCIA DE TORNILLO EN ALIMENTADOR AUTOMÁTICO
		-- *********************************************************************
		presencia_tornillo_AL = DI(1)
		Wait(150)
		if presencia_tornillo_AL == 1 and TORNILLO_TOMADO ~= 1 then
            DETENER_ALIMENTADOR = 1
			-- EJECUTAR TOMA DE TORNILLO ALIMENTADOR AUTOMÁTICO
			-- print(string.format('presencia_tornillo_AL1:%d - cartuchoOK:%d', presencia_tornillo_AL, cartuchoOK))
			--offAT()
			setTask(DO_Task10)
			-- LE AVISA EL PLC QUE ESTAMOS EN ZONA DE TOMA DE TORNILLO
			-- Nos vamos a prebocallave
			MovJ(P9, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
			-- SALIDA_AL
			local p_aproxL = RelPointTool(P19, {0, 0, -100})
			-- PUNTO DE TOMA LEJAJO
			local p_aproxC = RelPointTool(P19, {0, 0, -65})
			-- PUNTO DE TOMA CERCANO
			--MovJ(p_aproxL, {v = 50, a = 100, tool = 1, user = 0})
			repeat
				MovL(p_aproxC, {v = 80, a = 100, tool = 1, user = 0, cp = 50})
				SetOutputBool(DO_Reversa_AT, 1)
				-- ENCIENTE ATORNILLADOR REVERSA
				MovL(P19, {v = 1, a = 1, tool = 1, user = 0})
				Wait(200)
				-- PUNTO DE TOMA
				offAT()
				-- APAGA ATORNILLADOR
				MovL(p_aproxC, {v = 100, a = 100, tool = 1, user = 0})
				MovL(P8, {v = 90, a = 100, tool = 1, user = 0, cp = 0})
				--Posicion check presencia de tornillo
				Wait(100)
				presencia_tornillo_boca = DI(3)
				-- SQ3_Presencia en Bocallave
				Wait(20)
				SetGlobalVariable("TORNILLO_TOMADO", 1)
				-- SI LLEGÓ A ESTE PUNTO Y LA PRESENCIA DE TORNILLOS ESTÁ ENCENDIDA
				-- VERIFICAMOS SI TIENE TORNILLO EN BOCALLAVE
				if presencia_tornillo_boca == 0 then
					SetGlobalVariable("TORNILLO_TOMADO", 0)
					MovL(p_aproxC, {v = 50, a = 100, tool = 1, user = 0, cp = 50})
					SetOutputBool(DO_Reversa_AT, 1)
					-- ENCIENTE ATORNILLADOR REVERSA
					MovL(P19, {v = 1, a = 1, tool = 1, user = 0})
					offAT()
					MovL(p_aproxC, {v = 100, a = 100, tool = 1, user = 0})
					MovL(P8, {v = 90, a = 100, tool = 1, user = 0, cp = 0})
					Wait(100)
					presencia_tornillo_boca = DI(3)
					-- SQ3_Presencia en Bocallave
					presencia_tornillo_AL = DI(1)
					if presencia_tornillo_boca == ON then
						SetGlobalVariable("TORNILLO_TOMADO", 1)
						MovJ(P9, {v = 100, a = 100, tool = 1, user = 0, cp = 40})
						-- P_prebocallave
						break
					else
						MovJ(P9, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
						-- P_prebocallave
					end
				end
			until presencia_tornillo_boca == ON
			-- ESPERA QUE OTRO TORNILLO OCUPE EL LUGAR DEL QUE SALIÓ
			MovJ(P1, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
			-- SALIDA_HOME_POS
			resetTask(DO_Task10)
			-- LE AVISA EL PLC QUE SALIMOS DE ZONA DE TOMA DE TORNILLO
		elseif (presencia_tornillo_AL == 0 and TORNILLO_TOMADO ~= 1) then
			-- *********************************************************************
			-- NO SE VERIFICA PRESENCIA DE TORNILLO EN ALIMENTADOR AUTOMÁTICO
			-- *********************************************************************
			-- SQ4_BK1
			presencia_tornillo_BK1 = DI(4)
			-- SQ4_BK2
			presencia_tornillo_BK2 = DI(5)
			MovJ(P1, {v = 100, a = 100, cp = 100, tool = 1, user = 0})
			MovJ(P3, {v = 100, a = 100, cp = 100, tool = 1, user = 0})
			offAT()
			setTask(DO_Task10)
			-- LE AVISA EL PLC QUE ESTAMOS EN ZONA DE TOMA DE TORNILLO
			--Leer el número del tornillo actual que toca tomar
			local indice_actualBK1 = indice_tornilloBK1
			-- Leer el número del tornillo actual que toca tomar
			local indice_actualBK2 = indice_tornilloBK2
			-- ===================================================================================
			if
				indice_tornilloBK1 < MAX_TORBAK and presencia_tornillo_BK1 == ON and TORNILLO_TOMADO ~= 1
			then
				-- Movimientos físicos sobre las bandejas
				bandejaActiva = 1
				MovJ(P4, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
				-- Salida_HOME
				print(string.format("SE EJECUTA RUTINA DE TOMA EN BACKUP 1"))
				-- ===================================================================================*************
				-- EJECUTA LA TOMA DE BACKUP DE LA BANDEJA 1
				-- TOMA SECUENCIAL DE TORNILLOS(1 por ejecución)
				-- ==========================================================
				-- Calcular los desplazamientos físicos en milímetros
				offsetX, offsetY = getOffsetsBKP1(indice_actualBK1)
				-- P_tomaBK1
				p_TOMA = P2
				offAT()
				--APAGA ATORNILLADOR
				-- Actualizar y guardar el número del próximo tornillo
				indice_actualBK1 = indice_actualBK1 + 1
				SetGlobalVariable("indice_tornilloBK1", indice_actualBK1)
				-- ===================================================================================*************
			elseif
				presencia_tornillo_BK2 == ON and indice_tornilloBK2 < MAX_TORBAK and TORNILLO_TOMADO ~= 1
			then
				bandejaActiva = 2
				-- Movimientos físicos sobre las bandejas
				MovJ(P5, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
				-- Salida_HOME
				print(string.format("NO SE DETECTÓ PRESENCIA DE TORNILLO EN BACKUP 1"))
				print(string.format("SE EJECUTA RUTINA DE TOMA EN BACKUP 2"))
				-- ===================================================================================*************
				-- EJECUTA LA TOMA DE BACKUP DE LA BANDEJA 2
				-- ==========================================================
				-- Calcular los desplazamientos físicos en milímetros
				offsetX, offsetY = getOffsetsBKP2(indice_actualBK2)
				-- P_tomaBK2
				p_TOMA = P6
				-- Actualizar y guardar el número del próximo tornillo
				indice_actualBK2 = indice_actualBK2 + 1
				SetGlobalVariable("indice_tornilloBK2", indice_actualBK2)
			end
			-- ===================================================================================
			if
				bandejaActiva > 0 and (indice_tornilloBK1 < MAX_TORBAK or indice_tornilloBK2 < MAX_TORBAK)
			then
				-- ===================================================================================
				-- Punto de aproximación(Z - 150 mm)
				local p_aprox = RelPointTool(p_TOMA, {offsetX, offsetY, -55})
				MovL(p_aprox, {v = 100, a = 100, tool = 1, user = 0})
				-- Bajar al plano del tornillo
				local p_toma1 = RelPointTool(p_TOMA, {offsetX, offsetY, -13})
				local p_toma2 = RelPointTool(p_TOMA, {offsetX, offsetY, 0})
				-- Activar herramienta
				-- ENCENDER EL ATORNILLADOR
				offAT()
				onATREV()
				-- P_toma
				MovL(p_toma2, {v = 1, a = 1, tool = 1, user = 0})
				offAT()
				-- APAGAR EL ATORNILLADOR
				-- ===================================================================================
				-- Retirada vertical
				MovL(p_aprox, {v = 100, a = 100, tool = 1, user = 0})
				-- ===================================================================================
				-- 4. MOVIMIENTO PARA VALDAR EL TORNILLO
				MovJ(P3, {v = 100, a = 100, cp = 100, tool = 1, user = 0})
				MovJ(P9, {v = 100, a = 100, cp = 100, tool = 1, user = 0})
				-- PUNTO PREVIO A SENSADO
				MovJ(P8, {v = 100, a = 100, tool = 1, user = 0, cp = 50})
				-- PUNTO SENSADO PRESENCIABOCALLAVE
				local reintentos = 0
				repeat
					presencia_tornillo_boca = DI(3)
					-- SQ3_AL1 PRESENCIA DE TORNILLO EN BOCALLAVE
					Wait(150)
					reintentos = reintentos + 1
				until ((presencia_tornillo_boca == ON or reintentos > 3))
				if (presencia_tornillo_boca == OFF) then
					--Halt()
					MovJ(P9, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
					-- PUNTO PREVIO A SENSADO
					MovJ(P33, {v = 100, a = 100, tool = 1, user = 0, cp = 50})
					-- break  -- SI NO DETECTA TORNILLO DEBERÍA IR A BUSCAR OTRO
				else
					SetGlobalVariable("TORNILLO_TOMADO", 1)
					MovJ(P9, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
					-- PUNTO PREVIO A SENSADO
					MovJ(P1, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
				end
			end
		else
			print(string.format('NO SE DETECTA PRESENCIA DE TORNILLO EN LOS 3 MÉTODOS'))
			Halt()
		end
	end
	resetTask(DO_Task10)
  	DETENER_ALIMENTADOR = 0
	-- ==========================================================
	-- 5. SECUENCIA DE COLOCACIÓN DE TORNILLOS
	offAT()
	DETENER_ALIMENTADOR = 0
	VelJ(100)
	AccJ(100)
	VelL(100)
	AccL(100)
	if cuenta_tornillo == 0 and TORNILLO_TOMADO == 1 then
		waitTask(DO_Task01)
		-- SOLICITA AUTORIZACIÓN DE TAREA
		cuenta_tornillo = cuenta_tornillo + 1
		SetGlobalVariable("cuentaTornillo", cuenta_tornillo)
		resetTask(DO_Task10)
		colocarTornillo(0)
		----------------------------------------------------------------------
	elseif cuenta_tornillo == 1 and TORNILLO_TOMADO == 1 then
		waitTask(DO_Task02)
		-- SOLICITA AUTORIZACIÓN DE TAREA 2
		cuenta_tornillo = cuenta_tornillo + 1
		-- TRAYECTORIA COLOCACIÓN TORNILLO 2
		SetGlobalVariable("cuentaTornillo", cuenta_tornillo)
		resetTask(DO_Task10)
		colocarTornillo(1)
		--------------------------------------------------------------
	elseif cuenta_tornillo == 2 and TORNILLO_TOMADO == 1 then
		waitTask(DO_Task03)
		-- SOLICITA AUTORIZACIÓN DE TAREA
		cuenta_tornillo = cuenta_tornillo + 1
		-- TRAYECTORIA COLOCACIÓN TORNILLO 3
		SetGlobalVariable("cuentaTornillo", cuenta_tornillo)
		resetTask(DO_Task10)
		colocarTornillo(2)
	end
until (cuenta_tornillo == TOTAL_TORNILLOS)
MovJ(P1, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
--tomaTornillo()
if cuenta_tornillo == TOTAL_TORNILLOS then
	MovJ(P7, {v = 100, a = 100, tool = 1, user = 0, cp = 100})
	clearCycle()
	cartuchoOK = 0
	clearAllTask()
	DETENER_ALIMENTADOR = 0
end
-- HL0_AL
-- ==========================================================
-- FINALIZA LOOP PRINCIPAL DE ATORNILLADO
-- ==========================================================
Wait(20)
SetGlobalVariable("cuentaTornillo", 0)
Wait(20)
SetOutputBool(DO_Esp_Ciclo, 1)
Wait(20)
-- SOLICITA FINALIZAR LA CONEXIÓN CON EL PLC
conectar_PLC = 0