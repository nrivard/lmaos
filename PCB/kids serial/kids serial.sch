EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "Kids' Serial"
Date "2021-03-13"
Rev "1"
Comp ""
Comment1 "ACIA n8 Bus expansion card"
Comment2 "Uses an ACIA and FTDI USB breakout to provide a serial connection"
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Connector_Generic:Conn_02x16_Odd_Even J1
U 1 1 604C03AC
P 1475 3700
F 0 "J1" H 1525 4617 50  0000 C CNN
F 1 "n8 Bus Connector" H 1525 4526 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x16_P2.54mm_Horizontal" H 1475 3700 50  0001 C CNN
F 3 "~" H 1475 3700 50  0001 C CNN
	1    1475 3700
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0101
U 1 1 604C9E8F
P 925 3000
F 0 "#PWR0101" H 925 2850 50  0001 C CNN
F 1 "+5V" H 800 3050 50  0000 C CNN
F 2 "" H 925 3000 50  0001 C CNN
F 3 "" H 925 3000 50  0001 C CNN
	1    925  3000
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0102
U 1 1 604CA2D6
P 950 4500
F 0 "#PWR0102" H 950 4250 50  0001 C CNN
F 1 "GND" H 800 4450 50  0000 C CNN
F 2 "" H 950 4500 50  0001 C CNN
F 3 "" H 950 4500 50  0001 C CNN
	1    950  4500
	1    0    0    -1  
$EndComp
Wire Wire Line
	925  3000 1275 3000
Connection ~ 1275 3000
Wire Wire Line
	1275 3000 1775 3000
Wire Wire Line
	950  4500 1175 4500
Connection ~ 1275 4500
Wire Wire Line
	1275 4500 1775 4500
$Comp
L power:+5V #PWR0103
U 1 1 604CB07B
P 2100 4500
F 0 "#PWR0103" H 2100 4350 50  0001 C CNN
F 1 "+5V" H 2225 4550 50  0000 C CNN
F 2 "" H 2100 4500 50  0001 C CNN
F 3 "" H 2100 4500 50  0001 C CNN
	1    2100 4500
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0104
U 1 1 604CB0E8
P 2100 3000
F 0 "#PWR0104" H 2100 2750 50  0001 C CNN
F 1 "GND" H 2250 2950 50  0000 C CNN
F 2 "" H 2100 3000 50  0001 C CNN
F 3 "" H 2100 3000 50  0001 C CNN
	1    2100 3000
	1    0    0    -1  
$EndComp
Wire Wire Line
	1275 4400 1775 4400
Connection ~ 1775 4400
Wire Wire Line
	1775 4400 1850 4400
Wire Wire Line
	1275 3100 1775 3100
Connection ~ 1775 3100
Wire Wire Line
	1775 3100 1850 3100
Wire Wire Line
	1850 3100 1850 3000
Wire Wire Line
	1850 3000 2100 3000
Wire Wire Line
	1850 4400 1850 4500
Wire Wire Line
	1850 4500 1975 4500
Entry Wire Line
	1975 3200 2075 3300
Entry Wire Line
	1975 3300 2075 3400
Entry Wire Line
	1975 3400 2075 3500
Entry Wire Line
	1975 3500 2075 3600
Entry Wire Line
	1975 3600 2075 3700
Entry Wire Line
	1975 3700 2075 3800
Entry Wire Line
	1975 3800 2075 3900
Entry Wire Line
	1975 3900 2075 4000
Wire Wire Line
	1775 3200 1975 3200
Wire Wire Line
	1775 3300 1975 3300
Wire Wire Line
	1775 3400 1975 3400
Wire Wire Line
	1775 3500 1975 3500
Wire Wire Line
	1775 3600 1975 3600
Wire Wire Line
	1775 3700 1975 3700
Wire Wire Line
	1775 3800 1975 3800
Wire Wire Line
	1775 3900 1975 3900
Text Label 1800 3200 0    50   ~ 0
D0
Text Label 1800 3300 0    50   ~ 0
D1
Text Label 1800 3400 0    50   ~ 0
D2
Text Label 1800 3500 0    50   ~ 0
D3
Text Label 1800 3600 0    50   ~ 0
D4
Text Label 1800 3700 0    50   ~ 0
D5
Text Label 1800 3800 0    50   ~ 0
D6
Text Label 1800 3900 0    50   ~ 0
D7
Entry Wire Line
	925  3100 1025 3200
Entry Wire Line
	925  3200 1025 3300
Entry Wire Line
	925  3300 1025 3400
Entry Wire Line
	925  3400 1025 3500
Entry Wire Line
	925  3500 1025 3600
Entry Wire Line
	925  3600 1025 3700
Wire Wire Line
	1275 3200 1025 3200
Wire Wire Line
	1275 3300 1025 3300
Wire Wire Line
	1275 3400 1025 3400
Wire Wire Line
	1275 3500 1025 3500
Wire Wire Line
	1275 3600 1025 3600
Wire Wire Line
	1275 3700 1025 3700
Text Label 1125 3200 0    50   ~ 0
A0
Text Label 1125 3300 0    50   ~ 0
A1
Text Label 1125 3400 0    50   ~ 0
A2
Text Label 1125 3500 0    50   ~ 0
A3
Text Label 1125 3600 0    50   ~ 0
A4
Text Label 1125 3700 0    50   ~ 0
A5
Text GLabel 950  3750 0    50   Input ~ 0
~CS
Text GLabel 950  3900 0    50   Input ~ 0
R~W
Text GLabel 950  4025 0    50   Input ~ 0
CLK
Wire Wire Line
	1275 3800 1225 3800
Wire Wire Line
	1225 3800 1225 3750
Wire Wire Line
	1225 3750 950  3750
Wire Wire Line
	1275 3900 950  3900
Wire Wire Line
	1275 4000 1225 4000
Wire Wire Line
	1225 4000 1225 4025
Wire Wire Line
	1225 4025 950  4025
Text GLabel 950  4150 0    50   Input ~ 0
~RES
Wire Wire Line
	1275 4100 1175 4100
Wire Wire Line
	1175 4100 1175 4150
Wire Wire Line
	1175 4150 950  4150
Wire Wire Line
	1775 4000 1850 4000
Text GLabel 1850 4000 2    50   Output ~ 0
~IRQ
$Comp
L power:PWR_FLAG #FLG0101
U 1 1 604E4120
P 1975 4500
F 0 "#FLG0101" H 1975 4575 50  0001 C CNN
F 1 "PWR_FLAG" H 1975 4673 50  0000 C CNN
F 2 "" H 1975 4500 50  0001 C CNN
F 3 "~" H 1975 4500 50  0001 C CNN
	1    1975 4500
	-1   0    0    1   
$EndComp
Connection ~ 1975 4500
Wire Wire Line
	1975 4500 2100 4500
$Comp
L power:PWR_FLAG #FLG0102
U 1 1 604E505A
P 1175 4500
F 0 "#FLG0102" H 1175 4575 50  0001 C CNN
F 1 "PWR_FLAG" H 1175 4673 50  0000 C CNN
F 2 "" H 1175 4500 50  0001 C CNN
F 3 "~" H 1175 4500 50  0001 C CNN
	1    1175 4500
	-1   0    0    1   
$EndComp
Connection ~ 1175 4500
Wire Wire Line
	1175 4500 1275 4500
NoConn ~ 1775 4200
NoConn ~ 1775 4300
NoConn ~ 1275 4300
NoConn ~ 1275 4200
NoConn ~ 1775 4100
$Comp
L 65xx:6551 U1
U 1 1 604C389E
P 4625 3825
F 0 "U1" H 4800 5250 50  0000 C CNN
F 1 "6551" H 4800 5150 50  0000 C CIB
F 2 "Package_DIP:DIP-28_W15.24mm" H 4625 3975 50  0001 C CNN
F 3 "http://www.6502.org/documents/datasheets/mos/mos_6551_acia.pdf" H 4625 3975 50  0001 C CNN
	1    4625 3825
	1    0    0    -1  
$EndComp
Text GLabel 3850 2700 0    50   Input ~ 0
~RES
Text GLabel 3850 2825 0    50   Input ~ 0
CLK
Text GLabel 3850 3025 0    50   Input ~ 0
~IRQ
Text GLabel 3850 3325 0    50   Input ~ 0
~CS
Wire Wire Line
	4025 2725 4025 2700
Wire Wire Line
	4025 2700 3850 2700
Wire Wire Line
	4025 2825 3850 2825
Wire Wire Line
	4025 3025 3850 3025
Wire Wire Line
	4025 3325 3850 3325
$Comp
L power:+5V #PWR0105
U 1 1 604CACE1
P 3925 3225
F 0 "#PWR0105" H 3925 3075 50  0001 C CNN
F 1 "+5V" H 4000 3350 50  0000 C CNN
F 2 "" H 3925 3225 50  0001 C CNN
F 3 "" H 3925 3225 50  0001 C CNN
	1    3925 3225
	1    0    0    -1  
$EndComp
Wire Wire Line
	4025 3225 3925 3225
Entry Wire Line
	3825 3425 3925 3525
Entry Wire Line
	3825 3525 3925 3625
Wire Bus Line
	3825 3425 3825 3525
Text Label 3950 3525 0    50   ~ 0
A0
Text Label 3950 3625 0    50   ~ 0
A1
Wire Wire Line
	4025 3625 3925 3625
Wire Wire Line
	4025 3525 3925 3525
NoConn ~ 1275 3400
NoConn ~ 1275 3500
NoConn ~ 1275 3600
NoConn ~ 1275 3700
Entry Wire Line
	3825 4125 3925 4225
Entry Wire Line
	3825 4225 3925 4325
Entry Wire Line
	3825 4325 3925 4425
Entry Wire Line
	3825 4425 3925 4525
Entry Wire Line
	3825 4525 3925 4625
Entry Wire Line
	3825 4625 3925 4725
Entry Wire Line
	3825 4725 3925 4825
Entry Wire Line
	3825 4825 3925 4925
Wire Wire Line
	4025 4225 3925 4225
Wire Wire Line
	4025 4325 3925 4325
Wire Wire Line
	4025 4425 3925 4425
Wire Wire Line
	4025 4525 3925 4525
Wire Wire Line
	4025 4625 3925 4625
Wire Wire Line
	4025 4725 3925 4725
Wire Wire Line
	4025 4825 3925 4825
Wire Wire Line
	4025 4925 3925 4925
Text Label 3950 4225 0    50   ~ 0
D0
Text Label 3950 4325 0    50   ~ 0
D1
Text Label 3950 4425 0    50   ~ 0
D2
Text Label 3950 4525 0    50   ~ 0
D3
Text Label 3950 4625 0    50   ~ 0
D4
Text Label 3950 4725 0    50   ~ 0
D5
Text Label 3950 4825 0    50   ~ 0
D6
Text Label 3950 4925 0    50   ~ 0
D7
Text GLabel 3875 4025 0    50   Input ~ 0
R~W
Wire Wire Line
	4025 4025 3875 4025
$Comp
L power:GND #PWR0106
U 1 1 6050E282
P 4625 5400
F 0 "#PWR0106" H 4625 5150 50  0001 C CNN
F 1 "GND" H 4630 5227 50  0000 C CNN
F 2 "" H 4625 5400 50  0001 C CNN
F 3 "" H 4625 5400 50  0001 C CNN
	1    4625 5400
	1    0    0    -1  
$EndComp
Wire Wire Line
	4625 5275 4625 5350
$Comp
L power:+5V #PWR0107
U 1 1 6051025F
P 4625 2225
F 0 "#PWR0107" H 4625 2075 50  0001 C CNN
F 1 "+5V" H 4750 2275 50  0000 C CNN
F 2 "" H 4625 2225 50  0001 C CNN
F 3 "" H 4625 2225 50  0001 C CNN
	1    4625 2225
	1    0    0    -1  
$EndComp
Wire Wire Line
	4625 2225 4625 2350
$Comp
L power:GND #PWR0108
U 1 1 60512726
P 5400 4425
F 0 "#PWR0108" H 5400 4175 50  0001 C CNN
F 1 "GND" H 5405 4252 50  0000 C CNN
F 2 "" H 5400 4425 50  0001 C CNN
F 3 "" H 5400 4425 50  0001 C CNN
	1    5400 4425
	1    0    0    -1  
$EndComp
Wire Wire Line
	5225 4425 5400 4425
Wire Wire Line
	5225 4225 5400 4225
Wire Wire Line
	5400 4225 5400 4425
Connection ~ 5400 4425
NoConn ~ 5225 3025
$Comp
L Oscillator:CXO_DIP14 X1
U 1 1 6051A780
P 6375 2825
F 0 "X1" H 6450 3150 50  0000 L CNN
F 1 "CXO_DIP14" H 6450 3075 50  0000 L CNN
F 2 "Oscillator:Oscillator_DIP-14" H 6825 2475 50  0001 C CNN
F 3 "http://cdn-reichelt.de/documents/datenblatt/B400/OSZI.pdf" H 6275 2825 50  0001 C CNN
	1    6375 2825
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0109
U 1 1 60527292
P 6375 3225
F 0 "#PWR0109" H 6375 2975 50  0001 C CNN
F 1 "GND" H 6380 3052 50  0000 C CNN
F 2 "" H 6375 3225 50  0001 C CNN
F 3 "" H 6375 3225 50  0001 C CNN
	1    6375 3225
	1    0    0    -1  
$EndComp
Wire Wire Line
	6375 3125 6375 3225
NoConn ~ 6075 2825
$Comp
L power:+5V #PWR0110
U 1 1 6052AE8E
P 6375 2425
F 0 "#PWR0110" H 6375 2275 50  0001 C CNN
F 1 "+5V" H 6500 2475 50  0000 C CNN
F 2 "" H 6375 2425 50  0001 C CNN
F 3 "" H 6375 2425 50  0001 C CNN
	1    6375 2425
	1    0    0    -1  
$EndComp
Wire Wire Line
	6375 2425 6375 2525
Text GLabel 6825 2825 2    50   Output ~ 0
XTAL_CLK
Wire Wire Line
	6825 2825 6675 2825
Text GLabel 5400 2725 2    50   Input ~ 0
XTAL_CLK
Wire Wire Line
	5225 2725 5400 2725
$Comp
L Connector_Generic:Conn_01x06 J2
U 1 1 60533E57
P 6675 4425
F 0 "J2" H 6755 4417 50  0000 L CNN
F 1 "UARTConnector" H 6755 4326 50  0000 L CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_1x06_P2.54mm_Horizontal" H 6675 4425 50  0001 C CNN
F 3 "~" H 6675 4425 50  0001 C CNN
	1    6675 4425
	1    0    0    -1  
$EndComp
Text GLabel 6275 4225 0    50   Input ~ 0
VCC_IO
Text GLabel 6275 4425 0    50   Output ~ 0
TXD_IO
Text GLabel 6275 4525 0    50   Input ~ 0
RXD_IO
Wire Wire Line
	6475 4425 6275 4425
Wire Wire Line
	6475 4525 6275 4525
Wire Wire Line
	6475 4225 6275 4225
Text GLabel 6275 4650 0    50   Input ~ 0
~RTS_IO
Text GLabel 6250 4800 0    50   Output ~ 0
~CTS_IO
Wire Wire Line
	6475 4625 6325 4625
Wire Wire Line
	6325 4625 6325 4650
Wire Wire Line
	6325 4650 6275 4650
Wire Wire Line
	6475 4725 6325 4725
Wire Wire Line
	6325 4725 6325 4800
Wire Wire Line
	6325 4800 6250 4800
Text GLabel 5400 3525 2    50   Input ~ 0
RXD_IO
Text GLabel 5400 3625 2    50   Output ~ 0
TXD_IO
Wire Wire Line
	5225 3525 5400 3525
Wire Wire Line
	5225 3625 5400 3625
Text GLabel 5400 3825 2    50   Output ~ 0
~CTS_IO
Text GLabel 5400 3975 2    50   Output ~ 0
~RTS_IO
Wire Wire Line
	5225 3825 5400 3825
Wire Wire Line
	5225 3925 5325 3925
Wire Wire Line
	5325 3925 5325 3975
Wire Wire Line
	5325 3975 5400 3975
NoConn ~ 5225 4125
$Comp
L power:GND #PWR0111
U 1 1 6056E043
P 5900 4325
F 0 "#PWR0111" H 5900 4075 50  0001 C CNN
F 1 "GND" H 5850 4175 50  0000 C CNN
F 2 "" H 5900 4325 50  0001 C CNN
F 3 "" H 5900 4325 50  0001 C CNN
	1    5900 4325
	1    0    0    -1  
$EndComp
Wire Wire Line
	5900 4325 6475 4325
NoConn ~ 5225 2825
$Comp
L Connector_Generic:Conn_01x02 J3
U 1 1 604BB5D2
P 6675 3850
F 0 "J3" H 6755 3842 50  0000 L CNN
F 1 "PowerViaUSB" H 6755 3751 50  0000 L CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 6675 3850 50  0001 C CNN
F 3 "~" H 6675 3850 50  0001 C CNN
	1    6675 3850
	1    0    0    -1  
$EndComp
Text GLabel 6300 3950 0    50   Input ~ 0
VCC_IO
Wire Wire Line
	6475 3950 6300 3950
$Comp
L power:+5V #PWR0112
U 1 1 604C06C9
P 6300 3850
F 0 "#PWR0112" H 6300 3700 50  0001 C CNN
F 1 "+5V" H 6315 4023 50  0000 C CNN
F 2 "" H 6300 3850 50  0001 C CNN
F 3 "" H 6300 3850 50  0001 C CNN
	1    6300 3850
	1    0    0    -1  
$EndComp
Wire Wire Line
	6475 3850 6300 3850
$Comp
L Device:C_Small C1
U 1 1 604C8433
P 3450 3725
F 0 "C1" H 3542 3771 50  0000 L CNN
F 1 "100nf" H 3542 3680 50  0000 L CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P2.50mm" H 3450 3725 50  0001 C CNN
F 3 "~" H 3450 3725 50  0001 C CNN
	1    3450 3725
	1    0    0    -1  
$EndComp
Wire Wire Line
	4625 2350 3450 2350
Wire Wire Line
	3450 2350 3450 3625
Connection ~ 4625 2350
Wire Wire Line
	4625 2350 4625 2375
Wire Wire Line
	3450 3825 3450 5350
Wire Wire Line
	3450 5350 4625 5350
Connection ~ 4625 5350
Wire Wire Line
	4625 5350 4625 5400
Wire Bus Line
	925  3100 925  3600
Wire Bus Line
	2075 3300 2075 4000
Wire Bus Line
	3825 4125 3825 4825
$EndSCHEMATC
