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
    status_t status[MAX_NODES];
    uint8_t counter;
    uint8_t i;

    void debug_message(bool sent, msg_t* mess) {
        dbg("radio_pack","The following message was correctly %s at time %s\n", (sent ? "sent" : "received"), sim_time_string());
        dbg_clear("radio_pack","\tid: %hhu \n", mess->id);
        dbg_clear("radio_pack","\tcounter: %hhu \n", mess->counter);
        //if(!sent){// FIXME: only display these informations when we have a receive, not a send, and make sure it's after the counter was increased.
            dbg_clear("radio_pack","\tThe counters are:\n");
            for(i=0; i<MAX_NODES; i++){
                dbg_clear("radio_pack","\t\t%u : %hhu,%hhu\n", i+1, status[i].msg_num,status[i].msg_start);
            }
        //}
        return;
    }

    void alarm (uint8_t mote1, uint8_t mote2, status_t* status) {
        dbg("alarm", "MOTE %hhu AND MOTE %hhu HAVE BEEN NEAR FOR ", mote1, mote2);
        dbg("alarm", "%hhu MESSAGES\n", status->msg_num - status->msg_start);
        return;
    }

    event void Boot.booted() {
        dbg("boot","Application booted.\n");
        call SplitControl.start();
    }

    event void SplitControl.startDone(error_t err) {
        if(err == SUCCESS){
            dbg("radio", "Radio on!\n");
            counter = 0;                                //when radio channel is started, reset the counter of the mote
            for(i=0; i<MAX_NODES; i++){
                status[i].msg_num = 0;
                status[i].msg_start = 0;
            }
            call Timer.startPeriodic( PERIOD );
        } else {
            dbgerror("radio", "error while starting the radio, retrying...\n");
            call SplitControl.start();
        }
    }

    event void SplitControl.stopDone(error_t err) {
        //TODO
    }

    event void Timer.fired() {

        msg_t* mess = (msg_t*) call Packet.getPayload(&packet, sizeof(msg_t));
        if (mess == NULL){
            dbg("radio", "Error during the creation of a message\n");
            return;
        }
        mess->id = TOS_NODE_ID;
        mess->counter = counter;

        if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(msg_t)) == SUCCESS) {
            debug_message(TRUE, mess);
        }
    }

    event void AMSend.sendDone(message_t* buf, error_t err) {
        if (&packet == buf && err == SUCCESS ){
            counter = (counter + 1)%256;                                // if message is sent correctly, the next one to be sent must have the counter incremented
        } else {
            dbgerror("radio_send", "Failed to send the message.\n");
        }
    }

    event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len) {
        if (len != sizeof(msg_t)) {
            dbgerror("radio_rec","received a malformed packet.\n");
            return buf;
        } else {
            msg_t* mess = (msg_t*)payload;
            if (0 <= mess->id && mess->id < MAX_NODES) {
                debug_message(FALSE, mess);
                rec_id = mess->id;
                if(status[rec_id-1].msg_num == (mess->counter)-1){  //se ho ricevuto il messaggio successivo a quello che avevo salvato in precedenza...
                    dbg("radio_pack","sono nel if\n");
                    status[rec_id-1].msg_num = mess->counter;       //allora aggiorno il numero dell'ultimo messaggio ricevuto
                } else {
                    dbg("radio_pack","sono nel else\n");
                    status[rec_id-1].msg_start = mess->counter;     //altrimenti resetto il primo messaggio della sequenza a quello appena ricevuto
                    status[rec_id-1].msg_num = mess->counter;
                }
                if((status[rec_id-1].msg_num-status[rec_id-1].msg_start)%256 >= 10)
                    alarm(TOS_NODE_ID, rec_id, &status[rec_id-1]);
            }
            else {
                dbgerror("radio_rec", "received a packet with an invalid ID.");
            }
        }
        return buf;
    }

}
