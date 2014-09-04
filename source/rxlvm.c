#ifndef OS2_INCLUDED
    #include <os2.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <lvm_intr.h>

#define INCL_RXSHV
#define INCL_RXFUNC
#include <rexxsaa.h>


// CONSTANTS

#define US_VERSION_MAJOR    0                       // Major version number of this library
#define US_VERSION_MINOR    5                       // Minor version number of this library
#define US_VERSION_REFRESH  1                       // Refresh level of this library

// (string length constants ending in 'Z' include space for the null terminator)
#define US_INTEGER_MAXZ     12                      // Maximum length of an integer string
#define US_ERRSTR_MAXZ    ( 10 + US_INTEGER_MAXZ )  // Maximum length of a SZ_ENGINE_ERROR string
#define US_DEVTYPE_MAXZ     4                       // Maximum length of a device-type string
#define US_BMINFO_MAXZ      32                      // Maximum length of a Boot Manager information string
#define US_SZINFO_MAXZ      255                     // Maximum length of an information string (used for stem values)
#define US_STEM_MAXZ        238                     // Maximum length of a stem variable (no extension)
#define US_COMPOUND_MAXZ  ( US_STEM_MAXZ + US_INTEGER_MAXZ ) // Maximum length of a compound variable (stem+extension)

#define UL_SECTORS_PER_MB ( 1048576 / BYTES_PER_SECTOR )     // Used to convert sector sizes to MB

#define SZ_ENGINE_ERROR     "ERROR: %d"             // Template for LVM error string
#define SZ_LIBRARY_NAME     "RXLVM"                 // Name of this library

// Device type constants
#define SZ_DEVICE_HDD       "HDD"                   // Hard disk drive
#define SZ_DEVICE_PRM       "PRM"                   // Partitioned removeable media
#define SZ_DEVICE_CDROM     "CD"                    // CD/DVD drive
#define SZ_DEVICE_NETWORK   "LAN"                   // Network drive
#define SZ_DEVICE_OTHER     "?"                     // Unrecognized non-LVM device (e.g. RAM disk)

// Partition status constants
#define CH_PTYPE_FREESPACE  'F'                     // Free space
#define CH_PTYPE_AVAILABLE  'A'                     // Available (not part of a volume)
#define CH_PTYPE_CVOLUME    'C'                     // Belongs to a compatibility volume
#define CH_PTYPE_LVOLUME    'L'                     // Belongs to an LVM-type (advanced) volume
#define CH_PTYPE_INUSE      'U'                     // Marked 'in use' but not part of a volume
#define CH_PTYPE_UNKNOWN    '?'                     // Unknown/error condition (should be impossible)

// Boot flag constants
#define CH_FBOOT_BOOTABLE   'B'                     // Bootable (on Boot Manager menu)
#define CH_FBOOT_STARTABLE  'S'                     // Startable (directly bootable)
#define CH_FBOOT_INSTABLE   'I'                     // Installable (specific to IBM installer)
#define CH_FBOOT_NONE       'N'                     // None (not bootable)

// Removeable media type flags
#define US_RMEDIA_PRM       1                       // Partitionable removeable media
#define US_RMEDIA_BIGFLOPPY 2                       // "Big floppy" style removeable media

// List of functions to be registered by RxLvmAddFuncs
static PSZ RxLvmFunctionTbl[] = {
    "RxLvmDropFuncs",
    "RxLvmVersion",
    "RxLvmBootMgrInfo",
    "RxLvmBootMgrMenu",
    "RxLvmEngineClose",
    "RxLvmEngineOpen",
    "RxLvmGetDisks",
    "RxLvmGetPartitions",
    "RxLvmGetVolumes",
    "RxLvmRediscoverPRM"
};


// FUNCTION DECLARATIONS

// Exported REXX functions
RexxFunctionHandler RxLvmLoadFuncs;
RexxFunctionHandler RxLvmDropFuncs;
RexxFunctionHandler RxLvmVersion;
RexxFunctionHandler RxLvmBootMgrInfo;
RexxFunctionHandler RxLvmEngineClose;
RexxFunctionHandler RxLvmEngineOpen;
RexxFunctionHandler RxLvmGetDisks;
RexxFunctionHandler RxLvmGetPartitions;
RexxFunctionHandler RxLvmGetVolumes;
RexxFunctionHandler RxLvmRediscoverPRM;

// Private internal functions
PSZ  FixedVolumeFileSystem( ADDRESS volume, PSZ pszReportedFS );
PSZ  FixedPartitionFileSystem( BYTE fOS, PSZ pszReportedFS );
void EngineError( PRXSTRING prsResult, ULONG ulErrorCode );
void WriteStemElement( PSZ pszStem, ULONG ulIndex, PSZ pszValue );


/* ------------------------------------------------------------------------- *
 * RxLvmLoadFuncs                                                            *
 *                                                                           *
 * Should be self-explanatory...                                             *
 *                                                                           *
 * REXX ARGUMENTS:    none                                                   *
 * REXX RETURN VALUE: ""                                                     *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmLoadFuncs( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    int entries,
        i;

    if ( argc > 0 ) return ( 40 );
    entries = sizeof(RxLvmFunctionTbl) / sizeof(PSZ);
    for ( i = 0; i < entries; i++ )
        RexxRegisterFunctionDll( RxLvmFunctionTbl[i], SZ_LIBRARY_NAME, RxLvmFunctionTbl[i] );

    MAKERXSTRING( *prsResult, "", 0 );
    return ( 0 );
}


/* ------------------------------------------------------------------------- *
 * RxLvmDropFuncs                                                            *
 *                                                                           *
 * Ditto.                                                                    *
 *                                                                           *
 * REXX ARGUMENTS:    none                                                   *
 * REXX RETURN VALUE: ""                                                     *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmDropFuncs( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    int entries,
        i;

    if ( argc > 0 ) return ( 40 );
    entries = sizeof(RxLvmFunctionTbl) / sizeof(PSZ);
    for ( i = 0; i < entries; i++ )
        RexxDeregisterFunction( RxLvmFunctionTbl[i] );

    MAKERXSTRING( *prsResult, "", 0 );
    return ( 0 );
}


/* ------------------------------------------------------------------------- *
 * RxLvmVersion                                                              *
 *                                                                           *
 * Returns the current version string.                                       *
 *                                                                           *
 * REXX ARGUMENTS:    none                                                   *
 * REXX RETURN VALUE: current version in the form "major.minor.refresh"      *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmVersion( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    CHAR szVersion[ 12 ];

    if ( argc > 0 ) return ( 40 );
    sprintf( szVersion, "%d.%d.%d", US_VERSION_MAJOR, US_VERSION_MINOR, US_VERSION_REFRESH );
    MAKERXSTRING( *prsResult, szVersion, strlen(szVersion) );
    return ( 0 );
}


/* ------------------------------------------------------------------------- *
 * RxLvmRediscoverPRM()                                                      *
 *                                                                           *
 * Checks to see if any Partitionable Removeable Media (e.g. Zip disks) have *
 * been inserted since the last check.  IMPORTANT: the LVM Engine must be    *
 * CLOSED before this function may be called.  This function will fail if    *
 * the LVM Engine is open.                                                   *
 *                                                                           *
 * REXX ARGUMENTS:    none                                                   *
 * REXX RETURN VALUE: "" or error string                                     *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmRediscoverPRM( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    ULONG ulError;      // LVM.DLL error indicator

    if ( argc > 0 ) return ( 40 );
    Rediscover_PRMs( &ulError );
    if ( ulError != LVM_ENGINE_NO_ERROR ) EngineError( prsResult, ulError );
    else MAKERXSTRING( *prsResult, "", 0 );
    return ( 0 );
}


/* ------------------------------------------------------------------------- *
 * RxLvmEngineOpen                                                           *
 *                                                                           *
 * Opens the LVM engine (LVM.DLL), which is required for all LVM operations  *
 * (except, for some reason, the Rediscover_PRMs operation).                 *
 *                                                                           *
 * REXX ARGUMENTS:    none                                                   *
 * REXX RETURN VALUE: "" or error string                                     *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmEngineOpen( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    ULONG ulError;

    if ( argc > 0 ) return ( 40 );
    Open_LVM_Engine( TRUE, &ulError );
    if ( ulError != LVM_ENGINE_NO_ERROR ) {
        EngineError( prsResult, ulError );
        return ( 0 );
    }
    MAKERXSTRING( *prsResult, "", 0 );
    return ( 0 );
}


/* ------------------------------------------------------------------------- *
 * RxLvmEngineClose                                                          *
 *                                                                           *
 * Closes the LVM engine.                                                    *
 *                                                                           *
 * REXX ARGUMENTS:    none                                                   *
 * REXX RETURN VALUE: "" or error string                                     *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmEngineClose( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    if ( argc > 0 ) return ( 40 );
    Close_LVM_Engine();
    MAKERXSTRING( *prsResult, "", 0 );
    return ( 0 );
}


/* ------------------------------------------------------------------------- *
 * RxLvmBootMgrInfo                                                          *
 *                                                                           *
 * REXX ARGUMENTS: none                                                      *
 *                                                                           *
 * REXX RETURN VALUE:                                                        *
 *   "" if Boot Manager is not installed.  If an LVM error occurs, an error  *
 *   string is returned.  Otherwise, the returned string is in the format:   *
 *   "<disk> <active> <timeout> <default-type> <default-handle>".  As usual, *
 *   can also return an error string if an LVM error occurs.                 *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmBootMgrInfo( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    // Data structures defined by LVM.DLL that we use for our queries
    Partition_Information_Record enginePartitionInfo;
    Drive_Control_Array          engineDisks;
    Drive_Control_Record         engineCurrentDisk;

    ULONG   ulDisk = 0,     // Number of the physical disk Boot Manager is on
            i,              // Guess :)
            ulTimeout,      // Indicates the timeout value for a timeout boot
            ulError;        // LVM.DLL error indicator
    ADDRESS partition,      // LVM handle of physical Boot Manager partition
            drive,          // LVM handle of the disk drive Boot Manager is on
            defaultEntry;   // LVM handle of the default boot menu entry
    BOOLEAN fVolume,        // Indicates whether said entry is a volume rather just than a partition
            fAdvanced,      // Indicates whether Advanced (verbose) view mode is used
            fTimeout,       // Indicates whether a timeout boot will occur
            fActive;        // Indicates whether the Boot Manager partition is 'active'
    CHAR    szInfo[ US_BMINFO_MAXZ ];   // Buffer used to build the final return string


    if ( argc > 0 ) return ( 40 );

    // Query the Boot Manager partition handle
    partition = Get_Boot_Manager_Handle( &ulError );
    if ( ulError != LVM_ENGINE_NO_ERROR ) {
        EngineError( prsResult, ulError );
        return ( 0 );
    }

    // Return '' if Boot Manager is not installed
    if ( partition == NULL ) {
        MAKERXSTRING( *prsResult, "", 0 );
        return ( 0 );
    }

    // Find out what disk drive the Boot Manager partition resides on
    enginePartitionInfo = Get_Partition_Information( partition, &ulError );
    if ( ulError != LVM_ENGINE_NO_ERROR ) {
        EngineError( prsResult, ulError );
        return ( 0 );
    }
    drive = enginePartitionInfo.Drive_Handle;
    engineDisks = Get_Drive_Control_Data( &ulError );
    if ( ulError != LVM_ENGINE_NO_ERROR ) {
        EngineError( prsResult, ulError );
        return ( 0 );
    }
    for ( i = 0; i < engineDisks.Count; i++ ) {
        engineCurrentDisk = engineDisks.Drive_Control_Data[ i ];
        if ( engineCurrentDisk.Drive_Handle == drive )
            ulDisk = engineCurrentDisk.Drive_Number;
    }

    // Get the current Boot Manager configuration
    Get_Boot_Manager_Options( &defaultEntry, &fVolume,
                              &fTimeout,     &ulTimeout,
                              &fAdvanced,    &ulError   );
    if ( ulError != LVM_ENGINE_NO_ERROR ) {
        EngineError( prsResult, ulError );
        return ( 0 );
    }

    // Figure out if Boot Manager is 'active'
    if ( enginePartitionInfo.Active_Flag == ACTIVE_PARTITION )
        fActive = TRUE;
    else
        fActive = FALSE;

    // Now return all the nice data
    sprintf( szInfo, "%d %d %d %d %X", ulDisk, fActive, ulTimeout, fVolume, defaultEntry );
    MAKERXSTRING( *prsResult, szInfo, strlen(szInfo) );
    return ( 0 );
}



/* ------------------------------------------------------------------------- *
 * RxLvmBootMgrMenu()                                                        *
 *                                                                           *
 * Returns the list of volumes and/or partitions on the Boot Manager menu    *
 * (i.e. have the 'bootable' flag set).                                      *
 *                                                                           *
 * Data representing the menu entries is written to the specified REXX       *
 * variable.  stem.0 contains the number of entries, and each other item is: *
 * "<handle> <type> <name>"                                                  *
 * e.g. menu.1 == "0C0FB884 V OS/2 System"                                   *
 *                                                                           *
 * REXX ARGUMENTS:    name of the REXX stem variable to populate             *
 *                                                                           *
 * REXX RETURN VALUE: "1" or error string                                    *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmBootMgrMenu( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    // Data structures defined by LVM.DLL that we use for our queries
    Boot_Manager_Menu            engineBootMenu;
    Boot_Manager_Menu_Item       engineBootMenuEntry;
    Volume_Information_Record    engineVolumeInfo;
    Partition_Information_Record enginePartitionInfo;

    ULONG  ulError,                     // LVM Engine error code
           i;
    CHAR   szStem[ US_STEM_MAXZ ],      // Buffers used for building strings ...
           szNumber[ US_INTEGER_MAXZ ],
           szMenuItem[ US_SZINFO_MAXZ ];
    USHORT usRemoveable = 0;


    // Do some validity checking on the arguments
    if (( argc != 1 ) ||                        // Make sure we have exactly one argument...
        ( ! RXVALIDSTRING(argv[0]) ) ||         // ...which is a valid REXX string...
        ( RXSTRLEN(argv[0]) > US_STEM_MAXZ ))   // ...and isn't too long.
        return ( 40 );

    engineBootMenu = Get_Boot_Manager_Menu( &ulError );
    if ( ulError != LVM_ENGINE_NO_ERROR ) {
        EngineError( prsResult, ulError );
        return ( 0 );
    }

    // Generate the stem variable name from the argument (stripping any final dot)
    if ( argv[0].strptr[ argv[0].strlength-1 ] == '.') argv[0].strlength--;
    strncpy( szStem, argv[0].strptr, RXSTRLEN(argv[0]) );
    szStem[ RXSTRLEN(argv[0]) ] = '\0';

    // Create a stem.0 element containing the number of disks
    sprintf( szNumber, "%d", engineBootMenu.Count );
    WriteStemElement( szStem, 0, szNumber );

    for ( i = 0; i < engineBootMenu.Count; i++ ) {
        engineBootMenuEntry = engineBootMenu.Menu_Items[ i ];
        if ( engineBootMenuEntry.Volume ) {
            engineVolumeInfo = Get_Volume_Information( engineBootMenuEntry.Handle, &ulError );
            if ( ulError != LVM_ENGINE_NO_ERROR ) {
                EngineError( prsResult, ulError );
                return ( 0 );
            }
            sprintf( szMenuItem, "%08X 1 %s", engineBootMenuEntry.Handle, engineVolumeInfo.Volume_Name );
        } else {
            enginePartitionInfo = Get_Partition_Information( engineBootMenuEntry.Handle, &ulError );
            if ( ulError != LVM_ENGINE_NO_ERROR ) {
                EngineError( prsResult, ulError );
                return ( 0 );
            }
            sprintf( szMenuItem, "%08X 0 %s", engineBootMenuEntry.Handle, enginePartitionInfo.Partition_Name );
        }
        // Create a stem variable item for the current disk
        WriteStemElement( szStem, i+1, szMenuItem );
    }

    // Always return a standard value (1) on success
    MAKERXSTRING( *prsResult, "1", 1 );
    return ( 0 );
}


/* ------------------------------------------------------------------------- *
 * RxLvmGetDisks                                                             *
 *                                                                           *
 * Data representing all disk drives is written to the specified REXX        *
 * variable.  stem.0 contains the number of disks, and each other item is:   *
 * "<handle> <num> <size> <unusable> <corrupt> <removable> <serial> <name>"  *
 * e.g. disks.1 == "0C0FB884 1 156327 0 0 0 485209174 [ D1 ]"                *
 *                                                                           *
 * REXX ARGUMENTS:    name of the REXX stem variable to populate             *
 *                                                                           *
 * REXX RETURN VALUE: "1" or error string                                    *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmGetDisks( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    // Data structures defined by LVM.DLL that we use for our queries
    Drive_Control_Array      engineDrives;
    Drive_Control_Record     engineDriveRecord;
    Drive_Information_Record engineDriveInfo;

    ULONG  ulError,
           i,
           ulSize,
           ulSerial;
    CHAR   szStem[ US_STEM_MAXZ ],      // Buffers used for building strings ...
           szNumber[ US_INTEGER_MAXZ ],
           szDiskInfo[ US_STEM_MAXZ ];
    USHORT usRemoveable = 0;
    BOOL   fUnuseable = FALSE,
           fCorrupt   = FALSE;


    // Do some validity checking on the arguments
    if (( argc != 1 ) ||                        // Make sure we have exactly one argument...
        ( ! RXVALIDSTRING(argv[0]) ) ||         // ...which is a valid REXX string...
        ( RXSTRLEN(argv[0]) > US_STEM_MAXZ ))   // ...and isn't too long.
        return ( 40 );

    // Get the list of disks from LVM.DLL
    engineDrives = Get_Drive_Control_Data( &ulError );
    if ( ulError != LVM_ENGINE_NO_ERROR ) {
        EngineError( prsResult, ulError );
        return ( 0 );
    }

    // Generate the stem variable name from the argument (stripping any final dot)
    if ( argv[0].strptr[ argv[0].strlength-1 ] == '.') argv[0].strlength--;
    strncpy( szStem, argv[0].strptr, RXSTRLEN(argv[0]) );
    szStem[ RXSTRLEN(argv[0]) ] = '\0';

    // Create a stem.0 element containing the number of disks
    sprintf( szNumber, "%d", engineDrives.Count );
    WriteStemElement( szStem, 0, szNumber );

    // Now generate the information for each disk
    for ( i = 0; i < engineDrives.Count; i++ ) {

        // Get the current drive information
        engineDriveRecord = engineDrives.Drive_Control_Data[ i ];
        engineDriveInfo = Get_Drive_Status( engineDriveRecord.Drive_Handle, &ulError );
        if ( ulError != LVM_ENGINE_NO_ERROR ) {
            EngineError( prsResult, ulError );
            return ( 0 );
        }

        if ( engineDriveRecord.Drive_Is_PRM ) usRemoveable = US_RMEDIA_PRM;
        if ( engineDriveInfo.Is_Big_Floppy  ) usRemoveable = US_RMEDIA_BIGFLOPPY;

        if (( engineDriveInfo.Is_Big_Floppy ) || ( engineDriveInfo.Unusable )) {
            fUnuseable = TRUE;
            ulSize     = 0;
            ulSerial   = 0;
        } else {
            if ( engineDriveInfo.Corrupt_Partition_Table ) fCorrupt = TRUE;
            ulSize   = ( engineDriveRecord.Drive_Size ) / UL_SECTORS_PER_MB;
            ulSerial = engineDriveRecord.Drive_Serial_Number;
        }

        sprintf( szDiskInfo, "%08X %d %d %d %d %d %d %s",
                 engineDriveRecord.Drive_Handle,
                 engineDriveRecord.Drive_Number,
                 ulSize,
                 fUnuseable,
                 fCorrupt,
                 usRemoveable,
                 ulSerial,
                 engineDriveInfo.Drive_Name             );

        // Create a stem variable item for the current disk
        WriteStemElement( szStem, i+1, szDiskInfo );

    }
    // Free the LVM data structures
    Free_Engine_Memory( engineDrives.Drive_Control_Data );

    // Always return a standard value (1) on success
    MAKERXSTRING( *prsResult, "1", 1 );
    return ( 0 );
}


/* ------------------------------------------------------------------------- *
 * RxLvmGetPartitions                                                        *
 *                                                                           *
 * Data representing all partitions belonging to the specified object is     *
 * written to the specified REXX variable.  stem.0 contains the number of    *
 * disks, and each other item is:                                            *
 * "<phandle> <dhandle> <vhandle> <status> <fs> <size> <os> <boot> <name>"   *
 * e.g. parts.1 == "FC177C67 FC177717 FC179B17 C HPFS 2047 07 N OS/2"        *
 *                                                                           *
 * REXX ARGUMENTS:    1 - handle of the object to query                      *
 *                    2 - name of the REXX stem variable to populate         *
 *                                                                           *
 * REXX RETURN VALUE: "1" or error string                                    *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmGetPartitions( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    // Data structures defined by LVM.DLL that we use for our queries
    Partition_Information_Array  enginePartitions;
    Partition_Information_Record enginePartInfo;
    Volume_Information_Record    engineVolumeInfo;

    ADDRESS ulHandle;                    // requested handle
    ULONG   ulError,                     // LVM.DLL error indicator
            i,                           // Duh
            ulRc;                        // Used for return code
    PSZ     pszCompound,                 // The current compound variable name
            pszPartInfo;                 // The current partition info string
    CHAR    szStem[ US_STEM_MAXZ ],      // Buffers used for building strings ...
            szNumber[ US_INTEGER_MAXZ ],
            szDevice[ US_DEVTYPE_MAXZ ],
            szPartInfo[ US_STEM_MAXZ ],
            cStatus,                     // adjusted partition status flag
            cBootable;                   // Partition bootable flag (N/B/S/I)


    // Do some validity checking on the arguments
    if (( argc != 2 ) ||                        // Make sure we have exactly two arguments...
        ( ! RXVALIDSTRING(argv[0]) ) ||         // ...which are valid REXX strings...
        ( ! RXVALIDSTRING(argv[1]) ) ||
        ( RXSTRLEN(argv[1]) > US_STEM_MAXZ )    // ...and the stem name isn't too long.
       )
        return ( 40 );

    // Parse the handle argument
    if ( sscanf( argv[0].strptr, "%X", &ulHandle ) < 1 )
        return ( 40 );

    // Get the list of partitions from LVM.DLL
    enginePartitions = Get_Partitions( ulHandle, &ulError );
    if ( ulError != LVM_ENGINE_NO_ERROR ) {
        EngineError( prsResult, ulError );
        return ( 0 );
    }

    // Generate the stem variable name from the argument
    // (and strip any terminating dot while we're at it)
    if ( argv[1].strptr[ argv[1].strlength-1 ] == '.') argv[1].strlength--;
    strncpy( szStem, argv[1].strptr, RXSTRLEN(argv[1]) );
    szStem[ RXSTRLEN(argv[1]) ] = '\0';

    // Create a stem.0 element containing the number of volumes
    sprintf( szNumber, "%d", enginePartitions.Count );
    WriteStemElement( szStem, 0, szNumber );

    // Now generate the information for each partition
    for ( i = 0; i < enginePartitions.Count; i++ ) {
        enginePartInfo = enginePartitions.Partition_Array[ i ];

        switch ( enginePartInfo.Partition_Status ) {
            case PARTITION_IS_FREE_SPACE:
                cStatus   = CH_PTYPE_FREESPACE;
                cBootable = CH_FBOOT_NONE;
                break;

            case PARTITION_IS_IN_USE:
                if ( enginePartInfo.Volume_Handle == NULL ) {
                    // Marked "in use", but not part of a volume - probably Boot Manager
                    cStatus = CH_PTYPE_INUSE;
                    if ( enginePartInfo.Active_Flag == ACTIVE_PARTITION )
                        cBootable = CH_FBOOT_STARTABLE;
                    else if ( enginePartInfo.On_Boot_Manager_Menu )
                        cBootable = CH_FBOOT_BOOTABLE;
                    else
                        cBootable = CH_FBOOT_NONE;
                } else {
                    // Partition belongs to a volume
                    switch ( enginePartInfo.Partition_Type ) {
                        case 0 : cStatus = CH_PTYPE_FREESPACE;  break;  // Free space
                        case 1 : cStatus = CH_PTYPE_LVOLUME;    break;  // (Part of) LVM volume
                        case 2 : cStatus = CH_PTYPE_CVOLUME;    break;  // Compatibility volume
                        default: cStatus = CH_PTYPE_UNKNOWN;    break;  // Unknown/error
                    }
                    engineVolumeInfo = Get_Volume_Information( enginePartInfo.Volume_Handle, &ulError );
                    if ( ulError != LVM_ENGINE_NO_ERROR ) {
                        EngineError( prsResult, ulError );
                        return ( 0 );
                    }
                    switch ( engineVolumeInfo.Status ) {
                        case 1 : cBootable = CH_FBOOT_BOOTABLE;   break;
                        case 2 : cBootable = CH_FBOOT_STARTABLE;  break;
                        case 3 : cBootable = CH_FBOOT_INSTABLE;   break;
                        default: cBootable = CH_FBOOT_NONE;       break;
                    }
                }
                break;

            case PARTITION_IS_AVAILABLE:
                cStatus = CH_PTYPE_AVAILABLE;
                if ( enginePartInfo.Active_Flag == ACTIVE_PARTITION ) cBootable = CH_FBOOT_STARTABLE;
                else if ( enginePartInfo.On_Boot_Manager_Menu )       cBootable = CH_FBOOT_BOOTABLE;
                else                                                  cBootable = CH_FBOOT_NONE;
                break;

            default:
                // Fall-through; should be unreachable
                cStatus   = CH_PTYPE_UNKNOWN;
                cBootable = CH_FBOOT_NONE;
                break;
        }

        sprintf( szPartInfo, "%08X %08X %08X %c %s %d %02X %c %s",
                 enginePartInfo.Partition_Handle,
                 enginePartInfo.Drive_Handle,
                 enginePartInfo.Volume_Handle,
                 cStatus,
                 FixedPartitionFileSystem( enginePartInfo.OS_Flag, enginePartInfo.File_System_Name ),
                 enginePartInfo.Usable_Partition_Size / UL_SECTORS_PER_MB,
                 enginePartInfo.OS_Flag,
                 cBootable,
                 enginePartInfo.Partition_Name );

        // Create a stem variable item for the current partition
        WriteStemElement( szStem, i+1, szPartInfo );

    }

    // Free the LVM data structures
    Free_Engine_Memory( enginePartitions.Partition_Array );

    // Always return a standard value (1) on success
    MAKERXSTRING( *prsResult, "1", 1 );
    return ( 0 );
}


/* ------------------------------------------------------------------------- *
 * RxLvmGetVolumes                                                           *
 *                                                                           *
 * Data representing all logical volumes is written to the specified REXX    *
 * variable.  stem.0 contains the number of volumes, and each other item is: *
 * "<handle> <letter> <pref> <fs> <size> <dev> <type> <bootable> <name>"     *
 * e.g. volumes.1 == "0A00CDB1 C C HPFS 2047 HDD 0 B eComStation"            *
 *                                                                           *
 * REXX ARGUMENTS:    name of the REXX stem variable to populate             *
 *                                                                           *
 * REXX RETURN VALUE: "1" or error string                                    *
 * ------------------------------------------------------------------------- */
ULONG APIENTRY RxLvmGetVolumes( PSZ pszName, ULONG argc, RXSTRING argv[], PSZ pszQueue, PRXSTRING prsResult )
{
    // Data structures defined by LVM.DLL that we use for our queries
    Volume_Control_Array         engineVolumes;
    Volume_Information_Record    engineVolumeInfo;
    Partition_Information_Array  enginePartitions;
    Partition_Information_Record enginePartInfo;

    ULONG     ulError,                  // LVM.DLL error indicator
              i,                        // Duh
              ulRc;                     // Used for return code
    USHORT    usVolType;                // Volume type flag (0 or 1)
    PSZ       pszCompound,              // The current compound variable name
              pszVolInfo;               // The current volume info string
    CHAR      szStem[ US_STEM_MAXZ ],   // Buffers used for building strings ...
              szNumber[ US_INTEGER_MAXZ ],
              szDevice[ US_DEVTYPE_MAXZ ],
              szVolInfo[ US_STEM_MAXZ ],
              cCurrent,                 // A volume's current drive letter
              cPreference,              // A volume's preferred drive letter
              cBootable;                // Volume bootable flag (N/B/S/I)
    BOOLEAN   fCompatible;              // Use to query volume type from LVM.DLL


    // Do some validity checking on the arguments
    if (( argc != 1 ) ||                        // Make sure we have exactly one argument...
        ( ! RXVALIDSTRING(argv[0]) ) ||         // ...which is a valid REXX string...
        ( RXSTRLEN(argv[0]) > US_STEM_MAXZ )    // ...and isn't too long.
       )
        return ( 40 );

    // Get the list of volumes from LVM.DLL
    engineVolumes = Get_Volume_Control_Data( &ulError );
    if ( ulError != LVM_ENGINE_NO_ERROR ) {
        EngineError( prsResult, ulError );
        return ( 0 );
    }

    // Generate the stem variable name from the argument
    // (and strip any terminating dot while we're at it)
    // if ( argv[0].strlength > US_STEM_MAXZ - 5 ) argv[0].strlength = US_STEM_MAXZ - 5;
    if ( argv[0].strptr[ argv[0].strlength-1 ] == '.') argv[0].strlength--;
    strncpy( szStem, argv[0].strptr, RXSTRLEN(argv[0]) );
    szStem[ RXSTRLEN(argv[0]) ] = '\0';

    // Create a stem.0 element containing the number of volumes
    sprintf( szNumber, "%d", engineVolumes.Count );
    WriteStemElement( szStem, 0, szNumber );

    // Now generate the information for each volume
    for ( i = 0; i < engineVolumes.Count; i++ ) {

        // Get the current volume information record
        engineVolumeInfo = Get_Volume_Information( engineVolumes.Volume_Control_Data[ i ].Volume_Handle, &ulError );
        if ( ulError != LVM_ENGINE_NO_ERROR ) {
            EngineError( prsResult, ulError );
            return ( 0 );
        }

        // Now build our info-string that will be returned to the REXX program
        switch ( engineVolumes.Volume_Control_Data[ i ].Device_Type ) {
            case LVM_HARD_DRIVE : strcpy( szDevice, SZ_DEVICE_HDD );     break;
            case LVM_PRM        : strcpy( szDevice, SZ_DEVICE_PRM );     break;
            case NON_LVM_CDROM  : strcpy( szDevice, SZ_DEVICE_CDROM );   break;
            case NETWORK_DRIVE  : strcpy( szDevice, SZ_DEVICE_NETWORK ); break;
            default             : strcpy( szDevice, SZ_DEVICE_OTHER );   break;
        }
        usVolType = ! engineVolumeInfo.Compatibility_Volume;
        if ( engineVolumes.Volume_Control_Data[ i ].Device_Type >= NON_LVM_CDROM ) cBootable = CH_FBOOT_NONE;
        else switch ( engineVolumeInfo.Status ) {
            case 1 : cBootable = CH_FBOOT_BOOTABLE;  break;
            case 2 : cBootable = CH_FBOOT_STARTABLE; break;
            case 3 : cBootable = CH_FBOOT_INSTABLE;  break;
            default: cBootable = CH_FBOOT_NONE;      break;
        }
        if ( isalpha(engineVolumeInfo.Current_Drive_Letter) | engineVolumeInfo.Current_Drive_Letter == '*')
            cCurrent = engineVolumeInfo.Current_Drive_Letter;
        else cCurrent = '?';
        if ( isalpha(engineVolumeInfo.Drive_Letter_Preference) | engineVolumeInfo.Drive_Letter_Preference == '*')
            cPreference = engineVolumeInfo.Drive_Letter_Preference;
        else cPreference = '?';

        sprintf( szVolInfo, "%08X %c %c %s %d %s %d %c %s",
                 engineVolumes.Volume_Control_Data[ i ].Volume_Handle,
                 cCurrent,
                 cPreference,
                 FixedVolumeFileSystem( engineVolumes.Volume_Control_Data[ i ].Volume_Handle, engineVolumeInfo.File_System_Name ),
                 engineVolumeInfo.Volume_Size / UL_SECTORS_PER_MB,
                 szDevice,
                 usVolType,
                 cBootable,
                 engineVolumeInfo.Volume_Name );

        // Create a stem variable item for the current volume
        WriteStemElement( szStem, i+1, szVolInfo );

    }

    // Free the LVM data structures
    Free_Engine_Memory( engineVolumes.Volume_Control_Data );

    // Always return a standard value (1) on success
    MAKERXSTRING( *prsResult, "1", 1 );
    return ( 0 );
}


/* ------------------------------------------------------------------------- *
 * FixedVolumeFileSystem                                                     *
 *                                                                           *
 * Double-checks the given volume's filesystem-type string in order to work  *
 * around a bug in the LVM.DLL's reporting of Linux partition types.         *
 * OS Flag 0x82 is Linux Swap, but LVM.DLL reports it as 'Linux'; 0x83 is    *
 * Linux Native, but LVM.DLL reports it as '????'.                           *
 *                                                                           *
 * ARGUMENTS:                                                                *
 *     ADDRESS volume        : Handle to the volume being queried            *
 *     PSZ     pszReportedFS : FS name as reported by LVM.DLL                *
 *                                                                           *
 * RETURNS: PSZ                                                              *
 *     The "fixed" filesystem string.                                        *
 * ------------------------------------------------------------------------- */
PSZ FixedVolumeFileSystem( ADDRESS volume, PSZ pszReportedFS )
{
    Partition_Information_Array enginePartitions;

    ULONG ulError;
    BYTE  fOS;
    PSZ   s,
          pszFixed;

    // Get the OS flag reported by the (first) underlying partition
    enginePartitions = Get_Partitions( volume, &ulError );
    if (( ulError != LVM_ENGINE_NO_ERROR ) || ( enginePartitions.Count == 0 )) {
        if ( strlen(pszReportedFS) == 0 ) return "?";
        while (( s = strchr( pszReportedFS, ' ')) != NULL ) *s = 0xFF;
        return pszReportedFS;
    }

    // Now fix the reported file system based on the OS flag
    pszFixed = FixedPartitionFileSystem( enginePartitions.Partition_Array[ 0 ].OS_Flag,
                                         pszReportedFS                                  );

    // Free the LVM data structure
    Free_Engine_Memory( enginePartitions.Partition_Array );

    return ( pszFixed );
}


/* ------------------------------------------------------------------------- *
 * FixedPartitionFileSystem                                                  *
 *                                                                           *
 * Double-checks the given partition's filesystem-type string in order to    *
 * work around a bug in the LVM.DLL's reporting of Linux partition types;    *
 * see FixedVolumeFileSystem() description.                                  *
 *                                                                           *
 * ARGUMENTS:                                                                *
 *     BYTE fOS           : OS flag reported by the partition                *
 *     PSZ  pszReportedFS : FS name as reported by LVM.DLL                   *
 *                                                                           *
 * RETURNS: PSZ                                                              *
 *     The "fixed" filesystem string.                                        *
 * ------------------------------------------------------------------------- */
PSZ FixedPartitionFileSystem( BYTE fOS, PSZ pszReportedFS )
{
    PSZ s;

    if ( strlen(pszReportedFS) == 0 ) return "?";
    while (( s = strchr( pszReportedFS, ' ')) != NULL ) *s = 0xFF;
    switch ( fOS ) {
        case 0x82 : return ("Linux_Swap");
        case 0x83 : return ("Linux");
        default   : return ( pszReportedFS );
    }
}


/* ------------------------------------------------------------------------- *
 * EngineError                                                               *
 *                                                                           *
 * Writes a standardized error message to an RXSTRING, in the event that an  *
 * error code is returned by LVM.DLL during an operation.                    *
 *                                                                           *
 * ARGUMENTS:                                                                *
 *   PRXSTRING prsResult   : Pointer to the RXSTRING in which the message    *
 *                           will be written.  Must be allocated already.    *
 *   ULONG     ulErrorCode : The error code returned by LVM.DLL.             *
 *                                                                           *
 * RETURNS: N/A                                                              *
 * ------------------------------------------------------------------------- */
void EngineError( PRXSTRING prsResult, ULONG ulErrorCode )
{
    CHAR szError[ US_ERRSTR_MAXZ ];

    sprintf( szError, SZ_ENGINE_ERROR, ulErrorCode );
    if ( prsResult->strptr == NULL )
        DosAllocMem( (PPVOID) &(prsResult->strptr), strlen(szError), PAG_COMMIT | PAG_WRITE );
    MAKERXSTRING( *prsResult, szError, strlen(szError) );
}


/* ------------------------------------------------------------------------- *
 * WriteStemElement                                                          *
 *                                                                           *
 * Creates a stem element (compound variable) in the calling REXX program    *
 * using the REXX shared variable pool interface.                            *
 *                                                                           *
 * ARGUMENTS:                                                                *
 *   PSZ   pszStem  : The name of the stem (before the '.')                  *
 *   ULONG ulIndex  : The number of the stem element (after the '.')         *
 *   PSZ   pszValue : The value to write to the compound variable.           *
 *                                                                           *
 * RETURNS: N/A                                                              *
 * ------------------------------------------------------------------------- */
void WriteStemElement( PSZ pszStem, ULONG ulIndex, PSZ pszValue )
{
    SHVBLOCK shvVar;                   // REXX shared variable pool block
    ULONG    ulRc;
    CHAR     szCompoundName[ US_COMPOUND_MAXZ ],
             szValue[ US_SZINFO_MAXZ ];

    sprintf( szCompoundName, "%s.%d", pszStem, ulIndex );
    strncpy( szValue, pszValue, US_SZINFO_MAXZ );
    MAKERXSTRING( shvVar.shvname,  szCompoundName, strlen(szCompoundName) );
    MAKERXSTRING( shvVar.shvvalue, szValue,        strlen(szValue) );
    shvVar.shvnamelen  = RXSTRLEN( shvVar.shvname );
    shvVar.shvvaluelen = RXSTRLEN( shvVar.shvvalue );
    shvVar.shvcode     = RXSHV_SYSET;
    shvVar.shvnext     = NULL;
    ulRc = RexxVariablePool( &shvVar );
    if ( ulRc > 1 )
        printf("Unable to set %s: rc = %d\n", shvVar.shvname.strptr, shvVar.shvret );

}



