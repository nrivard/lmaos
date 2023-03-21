.include "lmaos.inc"
.include "pseudoinstructions.inc"
.include "strings.inc"
.include "system.inc"
.include "via.inc"
.include "fat32.inc"

.org $0600

.feature string_escapes

; pointer to file record currently being operated on.
; TODO: should be moved to real zeropage declaration when moved to LmaOS declarations
Fat32CurrentFileRecordPtr := $40 ; and $21
Fat32CurrentDirectoryReadRequest := $42 ; through $27

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
    JSR SerialSendString
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
    JSR SerialSendString
    LDX #3
@ReadPartitionLoop:
    ; partition LBA sector offset is little-endian
    LDA SDCardDataPacketBuffer + FAT32_MBR_PARTITION_TABLE_OFFSET + FAT32_PARTITION_RECORD_LBA_OFFSET, X
    STA FAT32PartitionBlock, X          ; save partition location for calculations later
    JSR SerialSendByteAsString
    DEX
    CPX #$FF
    BNE @ReadPartitionLoop
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR SerialSendByte
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
    JSR SerialSendByte
    COPYADDR Fat32DirectoryListingHeader, r0
    JSR SerialSendString
    COPYADDR Fat32DirectoryListingSeparator, r0
    JSR SerialSendString

@FetchRootDir:
    LDA FAT32RootDirCluster
    STA Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::cluster
    LDA FAT32RootDirCluster + 1
    STA Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::cluster + 1
    LDA FAT32RootDirCluster + 2
    STA Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::cluster + 2
    STZ Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::cluster + 4
    LDA #<FileHandler
    STA Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::handler
    LDA #>FileHandler
    STA Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::handler + 1
    JSR Fat32DirectoryRead
    BCS @RootDirError
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
    JSR SerialSendString
    JMP @Done

; a sample file handler. `Fat32CurrentFileRecordPtr` is already filled out
FileHandler:
    PHA
    PHY
@ReadAttributes:
    JSR Fat32FileReadAttributes
    CMP #(FAT32_RECORD_ATTRIBUTES_LFN_MASK) ; is this a long filename text record?
    BNE @PrintFilename
    BRA @Done
@PrintFilename:
    JSR Fat32FileReadName       ; read the filename
    COPYADDR Fat32Filename, r0
    JSR SerialSendString
@PrintFileCluster:
    LDA #(ASCII_TAB)
    JSR SerialSendByte
    LDY #(Fat32FileRecord::clusterHigh)
    LDA (Fat32CurrentFileRecordPtr), Y
    JSR SerialSendByteAsString
    INY
    LDA (Fat32CurrentFileRecordPtr), Y
    JSR SerialSendByteAsString
    LDY #(Fat32FileRecord::clusterLow)
    LDA (Fat32CurrentFileRecordPtr), Y
    JSR SerialSendByteAsString
    INY
    LDA (Fat32CurrentFileRecordPtr), Y
    JSR SerialSendByteAsString
@PrintSize:
    LDA #(ASCII_TAB)
    JSR SerialSendByte
    LDY #(Fat32FileRecord::size + 3)    ; little endian, so start at the end of the size field
@PrintSizeLoop:
    LDA (Fat32CurrentFileRecordPtr), Y
    JSR SerialSendByteAsString
    DEY
    CPY #(Fat32FileRecord::size - 1)    ; past the size field?
    BNE @PrintSizeLoop
@PrintTerminator:
    LDA #(ASCII_CARRIAGE_RETURN)
    JSR SerialSendByte
@Done:
    PLY
    PLA
    RTS

; Reads the directory requested in `Fat32CurrentDirectoryReadRequest`
; This function will repeatedly JSR into the provided `handler` for each valid file
; See docs on the `Fat32DirectoryReadRequest` for more information
; carry will be set if an error occurred
Fat32DirectoryRead:
    PHA
    PHY
    PHX
@LoadCluster:
    LDA Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::cluster
    LDX Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::cluster + 1
    LDY Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::cluster + 2
    JSR Fat32ClusterToSector
    JSR SDCardReadBlock
    BCC @ProcessBlock
    JMP @Done
@ProcessBlock:
    LDY #0
@ProcessBlockLoop:
    TYA
    JSR Fat32FileAtIndex              ; file addr is in A/X
    STA Fat32CurrentFileRecordPtr
    STX Fat32CurrentFileRecordPtr + 1
@FetchFirstByte:
    LDA (Fat32CurrentFileRecordPtr)
@TestFirstByte:
    CMP #(FAT32_RECORD_END_OF_DIR)
    BEQ @Done
    CMP #(FAT32_RECORD_FILE_DELETED) 
    BEQ @NextFile
    CMP #(FAT32_RECORD_DOT_ENTRY)
    BEQ @NextFile
@CallHandler:
    JSR @CallHandlerIndirect
    BRA @NextFile
@CallHandlerIndirect:
    JMP (Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::handler)
@NextFile:
    INY
    CPY #16
    BNE @ProcessBlockLoop
@FollowChain:
    JSR Fat32ClusterFollowChain
@NoError:
    CLC
    BRA @Done
@Done:
    PLX
    PLY
    PLA
    RTS

; updates `Fat32CurrentDirectoryReadRequest` with the next cluster in the chain
; if there is no cluster, `Fat32CurrentDirectoryReadRequest::cluster == $00000000`
Fat32ClusterFollowChain:
    PHA
    PHY
@CopyCluster:
    LDY #0
@CopyClusterLoop:
    LDA Fat32CurrentDirectoryReadRequest + Fat32DirectoryReadRequest::cluster, Y
    STA r0, Y
    INY
    CPY #4
    BNE @CopyClusterLoop
@CalculateFATSectorIndex:
    LDY #7
@CalculateFATSectorIndexLoop:
    LSR32 r0
    DEY
    BNE @CalculateFATSectorIndexLoop
@CalculateFATSector:
    ADC32 FAT32TableBlock, r0, $6000
@FetchFATSector:
    LDA $6000
    LDX $6000 + 1
    LDY $6000 + 2
    JSR SDCardReadBlock
    BCS @Done
@Done:
    PLY
    PLA
    RTS

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
@TestFileIsDirectory:
    JSR Fat32FileReadAttributes
    AND #(FAT32_RECORD_ATTRIBUTES_DIR_MASK)
    BEQ @SeparateFilenameAndExtension   ; not a directory
@PrintDirectory:
    LDA #'/'                            ; this is a directory
    STA Fat32Filename, Y
    INY
    BRA @TerminateString 
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

SDCardInitError:     .asciiz "SD card could not be initialized\r"
SDCardInitSuccess:   .asciiz "SD card initialized\r"
SDCardMBRError:      .asciiz "Could not read MBR\r"
SDCardFat32PartitionNotFound: .asciiz "No FAT32 partition could be found\r"
SDCardFat32PartitionFoundPrefix: .asciiz "FAT32 partition found at sector: "
SDCardVolumeIDError: .asciiz "Could not read volume ID\r"
Fat32RootDirError: .asciiz "Could not read root directory\r"

Fat32DirectoryListingHeader:    .asciiz "Filename    \tCluster \tSize\r"
Fat32DirectoryListingSeparator: .asciiz "------------\t--------\t--------\r"

HahaPrefix: .asciiz "File: "
; storage
; Fat32DataPacket:    .tag SDCardDataPacket       ; goes first so `data` is on page boundary
; Fat32Command:       .tag SDCardCommand
