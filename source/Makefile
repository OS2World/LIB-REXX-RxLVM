# Makefile for IBM C Compiler 3.x and NMAKE32.
CC     = icc
LINK   = ilink
RC     = rc
CFLAGS = /Sp1 /Ss /Q
LFLAGS = /NOLOGO
NAME   = rxlvm
LIBS   = rexx.lib lvm.lib

# Set environment variable DEBUG (=anything) to build with debugging symbols
!ifdef DEBUG
    CFLAGS = $(CFLAGS) /Ti /Tm
    LFLAGS = $(LFLAGS) /DEBUG
!endif

$(NAME).dll : $(NAME).obj
                $(LINK) $(LFLAGS) $(NAME).obj $(NAME).def $(LIBS) /O:$@

$(NAME).obj : $(NAME).c $(NAME).def
                $(CC) $(CFLAGS) /C /Ge- $(NAME).c

clean       :
                if exist $(NAME).dll del $(NAME).dll
                if exist $(NAME).obj del $(NAME).obj

