.include "lmaos.inc"
.include "lcd1602.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "via.inc"
.include "fat32.inc"

.org $0600

.feature string_escapes

Main:
    JMP Fat32Init

.include "spi.asm"
.include "sdcard.asm"

Fat32Init:
@SDCardInit:
    JSR SDCardInit
    BCS @SDCardInitError
    COPYADDR SDCardInitSuccess, r0
    JSR ACIASendString
@FetchMBR:
    LDA #0
    TAX
    TAY
    JSR SDCardReadBlock     ; fetch mbr, LBA block 0
    BCS @FetchMBRError
@ReadMBRPattern:
    JSR Fat32VerifySectorSignature
    BCS @FetchMBRError
@VerifyFat32:
    ; TODO: we should be reading more than the first record but for now let's just read one
    LDA SDCardDataPacketBuffer + FAT32_MBR_PARTITION_TABLE_OFFSET + FAT32_PARTITION_RECORD_TYPE_OFFSET
    CMP #(FAT32_MBR_PARTITION_TYPE_WIN95)
    BEQ @ReadPartitionStart
    CMP #(FAT32_MBR_PARTITION_TYPE_WIN95_LBA)
    BNE @Fat32PartitionNotFound
@ReadPartitionStart:
    COPYADDR SDCardFat32PartitionFoundPrefix, r0
    JSR ACIASendString
    LDX #3
@ReadPartitionLoop:
    ; partition LBA sector offset is little-endian
    LDA SDCardDataPacketBuffer + FAT32_MBR_PARTITION_TABLE_OFFSET + FAT32_PARTITION_RECORD_LBA_OFFSET, X
    JSR ByteToHexString                 ; result in r7
    LDA r7
    JSR ACIASendByte
    LDA r7 + 1
    JSR ACIASendByte
    DEX
    CPX #$FF
    BNE @ReadPartitionLoop
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR ACIASendByte
@ReadVolumeID:
    ; TODO: this means we will blow away the cached MBR...
    LDA SDCardDataPacketBuffer + FAT32_MBR_PARTITION_TABLE_OFFSET + FAT32_PARTITION_RECORD_LBA_OFFSET + 0
    LDX SDCardDataPacketBuffer + FAT32_MBR_PARTITION_TABLE_OFFSET + FAT32_PARTITION_RECORD_LBA_OFFSET + 1
    LDY SDCardDataPacketBuffer + FAT32_MBR_PARTITION_TABLE_OFFSET + FAT32_PARTITION_RECORD_LBA_OFFSET + 2
    JSR SDCardReadBlock
    BCS @VolumeIDError
@VerifyVolumeBytesPerSector:
    JSR Fat32VerifyVolumeID
@Done:
    RTS

@SDCardInitError:
    COPYADDR SDCardInitError, r0
    JSR ACIASendString
    JMP @Done

@FetchMBRError:
    COPYADDR SDCardMBRError, r0
    JSR ACIASendString
    JMP @Done

@Fat32PartitionNotFound:
    COPYADDR SDCardFat32PartitionNotFound, r0
    JSR ACIASendString
    JMP @Done

@VolumeIDError:
    COPYADDR SDCardVolumeIDError, r0
    JSR ACIASendString
    JMP @Done

; subroutine that verifies sector signature
; signature should be at the end of SDCardDataPacketBuffer
Fat32VerifySectorSignature:
    LDA SDCardDataPacketBuffer + FAT32_SECTOR_SIGNATURE_1_OFFSET
    CMP #(FAT32_SECTOR_SIGNATURE_1)
    BNE @Error
    LDA SDCardDataPacketBuffer + FAT32_SECTOR_SIGNATURE_2_OFFSET
    CMP #(FAT32_SECTOR_SIGNATURE_2)
    BNE @Error
    CLC
    BRA @Done
@Error:
    SEC
@Done:
    RTS

; subroutine that verifies a volume ID
; volume ID should live in SDCardDataPacketBuffer
Fat32VerifyVolumeID:
@VerifySignature:
    JSR Fat32VerifySectorSignature
    BCS @Error
@VerifyBytesPerSector:
    LDA SDCardDataPacketBuffer + FAT32_VOLUME_ID_BPS_OFFSET
    CMP #<FAT32_VOLUME_ID_BPS_512
    BNE @Error
    LDA SDCardDataPacketBuffer + FAT32_VOLUME_ID_BPS_OFFSET + 1
    CMP #>FAT32_VOLUME_ID_BPS_512
    BNE @Error
@VerifyNumberFats:
    LDA SDCardDataPacketBuffer + FAT32_VOLUME_ID_NUM_FATS_OFFSET
    CMP #(FAT32_VOLUME_ID_NUM_FATS)
    BNE @Error
    CLC
    BRA @Done
@Error:
    SEC
@Done:
    RTS

SDCardInitError:     .asciiz "SD card could not be initialized\r"
SDCardInitSuccess:   .asciiz "SD card initialized\r"
SDCardMBRError:      .asciiz "Could not read MBR\r"
SDCardFat32PartitionNotFound: .asciiz "No FAT32 partition could be found\r"
SDCardFat32PartitionFoundPrefix: .asciiz "FAT32 partition found at sector: "
SDCardVolumeIDError: .asciiz "Could not read volume ID\r"

; storage
; Fat32DataPacket:    .tag SDCardDataPacket       ; goes first so `data` is on page boundary
; Fat32Command:       .tag SDCardCommand
