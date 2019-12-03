module PB_rise(PB,clk,rst_n,rise);
input PB,clk,rst_n;
output reg rise;
logic ff1out, ff2out,ff3out;
//ff1
always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		ff1out <=1'b1;
	else
		ff1out <=PB;
end
//ff2
always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		ff2out <=1'b1;
	else
		ff2out <= ff1out;
end

//third flop will store value one cycle ago
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n)
		ff3out <= 1'b1;
	else
		ff3out <= ff2out;
end
assign rise = ~ff3out & ff2out; //when ff2out is 1(button lifeted), ff3out is still 0 from before, so will have rise =1
				//;when that 1 comes thru from ff2 to ff3(both 1), the ~ff3 & ff2 make rise back to 0
endmodule