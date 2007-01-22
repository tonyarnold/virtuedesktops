/******************************************************************************
* 
Peony framework 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#ifndef __DE_MAIN_H__
#define __DE_MAIN_H__

// c standard 
#include <stdio.h>
#include <stdarg.h>

extern int g_minorVersion; 
extern int g_majorVersion; 

void injectEntry(ptrdiff_t a_iOffset, void *a_poParamBlock, size_t a_iParamSize, char *dummy_pthread_struct); 

#endif 