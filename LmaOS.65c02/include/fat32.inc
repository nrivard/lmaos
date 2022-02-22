; LmaOS
;
; Copyright Nate Rivard 2020

.ifndef FAT32_INC
FAT32_INC = 1

; size of the MBR
FAT32_MBR_SIZE := $0200
; Offset of the partition table in the MBR
FAT32_MBR_PARTITION_TABLE_OFFSET := $01BE

; offset of the 1st signature pattern byte
FAT32_SECTOR_SIGNATURE_1_OFFSET := $01FE
; offset of the 2nd signature pattern byte
FAT32_SECTOR_SIGNATURE_2_OFFSET := $01FF
; patterns used for the signature
FAT32_SECTOR_SIGNATURE_1 := $55
FAT32_SECTOR_SIGNATURE_2 := $AA

; size of each partition record
FAT32_PARTITION_RECORD_SIZE := $10
; offset of the `type` in a partition record
FAT32_PARTITION_RECORD_TYPE_OFFSET := $04
; offset of the LBA offset in a parition record (ie, location in the LBA)
FAT32_PARTITION_RECORD_LBA_OFFSET := $08    ; this is 4 bytes long, little endian

; the two FAT32 partition types. may have to check both!
FAT32_MBR_PARTITION_TYPE_WIN95 := $0B
FAT32_MBR_PARTITION_TYPE_WIN95_LBA := $0C

; offset for bytes-per-sector in a volume ID
FAT32_VOLUME_ID_BPS_OFFSET := $0B   ; 2 bytes, little endian
FAT32_VOLUME_ID_BPS_512 := $0200    ; volume id should always report 512 as the bytes-per-sector
; offset for the number of file allocation tables in a volume ID
FAT32_VOLUME_ID_NUM_FATS_OFFSET := $10 ; 1 byte
FAT32_VOLUME_ID_NUM_FATS := $02     ; should always be 2 FATs

; .export FAT32SectorBuffer, FAT32PartitionTable

; .zeropage

; FAT32SectorMetadata: .res $04

; .bss

; .org $0300

; FAT32SectorBuffer: .res $200
; FAT32PartitionTable: .res $10   ; the LBA offsets (4 bytes) of up to 4 partitions

; .reloc

.endif
