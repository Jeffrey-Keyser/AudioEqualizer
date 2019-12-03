module spkr_drv(lft_chnnl, rght_chnnl, vld, lft_PDM, rght_PDM, rst_n, clk, lft_reg, rght_reg);

input [15:0] lft_chnnl, rght_chnnl;
input vld, clk, rst_n;
output lft_PDM, rght_PDM;

output reg [15:0] lft_reg, rght_reg;
logic lft_PDM, rght_PDM;

always_ff @(posedge clk)
	if(vld) begin
		lft_reg <= lft_chnnl;
		rght_reg <= rght_chnnl;
	end

PDM PDM1(.clk(clk), .rst_n(rst_n), .duty(lft_reg), .PDM(lft_PDM));
PDM PDM2(.clk(clk), .rst_n(rst_n), .duty(rght_reg), .PDM(rght_PDM));


endmodule
