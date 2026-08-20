--*********************************************************************
-- ROBOT TYPE : #DOBOT CR 30H
-- FUNCTION   : INICIOCIÓN DE VARIABLES
-- Work Type  : ATORNILLADO
-- Copyright  : GRUPRO SA
--            : EL TALAR, BUENOS AIRES ARGENTINA
--*********************************************************************

-- 			 ¡¡¡VARIABLES FUNDAMENTALES PARA LA CAMARA!!!

--*********************************************************************

camera_ip = '192.168.200.50' -- IP de la cámara Robótica/VISOR
camera_port = 2006           -- Puerto TCP de la cámara (VIA Ethernet --> Puerto LAN2)
timeout = 5		             -- Límite de espera de socket (segundos)
i_Aux_Count_Vector_Slot=0    -- Defino una variable (iteradora) auxiliar para monitorear el tamaño del string procesado
JOB_ACTUAL=0

Var_Delt_X = 0
Var_Delt_Y = 0
Var_Delt_Z = 0
Camara_Disparada=false		 --  Variable de Control
--CAMARA_ACTIVA = true

--*********************************************************************
-- Este archivo solo se utiliza para definir variables y funciones secundarias.
conectar_PLC = 0
conexion_OK = 0
DETENER_ALIMENTADOR = 0
TOTAL_TORNILLOS = 0

-- PRESENCIA DE TORNILLO EN LA BOCA DE SALIDA DEL ALIMENTADOR
presencia_tornillo_ALS = 0 -- SQ1_AL1
-- PRESENCIA DE TORNILLO EN LA SALIDA DEL ALIMENTADOR
presencia_tornillo_AL = 0 -- SQ2_AL2
-- CANTIDAD DE REINTENTOS DE LLENADO DEL ALIMENTADOR ANTES DE ALARMAR POR VACIAMIENTO DEL TACHO
reintentos_llenado_cartucho = 25
cont_reint_llen = 0
cuenta_tornillo = 0
-- PRESENCIA DE TORNILLSO EN BACKUP
presencia_tornillo_BK1 = 0 -- SQ4_BK1
presencia_tornillo_BK2 = 0 -- SQ5_BK2
-- VERIFICA SI LA BOCALLAVE TIENE TORNILLO
presencia_tornillo_boca = 0
-- SQ3_AL1

presencia_tornillo_ALS = 0 -- SQ1_AL1
presencia_tornillo_AL = 0 -- SQ2_AL2
presencia_tornillo_boca = 0 -- SQ3_AL1
tornilloOK = 0

--------------------------------------------------------------------
-- DATOS BANDEJAS BAKUP UNDERBODY
--------------------------------------------------------------------
filasBKP1 = 5
columnasBKP1 = 8

filasBKP2 = 8
columnasBKP2 = 5
MAX_TORBAK = 40 -- 40 tornillos en total
separacion = 30
--------------------------------------------------------------------
CARGA_BDJ_BKP1 = 0
CARGA_BDJ_BKP2 = 0
bandejaActiva = 1

CYCLE_CODE = 0
robotPOSOK = 0
robot_home = 0
robot_anticipado = 0
ROBOTHOME = 0

function SyncPuntos(param1, param2)
  HOME_POS = P7
  Salida_HOME = P1 -- Salida_HOME
  --print("EJEMPLO => Salida_HOME = P1", Salida_HOME, P1)
  P_aproxBKP = P3 --P_aprox_BKP
  P_tomaBK1 = P2 --P_tomaBK1
  P_entradaBK1 = P4 -- P_entradaBK1
  P_tomaBK2 = P5 --P_tomaBK2
  P_entradaBK2 = P6 -- P_entradaBK2
  T1 = P11
  T2 = P12
  T3 = P16
  P_tomaAL = P19 -- PUNTO TOMA DEL ALIMENTADOR AUTOMÁTICO
  return
end

function waitTask(taskNum)
  -- EL PLC DEBE AUTORIZAR LA TAREA QUE SE LE SOLICITA
  -- SI SE ACTIVA LA TASK01 SE DEBE ESPERAR LA ENTRADA HOMÓNIMA
  SetOutputBool(taskNum, 1)
  Wait(20)
  local t = taskNum - 2
  local inp = "DI_Task" .. t
  local oup = "DO_Task" .. t
  print(string.format('SE SOLICITA AL PLC %s', oup))
  local taskResp = GetInputBool(taskNum)
	Wait(10)
	while taskResp == 0 do
		print(string.format('SE AGUARDA DI_Task%d DESDE EL PLC', t))
		taskResp = GetInputBool(taskNum)
		Wait(30)
	end
	return
end

function getTask(taskNum)
	-- SE OBTIENE UNA ZONA DEL PLC
	local retorno = GetOutputBool(taskNum)
  Wait(70)
	return retorno
end

function setTask(taskNum)
	-- SI SE ACTIVA LA TASK al PLC
	SetOutputBool(taskNum, 1)
    Wait(20)
	return
end

function resetTask(taskNum)
	-- SI SE DESACTIVA LA TASK al PLC
	SetOutputBool(taskNum, 0)
    Wait(20)
	return
end

function clearCycle()
  SetOutputBool(DO_Esp_Ciclo, 0)
  Wait(30)
  SetOutputInt(DO_echo_cycle, 0)
  Wait(30)
  SetOutputBool(DO_Esp_Ciclo, 1)
  Wait(30)
  SetGlobalVariable("cuentaTornillo",0)
end

function clearAllTask()
  SetOutputBool(DO_Esp_Ciclo, 0)
  Wait(30)
  SetGlobalVariable("cuentaTornillo",0)
  Wait(30)
  SetOutputInt(DO_echo_cycle, 0)
  Wait(30)
  SetOutputBool(DO_ALARMA_TORQUE, 0)
  Wait(30)
  SetOutputBool(DO_Esp_Ciclo, 1)
  Wait(50)
  for i = DI_Task01, DI_Task30 do
	SetOutputBool(i, 0)
    Wait(10)
  end
end

-- ENCENDER ATORNILLADOR
function onAT()
	SetOutputBool(DO_Activar_AT, 0)
	-- DO_Activar_AT
	Wait(300)
	SetOutputBool(DO_Activar_AT, 1)
	-- DO_Activar_AT
	Wait(300)
	return
end

function offAT()
	SetOutputBool(DO_Reversa_AT, 0)
  Wait(300)
	-- DO_Activar_AT
  SetOutputBool(DO_Activar_AT, 0)
	Wait(300)
	return
end

function onATREV()
	SetOutputBool(DO_Activar_AT, 0)
	Wait(300)
	SetOutputBool(DO_Reversa_AT, 1)
  Wait(300)
  SetOutputBool(DO_Activar_AT, 1)	-- DO_Activar_AT
	-- DO_Activar_AT
	Wait(300)
	return
end

function onAlim()
  DO(2, ON)
  Wait(20)
  return
end

function offAlim()
  DO(2, OFF)
  Wait(20)
  return
end

function getOffsetsBKP1(indice)
  -- 2. Calcular en qué fila y columna está el tornillo actual
  -- Usamos math.floor para obtener la fila (0 a 3) y el módulo '%' para la columna (0 a 7)
  local r = math.floor(indice / columnasBKP1)
  local c = indice % columnasBKP1
  print(string.format('TORNILLO BACKUP 1 indice:%d', indice))
  -- Calcular los desplazamientos físicos en milímetros
  local offset_x = c * separacion
  local offset_y = (r * separacion)
print("Tornillo(" ..r .."," ..c ..") tomado. El próximo será el índice: " ..tostring(indice+1))
  print(string.format('SEPARACIÓN BACKUP 1 X:%d, Y:%d', offset_x, offset_y))
  return offset_x, offset_y
end

function getOffsetsBKP2(indice)
  -- 2. Calcular en qué fila y columna está el tornillo actual
  -- Usamos math.floor para obtener la fila (0 a 3) y el módulo '%' para la columna (0 a 7)
  local r = math.floor(indice / columnasBKP2)
  local c = indice % columnasBKP2
  print(string.format('TORNILLO BACKUP 2 indice:%d', indice))
  -- Calcular los desplazamientos físicos en milímetros
  local offset_x = c * separacion
  local offset_y = (r * separacion)
print("Tornillo(" ..r .."," ..c ..") tomado. El próximo será el índice: " ..tostring(indice+1))
  print(string.format('SEPARACIÓN BACKUP 2 X:%d, Y:%d', offset_x, offset_y))
  return offset_x, offset_y
end

function getTornillosCiclo()
  -- ===================================================================
  -- OBTIENE AL NRO DE TORNILLOS DEPENDIENDO DEL CICLO
  -- SE DETIENE HASTA QUE LO OBTENGA
  -- ===================================================================
  local retorno = 0
  repeat
    CYCLE_CODE = GetInputInt(DI_cycle)
    Wait(100)
      print(string.format('ESPERANDO CÓDIGO DE CICLO:%d', CYCLE_CODE))
    if CYCLE_CODE == 1 then
      retorno = 3	
    elseif CYCLE_CODE == 2 then
      retorno = 3
    end
    Wait(500)
    until CYCLE_CODE > 0
    SetOutputInt(DO_echo_cycle, CYCLE_CODE)
    Wait(20)
    SetOutputBool(DO_Esp_Ciclo, 0)
    Wait(20)
    return retorno
end