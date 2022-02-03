; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef SYSTEM_INC
SYSTEM_INC = 1

; microprocessor clock speed
MpuRateHz := 2000000

; system uptime interrupt rate
ClockRateHz := 100

; Port Addresses
N8BUS_PORT0 := $BF00
N8BUS_PORT1 := $BF40
N8BUS_PORT2 := $BF80
N8BUS_PORT3 := $BFC0

.endif
