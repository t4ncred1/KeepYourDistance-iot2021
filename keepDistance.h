/**
 *  This is a file of the deliverable project of the course Internet of Things
 *
 *  Project name: Keep your distance
 *  Year: 2021
 *  Authors: Tancredi Covioli (C.P.: 10498705); Alessandro Dangelo (C.P.: 10524044)
 */

#ifndef KEEPDISTANCE_H
#define KEEPDISTANCE_H

typedef nx_struct msg_struct {
   nx_uint8_t id;
} msg_t;

enum{
   AM_SEND_MSG = 6,
};

#define PERIOD 500
#define MAX_NODES 6

#endif
