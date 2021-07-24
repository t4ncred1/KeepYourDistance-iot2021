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
   nx_uint8_t counter;
} msg_t;

typedef nx_struct status_struct {
   nx_uint16_t msg_num;				//numero dell'ultimo messaggio ricevuto
   nx_uint16_t msg_start;			//numero del primo dei messaggi rievuti in sequenza
} status_t;

enum{
   AM_SEND_MSG = 6,
};

#define PERIOD 500					//intervallo di tempo per l'invio dei messaggi
#define MAX_NODES 10				//numero massimo di motes

#endif
