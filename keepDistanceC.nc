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
	}

} implementation {
	uint8_t rec_id;
	message_t packet;
	status_t status[MAX_NODES];
	uint16_t counter;
	uint8_t i;

	void debug_message(bool sent, msg_t* mess) {
		dbg("radio_pack","The following message was correctly %s at time %s\n", (sent ? "sent" : "received"), sim_time_string());
		dbg_clear("radio_pack","\tid: %hhu \n", mess->id);
		dbg_clear("radio_pack","\tcounter: %hhu \n", mess->counter);
		if(!sent){
			dbg_clear("radio_pack","\tThe counters are:\n");
			for(i=0; i<MAX_NODES; i++){
				dbg_clear("radio_pack","\t\t%u : %hhu,%hhu\n", i+1, status[i].msg_num,status[i].msg_start);
			}
		}
		return;
	}

	void alarm (uint8_t mote1, uint8_t mote2, status_t* status) {
		dbg("alarm", "MOTE %hhu AND MOTE %hhu HAVE BEEN NEAR FOR ", mote1, mote2);
		dbg("alarm", "%hhu MESSAGES\n", status->msg_num - status->msg_start);
		printf("ALARM! m%d <- m%d, n:%d\n", mote1, mote2, (status->msg_num - status->msg_start));
		printfflush();
		return;
	}

	event void Boot.booted() {
		dbg("boot","Application booted.\n");
		call SplitControl.start();
	}

	event void SplitControl.startDone(error_t err) {
		if(err == SUCCESS){
			dbg("radio", "Radio on!\n");
			counter = 0;								//quando il canale radio si avvia, il contatore del mote viene resettato
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
		dbg("init","%hhu turned off radio\n as a wise moon once said: 'io non vedo l'ora di tornare!'\n", TOS_NODE_ID);
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
			counter = (counter + 1);								// se il messaggio è stato inviato correttamente, il prossimo messaggio da inviare dovrà avere il contatore incrementato
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
			if (0 < mess->id && mess->id <= MAX_NODES) {
				debug_message(FALSE, mess);
				rec_id = mess->id;
				if(status[rec_id-1].msg_num == (mess->counter)-1){	//se ho ricevuto il messaggio successivo a quello che avevo salvato in precedenza...
					status[rec_id-1].msg_num = mess->counter;		//allora aggiorno il numero dell'ultimo messaggio ricevuto
				} else {
					status[rec_id-1].msg_start = mess->counter;		//altrimenti resetto il primo messaggio della sequenza a quello appena ricevuto
					status[rec_id-1].msg_num = mess->counter;
					printf("m%d: m%d got near me\n", TOS_NODE_ID, rec_id);
					printfflush();
				}
				if((status[rec_id-1].msg_num-status[rec_id-1].msg_start)%10 == 0 && (status[rec_id-1].msg_num-status[rec_id-1].msg_start) != 0)
					alarm(TOS_NODE_ID, rec_id, &status[rec_id-1]);
			}
			else {
				dbgerror("radio_rec", "received a packet with an invalid ID.");
			}
		}
		return buf;
	}

}
