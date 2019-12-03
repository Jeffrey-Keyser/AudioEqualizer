module slide_intf(POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME, MOSI, SCLK, SS_n, MISO, clk, rst_n);

output logic [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME;
output SS_n, SCLK, MOSI;
input MISO, clk, rst_n;

reg   [11:0] regs[7:0];
logic strt_cnv, cnv_cmplt;
logic [11:0] res;
logic [2:0] chnnl;
logic EN[7:0];
logic [1:0] state, nxt_state;

A2D_intf a2d(.clk(clk), .rst_n(rst_n), .res(res), .chnnl(chnnl), .strt_cnv(strt_cnv), .cnv_cmplt(cnv_cmplt), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

localparam IDLE = 2'b0;
localparam CHNL_RD = 2'b1;
localparam IDLE_PREV = 2'h2;

always @ (posedge clk, negedge rst_n) begin
	if (!rst_n)
	state <= IDLE_PREV;
	else
	state <= nxt_state;
end

// State Machine
always_comb begin
// Default outputs
strt_cnv = 0;
nxt_state = IDLE;
case (state)
	IDLE_PREV:
		nxt_state = IDLE;
	IDLE:
		//if(chnnl != 3'b110) begin
		begin
			nxt_state = CHNL_RD;
			strt_cnv = 1;
		end
	CHNL_RD:
	begin
		if (cnv_cmplt)
		begin
			nxt_state = IDLE;
		end
		else
			nxt_state = CHNL_RD;
	end

endcase

end

// Iterate through all channels
always @(posedge cnv_cmplt, negedge rst_n) begin
	if (!rst_n)
	chnnl <= 3'b111; // channel 5, 6 out of channel 0-7 not mapped
	else if(chnnl == 4)
	chnnl <= 3'b111;
	else
	chnnl <= chnnl + 1;
end

genvar i;

generate 
for(i = 0; i < 8; i++) begin
	assign EN[i] = (chnnl == i);
	always @(posedge clk)
	//always_comb
		if(EN[i]) regs[i] = res;
		//else regs[i] = 1'b0;
end

endgenerate

always @(posedge cnv_cmplt)
begin
POT_B1 <= regs[0];
POT_LP <= regs[1];
POT_B3 <= regs[2];
POT_HP <= regs[3];
POT_B2 <= regs[4];
VOLUME <= regs[7];
end

endmodule

