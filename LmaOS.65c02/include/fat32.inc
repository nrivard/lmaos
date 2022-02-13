; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef FAT32_INC
FAT32_INC = 1

; size of the MBR
FAT32_MBR_SIZE := $0200
; Offset of the partition table in the MBR
FAT32_MBR_PARTITION_TABLE_OFFSET := $01BE

; size of each partition record
FAT32_PARTITION_RECORD_SIZE := $10
; offset of the `type` in a partition record
FAT32_PARTITION_RECORD_TYPE_OFFSET := $04
; offset of the LBA offset in a parition record (ie, location in the LBA)
FAT32_PARTITION_RECORD_LBA_OFFSET := $08

; the two FAT32 partition types. may have to check both!
FAT32_MBR_PARTITION_TYPE_WIN95 := $0B
FAT32_MBR_PARTITION_TYPE_WIN95_LBA := $0C

.export FAT32SectorBuffer, FAT32PartitionTable

.zeropage

FAT32SectorMetadata: .res $04

.bss

.org $0300

FAT32SectorBuffer: .res $200
FAT32PartitionTable: .res $10   ; the LBA offsets (4 bytes) of up to 4 partitions

.reloc

.endif
