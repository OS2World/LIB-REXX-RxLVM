:userdoc.
:title.RxLVM Library Reference

.******************************************************************************
:h1 x=left y=bottom width=100% height=100% id=about.Notices
:p.:hp2.RxLVM Library Reference
.br
Version 0.5.1 - March 18, 2007:ehp2.

:p.The RxLVM library (:hp2.RXLVM.DLL:ehp2. and associated source code) and this
document are (C) 2006 Alex Taylor.  The following license terms apply to both.

:p.Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met&colon.

:ol.
:li.Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
:li.Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
:li.The name of the author may not be used to endorse or promote products
derived from this software without specific prior written permission.
:eol.

:p.THIS SOFTWARE IS PROVIDED BY THE AUTHOR &osq.&osq.AS IS&csq.&csq. AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.


.******************************************************************************
:h1 x=left y=bottom width=100% height=100% id=using.Using the RxLVM API
:p.RxLVM (RXLVM.DLL) is a library of REXX functions for interacting with the
Logical Volume Manager (LVM).

:p.Because REXX is a highly accessible language, and LVM is a potentially
destructive tool if used incautiously, RxLVM only allows access to a relatively
small subset of LVM functions.  These functions are informational only&colon. no
means is provided for making changes to the system.

:p.Using RxLVM functions, you can access information about disk drives, volumes,
and/or partitions, query Boot Manager, and check for removeable media devices.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=registering.Registering and deregistering functions
:p.As with any REXX function library, you must register RxLVM functions
before you can use them.

:p.The function :link reftype=hd refid=rxlvmloadfuncs.RxLvmLoadFuncs:elink.
will register all other RxLVM functions automatically&colon.
:xmp.
    CALL RxFuncAdd 'RxLvmLoadFuncs', 'RXLVM', 'RxLvmLoadFuncs'
    CALL RxLvmLoadFuncs
:exmp.

:p.Similarly, you can deregister all RxLVM functions using
:link reftype=hd refid=rxlvmdropfuncs.RxLvmDropFuncs:elink.&colon.
:xmp.
    CALL RxLvmDropFuncs
:exmp.

:nt.It is suggested that your REXX programs always call RxLvmDropFuncs when they
have finished using the RxLVM API.  This is because new versions of RxLVM may be
released from time to time, and if RXLVM.DLL is updated while functions from an
older version are still registered, the results may be unpredictable.:ent.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=opening.Opening and closing the LVM engine
:p.The functional component of the Logical Volume Manager is called the :hp2.LVM
engine:ehp2..  RxLVM uses the LVM engine (through its application interface,
LVM.DLL) for all LVM functionality.

:p.In general, before any program can access LVM, it must :hp2.open:ehp2. the
LVM engine.  Only one program at a time can have the LVM engine open.

:p.Consequently, before you can use any RxLVM function other than RxLvmLoadFuncs,
RxLvmDropFuncs, RxLvmVersion, RxLvmEngineOpen, and RxLvmRediscoverPRM (which is a
special case), you must first open the LVM engine using the function
:link reftype=hd refid=rxlvmengineopen.RxLvmEngineOpen:elink..  For
example&colon.
:xmp.
    opened = RxLvmEngineOpen()
:exmp.
:p.RxLvmEngineOpen returns the empty string on success, or an LVM
:link reftype=hd refid=errorstrings.error string:elink. if the LVM engine could
not be opened.  The most common reason for failure is if another program already
has the LVM engine open.  (See the :link reftype=hd refid=rxlvmengineopen.function
description:elink. for more information.)

:p.Similarly, once you have finished accessing LVM, you must :hp2.close:ehp2.
the LVM engine using the function
:link reftype=hd refid=rxlvmengineclose.RxLvmEngineClose:elink., e.g.
:xmp.
    CALL RxLvmEngineClose
:exmp.
:p.Normally, the LVM engine should close itself automatically when the current
program terminates, but you should nonetheless close it explicitly as soon as
you no longer require access to LVM functions.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=handles.Using handles
:p.A :hp2.handle:ehp2. is a unique identifier maintained by the LVM engine for
every volume, partition, and drive.  It is a four-byte value, which RxLVM
represents as an eight-character hexadecimal string.

:p.Various RxLVM functions use these handles as a way of uniquely identifying a
volume, partition, or drive.  Since drive letters are optional (and can be
changed), this is the most reliable means of identification available.

:nt.Once the LVM engine has been closed (i.e. with
:link reftype=hd refid=rxlvmengineclose.RxLvmEngineClose:elink.), handles are
not guaranteed to remain valid the next time the LVM engine is opened (not even
within the same process).:ent.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=errorstrings.LVM error strings
:p.In addition to the return values listed in the function descriptions, all
RxLVM functions except for RxLvmLoadFuncs, RxLvmDropFuncs, RxLvmVersion and
RxLvmEngineClose may also return an error string of the format ":hp2.ERROR&colon.
:ehp2.:hp3.n:ehp3.", where n is an error code returned from the LVM engine.

:p.If an error of this form is received, it indicates that an error occured
while calling a function in LVM.DLL (the LVM engine interface).  It is
therefore up to each REXX program to check for such errors whenever calling
an RxLVM function.

:p.A complete list of the error codes that can be returned by the LVM engine
may be found :link reftype=hd refid=lvmcodes.here:elink..


.******************************************************************************
:h1 x=left y=bottom width=100% height=100%.RxLVM Functions
:p.This chapter describes all of the functions available in the RxLVM library.

.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmbootmgrinfo.RxLvmBootMgrInfo
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead.ÄÄÄRxLvmBootMgrInfoÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Queries the existence and status of IBM Boot Manager.

:p.
:p.:hp7.Parameters:ehp7.
:p.None.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmBootMgrInfo returns the empty string ("") if Boot Manager is not
installed.  If Boot Manager was detected, a string of the format&colon.
:p.:hp1.disk active timeout deftype defhandle:ehp1.
:p.is returned.  The meanings of the various fields are&colon.

:dl break=none tsize=12.
:dt.:hp1.disk:ehp1.
:dd.The number of the physical disk drive (where 1 is the first disk) on
which Boot Manager is installed.

:dt.:hp1.active:ehp1.
:dd.A flag indicating whether Boot Manager is active (startable).  This is
one of the following values&colon.
:dl compact tsize=4 break=none.
:dt.1
:dd.Boot Manager is installed and active
:dt.0
:dd.Boot Manager is installed but not active
:edl.

:dt.:hp1.timeout:ehp1.
:dd.The current Boot Manager timeout value (the number of seconds before the
default entry indicated by :hp1.defhandle:ehp1. will be booted automatically
on system startup).  This will be 0 if the timeout feature is disabled.

:dt.:hp1.deftype:ehp1.
:dd.A flag indicating the nature of the default entry indicated by
:hp1.defhandle:ehp1..  This is one of the following values&colon.
:dl compact tsize=4 break=none.
:dt.1
:dd.The default entry is a volume
:dt.0
:dd.The default entry is a non-volume partition
:edl.

:dt.:hp1.defhandle:ehp1.
:dd.The handle of the default menu entry.  This is the item on the Boot Manager
menu which will be booted automatically on system startup once the
:hp1.timeout:ehp1. value expires.
:edl.

:p.An LVM error message will be returned if the LVM engine encounters an error.

:p.
:p.:hp7.Example:ehp7.
:xmp.
  bmgr = RxLvmBootMgrInfo()
  SELECT
      WHEN bmgr == '' THEN
          SAY 'Boot Manager is not installed.'
      WHEN LEFT( bmgr, 6 ) == 'ERROR&colon.' THEN DO
          PARSE VAR bmgr 'ERROR&colon.' lvm_error
          SAY 'Boot Manager state could not be determined.  LVM.DLL returned error code' lvm_error
          RETURN lvm_error
      END
      OTHERWISE
          SAY 'Current Boot Manager configuration&colon.' bmgr
  END
:exmp.
:p.The following is a sample of output from the example above&colon.
:xmp.
  Current Boot Manager configuration&colon. 1 1 30 1 FC04D5A7
:exmp.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmbootmgrmenu.RxLvmBootMgrMenu
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead.ÄÄRxLvmBootMgrMenu( stem )ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Queries the contents of the Boot Manager menu.

:p.
:p.:hp7.Parameters:ehp7.
:parml break=all.
:pt.stem
:pd.The name of the stem variable in which the list of Boot Manager menu entries
will be stored.  After RxLvmBootMgrMenu returns successfully, :hp1.stem:ehp1..0
will contain an integer :hp1.n:ehp1., indicating the number of menu entries
found; and :hp1.stem:ehp1..1 through :hp1.stem.n:ehp1. will each contain data
describing a single menu entry, in the format&colon.
:p.:hp1.handle type name:ehp1.
:p.The meanings of the various fields are&colon.

:dl break=fit tsize=13.
:dt.:hp1.handle:ehp1.
:dd.The handle of the bootable volume or partition (a unique 8-digit hexadecimal
string).

:dt.:hp1.type:ehp1.
:dd.A flag indicating whether the menu entry describes a volume or a non-volume
partition.  This is one of the following values&colon.
:dl compact tsize=4 break=none.
:dt.1
:dd.This entry is a volume
:dt.0
:dd.This entry is a non-volume partition
:edl.

:dt.:hp1.name:ehp1.
:dd.The name of the bootable volume or partition.  This is a string of up to 20
characters, and may contain spaces and punctuation marks.
:edl.
:eparml.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmBootMgrMenu returns 1, or an LVM error message.

:p.
:p.:hp7.Example:ehp7.
:xmp.
  qm = RxLvmBootMgrMenu('menu.')
  IF LEFT( qm, 6 ) == 'ERROR&colon.' THEN DO
      PARSE VAR qm 'ERROR&colon. ' lvm_error
      SAY 'LVM.DLL returned error code' lvm_error
      RETURN lvm_error
  END
  SAY 'Boot Manager menu contains' menu.0 'entries&colon.'
  DO i = 1 TO menu.0
      SAY '   ' menu.i
  END
:exmp.
:p.The following is a sample of output from the example above&colon.
:xmp.
  The Boot Manager menu contains 3 entries&colon.
      FC04D5A7 1 System
      FC047F87 0 Windows 2000
      FC04D4E7 1 Maintenance
:exmp.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmdropfuncs.RxLvmDropFuncs
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead.ÄÄÄRxLvmDropFuncsÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Deregisters all RxLVM API functions.

:p.
:p.:hp7.Parameters:ehp7.
:p.None.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmDropFuncs returns the empty string ("").

:p.
:p.:hp7.Example:ehp7.
:xmp.
  CALL RxLvmDropFuncs
:exmp.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmengineclose.RxLvmEngineClose
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead.ÄÄÄRxLvmEngineCloseÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Closes the LVM engine.  Always call this function once your REXX program
is finished accessing LVM.

:p.
:p.:hp7.Parameters:ehp7.
:p.None.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmEngineClose returns the empty string ("").

:p.
:p.:hp7.Example:ehp7.
:xmp.
  CALL RxLvmEngineClose
:exmp.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmengineopen.RxLvmEngineOpen
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead.ÄÄÄRxLvmEngineOpenÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Opens the LVM engine.  The LVM engine must be open in order to use any other
RxLVM function except for RxLvmLoadFuncs, RxLvmDropFuncs, RxLvmVersion, and
RxLvmRediscoverPRM.

:p.Only one process at a time may have the LVM engine open.  RxLvmEngineOpen
will return an error (see below) if the LVM engine is open already.
:p.
:p.:hp7.Parameters:ehp7.
:p.None.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmEngineOpen returns the empty string ("") or an LVM error message.
:p.The LVM error code will normally be 5 if the LVM engine is already open
under the current process; or 9 if it is open under a different process.

:p.
:p.:hp7.Example:ehp7.
:xmp.
  open = RxLvmEngineOpen()
  IF open \= '' THEN DO
      PARSE VAR open 'ERROR&colon. ' lvm_error
      IF lvm_error \= '' THEN SAY 'LVM returned error code' lvm_error
      RETURN lvm_error
  END
:exmp.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmgetdisks.RxLvmGetDisks
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead.ÄÄRxLvmGetDisks( stem )ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Gets a list of all physical disk drives recognized by the system.

:p.
:p.:hp7.Parameters:ehp7.
:parml break=all.
:pt.stem
:pd.The name of the stem variable in which the list of disks will be stored.
After RxLvmGetDisks returns successfully, :hp1.stem:ehp1..0 will contain an
integer :hp1.n:ehp1., indicating the number of disks found; and
:hp1.stem:ehp1..1 through :hp1.stem.n:ehp1. will each contain data
describing a single disk, in the format&colon.
:p.:hp1.handle number size unuseable corrupt removeable serial name:ehp1.
:p.The meanings of the various fields are&colon.

:dl break=fit tsize=13.
:dt.:hp1.handle:ehp1.
:dd.The disk's handle (a unique 8-digit hexadecimal string).

:dt.:hp1.number:ehp1.
:dd.The number assigned to the disk drive by LVM.  This is a positive integer,
where 1 represents the first disk.

:dt.:hp1.size:ehp1.
:dd.The total size of the disk, in megabytes (1 megabyte = 1,048,576 bytes).

:dt.:hp1.unuseable:ehp1.
:dd.A flag indicating whether the disk drive is reported "unuseable" (i.e.
inaccessible) by LVM.  This is one of the following values&colon.
:dl compact tsize=4 break=none.
:dt.0
:dd.The disk drive is useable
:dt.1
:dd.The disk drive is currently being reported as unuseable
:edl.

:dt.:hp1.corrupt:ehp1.
:dd.A flag indicating whether the disk drive has a corrupted partition table
(as reported by LVM).  This is one of the following values&colon.
:dl compact tsize=4 break=none.
:dt.0
:dd.The partition table is correct
:dt.1
:dd.The partition table is being reported as corrupt
:edl.

:dt.:hp1.removeable:ehp1.
:dd.This flag indicates whether or not the disk drive is a removeable media
device.  This is one of the following values&colon.
:dl compact tsize=4 break=none.
:dt.0
:dd.Normal disk drive
:dt.1
:dd.Partitionable removeable media device
:dt.2
:dd."Big floppy" type removeable media (e.g. LS-120 super-diskette)
:edl.

:dt.:hp1.serial:ehp1.
:dd.The serial number reported by the disk drive.  This is an integer value.

:dt.:hp1.name:ehp1.
:dd.The disk's name.  This is a string of up to 20 characters, and may contain
spaces and punctuation marks.
:edl.
:eparml.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmGetDisks returns 1, or an LVM error message.

:p.
:p.:hp7.Example:ehp7.
:xmp.
  qd = RxLvmGetDisks("disks.")
  IF LEFT( qd, 6 ) == 'ERROR&colon.' THEN DO
      PARSE VAR qd 'ERROR&colon. ' lvm_error
      SAY 'LVM.DLL returned error code' lvm_error
      RETURN lvm_error
  END
  SAY disks.0 'disks found&colon.'
  DO i = 1 TO disks.0
      SAY '   ' disks.i
  END
:exmp.
:p.The following is a sample of output from the example above&colon.
:xmp.
  3 volumes found&colon.
      FC047717 1 156327 0 0 0 890692272 [ D1 ]
      FC047767 2 156327 0 0 0 700276006 [ D2 ]
      FC0477B7 3 0 1 0 1 0 [ D3 ]
:exmp.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmgetpartitions.RxLvmGetPartitions
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead. ÄÄRxLvmGetPartitions( handle, stem )ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Gets a list of all partitions on the specified disk or in the specified
volume.  Note that the term "partition" in this context includes contiguous
regions of free space as well as allocated partitions.

:p.
:p.:hp7.Parameters:ehp7.
:parml break=all.
:pt.handle
:pd.The handle of the volume or disk drive whose partitions are to be returned.

:pt.stem
:pd.The name of the stem variable in which the list of partitions will be
stored.  After RxLvmGetPartitions returns successfully, :hp1.stem:ehp1..0
will contain an integer :hp1.n:ehp1., indicating the number of volumes found;
and :hp1.stem:ehp1..1 through :hp1.stem.n:ehp1. will each contain data
describing a single partition, in the format&colon.
:p.:hp1.handle diskhandle volhandle status filesystem size OS bootable name:ehp1.
:p.The meanings of the various fields are&colon.

:dl break=fit tsize=13.
:dt.:hp1.handle:ehp1.
:dd.The partition's handle (a unique 8-digit hexadecimal string).

:dt.:hp1.diskhandle:ehp1.
:dd.The handle of the disk drive on which the partition resides (a unique 8-digit
hexadecimal string).

:dt.:hp1.volhandle:ehp1.
:dd.The handle of the volume to which the partition belongs (a unique 8-digit
hexadecimal string).  This will be 00000000 if the partition does not belong to
any volume.

:dt.:hp1.status:ehp1.
:dd.A flag indicating the partition status.  This is one of the following
values&colon.
:dl compact tsize=4 break=none.
:dt.F
:dd.Free space
:dt.A
:dd.Available, i.e. the partition does not currently belong to any volume.
:dt.U
:dd.The partition does not belong to a volume, but is marked as "in use" by the
LVM engine (this normally applies to the Boot Manager partition).
:dt.C
:dd.The partition is a standard-type (or "compatibility") volume.
:dt.L
:dd.The partition belongs to an advanced-type (or "LVM") volume.
:dt.?
:dd.The partition status could not be determined.
:edl.

:dt.:hp1.filesystem:ehp1.
:dd.The file system currently in use on the partition, or ? if the file system
could not be determined (for instance, in the case of free space).
:nt.To allow for correct parsing, RxLVM will replace any spaces in the file
system name with the byte value 0xFF (which corresponds to "non-breaking space"
under most system codepages).:ent.

:dt.:hp1.size:ehp1.
:dd.The accessible size of the partition, in megabytes (1 megabyte = 1,048,576
bytes).

:dt.:hp1.OS:ehp1.
:dd.The "operating system flag" (also known as the "partition type" flag) reported
by the partition.  This is a two-digit hexadecimal byte value.

:dt.:hp1.bootable:ehp1.
:dd.The partition's bootable flag.  This is one of the following values&colon.
:dl compact tsize=4 break=none.
:dt.B
:dd.Bootable (partition appears on the Boot Manager menu, either by itself or as
a volume)
:dt.S
:dd.Startable (partition is directly bootable, or "active")
:dt.I
:dd.Installable (partition reports an "installable" flag set by the IBM OS/2 installer)
:dt.N
:dd.None (partition is not bootable)
:edl.

:dt.:hp1.name:ehp1.
:dd.The partition's name.  This is a string of up to 20 characters, and may contain
spaces and punctuation marks.
:edl.
:eparml.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmGetPartitions returns the empty string ("") or an LVM error message.

:p.
:p.:hp7.Example:ehp7.
:xmp.
  qd = RxLvmGetDisks('disks.')
  IF LEFT( qd, 6 ) == 'ERROR&colon.' THEN DO
      PARSE VAR qd 'ERROR&colon. ' lvm_error
      SAY 'LVM.DLL returned error code' lvm_error
      RETURN lvm_error
  END
  DO i = 1 TO disks.0
      SAY 'Partitions on Disk' i'&colon.'
      PARSE VAR disks.i handle .
      pd = RxLvmGetPartitions( handle, 'parts.')
      IF LEFT( pd, 6 ) == 'ERROR&colon.' THEN DO
          PARSE VAR pd 'ERROR&colon. ' lvm_error
          SAY 'LVM.DLL returned error code' lvm_error
          RETURN lvm_error
      END
      DO j = 1 TO parts.0
          SAY '   ' parts.j
      END
  END
:exmp.
:p.The following is a sample of output from the example above&colon.
:xmp.
Partitions on Disk 1&colon.
    FC177D47 FC177717 00000000 U Boot&house.Manager 7 0A S [ BOOT MANAGER ]
    FC177C67 FC177717 FC179B17 C HPFS 2047 07 B OS/2
    FC177F87 FC177717 00000000 A NTFS-H 19092 17 B Windows 2000
    FC176197 FC177717 FC1788D7 L JFS 102404 35 N PROGRAMS
    FC1776F7 FC177717 FC178B77 L HPFS 32771 35 N FILES
Partitions on Disk 2&colon.
    FC176297 FC177767 FC179BB7 C FAT16-H 2000 16 N SADUMP
    FC1765B7 FC177767 FC179A57 C FAT16 2000 06 B SERVICE
    FC1767C7 FC177767 FC178BD7 L JFS 136001 35 N WORKING
    FC1768F7 FC177767 00000000 F ? 16321 00 N [ FS1 ]
Partitions on disk 3&colon.
    FC177B37 FC1777B7 00000000 F ? 96 00 N [ FS2 ]
:exmp.
:nt.The &house. character is used here to represent byte value 0xFF, which will
normally appear on screen as a space.:ent.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmgetvolumes.RxLvmGetVolumes
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead.ÄÄRxLvmGetVolumes( stem )ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Gets a list of all volumes defined on the system.

:p.
:p.:hp7.Parameters:ehp7.
:parml break=all.
:pt.stem
:pd.The name of the stem variable in which the list of volumes will be stored.
After RxLvmGetVolumes returns successfully, :hp1.stem:ehp1..0 will contain an
integer :hp1.n:ehp1., indicating the number of volumes found; and
:hp1.stem:ehp1..1 through :hp1.stem.n:ehp1. will each contain data
describing a single volume, in the format&colon.
:p.:hp1.handle letter prefletter filesystem size device type bootable name:ehp1.
:p.The meanings of the various fields are&colon.

:dl break=fit tsize=13.
:dt.:hp1.handle:ehp1.
:dd.The volume's handle (a unique 8-digit hexadecimal string).

:dt.:hp1.letter:ehp1.
:dd.The drive letter currently assigned to the volume.  This is a single letter
from A to Z, without a trailing colon.  If the volume has no drive letter (which
is the case for hidden volumes), a ? will appear instead.

:dt.:hp1.prefletter:ehp1.
:dd.The drive letter, without a colon, that the volume prefers to have (i.e.
that the user has assigned to it).  This may differ from its actual drive letter
in the event of a conflict.  As above, a ? will appear for hidden volumes.  If
the volume has a drive letter assignment that is not under the control of LVM
(as is the case, for example, for CD or LAN drives), a * will appear instead.

:dt.:hp1.filesystem:ehp1.
:dd.The file system currently in use on the volume.
:nt.To allow for correct parsing, RxLVM will replace any spaces in the file
system name with the byte value 0xFF (which corresponds to "non-breaking space"
under most system codepages).:ent.

:dt.:hp1.size:ehp1.
:dd.The total size of the volume, in megabytes (1 megabyte = 1,048,576 bytes).

:dt.:hp1.device:ehp1.
:dd.The type of device on which the volume resides.  This is one of the
following values&colon.
:dl compact tsize=6 break=none.
:dt.HDD
:dd.Hard disk drive
:dt.PRM
:dd.Partitionable removeable media
:dt.CD
:dd.CD/DVD drive (not controlled by LVM)
:dt.LAN
:dd.LAN drive (not controlled by LVM)
:dt.?
:dd.Unknown device type (not controlled by LVM)
:edl.

:dt.:hp1.type:ehp1.
:dd.A flag indicating the volume type.  This is one of the following
values&colon.
:dl compact tsize=4 break=none.
:dt.0
:dd.A standard (or "compatibility") volume
:dt.1
:dd.An advanced (or "LVM") volume
:edl.

:dt.:hp1.bootable:ehp1.
:dd.The volume's bootable flag.  This is one of the following values&colon.
:dl compact tsize=4 break=none.
:dt.B
:dd.Bootable (volume appears on the Boot Manager menu)
:dt.S
:dd.Startable (volume is directly bootable, or "active")
:dt.I
:dd.Installable (volume reports an "installable" flag set by the IBM OS/2 installer)
:dt.N
:dd.None (volume is not bootable)
:edl.

:dt.:hp1.name:ehp1.
:dd.The volume's name.  This is a string of up to 20 characters, and may contain
spaces and punctuation marks.
:edl.
:eparml.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmGetVolumes returns 1, or an LVM error message.

:p.
:p.:hp7.Example:ehp7.
:xmp.
  qv = RxLvmGetVolumes("vols.")
  IF LEFT( qv, 6 ) == 'ERROR&colon.' THEN DO
      PARSE VAR qv 'ERROR&colon. ' lvm_error
      SAY 'LVM.DLL returned error code' lvm_error
      RETURN lvm_error
  END
  SAY vols.0 'volumes found&colon.'
  DO i = 1 TO vols.0
      SAY '   ' vols.i
  END
:exmp.
:p.The following is a sample of output from the example above&colon.
:xmp.
  4 volumes found&colon.
      FC04D5A7 C C HPFS 2047 HDD 0 B System
      FC04D4E7 D D FAT16 2000 HDD 0 B Maintenance
      FC04C567 E E JFS 102404 HDD 1 N Applications
      FC04B0C7 H * CDFS 527 CD 0 N [ CDROM 1 ]
:exmp.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmloadfuncs.RxLvmLoadFuncs
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead.ÄÄÄRxLvmLoadFuncsÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Registers all other RxLVM API functions.

:p.
:p.:hp7.Parameters:ehp7.
:p.None.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmLoadFuncs returns the empty string ("").

:p.
:p.:hp7.Example:ehp7.
:xmp.
  CALL RxFuncAdd 'RxLvmLoadFuncs', 'RXLVM', 'RxLvmLoadFuncs'
  CALL RxLvmLoadFuncs
:exmp.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmrediscoverprm.RxLvmRediscoverPRM
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead.ÄÄÄRxLvmRediscoverPRMÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Checks to see if any partitionable removeable media devices (such as Zip
disks or USB mass-storage devices) have been inserted since the last time such
a check was done.
:p.A check for removeable media is done whenever this function is called,
whenever the system is booted, or whenever the LVM engine is opened.

:nt.RxLvmRediscoverPRM requires the LVM engine to be closed.  It will fail if
the LVM engine is already open (by any program).:ent.

:p.
:p.:hp7.Parameters:ehp7.
:p.None.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmRediscoverPRM returns the empty string ("") or an LVM error message.

:p.
:p.:hp7.Example:ehp7.
:xmp.
  discovery = RxLvmRediscoverPRM()
  IF discovery \= '' THEN DO
      PARSE VAR discovery 'ERROR&colon. ' lvm_error
      IF lvm_error \= '' THEN SAY 'LVM returned error code' lvm_error
  END
:exmp.


.* ----------------------------------------------------------------------------
:h2 x=left y=bottom width=100% height=100% id=rxlvmversion.RxLvmVersion
:p.:hp7.Syntax:ehp7.
:cgraphic.
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                           ³
³ &rahead.&rahead.ÄÄRxLvmVersionÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
³                                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
:ecgraphic.

:p.:hp7.Description:ehp7.
:p.Queries the current version of the RxLVM library.

:p.
:p.:hp7.Parameters:ehp7.
:p.None.

:p.
:p.:hp7.Returns:ehp7.
:p.RxLvmVersion returns a version string of the form
":hp1.x:ehp1..:hp1.y:ehp1..:hp1.z:ehp1.", where :hp1.x:ehp1., :hp1.y:ehp1., and
:hp1.z:ehp1. are each a positive number indicating the major version, minor
version, and refresh level, respectively, of the RxLVM library.  Note that
:hp1.x:ehp1., :hp1.y:ehp1., and :hp1.z:ehp1. may each contain any number of
digits.

:p.
:p.:hp7.Example:ehp7.
:xmp.
  PARSE VALUE RxLvmVersion() WITH major '.' minor '.' refresh
  SAY 'Current RXLVM.DLL version is' major'.'minor 'refresh level' refresh
:exmp.



.******************************************************************************
:h1 x=left y=bottom width=100% height=100% id=lvmcodes.Error Codes Returned by LVM
:p.The application interface to the LVM engine resides in the system library
LVM.DLL, and is used by RxLVM for all LVM-specific functions.

:p.LVM.DLL defines almost 50 different return codes for various error conditions.
When an LVM error occurs, RxLVM returns a specially-formatted
:link reftype=hd refid=errorstrings.error message:elink. containing the LVM
return code.  The various codes are listed below.

:nt.Since RxLVM does not implement a large number of LVM functions, many of these
error conditions will never be encountered.  However, all known error codes are
included here for the sake of completeness.:ent.

:table cols='6 74'.
:row.
:c.ERROR
:c.CONDITION
:row.
:c.0
:c.No error (operation succeeded)
:row.
:c.1
:c.Out of memory
:row.
:c.2
:c.I/O error
:row.
:c.3
:c.Invalid handle
:row.
:c.4
:c.Internal error
:row.
:c.5
:c.LVM engine already open (i.e. by the current process)
:row.
:c.6
:c.LVM engine not open
:row.
:c.7
:c.Name exceeds maximum length
:row.
:c.8
:c.Operation not allowed
:row.
:c.9
:c.Drive open failure (another process may have the LVM engine open)
:row.
:c.10
:c.Bad partition
:row.
:c.11
:c.Cannot create primary partition using requested parameters
:row.
:c.12
:c.Too many primary partitions
:row.
:c.13
:c.Cannot create logical partition using requested parameters
:row.
:c.14
:c.Requested size too large
:row.
:c.15
:c.1024 cylinder boot limit reported by system
:row.
:c.16
:c.Partition alignment error
:row.
:c.17
:c.Requested size too small
:row.
:c.18
:c.Not enough free space
:row.
:c.19
:c.Unknown allocation algorithm specified
:row.
:c.20
:c.Duplicate name
:row.
:c.21
:c.Invalid name
:row.
:c.22
:c.Invalid drive letter preference
:row.
:c.23
:c.No drives found
:row.
:c.24
:c.Wrong volume type
:row.
:c.25
:c.Volume too small
:row.
:c.26
:c.Boot Manager already installed
:row.
:c.27
:c.Boot Manager not found
:row.
:c.28
:c.Invalid parameter
:row.
:c.29
:c.Bad feature set
:row.
:c.30
:c.Too many partitions specified
:row.
:c.31
:c.LVM (advanced) volumes are not bootable
:row.
:c.32
:c.Partition already in use
:row.
:c.33
:c.Partition could not be made bootable
:row.
:c.34
:c.Volume not found
:row.
:c.35
:c.Drive not found
:row.
:c.36
:c.Partition not found
:row.
:c.37
:c.Too many features active
:row.
:c.38
:c.Partition too small
:row.
:c.39
:c.Maximum number of partitions already in use
:row.
:c.40
:c.I/O request out of range
:row.
:c.41
:c.Partition not be made startable
:row.
:c.42
:c.Volume could not be made startable
:row.
:c.43
:c.ExtendFS request failed
:row.
:c.44
:c.Reboot required
:row.
:c.45
:c.Cannot open log file
:row.
:c.46
:c.Cannot write to log file
:row.
:c.47
:c.Rediscover removeable media failed
:etable.


.******************************************************************************
.* :h1 x=left y=bottom width=100% height=100% id=glossary.Glossary of Terms
.* :dl.
.* :dt.Bootable
.* :dt.Drive
.* :dt.Drive letter
.* :dt.ExtendFS
.* :dt.Handle
.* :dt.Installable
.* :dt.Partition
.* :dt.PRM
.* :dt.Startable
.* :dt.Volume
.* :dd.
.* :edl.


.* ----------------------------------------------------------------------------
.* :h2 x=left y=bottom width=100% height=100% id=.
.* :p.:hp7.Syntax:ehp7.
.* :cgraphic.
.* ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
.* ³                                                                           ³
.* ³ &rahead.&rahead.ÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ&rahead.&lahead. ³
.* ³                                                                           ³
.* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
.* :ecgraphic.
.*
.* :p.:hp7.Description:ehp7.
.* :p.
.*
.* :p.
.* :p.:hp7.Parameters:ehp7.
.* :p.
.*
.* :p.
.* :p.:hp7.Returns:ehp7.
.* :p. returns the empty string ("") or an LVM error message.
.*
.* :p.
.* :p.:hp7.Example:ehp7.
.* :xmp.
.* :exmp.

:euserdoc.


