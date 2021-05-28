/**
 *  This is a file of the deliverable project of the course Internet of Things
 *
 *  Project name: Keep your distance
 *  Year: 2021
 *  Authors: Tancredi Covioli (C.P.: 10498705); Alessandro Dangelo (C.P.: 10524044)
 */

#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "keepDistance.h"

configuration keepDistanceAppC{}

implementation{

    components MainC, keepDistanceC as App;
    components new TimerMilliC() as timer;
    components ActiveMessageC;
    components new AMSenderC(AM_SEND_MSG);
    components new AMReceiverC(AM_SEND_MSG);
    components PrintfC;
    components SerialStartC;

    App.Boot -> MainC.Boot;
    App.Timer -> timer;
    App.SplitControl -> ActiveMessageC;
    App.AMSend -> AMSenderC;
    App.Receive -> AMReceiverC;
    App.Packet -> AMSenderC;
}
