/******************************************************************************
* 
* DEComm.Peony.Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
*
* Redistribution and use in source and binary forms, with or without modification, 
* are permitted provided that the following conditions are met:
* 
* - Redistributions of source code must retain the above copyright notice, this list 
*   of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice, this 
*   list of conditions and the following disclaimer in the documentation and/or other 
*   materials provided with the distribution.
* - The name of the author may not be used to endorse or promote products derived 
*   from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY 
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
* BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
* IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
* WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
* 
*****************************************************************************/ 

#ifndef __DEC_H__
#define __DEC_H__ 

#include <Carbon/Carbon.h>

void CGSExtSetWindowAlpha(int window, float startAlpha, float endAlpha, int animate, float animateSeconds); 
void CGSExtSetWindowListAlpha(int* window, int windowCount, float startAlpha, float endAlpha, int animate, float duration); 
void CGSExtSetWindowWorkspace(int window, int workspace); 
void CGSExtSetWindowListWorkspace(int* windows, int windowCount, int workspace); 
void CGSExtOrderWindow(int window, int type, int referenceWindow); 
void CGSExtOrderWindowList(int* windows, int windowCount, int type, int referenceWindow); 
void CGSExtSetWindowTags(int window, int tags); 
void CGSExtSetWindowListTags(int* windows, int windowCount, int tags); 
void CGSExtClearWindowTags(int window, int tags); 
void CGSExtClearWindowListTags(int* windows, int windowCount, int tags); 
void CGSExtSetWindowLevel(int window, int level); 
void CGSExtSetWindowListLevel(int* windows, int windowCount, int level); 
void CGSExtSetWindowProperty(int window, char* key, char* value); 
void CGSExtSetWindowListProperty(int* windows, int windowCount, char* key, char* value); 
void CGSExtDeleteWindowProperty(int window, char* key); 
void CGSExtDeleteWindowListProperty(int* windows, int windowCount, char* key); 

#endif 
