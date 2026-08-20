while true do
	recargaBKP1 = GetInputBool(DI_Task31)
	recargaBKP2 = GetInputBool(DI_Task32)
	local indice_actualBKP1 = GetGlobalVariable("indice_tornilloBK1")
	local indice_actualBKP2 = GetGlobalVariable("indice_tornilloBK2")
	-- Comprobar si ya se completó la matriz
	if indice_actualBKP1 >= MAX_TORBAK then
		print("La BADEJA 1 está vacía.")
		setTask(DO_Task31)
		-- LE AVISA EL PLC QUE SE VACIÓ LA BANDEJA 1
		SetGlobalVariable("BNJ_BKP1_VACIA", 1)
		bandejaActiva = 2
		if recargaBKP1 == 1 then
			SetGlobalVariable("indice_tornilloBK1", 0)
			SetGlobalVariable("BNJ_BKP1_VACIA", 0)
			resetTask(DO_Task31)
		end
	end
	-- Comprobar si ya se completó la matriz
	if indice_actualBKP2 >= MAX_TORBAK then
		print("La BANDEJA 2 está vacía.")
		setTask(DO_Task32)
		-- LE AVISA EL PLC QUE SE VACIÓ LA BANDEJA 2
		SetGlobalVariable("BNJ_BKP2_VACIA", 1)
		bandejaActiva = 1
		if recargaBKP2 == 1 then
			SetGlobalVariable("indice_tornilloBK2", 0)
			SetGlobalVariable("BNJ_BKP2_VACIA", 0)
			resetTask(DO_Task32)
		end
	end
	Wait(100)
end