module I2S_Slave(vld,rght_chnnl,lft_chnnl, I2S_data, I2S_ws, I2S_sclk,clk, rst_n);
input I2S_data, I2S_ws, I2S_sclk,clk, rst_n;
output logic [23:0] rght_chnnl,lft_chnnl;
output logic vld;

logic sclkff1out, sclkff2out,sclkff3out, sclk_rise;
logic wsff1out, wsff2out,wsff3out, ws_fall;

typedef enum reg [1:0] {SYNC,EXTRA,LEFT,RIGHT} state_t;
state_t state,nxt_state;

reg [4:0] bit_cntr;
reg [47:0] shft_reg;
logic clr_cnt,eq22,eq23,eq24;
//State Machine
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) begin
		state <= SYNC;
	end
	else
		state <= nxt_state;

//next state logic
always_comb begin
nxt_state = SYNC; //added
clr_cnt = 0;
vld =0;
 case(state)
	SYNC: 	
		if(ws_fall)
			nxt_state = EXTRA;
	EXTRA:
		if(sclk_rise) begin
			nxt_state = LEFT;
			clr_cnt =1;	
		end
		else
			nxt_state = EXTRA;	
	LEFT:
		if(eq24)
		begin
			clr_cnt = 1;
			nxt_state = RIGHT;
		end
		else
			nxt_state = LEFT;
	default:
		//R1 or R0 not aligned
		// since count increment at middle of R1 and R0 after sclk_rise
		// & w/ sclk_rise ensure check for the first half of R1 and R0 only
		if((eq22 & ~I2S_ws & sclk_rise)|(eq23 & I2S_ws & sclk_rise)) 		
			nxt_state = SYNC;
		else if(eq24)
		begin
			nxt_state = LEFT;
			clr_cnt = 1;
			vld = 1;
		end
		else
			nxt_state = RIGHT;
 	endcase
end



//counter
always@(posedge clk)
begin
	if(clr_cnt)
		bit_cntr <= 5'b00000;
	else if(sclk_rise)
		bit_cntr <= bit_cntr + 1;
	//else when sclk_rise if low, reg retain value
end 
assign eq22 = (bit_cntr == 5'b10110);
assign eq23 = (bit_cntr == 5'b10111);
assign eq24 = (bit_cntr == 5'b11000);

//shift register
always@(posedge clk)
begin
	if(sclk_rise)
		shft_reg <= {shft_reg[46:0],I2S_data};
	//else when sclk_rise is low, shift reg retain value
end 
assign lft_chnnl = shft_reg[47:24];
assign rght_chnnl = shft_reg[23:0];


//Synch & + edge detect for sclk
//sclkff1
always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		sclkff1out <=1'b0;
	else
		sclkff1out <=I2S_sclk;
end
//sclkff2
always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		sclkff2out <=1'b0;
	else
		sclkff2out <= sclkff1out;
end

//third flop will store value one cycle ago
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n)
		sclkff3out <= 1'b0;
	else
		sclkff3out <= sclkff2out;
end
assign sclk_rise = ~sclkff3out & sclkff2out;


//Synch & - edge detect for ws
//sclkff1
always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		wsff1out <=1'b1;
	else
		wsff1out <=I2S_ws;
end
//sclkff2
always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		wsff2out <=1'b1;
	else
		wsff2out <= wsff1out;
end

//third flop will store value one cycle ago
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n)
		wsff3out <= 1'b1;
	else
		wsff3out <= wsff2out;
end
assign ws_fall = wsff3out & ~wsff2out;
endmodule