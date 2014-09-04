RxLVM - REXX Logical Volume Manager Interface
| V0.5.1 (released March 18 2007)

  RxLVM is a library of REXX functions for accessing information from the OS/2
  Logical Volume Manager (LVM).  Using these functions, you can get information
  about drives, volumes, and partitions, query Boot Manager, and check for
  removeable media.

  At present, you are limited on read-only LVM functions.  That is, you cannot
  use RxLVM to make any actual changes to volumes or partitions.

  See RXLVM.INF for full library documentation.


Files

  README.TXT    This file
  REXXLVM.CMD   Sample REXX program demonstrating RxLVM functions
  RXLVM.DLL     The RxLVM library
  RXLVM.INF     RxLVM documentation (OS/2 INF format)
  SOURCE.ZIP    RxLVM source code


Installation

  To use RxLVM in a REXX program, it must either be in the current working
  directory, or somewhere on your LIBPATH.

  RXLVM.INF contains the API documentation.  For easy accessibility, put it
  somewhere on your BOOKSHELF path, and/or create a program object.


Compiling 

  Building RxLVM.DLL from source requires the LVM toolkit (available at
  http://www.cs-club.org/~alex/os2/toolkits/lvm/index.html or on Hobbes),
  as well as the OS/2 4.5x toolkit from IBM.  The included makefile is for
  IBM VisualAge C/C++ 3.x, but the source should be compatible (with, at
  most, minimal changes) with any up-to-date OS/2 C compiler.


Changelog

  v0.5.1 (2007-03-18)
   - Added RxLvmGetPartitions() function.
   - Fix for filesystem names containing spaces.
   - All reported handles are now eight digits long, with leading 0s if needed.
   - Code cleanup.

  v0.5.0 (2007-03-16)
   - Limited test version, not publically released.

  v0.4.1 (2007-01-15)
   - Fixed minor memory allocation bug in "ERROR:" string generation.
   - First public release (2006-03-15).

  v0.4.0 (2006-06-27)
   - Added RxLvmBootMgrMenu() function.
   - Some minor code cleanup.

  v0.3.0 (2006-06-09)
   - First production release (for OEM use).


License

  RxLVM is released under a BSD-style license; see RXLVM.INF for details.

  RxLVM is (C) 2007 Alex Taylor.

