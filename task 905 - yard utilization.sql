SELECT count(*)
FROM equipment
/*INNER JOIN spinnaker.containers ON 
	equipment.nbr = spinnaker.containers.container_number
INNER JOIN spinnaker.td_block ON
	spinnaker.containers.block_or_carrier = spinnaker.td_block.name*/
WHERE 
	loc_type = 'Y'
	AND sztp_class = 'CTR'
--	AND spinnaker.td_block.name IN 
/*		--MIT
		('A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'AX', 
		 'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'BX', 
		 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 
		 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'DES RORO', 
		 'E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7', 
		 'F3', 'F4', 'F5', 'F6', 'F7', 'FC', 
		 'G3', 'G4', 'G5', 'G6', 'G7', 
		 'H3', 'H4', 'H5', 'H7', 
		 'J5', 'J7', 
		 'K2', 'K3', 'K4', 
		 'L3', 'L4', 'L5', 'L6', 'L7', 'L8', 'L9', 
		 'M1', 'M2', 'M3', 'M4', 'M5', 'M6', 
		 'N1', 'N2', 'N3', 'N4', 'NE', 'NN')*/
/*		--ZLO
		('A0', 'A1', 'A2', 'A3', 'A4', 
		 'B0', 'B1', 'B2', 'B3', 'B4', 
		 'C0', 'C1', 'C2', 'C3', 'C4', 
		 'D0', 'D1', 'D2', 'D3', 'D4', 
		 'E0', 'E1', 'E2', 'E3', 'E4', 
		 'F0', 'F1', 'F2', 'F3', 'F4', 
		 'H1', 'H2', 'H3', 'H4', 
		 'I2', 'I3', 'I4', 
		 'J1', 'J2', 'J3', 'J4', 'J5', 'J6', 
		 'K1', 'K3', 'K4', 
		 'R4', 'A9', 'B5', 'B9', 'C5', 
		 'G1', 'G2', 'G3', 'G4', 'I5', 
		 'M0', 'M1', 'M2', 'M3', 'M4', 
		 'M5', 'M8', 'M9', 
		 'P4', 'P5', 'P6', 'P7', 'P8', 
		 'R5', 'T5', 'T6', 
		 '11-12-13', '14-15-16', '17-18-19', 
		 '20-21-22', '05-06-07', '08-09-10', 
		 'ADUANA-15', 'BUSCAR', 'CAM', 'CFS', 
		 'CONTECON', 'ESCANEO', 'EXTRA', 'FRIMAN', 
		 'MTY OUT', 'OCUPA', 'PARCHADO', 'PESAJE', 
		 'PLA-ADUANA', 'RAPISCAN', 'R-GAMA', 
		 'ROJOS', 'TIMSA', 'TREN', 'YARD')*/
/*		--PA
		('A', 'A400', 'AA401', 
		 'B100', 'B200', 'B300', 'BB401', 
		 'C100-200', 'C300', 'CC401', 
		 'D100', 'D200', 'D300', 'DD401', 
		 'E100', 'E200', 'E300', 'EE401', 
		 'F100', 'F200', 'F300', 'FF401', 
		 'G100', 'G200', 'G300', 'GG401', 
		 'H', 'HH401', 'KK401', 
		 'N201', 'N300', 'NN100', 
		 'P201', 'P300', 'PP100', 'PP501', 
		 'SS100', 'SS200', 'SS401', 'SS501', 
		 'T201', 'T300', 
		 'TT100', 'TT200', 'TT401', 'TT501', 
		 'WW100', 'WW200', 'WW501', 
		 'X200', 'X300', 'XX501', 'YY501')*/
/*		--B63
		('AUTOLOT', 
		 'B100', 'B200', 'B300', 'B400', 'B500', 
		 'BACKREACH', 'BKREACH', 
		 'C100', 'C1000', 'C1100', 'C1200', 
		 'C200', 'C300', 'C400', 
		 'C494', 'C494 B1', 'C494 B2', 'C494B1', 
		 'C500', 'C600', 'C6REEFER', 
		 'C700', 'C800', 'C8REEFER', 
		 'CC100', 'CC200', 'CC300', 'CC400', 
		 'CC500', 'CC600', 'CC700', 'CC800', 
		 'CHASSIS', 
		 'D000', 'D100', 'D200', 'D300', 
		 'D400', 'D500', 'D600', 
		 'DD000', 'DD100', 'DD200', 'DD300', 
		 'DD400', 'DD500', 'DD600', 
		 'M&R', 'M5000', 'MAINGATE', 
		 'MR1', 'MR2', 'MR3', 'MR4', 'MR5', 
		 'MR6', 'MR7', 'MR8', 'MR9', 
		 'SHOP', 'UTR', 'WHEELS', 'WHLS')*/
/*		--SMITCO
		('A1', 'A2', 'B1', 'C1', 'CB', 
		 'D1', 'E1', 'R1', 'MB', 'YARD')*/
FETCH FIRST 10 ROWS ONLY 
;