; LmaOS
;
; Copyright Nate Rivard 2022

.ifndef FAT32_ASM
FAT32_ASM = 1

.include "fat32.inc"

FAT32Init:
    STZ FAT32SectorMetadata
    STZ FAT32SectorMetadata + 1
    STZ FAT32SectorMetadata + 2
    STZ FAT32SectorMetadata + 3

; reads the MBR and caches partition LBA offsets
; carry will be set if an error occurred, clear if successful
FAT32ReadPartitionTable:
    ; TODO: load the MBR (LBA = 0) somehow :)
@SanityCheckMBR:
    LDA FAT32SectorBuffer + FAT32_MBR_SIZE - 2
    CMP #$55
    BNE @MBRCorrupt
    LDA FAT32SectorBuffer + FAT32_MBR_SIZE - 1
    CMP #$AA
    BNE @MBRCorrupt

@MBRCorrupt:
    SEC
    RTS

.endif