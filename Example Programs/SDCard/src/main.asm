.include "lmaos.inc"
.include "lcd1602.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "via.inc"
.include "fat32.inc"

.org $0600

.feature string_escapes

; pointer to file record currently being operated on.
; TODO: should be moved to real zeropage declaration when moved to LmaOS declarations
Fat32CurrentFileRecordPtr := $20 ; and $21

Main:
    JMP Fat32Init

FAT32PartitionBlock:    .res 4     ; where LBA=0 is located
FAT32TableBlock:        .res 4     ; where the first FAT table is located (yes i'm aware i'm saying file allocation table table!)
FAT32ClustersBlock:     .res 4     ; where the first cluster is located
FAT32SectorsPerCluster: .res 1     ; number of sectors per cluster. duh!
FAT32RootDirCluster:    .res 4     ; cluster number that holds the root directory

; storage for Fat32ReadFilename
; TODO: this should probably be defined elsewhere, as when this gets moved to ROM, this trick won't work anymore
Fat32Filename: .res 13  ; storage for the full short filename, including a dot between the extension and zero terminated

.include "spi.asm"
.include "sdcard.asm"

Fat32Init:
@SDCardInit:
    JSR SDCardInit
    BCC @SDCardInitialized
    JMP @SDCardInitError
@SDCardInitialized:
    COPYADDR SDCardInitSuccess, r0
    JSR ACIASendString
@FetchMBR:
    LDA #0
    TAX
    TAY
    JSR SDCardReadBlock     ; fetch mbr, LBA block 0
    BCC @ReadMBRPattern
    JMP @FetchMBRError
@ReadMBRPattern:
    JSR Fat32VerifySectorSignature
    BCC @VerifyFat32
    JMP @FetchMBRError
@VerifyFat32:
    ; TODO: we should be reading more than the first record but for now let's just read one
    LDA SDCardDataPacketBuffer + FAT32_MBR_PARTITION_TABLE_OFFSET + FAT32_PARTITION_RECORD_TYPE_OFFSET
    CMP #(FAT32_MBR_PARTITION_TYPE_WIN95)
    BEQ @ReadPartitionStart
    CMP #(FAT32_MBR_PARTITION_TYPE_WIN95_LBA)
    BEQ @ReadPartitionStart 
    JMP @Fat32PartitionNotFound
@ReadPartitionStart:
    COPYADDR SDCardFat32PartitionFoundPrefix, r0
    JSR ACIASendString
    LDX #3
@ReadPartitionLoop:
    ; partition LBA sector offset is little-endian
    LDA SDCardDataPacketBuffer + FAT32_MBR_PARTITION_TABLE_OFFSET + FAT32_PARTITION_RECORD_LBA_OFFSET, X
    STA FAT32PartitionBlock, X          ; save partition location for calculations later
    JSR ACIASendByteAsString
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
    BCC @VerifyVolumeBytesPerSector
    JMP @VolumeIDError
@VerifyVolumeBytesPerSector:
    JSR Fat32VerifyVolumeID
@CalculateFATTableBlock:
    CLC
    LDA FAT32PartitionBlock
    ADC SDCardDataPacketBuffer + FAT32_VOLUME_NUM_RESERVED_SECTORS_OFFSET
    STA FAT32TableBlock
    LDA FAT32PartitionBlock + 1
    ADC SDCardDataPacketBuffer + FAT32_VOLUME_NUM_RESERVED_SECTORS_OFFSET + 1
    STA FAT32TableBlock + 1
    LDA FAT32PartitionBlock + 2
    ADC #0
    STA FAT32TableBlock + 2
    LDA FAT32PartitionBlock + 3
    ADC #0
    STA FAT32TableBlock + 3
@CalculateClustersStart:
    COPY32 SDCardDataPacketBuffer + FAT32_VOLUME_ID_SECTORS_PER_FAT_OFFSET, FAT32ClustersBlock
    ASL32 FAT32ClustersBlock    ; 2 * num of sectors per FAT table
    ADC32 FAT32TableBlock, FAT32ClustersBlock, FAT32ClustersBlock
@CopySectorsPerClusterAndRootDir:
    LDA SDCardDataPacketBuffer + FAT32_VOLUME_ID_SECTORS_PER_CLUSTER_OFFSET
    STA FAT32SectorsPerCluster
    COPY32 SDCardDataPacketBuffer + FAT32_VOLUME_ID_ROOT_DIR_CLUSTER_OFFSET, FAT32RootDirCluster

@PrintDirListingHeader:
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR ACIASendByte
    COPYADDR Fat32DirectoryListingHeader, r0
    JSR ACIASendString
    COPYADDR Fat32DirectoryListingSeparator, r0
    JSR ACIASendString
@FetchRootDir:
    LDA FAT32RootDirCluster
    LDX FAT32RootDirCluster + 1
    LDY FAT32RootDirCluster + 2
    JSR Fat32ClusterToSector
    JSR SDCardReadBlock
    BCC @ReadRootDir
    JMP @RootDirError
@ReadRootDir:
    LDY #0
@ReadRootDirLoop:
    PHY                         ; preserve index into the file list
    TYA
    JSR Fat32FileAtIndex          ; file addr is in A/X
    STA Fat32CurrentFileRecordPtr
    STX Fat32CurrentFileRecordPtr + 1
    JSR Fat32FileIsValid        ; is this a valid file?
    BCC @ReadRootDirNext
    JSR Fat32FileReadAttributes
    CMP #(FAT32_RECORD_ATTRIBUTES_LFN_MASK) ; is this a long filename text record?
    BNE @PrintFilename
    BRA @ReadRootDirNext
@PrintFilename:
    JSR Fat32FileReadName       ; read the filename
    COPYADDR Fat32Filename, r0
    JSR ACIASendString
@TestFileIsDirectory:
    JSR Fat32FileReadAttributes
    AND #(FAT32_RECORD_ATTRIBUTES_DIR_MASK)
    BEQ @PrintFileCluster       ; not a directory
    LDA #'/'                    ; this is a directory, so print a char so we know
    JSR ACIASendByte
@PrintFileCluster:
    LDA #(ASCII_TAB)
    JSR ACIASendByte
    LDY #(Fat32FileRecord::clusterHigh)
    LDA (Fat32CurrentFileRecordPtr), Y
    JSR ACIASendByteAsString
    INY
    LDA (Fat32CurrentFileRecordPtr), Y
    JSR ACIASendByteAsString
    LDY #(Fat32FileRecord::clusterLow)
    LDA (Fat32CurrentFileRecordPtr), Y
    JSR ACIASendByteAsString
    INY
    LDA (Fat32CurrentFileRecordPtr), Y
    JSR ACIASendByteAsString
@PrintSize:
    LDA #(ASCII_TAB)
    JSR ACIASendByte
    LDY #(Fat32FileRecord::size + 3)    ; little endian, so start at the end of the size field
@PrintSizeLoop:
    LDA (Fat32CurrentFileRecordPtr), Y
    JSR ACIASendByteAsString
    DEY
    CPY #(Fat32FileRecord::size - 1)    ; past the size field?
    BNE @PrintSizeLoop
@PrintTerminator:
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR ACIASendByte
@ReadRootDirNext:
    PLY                         ; restore index into the file list
    INY
    CPY #16
    BNE @ReadRootDirLoop
@Done:
    RTS

@SDCardInitError:
    COPYADDR SDCardInitError, r0
    BRA @SendErrorString

@FetchMBRError:
    COPYADDR SDCardMBRError, r0
    BRA @SendErrorString

@Fat32PartitionNotFound:
    COPYADDR SDCardFat32PartitionNotFound, r0
    BRA @SendErrorString

@VolumeIDError:
    COPYADDR SDCardVolumeIDError, r0
    BRA @SendErrorString

@RootDirError:
    COPYADDR Fat32RootDirError, r0
    BRA @SendErrorString    ; just in case there are more errors :)

@SendErrorString:
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

; converts a cluster number given by
; `A` lowest byte, `X` middle byte, `Y` highest byte
; to a raw sector number. Cluster number will be returned
; as `A` lowest byte, `X` middle byte, `Y` highest byte (only a 24 bit sector is returned)
Fat32ClusterToSector:
@CopyCluster:
    STA r0
    STX r0 + 1
    STY r0 + 2  ; TODO: do we need to add the high order byte in r0 + 3?
    STZ r0 + 3
@CorrectClusterNumber:
    SEC
    SBC #2      ; clusters always start at 2, so need to correct it by subtracting 2
    STA r0
    TXA
    SBC #0
    STA r0 + 1
    TYA
    SBC #0
    STA r0 + 2
    LDA r0 + 3
    SBC #0
    STA r0 + 3
@MultiplySectorsPerCluster:
    COPY16 FAT32SectorsPerCluster, r2   ; can't use r1 as we're using part of it as scratchpad for cluster number
@MultiplySectorsPerClusterLoop:
    LSR r2
    BCS @CalculateOffset
    ASL32 r0
    BRA @MultiplySectorsPerClusterLoop
@CalculateOffset:
    ADC32 r0, FAT32ClustersBlock, r0
@SetReturnValues:
    LDA r0
    LDX r0 + 1
    LDY r0 + 2
@Done:
    RTS

; calculates start of a file record in SDCardPacketData at index given by `A`
; returns the address in `A` lowest byte and `X` high byte
Fat32FileAtIndex:
@CalculateFileOffset:
    STZ r0
    STZ r0 + 1
    TAX
@CalculateFileOffsetLoop:
    BEQ @Done
    ADD16 r0, $20      ; each record is 32-bytes
    DEX
    BRA @CalculateFileOffsetLoop
@Done:
    ADD16 r0, SDCardDataPacketBuffer
    LDA r0
    LDX r0 + 1
    RTS

; reads file attributes of the current file at Fat32CurrentFileRecordPtr
; return status in `A`
Fat32FileReadAttributes:
    PHY
@ReadAttributes:
    LDY #(Fat32FileRecord::attributes)
    LDA (Fat32CurrentFileRecordPtr), Y
@Done:
    PLY
    RTS

; reads first byte of the current file at Fat32CurrentFileRecordPtr
; to determine if this is a valid file or not
; Files starting with $E5 or $00 are considered invalid
; carry will be set if file is valid, and cleared if file is invalid
Fat32FileIsValid:
    PHA
@FetchFirstByte:
    LDA (Fat32CurrentFileRecordPtr)
@TestFirstByte:
    CMP #(FAT32_RECORD_FILE_DELETED)
    BEQ @FileInvalid
    CMP #(FAT32_RECORD_END_OF_DIR)
    BEQ @FileInvalid
    CMP #(FAT32_RECORD_DOT_ENTRY)
    BEQ @FileInvalid
    SEC
    BRA @Done
@FileInvalid:
    CLC
@Done:
    PLA
    RTS

; reads the short filename of the current file at Fat32CurrentFileRecordPtr
; filename with a dot between name and extension and zero-terminated will be stored at Fat32Filename
Fat32FileReadName:
    PHA
    PHY
@ReadFilename:
    LDY #0
@ReadFilenameLoop:
    LDA (Fat32CurrentFileRecordPtr), Y
    STA Fat32Filename, Y
    INY
    CPY #8
    BNE @ReadFilenameLoop
@SeparateFilenameAndExtension:
    LDA #'.'
    STA Fat32Filename, Y
@ReadExtensionLoop:
    LDA (Fat32CurrentFileRecordPtr), Y
    INY                 ; here we have to INY before storing bc we added an additional character in our string: '.'
    STA Fat32Filename, Y
    CPY #12
    BNE @ReadExtensionLoop
@TerminateString:
    LDA #0
    STA Fat32Filename, Y
@Done:
    PLY
    PLA
    RTS


;; sends the byte in `A` as a hex string via the ACIA sychronously
;; this is a convenience and destroys r7
ACIASendByteAsString:
    JSR ByteToHexString
    LDA r7
    JSR ACIASendByte
    LDA r7 + 1
    JSR ACIASendByte
    RTS

SDCardInitError:     .asciiz "SD card could not be initialized\r"
SDCardInitSuccess:   .asciiz "SD card initialized\r"
SDCardMBRError:      .asciiz "Could not read MBR\r"
SDCardFat32PartitionNotFound: .asciiz "No FAT32 partition could be found\r"
SDCardFat32PartitionFoundPrefix: .asciiz "FAT32 partition found at sector: "
SDCardVolumeIDError: .asciiz "Could not read volume ID\r"
Fat32RootDirError: .asciiz "Could not read root directory\r"

Fat32DirectoryListingHeader:    .asciiz "Filename    \tCluster \tSize\r"
Fat32DirectoryListingSeparator: .asciiz "------------\t--------\t--------\r"

; storage
; Fat32DataPacket:    .tag SDCardDataPacket       ; goes first so `data` is on page boundary
; Fat32Command:       .tag SDCardCommand
