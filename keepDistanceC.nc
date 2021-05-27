/**
 *  This is a file of the deliverable project of the course Internet of Things
 *
 *  Project name: Keep your distance
 *  Year: 2021
 *  Authors: Tancredi Covioli (C.P.: 10498705); Alessandro Dangelo (C.P.: 10524044)
 */

#include "keepDistance.h"
#include "Timer.h"

module keepDistanceC {
    uses {
        interface Boot;
        interface SplitControl;
        interface AMSend;
        interface Receive;
        interface Packet;
        interface Timer<TMilli> as Timer;
        //interface PacketAcknowledgements;
    }

} implementation {
    uint8_t rec_id;
    message_t packet;

    event void Boot.booted(){
        dbg("boot","Application booted.\n");
        call SplitControl.start();
    }

    event void SplitControl.startDone(error_t err){
        if(err == SUCCESS){
            dbg("radio", "Radio on!\n");
            call Timer.startPeriodic( PERIOD );
        }
        else {
            dbgerror("radio", "error while starting the radio, retrying...\n");
            call SplitControl.start();
        }
    }

    event void SplitControl.stopDone(error_t err){
        //TODO
    }

    event void Timer.fired(){
        //TODO
    }

    event void AMSend.sendDone(message_t* buf, error_t err){
        if (&packet == buf && err == SUCCESS ){
           //TODO
        } else {
            dbgerror("radio_send", "Failed to send the message.\n");
        }
    }

    event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len){
        if (len != sizeof(msg_t)) {return buf;}
        else {
           //TODO
        }
    }

}
