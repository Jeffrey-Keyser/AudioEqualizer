module SPI_mstr(clk,rst_n,wt_data,wrt,rd_data,done,SS_n,SCLK,MOSI,MISO);

input clk, rst_n, wrt;
input [15:0] wt_data;
output reg done, SS_n;
output[15:0] rd_data;
input  MISO;
output SCLK, MOSI;

typedef enum reg [1:0] {IDLE, SHIFT, FULL } state_t;
state_t state,nxt_state;
logic done16,shift,full,set_done,ld_SCLK,init;
reg [15:0] shift_reg;
reg [4:0] bit_cntr;
reg [3:0] SCLK_div;


always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= IDLE;
	else    
		state <= nxt_state;

//alwyas for done
always_ff@(posedge clk, negedge rst_n) 
	if(!rst_n)
		done <= 0;
	else if (set_done)
		done <= 1;
	else if (init)
         	done <= 0;


//alwyas for ss_n
always_ff@(posedge clk, negedge rst_n) 
	if(!rst_n)
		SS_n <= 1;
	else if (set_done)
		SS_n <= 1;
	else if (init)
         	SS_n <= 0;

always_comb begin
//default SM outputs
nxt_state = IDLE;
init = 0;
set_done = 0;
ld_SCLK = 0; 
 case(state)
	SHIFT: 	
		if(done16)
			nxt_state = FULL;
		else
			nxt_state = SHIFT;
	FULL:
		if(full) 
		begin
			set_done = 1;
	 		ld_SCLK = 1; 
			nxt_state = IDLE;
		end
		else
			nxt_state = FULL;
	default: //default in IDEL	
		if(wrt) begin
			ld_SCLK = 0;
			init = 1;
			nxt_state = SHIFT;
 		end
		else begin
			ld_SCLK = 1;
			nxt_state = IDLE;
		end
 endcase
end

always @(posedge clk) begin
//bit_cntr
 if(init)
	bit_cntr <= 5'b00000;
 else if(!init)
	if(shift)
		bit_cntr <= bit_cntr + 1;

//SCLK_div
 if(ld_SCLK)
	SCLK_div <= 4'b1011;
 else if(!ld_SCLK)
	SCLK_div <= SCLK_div +1;

//reg
if({init,shift} == 2'b10)
	shift_reg <= wt_data;
else if({init,shift} == 2'b11)
	shift_reg <= wt_data;
else if({init,shift} == 2'b01)
	shift_reg <=  {shift_reg[14:0],MISO};

end

assign SCLK = SCLK_div[3];
assign MOSI = shift_reg[15];
assign full = (SCLK_div == 4'b1111);
assign shift = (SCLK_div == 4'b1001);
assign done16 = (bit_cntr == 5'b10000);
assign rd_data = shift_reg;


endmodule
