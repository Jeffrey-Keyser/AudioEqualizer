module BT_intf(cmd_n,TX,RX,next_n,prev_n, clk, rst_n);
output logic TX, cmd_n;
input RX, next_n, prev_n, clk, rst_n;

logic next_rise, prev_rise;
logic send,resp_rcvd;
logic [4:0] cmd_start;
logic [3:0] cmd_len;
logic[16:0] counter;

PB_rise next(.PB(next_n),.clk(clk),.rst_n(rst_n),.rise(next_rise));
PB_rise prev(.PB(prev_n),.clk(clk),.rst_n(rst_n),.rise(prev_rise));
snd_cmd cmd (.TX(TX),.cmd_start(cmd_start),.send(send),.cmd_len(cmd_len),.clk(clk),.rst_n(rst_n),.resp_rcvd(resp_rcvd),.RX(RX));


typedef enum reg [2:0] {IDLE, SEND1, SEND2, WAIT, NEXT, PREV} state_t;
state_t state, nxt_state;

//SM
always@(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else 
		state <= nxt_state;

//
always_comb
begin
nxt_state = IDLE;
send = 1'b0;
//counter_en = 1'b0;
	case(state)
		IDLE:
			if(resp_rcvd) // done waiting for 17 bit counter
			begin
				nxt_state = SEND1;
				cmd_start = 5'b00000;
				cmd_len = 6;
				send = 1'b1;
			end

		SEND1:
			if(resp_rcvd)	//done sending first string
			begin
				nxt_state = SEND2;
				cmd_start = 5'b00110;
				cmd_len = 10;
				send = 1'b1;
			end
			else
				nxt_state =SEND1;
		SEND2:
			if(resp_rcvd)	//done sending second string
				nxt_state = WAIT; // start waiting for button press
			else
				nxt_state = SEND2;

		WAIT:
			if(!next_n) // button next pressed
			begin
				nxt_state = NEXT;
				cmd_start = 5'b10000;
				cmd_len = 4;
				send = 1'b1;
			end
			else if(!prev_n) // button prev pressed
			begin
				nxt_state = PREV;
				cmd_start = 5'b10100;
				cmd_len = 4;
				send = 1'b1;
			end	
			else
				nxt_state = WAIT;
		NEXT:
			if(resp_rcvd)	//done sending "AT+" string
				nxt_state = WAIT; //go back to wait again
			else
				nxt_state = NEXT;
		default:
			if(resp_rcvd)	//done sending "AT+" string
				nxt_state = WAIT; //go back to wait again
			else
				nxt_state = PREV;
	endcase
end




//counter
always@(posedge clk, negedge rst_n)
	if(!rst_n)
		counter <= 17'h0;
	else if(!(&(counter)))
		counter <= counter +1;

assign cmd_n = ~&(counter);
endmodule