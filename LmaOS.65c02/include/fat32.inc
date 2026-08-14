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
; offset of the LBA offset in a partition record (ie, location in the LBA)
FAT32_PARTITION_RECORD_LBA_OFFSET := $08    ; this is 4 bytes long, little endian

; the two FAT32 partition types. may have to check both!
FAT32_MBR_PARTITION_TYPE_WIN95 := $0B
FAT32_MBR_PARTITION_TYPE_WIN95_LBA := $0C

; offset for bytes-per-sector in a volume ID
FAT32_VOLUME_ID_BPS_OFFSET := $0B   ; 2 bytes, little endian
FAT32_VOLUME_ID_BPS_512 := $0200    ; volume id should always report 512 as the bytes-per-sector
; offset for number of sectors per cluster
FAT32_VOLUME_ID_SECTORS_PER_CLUSTER_OFFSET := $0D  ; 1 byte
; offset for the number of file allocation tables in a volume ID
FAT32_VOLUME_ID_NUM_FATS_OFFSET := $10 ; 1 byte
FAT32_VOLUME_ID_NUM_FATS := $02     ; should always be 2 FATs
; offset for the number of reserved sectors
FAT32_VOLUME_NUM_RESERVED_SECTORS_OFFSET := $0E ; 2 bytes, little endian. usually $20
; offset for number of sectors per FAT table
FAT32_VOLUME_ID_SECTORS_PER_FAT_OFFSET := $24 ; 4 bytes, little endian. depends on disk size
; offset for the root directory cluster
FAT32_VOLUME_ID_ROOT_DIR_CLUSTER_OFFSET := $2C  ; bytes, little endian. usually $00000002

; offset for file attributes in a directory entry
FAT32_RECORD_ATTRIBUTES_LFN_MASK := $0F
FAT32_RECORD_ATTRIBUTES_DIR_MASK := $10

; first byte of a directory record will be this if the file was deleted and can be reclaimed
FAT32_RECORD_FILE_DELETED := $E5
; first byte of a directory record will be this if it's the end of the directory
FAT32_RECORD_END_OF_DIR := $00
; first byte of a directory record will be this if it's special `.` or `..` entry
FAT32_RECORD_DOT_ENTRY := $2E

.struct Fat32DirectoryReadRequest
    cluster             .res 4     ; the first cluster of the directory to read
    handler             .addr      ; address of a subroutine to be called for each valid file.
                                   ; `Fat32CurrentFileRecordPtr` will contain the pointer to the file record
                                   ; must call RTS when finished processing the current file
.endstruct

; layout of a Fat32 file record
.struct Fat32FileRecord
    filename            .res 8
    extension           .res 3
    attributes          .byte
    RESERVED            .byte
    creationCentisec    .byte
    creationTime        .word
    creationDate        .word
    lastAccessDate      .word
    clusterHigh         .word
    writeTime           .word
    writeDate           .word
    clusterLow          .word
    size                .res 4
.endstruct

; .export FAT32SectorBuffer, FAT32PartitionTable

; .zeropage

; FAT32SectorMetadata: .res $04

; .bss

; .org $0300

; FAT32SectorBuffer: .res $200
; FAT32PartitionTable: .res $10   ; the LBA offsets (4 bytes) of up to 4 partitions

; .reloc

.endif
