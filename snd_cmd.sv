module snd_cmd(cmd_start,send,cmd_len,clk,rst_n, resp_rcvd,TX,RX);
input logic [4:0] cmd_start ;
input logic [3:0] cmd_len;
input logic send, clk, rst_n, RX;
output logic TX,resp_rcvd;

typedef enum reg [1:0] {IDLE,VALID,GET,TRANS} state_t;
state_t state,nxt_state;

//wire for SM
logic last_byte,inc_addr;

//wire from UART
logic rx_rdy,tx_done,trmt;
logic [7:0] tx_data,rx_data;

//reg for == clound
logic[4:0]last_addr, addr;

//instantiate 
UART UART(.clk(clk),.rst_n(rst_n),.RX(RX),.TX(TX),.rx_rdy(rx_rdy),.clr_rx_rdy(rx_rdy),.rx_data(rx_data),.trmt(trmt),.tx_data(tx_data),.tx_done(tx_done));
cmdROM ROM(.clk(clk),.addr(addr),.dout(tx_data));

//SM
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) 
		state <= IDLE;
	else
		state <= nxt_state;

//next state logic
always_comb begin
nxt_state = IDLE;
trmt = 0;
inc_addr = 0;
case(state)
	IDLE:
		if(send)
			nxt_state = VALID;
	VALID:
		nxt_state = GET;
	GET:
		begin
			trmt = 1;
			inc_addr = 1;
			nxt_state = TRANS;	
		end
	default:
		if(tx_done & ~last_byte)
		begin
			trmt = 1;
			inc_addr = 1;
			nxt_state = TRANS;
		end
		else if(tx_done & last_byte)
			nxt_state = IDLE;
		else
			nxt_state = TRANS;
endcase
end

//ff for last char check
always @(posedge clk)
begin
	//at start, determine where command address stops
	if(send)
		last_addr =  cmd_start + cmd_len;
	//else reg retain value
end

//ff for inc add
always @(posedge clk)
begin
	if(send)
		addr = cmd_start;
	else if(inc_addr)
		addr = addr + 1;
	//else reg retain value
end

//coparison cloud logic
assign last_byte = last_addr == addr;
assign resp_rcvd = rx_rdy & (rx_data == 8'h0A);
endmodule