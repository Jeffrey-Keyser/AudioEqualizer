module rst_synch(RST_n,clk, rst_n);
input RST_n,clk;
output reg rst_n;
logic ff1in,ff1out;
always@(negedge clk, negedge RST_n)
begin

if(!RST_n)
begin
	ff1out <= 1'b0;
	rst_n <= 1'b0;
end
else
begin
	rst_n <= ff1out;
	ff1out <= 1'b1;
end
end
endmodule