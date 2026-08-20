-- El programa paralelo que se ejecuta con el programa principal puede establecer E/S, variables, etc., y no puede llamar a instrucciones de movimiento.
--*********************************************************************
-- ROBOT TYPE : #DOBOT CR 30H
-- FUNCTION   : INICIACIÓN DE VARIABLES
-- Work Type  : ATORNILLADO
-- Copyright  : GRUPRO SA
--            : EL TALAR, BUENOS AIRES ARGENTINA
--*********************************************************************
-- El programa paralelo que se ejecuta con el programa principal puede establecer E/S, variables, etc., y no puede llamar a instrucciones de movimiento.
-- A parallel program that runs with the main thread and can set I/O, variables, etc.
--  It cannot call motion instructions.
-- Version: Lua 5.4.4
-- This thread is the main thread and can call any commands.
-- Script Lua: Robot como Cliente TCP hacia el PLC

local ip = '136.129.6.2'
-- IP de tu PLC
local port = 44818
-- El puerto configurado en el programa de tu PLC
local err = 0
local socket = 0
local RecBuf = ''
conectar_PLC = 1

-- 1. Crear la red TCP como Cliente (isServer = false) una sola vez fuera del bucle para evitar saturación de sockets
err, socket = TCPCreate(false, ip, port)
if err == 0 then
    if conexion_OK ~= 1 then
        print('Cliente TCP creado. Intentando conectar al PLC...')
    end
    -- 2. Conectarse al PLC (espera hasta 5 segundos para conectar)
    err = TCPStart(socket, 5)
    if err == 0 and conexion_OK ~= 1 then
        print('Conectado al PLC exitosamente.')
        conexion_OK = 1
    else
        if conexion_OK ~= 1 then
            print('No se pudo conectar al PLC (Tiempo de espera agotado).')
        end
    end
else
    print('Error al crear el Cliente TCP.')
end

while true do
    -- Mantiene vivo el hilo sin crear sockets repetidamente
    Wait(100)
end