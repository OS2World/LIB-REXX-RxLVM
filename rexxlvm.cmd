/* REXXLVM.CMD
 * Demonstrate the functions of RXLVM.DLL.
 *
 * NOTE:  In addition to the return values listed below, all RXLVM.DLL functions
 * except for RxLvmLoadFuncs, RxLvmDropFuncs, RxLvmVersion and RxLvmEngineClose
 * may also return an error string of the format 'ERROR: n' (where n is an LVM
 * Engine error number), indicating that an error occured while calling an
 * LVM.DLL function.  See the bottom of this file for a list of error codes.
 */
SIGNAL ON NOVALUE

/* RxLvmLoadFuncs:
 *   Register all RXLVM.DLL functions.  Returns ''.
 */
CALL RxFuncAdd 'RxLvmLoadFuncs', 'RXLVM', 'RxLvmLoadFuncs'
CALL RxLvmLoadFuncs

/* RxLvmVersion:
 *   Retrieve the current RXLVM.DLL version.  Returns the version string
 *   'x.y.z' (where x, y, and z are each a number with one or more digits).
 */
PARSE VALUE RxLvmVersion() WITH major '.' minor '.' refresh
SAY 'Current RXLVM.DLL version is' major'.'minor 'refresh level' refresh
SAY

/* RxLvmRediscoverPRM:
 *   Refresh removeable media.  Returns ''.
 */

CALL CHAROUT, 'Discovering removeable media... '
disc = RxLvmRediscoverPRM()
IF disc == '' THEN
    SAY 'done'
ELSE DO
    PARSE VAR disc 'ERROR: ' lvm_error
    IF lvm_error \= '' THEN SAY 'LVM.DLL returned error code' lvm_error
END
SAY

/* RxLvmEngineOpen:
 *   Open the LVM Engine (required for all other LVM functions except
 *   RxLvmRediscoverPRM).  Returns ''.
 */
open = RxLvmEngineOpen()
IF open == '' THEN
    SAY 'Opened LVM Engine successfully.'
ELSE DO
    PARSE VAR open 'ERROR: ' lvm_error
    IF lvm_error \= '' THEN SAY 'LVM.DLL returned error code' lvm_error
    RETURN lvm_error
END

/* RxLvmBootMgrInfo:
 *   See if Boot Manager is installed, and get its current configuration.
 *   Returns '' if Boot Manager is not installed; otherwise, it returns
 *   '<disk> <active> <timeout> <def-type> <def-handle>', where:
 *     <disk>       is the number (starting from 1) of the physical disk where
 *                  Boot Manager resides;
 *     <active>     is 1 if Boot Manager is active (startable) or 0 if Boot
 *                  Manager is installed but not active;
 *     <timeout>    is the number of seconds before the default menu entry is
 *                  booted on startup, or 0 if the boot timer is disabled;
 *     <def-type>   is 1 if the default entry is a volume, or 0 if it's a raw
 *                  partition;
 *     <def-handle> is the handle (8 hex digits) of the default boot entry on
 *                  the Boot Manager menu.
 */

bmgr = RxLvmBootMgrInfo()
SELECT
    WHEN bmgr == '' THEN
        SAY 'Boot Manager is not installed.'
    WHEN LEFT( bmgr, 6 ) == 'ERROR:' THEN DO
        PARSE VAR bmgr 'ERROR:' lvm_error
        SAY 'Boot Manager state could not be determined.  LVM.DLL returned error code' lvm_error
        RETURN lvm_error
    END
    OTHERWISE DO
        PARSE VAR bmgr bmdisk bmactive bmtimer bmdeftype bmdefhandle
        IF bmactive == 1  THEN active = 'Yes'
        ELSE                   active = 'No'
        IF bmtimer  == 0 THEN timer = 'Disabled'
        ELSE                  timer = bmtimer 'seconds'
        IF bmdeftype == 1 THEN type = 'Volume handle'
        ELSE                   type = 'Partition handle'
        IF bmdefhandle == '' THEN handle = '(last booted)'
        ELSE                      handle = type bmdefhandle
        SAY 'Boot Manager details:'
        SAY '  Disk:   ' bmdisk
        SAY '  Active: ' active
        SAY '  Timout: ' timer
        SAY '  Default:' handle
    END
END
SAY

/* RxLvmGetVolumes:
 *   Query the list of volumes.  Always returns 1.  The parameter specifies a
 *   REXX stem name which will be populated with the volume data.  stem.0
 *   contains the number of volumes, and each other stem item contains the
 *   following information:
 *   <handle> <letter> <preference> <filesystem> <size> <device> <type> <bootable> <name>
 *     <handle>     An 8-digit hexadecimal string that uniquely identifies the
 *                  volume
 *     <letter>     The volume's current drive letter, or ? if none
 *     <preference> The volume's preferred drive letter, '?' if none, or '*' if the
 *                  drive letter is not assigned by LVM
 *     <filesystem> The volume's current file system
 *     <size>       The volume's size, in MiB
 *     <device>     The volume's device type.  This will be one of:
 *                      HDD - Hard disk drive
 *                      PRM - Removeable media under LVM control
 *                      CD  - CD/DVD drive (not controlled by LVM)
 *                      LAN - LAN drive (not controlled by LVM)
 *                      ?   - Unknown non-LVM device (e.g. RAM disk)
 *     <type>       The volume type.  This will be one of:
 *                      0   - standard (i.e. "compatibility") volume
 *                      1   - advanced (i.e. "LVM") volume
 *     <bootable>   The volume's bootable flag.  This will be one of:
 *                      B   - bootable (on Boot Manager menu)
 *                      S   - startable
 *                      I   - installable
 *                      N   - none
 *     <name>       The volume's name (may contain spaces or punctuation marks)
 *
 *   Example:
 *      volumes.0 == 4
 *      volumes.1 == "FC04D5A7 C C HPFS 2047 HDD 0 B eComStation"
 *      volumes.2 == "FC04D4E7 D D FAT16 2000 HDD 0 B Maintenance"
 *      volumes.3 == "FC04C567 E E JFS 102404 HDD 1 N Applications"
 *      volumes.4 == "FC04B0C7 H * CDFS 527 CD 0 N [ CDROM 1 ]"
 */
qv = RxLvmGetVolumes("vols.")
IF LEFT( qv, 6 ) == 'ERROR:' THEN DO
    PARSE VAR qv 'ERROR: ' lvm_error
    SAY 'LVM.DLL returned error code' lvm_error
    RETURN lvm_error
END
SAY vols.0 'volumes found:'
DO i = 1 TO vols.0
    PARSE VAR vols.i vhandle vletter vpref vfilesys vsize vdevice vtype vbootable vname
    IF vletter == '?'        THEN letter = '--'
    ELSE IF vpref \= vletter THEN letter = vpref'->'vletter':'
    ELSE                          letter = vletter':'
    IF vtype == 1 THEN type = 'Advanced volume'
    ELSE               type = 'Standard volume'
    SELECT
        WHEN vbootable == 'S' THEN boot = 'Startable'
        WHEN vbootable == 'I' THEN boot = 'Installable'
        WHEN vbootable == 'B' THEN boot = 'Bootable'
        OTHERWISE                  boot = ''
    END
    SAY RIGHT( letter, 6 ) LEFT( vname, 20 ) LEFT( vfilesys, 10 ) LEFT( vsize 'MB', 14 ) vdevice ' ' boot
    SAY '      ' type '['vhandle']'
END
SAY

/* RxLvmGetDisks:
 *   Query the list of physical disk drives.  Always returns 1.  The parameter
 *   specifies a REXX stem name which will be populated with the disk data.
 *   stem.0 contains the number of disks, and each other stem item contains
 *   the following information:
 *   <handle> <number> <size> <unuseable> <corrupt> <removeable> <serial> <name>
 *     <handle>     An 8-digit hexadecimal string that uniquely identifies the
 *                  disk
 *     <number>     The disk number (1 = first disk, 2 = second disk, etc.)
 *     <size>       The disk's size, in MiB
 *     <unuseable>  Used to indicate if the disk is currently accessible:
 *                      0 - disk is accessible
 *                      1 - disk is inaccessible
 *     <corrupt>    Indicates whether the disk has a corrupt partition table:
 *                      0 - partition table has no detected errors
 *                      1 - partition table is corrupt
 *     <removeable> Indicates whether the disk is removeable or not:
 *                      0 - disk is not removeable (normal disk drive)
 *                      1 - disk is partitionable removeable media
 *                      2 - disk is a "big floppy" style removeable
 *     <serial>     The disk's serial number (an integer value)
 *     <name>       The disk's name (may contain spaces or punctuation marks)
 *
 *   Example:
 *      disks.0 == 3
 *      disks.1 = FC047717 1 156327 0 0 0 890692272 [ D1 ]
 *      disks.2 = FC047767 2 156327 0 0 0 700276006 [ D2 ]
 *      disks.3 = FC0477B7 3 0 1 0 1 0 [ D3 ]
 */
qd = RxLvmGetDisks("disks.")
IF LEFT( qd, 6 ) == 'ERROR:' THEN DO
    PARSE VAR qd 'ERROR: ' lvm_error
    SAY 'LVM.DLL returned error code' lvm_error
    RETURN lvm_error
END
SAY disks.0 'disks found:'
DO i = 1 TO disks.0
    PARSE VAR disks.i dhandle dnum dsize dna dcorrupt drm dserial dname
    SELECT
        WHEN drm == 1 THEN rmnote = 'PRM'
        WHEN drm == 2 THEN rmnote = 'Big Floppy'
        OTHERWISE          rmnote = ''
    END
    IF dcorrupt > 0 THEN nanote = '** Corrupt Partition Table Reported **'
    ELSE IF dna > 0 THEN nanote = '** Not Available **'
    ELSE nanote = ''
    SAY RIGHT( dnum, 2 ) LEFT( dname, 20 ) LEFT( dsize 'MB', 14 ) LEFT('S/N' dserial, 16 ) rmnote
    IF nanote \= '' THEN SAY '  ' nanote
    ELSE DO
/* RxLvmGetPartitions:
 *   Query the list of partitions belonging to the specified disk or volume.
 *   The first parameter is the handle of the disk drive or volume to be queried;
 *   the second parameter specifies a REXX stem name which will be populated with
 *   the partition data.  stem.0 contains the number of partitions, and each
 *   other stem item contains the following information:
 *   <handle> <diskhandle> <volhandle> <status> <filesystem> <size> <os> <boot> <name>
 *     <handle>     An 8-digit hexadecimal string that uniquely identifies the
 *                  partition
 *     <diskhandle> An 8-digit hexadecimal string that uniquely identifies the
 *                  disk on which the partition resides
 *     <volhandle>  An 8-digit hexadecimal string that uniquely identifies the
 *                  volume to which the partition belongs (or 00000000 if none)
 *     <status>     Used to indicate the partition's status:
 *                      F - free space
 *                      A - available
 *                      U - in use, but not part of a volume
 *                      C - partition is a compatibility volume
 *                      L - partition is part of an LVM (advanced) volume
 *                      ? - status could not be determined
 *     <filesystem> The partition's current file system, or ? if none
 *     <size>       The partition's size, in MiB
 *     <os>         The partition type/OS flag (a hexadecimal byte value)
 *     <bootable>   The partition's bootable flag.  This will be one of:
 *                      B - bootable (on Boot Manager menu)
 *                      S - startable
 *                      I - installable
 *                      N - none
 *     <name>       The partition's name (may contain spaces or punctuation marks)
 *
 * Example:
 *    parts.0 = 4
 *    parts.1 = FC176297 FC177767 FC179BB7 C FAT16-H 2000 16 N SADUMP
 *    parts.2 = FC1765B7 FC177767 FC179A57 C FAT16 2000 06 B SERVICE
 *    parts.3 = FC1767C7 FC177767 FC178BD7 L JFS 136001 35 N WORKING
 *    parts.4 = FC1768F7 FC177767 00000000 F ? 16321 00 N [ FS1 ]
*/
        pd = RxLvmGetPartitions( dhandle, 'parts.')
        IF LEFT( pd, 6 ) == 'ERROR:' THEN DO
            PARSE VAR pd 'ERROR: ' lvm_error
            SAY 'LVM.DLL returned error code' lvm_error
            RETURN lvm_error
        END
        DO j = 1 TO parts.0
            PARSE VAR parts.j phnd . . pstatus pfs psize posf pboot pname
            CALL CHAROUT, '  ' j '-' LEFT( pname, 22 ) RIGHT( psize, 8 ) 'MB ' LEFT( pfs, 12 ) ' '
            SELECT
                WHEN pstatus == 'F' THEN CALL CHAROUT, 'FREE SPACE '
                WHEN pstatus == 'A' THEN CALL CHAROUT, '           '
                WHEN pstatus == 'C' THEN CALL CHAROUT, 'Volume (C) '
                WHEN pstatus == 'L' THEN CALL CHAROUT, 'Volume (L) '
                WHEN pstatus == 'U' THEN CALL CHAROUT, 'In Use     '
                OTHERWISE NOP
            END
            SELECT
                WHEN pboot == 'B' THEN SAY ' Bootable'
                WHEN pboot == 'S' THEN SAY ' Startable'
                WHEN pboot == 'I' THEN SAY ' Inst''able'
                OTHERWISE SAY
            END
        END
    END
END
SAY

qm = RxLvmBootMgrMenu("menu.");
IF LEFT( qm, 6 ) == 'ERROR:' THEN DO
    PARSE VAR qm 'ERROR: ' lvm_error
    SAY 'LVM.DLL returned error code' lvm_error
    RETURN lvm_error
END
SAY 'Boot Manager menu contains' menu.0 'entries:'
DO i = 1 TO menu.0
    SAY menu.i
END

/* RxLvmEngineClose:
 *   Close the LVM Engine.  Always do this once you don't need to talk to LVM
 *   anymore.  Returns ''.
 */
CALL RxLvmEngineClose

/* RxLvmDropFuncs:
 *   Deregister all LVM.DLL functions.  Returns ''
 */
CALL RxLvmDropFuncs
RETURN



NOVALUE:
    SAY
    CALL LINEOUT 'STDERR:', RIGHT( sigl, 5 ) '+++ Uninitialized variable'
    CALL LINEOUT 'STDERR:', '      +++' STRIP( SOURCELINE( sigl ))
EXIT



/*

ERROR CODES RETURNED BY THE LVM ENGINE

(Many of these error codes should actually be impossible to receive from RXLVM,
since the corresponding operations are not supported by the library.)

LVM_ENGINE_NO_ERROR                           0     Operation succeeded.
LVM_ENGINE_OUT_OF_MEMORY                      1     Not enough memory was available to process the request.
LVM_ENGINE_IO_ERROR                           2     Unable to read from or write to a disk.
LVM_ENGINE_BAD_HANDLE                         3     An invalid handle was specified.
LVM_ENGINE_INTERNAL_ERROR                     4     An internal error was detected by the LVM engine.
LVM_ENGINE_ALREADY_OPEN                       5     The LVM engine has already been opened by this program.
LVM_ENGINE_NOT_OPEN                           6     The LVM engine has not yet been opened by this program.
LVM_ENGINE_NAME_TOO_BIG                       7     The device name exceeds the maximum length.
LVM_ENGINE_OPERATION_NOT_ALLOWED              8     The requested operation is not permitted.
LVM_ENGINE_DRIVE_OPEN_FAILURE                 9     Unable to open drive(s); another LVM program may be running.
LVM_ENGINE_BAD_PARTITION                     10     The specified partition is not useable.
LVM_ENGINE_CAN_NOT_MAKE_PRIMARY_PARTITION    11     Primary partition cannot be created using the requested parameters.
LVM_ENGINE_TOO_MANY_PRIMARY_PARTITIONS       12     Drive already has the maximum number of primary partitions.
LVM_ENGINE_CAN_NOT_MAKE_LOGICAL_DRIVE        13     Logical partition cannot be created using the requested parameters.
LVM_ENGINE_REQUESTED_SIZE_TOO_BIG            14     The requested size is too large for the available space.
LVM_ENGINE_1024_CYLINDER_LIMIT               15     The system cannot boot partitions beyond 1024 cylinders.
LVM_ENGINE_PARTITION_ALIGNMENT_ERROR         16     The disk's partitions are improperly aligned.
LVM_ENGINE_REQUESTED_SIZE_TOO_SMALL          17     The requested size is too small.
LVM_ENGINE_NOT_ENOUGH_FREE_SPACE             18     Not enough free space is available to perform the operation.
LVM_ENGINE_BAD_ALLOCATION_ALGORITHM          19     An invalid allocation algorithm was requested when creating a partition.
LVM_ENGINE_DUPLICATE_NAME                    20     The specified name is already in use.
LVM_ENGINE_BAD_NAME                          21     The specified name is invalid.
LVM_ENGINE_BAD_DRIVE_LETTER_PREFERENCE       22     The requested drive letter is not available.
LVM_ENGINE_NO_DRIVES_FOUND                   23     No drives were found.
LVM_ENGINE_WRONG_VOLUME_TYPE                 24     The requested operation cannot be performed on volumes of this type.
LVM_ENGINE_VOLUME_TOO_SMALL                  25     The requested volume size is too small.
LVM_ENGINE_BOOT_MANAGER_ALREADY_INSTALLED    26     Boot Manager is already installed.
LVM_ENGINE_BOOT_MANAGER_NOT_FOUND            27     Boot Manager is not installed.
LVM_ENGINE_INVALID_PARAMETER                 28     An invalid parameter was passed to LVM.
LVM_ENGINE_BAD_FEATURE_SET                   29     An invalid feature set was requested.
LVM_ENGINE_TOO_MANY_PARTITIONS_SPECIFIED     30     Too many partitions were specified for the requested operation.
LVM_ENGINE_LVM_PARTITIONS_NOT_BOOTABLE       31     Advanced/LVM volumes cannot be made bootable.
LVM_ENGINE_PARTITION_ALREADY_IN_USE          32     The selected partition is already in use.
LVM_ENGINE_SELECTED_PARTITION_NOT_BOOTABLE   33     The partition could not be added to the Boot Manager menu.
LVM_ENGINE_VOLUME_NOT_FOUND                  34     A non-existant volume was specified.
LVM_ENGINE_DRIVE_NOT_FOUND                   35     A non-existant drive was specified.
LVM_ENGINE_PARTITION_NOT_FOUND               36     A non-existant partition was specified.
LVM_ENGINE_TOO_MANY_FEATURES_ACTIVE          37     Too many features are active within the LVM engine.
LVM_ENGINE_PARTITION_TOO_SMALL               38     The partition is too small for the requested operation.
LVM_ENGINE_MAX_PARTITIONS_ALREADY_IN_USE     39     The maximum number of partitions is in use.
LVM_ENGINE_IO_REQUEST_OUT_OF_RANGE           40     The read/write request was out of range.
LVM_ENGINE_SPECIFIED_PARTITION_NOT_STARTABLE 41     The specified partition could not be made startable.
LVM_ENGINE_SELECTED_VOLUME_NOT_STARTABLE     42     The specified volume could not be made startable.
LVM_ENGINE_EXTENDFS_FAILED                   43     A partition could not be added to an existing volume.
LVM_ENGINE_REBOOT_REQUIRED                   44     The system must be rebooted.
LVM_ENGINE_CAN_NOT_OPEN_LOG_FILE             45     The LVM log file could not be opened.
LVM_ENGINE_CAN_NOT_WRITE_TO_LOG_FILE         46     The LVM log file could not be written to.
LVM_ENGINE_REDISCOVER_FAILED                 47     The attempt to rediscover removeable media failed.

*/
