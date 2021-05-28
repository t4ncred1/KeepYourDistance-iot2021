/**
 *  This is a file of the deliverable project of the course Internet of Things
 *
 *  Project name: Keep your distance
 *  Year: 2021
 *  Authors: Tancredi Covioli (C.P.: 10498705); Alessandro Dangelo (C.P.: 10524044)
 */

#include "printf.h"
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
    uint16_t counters[MAX_NODES];
    uint8_t i;

    void debug_message(bool sent, msg_t* mess){
        dbg("radio_pack","The following message was correctly %s at time %s\n", (sent ? "sent" : "received"), sim_time_string());

        printf("The following message was correctly %s\n", (sent ? "sent" : "received"));
        printfflush();

        dbg_clear("radio_pack","\tid: %hhu \n", mess->id);

        printf("\tid: %hhu \n", mess->id);
        printfflush();

        if(!sent){
            dbg_clear("radio_pack","\tThe counters are:\n");

            printf("\tThe counters are:\n");
            printfflush();

            for(i=0; i<MAX_NODES; i++){
                dbg_clear("radio_pack","\t\t%u : %hhu\n", i+1, counters[i]);
                printf("\t\t%u : %u\n", i+1, counters[i]);
                printfflush();
            }

        }
    }

    void alarm (uint8_t mote1, uint8_t mote2, uint16_t counter){
        dbg("alarm", "MOTE %hhu AND MOTE %hhu HAVE BEEN NEAR FOR ", mote1, mote2);
        dbg("alarm", "%hhu MESSAGES\n", counter);
        printf("alarm!\n");
        printfflush();
    }

    event void Boot.booted(){
        dbg("boot","Application booted.\n");
        printf("boot id: %hu", TOS_NODE_ID); // TODO: DEBUG
        printfflush();
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

        msg_t* mess = (msg_t*) call Packet.getPayload(&packet, sizeof(msg_t));
        if (mess == NULL){
            dbg("radio", "Error during the creation of a message\n");
            return;
        }
        mess->id = TOS_NODE_ID;

        if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(msg_t)) == SUCCESS){
            debug_message(TRUE, mess);
        }
    }

    event void AMSend.sendDone(message_t* buf, error_t err){
        if (&packet == buf && err == SUCCESS ){
            dbg("radio_send", "message sent correctly.\n");
        } else {
            dbgerror("radio_send", "Failed to send the message.\n");
        }
    }

    event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len){
        if (len != sizeof(msg_t)) {
            dbgerror("radio_rec","received a malformed packet.\n");
            return buf;
        } else {
          msg_t* mess = (msg_t*) payload;
          if (0 <= mess->id && mess->id < MAX_NODES){
              counters[mess->id]++;
              debug_message(FALSE, mess);
              if (counters[mess->id]%10==0 && counters[mess->id]!=0){
                  counters[mess->id] = 0;
                  alarm(TOS_NODE_ID, mess->id, counters[mess->id]);
              }
          } else {
              dbgerror("radio_rec", "received a packet with an invalid ID.");
          }
        }
    }

}
