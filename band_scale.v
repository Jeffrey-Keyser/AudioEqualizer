module band_scale(POT_sqrd_signed,audio,scaled);
input signed[12:0] POT_sqrd_signed;
input signed[15:0] audio;
output signed[15:0] scaled ;

wire signed [28:0] product;

assign product = audio * POT_sqrd_signed;

// check for saturation
wire posSat;
wire negSat;
assign negSat = product[28] ? (product[27:25] == 3'b111  ? 1'b0: 1'b1) : 1'b0;
assign posSat = product[28] ? 1'b0 : ( product[27:25] == 3'b000 ? 1'b0 : 1'b1 );
assign scaled = negSat      ? 16'h8000 : (posSat ? 16'h7fff : product[25:10]);

endmodule