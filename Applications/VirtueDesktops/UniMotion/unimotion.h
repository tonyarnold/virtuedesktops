/*
 *  UniMotion - Unified Motion detection for Apple portables.
 *
 *  Copyright (c) 2006 Lincoln Ramsay. All rights reserved.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License version 2.1 as published by the Free Software Foundation.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation Inc. 59 Temple Place, Suite 330, Boston MA 02111-1307 USA
 */
#ifndef UNIMOTION_H
#define UNIMOTION_H

#ifdef __cplusplus
extern "C" {
#endif

// The various SMS hardware that unimotion supports
enum sms_hardware {
    unknown = 0,
    powerbook = 1,
    ibook = 2,
    highrespb = 3,
    macbookpro = 4
};

// prototypes for the functions in unimotion.c

// returns the value of SMS hardware present or unknown if no hardware is detected
int detect_sms();

// use the value returned from detect_sms as the type
// returns 1 on success and 0 on failure
// modifies x, y and z if they are not 0
int read_sms(int type, int *x, int *y, int *z);
int read_sms_raw(int type, int *x, int *y, int *z);

#ifdef __cplusplus
}
#endif

#endif

