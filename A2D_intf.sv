module A2D_intf(cnv_cmplt,res,SS_n,SCLK,MOSI,MISO,chnnl,strt_cnv,clk,rst_n);
input strt_cnv,clk,rst_n,MISO;
input[2:0] chnnl;
output reg cnv_cmplt,SS_n,SCLK,MOSI;
output[11:0] res;
logic wrt,done,conv_cmplt;
logic[15:0] rd_data,cmd;

typedef enum reg [1:0] {IDLE,GARB,WAIT,SPI} state_t;
state_t state, nxt_state;

//instantiate SPI_mast
SPI_mstr spi(.clk(clk),.rst_n(rst_n),.wt_data(cmd),.wrt(wrt),.rd_data(rd_data),.done(done),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO));
always @(posedge clk, negedge rst_n)begin
	if (!rst_n)
		state <= IDLE;
	else    
		state <= nxt_state;
end
always_comb begin
	nxt_state = IDLE;
	wrt =0;
	conv_cmplt =0;
	case(state)
		IDLE:	if(strt_cnv) 
			begin
			wrt = 1;
			nxt_state = GARB;
			end
		GARB:	if(done)
			nxt_state = WAIT;
			else
			nxt_state = GARB;
		WAIT:	begin
			nxt_state = SPI;
			wrt =1;
			end
		default:if(done)
			begin
			conv_cmplt = 1;
			nxt_state = IDLE;
			end
			else nxt_state = SPI;
	endcase
end

//flop for cnv_cmplt
always @(posedge clk, negedge rst_n)begin
	if (!rst_n)
		cnv_cmplt <= 1'b0;
	else if(strt_cnv)
		cnv_cmplt <= 1'b0;
	else if(conv_cmplt)
		cnv_cmplt <= 1;
end
assign cmd = {2'b00,chnnl,11'h000};
assign res[11:0] = rd_data[11:0];

endmodule