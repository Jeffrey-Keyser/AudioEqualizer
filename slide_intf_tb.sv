module slide_intf_tb();

logic clk, rst_n;
reg[11:0] mem[5:0];
logic SS_n, SCLK, MOSI, MISO;
wire [11:0]POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME;

A2D_with_Pots pot(.clk(clk), .rst_n(rst_n), .LP(mem[0]), .B1(mem[1]), .B2(mem[2]),
	.B3(mem[3]), .HP(mem[4]), .VOL(mem[5]), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

slide_intf iDUT (.POT_LP(POT_LP), .POT_B1(POT_B1), .POT_B2(POT_B2), .POT_B3(POT_B3), .POT_HP(POT_HP), .VOLUME(VOLUME), .MOSI(MOSI), .SCLK(SCLK), .SS_n(SS_n), .MISO(MISO), .clk(clk), .rst_n(rst_n));

initial begin
        mem[0] = 12'b111111111111;
        mem[1] = 12'b111111111111;
        mem[2] = 12'b111111111111;
        mem[3] = 12'b111111111111;
        mem[4] = 12'b111111111111;
        mem[5] = 12'b111111111111;
	clk = 0;
	rst_n = 1;
	@(negedge clk);
	rst_n = 0;
	@(posedge clk)
	@(negedge clk)
	rst_n = 1;

	#80000;
        mem[0] = 12'b111111111110;
        mem[1] = 12'b111111111101;
        mem[2] = 12'b111111111011;
        mem[3] = 12'b111111110111;
        mem[4] = 12'b111111101111;
        mem[5] = 12'b111111011111;

end
       
always #5 clk = ~clk;

endmodule
