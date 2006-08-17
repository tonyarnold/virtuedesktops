#ifndef __DEC_INJECTOR_H__
#define __DEC_INJECTOR_H__

OSErr dec_find_dock_process(ProcessSerialNumber* psn);  
OSErr dec_info(int* isInjected, int* majorVersion, int* minorVersion); 
OSErr dec_inject_code(); 
OSErr dec_kill_dock(); 

#endif 
