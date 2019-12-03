module EQ_engine(clk, rst_n, POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME, aud_in_lft, aud_in_rght, vld, aud_out_lft, aud_out_rght);

	input vld, clk, rst_n;
	input [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME;
	input signed [23:0] aud_in_lft, aud_in_rght;
	output [15:0] aud_out_lft, aud_out_rght;
	
	logic [15:0] low_out_lft, low_out_rght, high_out_lft, high_out_rght;
	logic low_sequencing, high_sequencing;
	logic  low_wrt_smpl;

	
	low_freq_queue lowQue(.lft_out(low_out_lft),.rght_out(low_out_rght),.sequencing(low_sequencing), .wrt_smpl(low_wrt_smpl), .lft_smpl(aud_in_lft[23:8]), .rght_smpl(aud_in_rght[23:8]), 
		.clk(clk), .rst_n(rst_n));
	high_freq_queue highQue(.lft_out(high_out_lft),.rght_out(high_out_rght),.sequencing(high_sequencing), .wrt_smpl(vld), .lft_smpl(aud_in_lft[23:8]), .rght_smpl(aud_in_rght[23:8]), 
		.clk(clk), .rst_n(rst_n));

	logic vld_div_2; 
	//set valid bit for low frequence queue
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			vld_div_2 <= 1'b0;
		else if(vld)
			vld_div_2 <= ~vld_div_2;		
	end
	assign low_wrt_smpl = vld & vld_div_2;

	logic signed [15:0] LP_rght, LP_lft, B1_rght, B1_lft, B2_rght, B2_lft, B3_rght, B3_lft, HP_rght, HP_lft;
	logic signed [15:0] LP_rght_flopped, LP_lft_flopped, B1_rght_flopped, B1_lft_flopped, B2_rght_flopped, B2_lft_flopped, B3_rght_flopped, B3_lft_flopped, HP_rght_flopped, HP_lft_flopped;
	FIR_LP LP(.rght_out(LP_rght), .lft_out(LP_lft), .lft_in(low_out_lft), .rght_in(low_out_rght), .seq(low_sequencing), .clk(clk), .rst_n(rst_n));
	FIR_B1 B1(.rght_out(B1_rght), .lft_out(B1_lft), .lft_in(low_out_lft), .rght_in(low_out_rght), .seq(low_sequencing), .clk(clk), .rst_n(rst_n));
	FIR_B2 B2(.rght_out(B2_rght), .lft_out(B2_lft), .lft_in(high_out_lft), .rght_in(high_out_rght), .seq(high_sequencing), .clk(clk), .rst_n(rst_n));
	FIR_B3 B3(.rght_out(B3_rght), .lft_out(B3_lft), .lft_in(high_out_lft), .rght_in(high_out_rght), .seq(high_sequencing), .clk(clk), .rst_n(rst_n));
	FIR_HP HP(.rght_out(HP_rght), .lft_out(HP_lft), .lft_in(high_out_lft), .rght_in(high_out_rght), .seq(high_sequencing), .clk(clk), .rst_n(rst_n));

	always@(posedge clk)
	begin
		if(vld)
		begin
			LP_rght_flopped <= LP_rght;
			LP_lft_flopped <=LP_lft;
 			B1_rght_flopped <= B1_rght;
			B1_lft_flopped<= B1_lft; 
			B2_rght_flopped<= B2_rght; 
			B2_lft_flopped<= B2_lft; 
			B3_rght_flopped<= B3_rght; 
			B3_lft_flopped<= B3_lft;
			HP_rght_flopped<= HP_rght; 
			HP_lft_flopped<= HP_lft;
		end
	end
//input [11:0] POT;
//input signed[15:0] audio;
//output signed[15:0] scaled;
	logic signed [15:0] band1_out, band2_out, band3_out, band4_out, band5_out, band6_out, band7_out, band8_out, band9_out, band10_out;
	logic signed [12:0] POT_LP_SQRD_SIGNED, POT_B1_SQRD_SIGNED, POT_B2_SQRD_SIGNED, POT_B3_SQRD_SIGNED, POT_HP_SQRD_SIGNED;
	logic [23:0] POT_LP_SQRD, POT_B1_SQRD, POT_B2_SQRD, POT_B3_SQRD, POT_HP_SQRD;
	
	assign POT_LP_SQRD =(POT_LP * POT_LP);
	assign POT_B1_SQRD =(POT_B1 * POT_B1);
	assign POT_B2_SQRD =(POT_B2 * POT_B2);
	assign POT_B3_SQRD =(POT_B3 * POT_B3);
	assign POT_HP_SQRD =(POT_HP * POT_HP);

	assign POT_LP_SQRD_SIGNED = {1'b0 , POT_LP_SQRD[23:12]};
	assign POT_B1_SQRD_SIGNED = {1'b0 , POT_B1_SQRD[23:12]};
	assign POT_B2_SQRD_SIGNED = {1'b0 , POT_B2_SQRD[23:12]};
	assign POT_B3_SQRD_SIGNED = {1'b0 , POT_B3_SQRD[23:12]};
	assign POT_HP_SQRD_SIGNED = {1'b0 , POT_HP_SQRD[23:12]};
					
	
	band_scale band1(.POT_sqrd_signed(POT_LP_SQRD_SIGNED),.audio(LP_lft_flopped),.scaled(band1_out));
	band_scale band2(.POT_sqrd_signed(POT_B1_SQRD_SIGNED),.audio(B1_lft_flopped),.scaled(band2_out));
	band_scale band3(.POT_sqrd_signed(POT_B2_SQRD_SIGNED),.audio(B2_lft_flopped),.scaled(band3_out));
	band_scale band4(.POT_sqrd_signed(POT_B3_SQRD_SIGNED),.audio(B3_lft_flopped),.scaled(band4_out));
	band_scale band5(.POT_sqrd_signed(POT_HP_SQRD_SIGNED),.audio(HP_lft_flopped),.scaled(band5_out));
	
	band_scale band6(.POT_sqrd_signed(POT_LP_SQRD_SIGNED),.audio(LP_rght_flopped),.scaled(band6_out));
	band_scale band7(.POT_sqrd_signed(POT_B1_SQRD_SIGNED),.audio(B1_rght_flopped),.scaled(band7_out));
	band_scale band8(.POT_sqrd_signed(POT_B2_SQRD_SIGNED),.audio(B2_rght_flopped),.scaled(band8_out));
	band_scale band9(.POT_sqrd_signed(POT_B3_SQRD_SIGNED),.audio(B3_rght_flopped),.scaled(band9_out));
	band_scale band10(.POT_sqrd_signed(POT_HP_SQRD_SIGNED),.audio(HP_rght_flopped),.scaled(band10_out));
	
	// TODO: Might need another flop here to get full bandout than do summation
	
	
	// Summation
	logic signed [15:0] lft_sum, rght_sum;
	logic signed [28:0] comb_left, comb_rght;
	assign lft_sum = band1_out + band2_out + band3_out + band4_out + band5_out;
	assign rght_sum = band6_out + band7_out + band8_out + band9_out + band10_out;
	
	
	// Volume
	logic signed [12:0] sig_vol;
	assign sig_vol = {1'b0, VOLUME};
	
	//flop between sum and multi too meet timing
	always@(posedge clk)
	begin
		comb_left <= lft_sum * sig_vol;
		comb_rght <= rght_sum * sig_vol;
	end
	
	assign aud_out_lft = comb_left[27:12];
	assign aud_out_rght = comb_rght[27:12];
	
		

endmodule
