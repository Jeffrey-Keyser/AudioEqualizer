module Equalizer(clk,RST_n,LED,ADC_SS_n,ADC_MOSI,ADC_SCLK,ADC_MISO,
                 I2S_data,I2S_ws,I2S_sclk,cmd_n,sht_dwn,lft_PDM,
				 rght_PDM,Flt_n,next_n,prev_n,RX,TX);
				  
        input clk;		// 50MHz CLOCK
	input RST_n;		// unsynched active low reset from push button
	output [7:0] LED;	// Extra credit opportunity, otherwise tie low
	output ADC_SS_n;	// Next 4 are SPI interface to A2D
	output ADC_MOSI;
	output ADC_SCLK;
	input ADC_MISO;
	input I2S_data;		// serial data line from BT audio
	input I2S_ws;		// word select line from BT audio
	input I2S_sclk;		// clock line from BT audio
	output cmd_n;		// hold low to put BT module in command mode
	output reg sht_dwn;	// hold high for 5ms after reset
	output lft_PDM;		// Duty cycle of this drives left speaker
	output rght_PDM;	// Duty cycle of this drives right speaker
	input Flt_n;		// when low Amp(s) had a fault and needs sht_dwn
	input next_n;		// active low to skip to next song
	input prev_n;		// active low to repeat previous song
	input RX;			// UART RX (115200) from BT audio module
	output TX;			// UART TX to BT audio module
		
	///////////////////////////////////////////////////////
	// Declare and needed wires or registers below here //
	/////////////////////////////////////////////////////
	wire rst_n, vld;
	wire [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME;
	wire signed [23:0] rght_chnnl,lft_chnnl;
	wire [15:0] lft_reg, rght_reg;
 	reg [17:0] counter;
	wire [15:0] aud_out_lft, aud_out_rght;



	/////////////////////////////////////
	// Instantiate Reset synchronizer //
	///////////////////////////////////
	rst_synch rst(.RST_n(RST_n),.clk(clk), .rst_n(rst_n));


	//////////////////////////////////////
	// Instantiate Slide Pot Interface //
	////////////////////////////////////		
	slide_intf SI(.POT_LP(POT_LP), .POT_B1(POT_B1), .POT_B2(POT_B2), .POT_B3(POT_B3), .POT_HP(POT_HP), 
		.VOLUME(VOLUME), .MOSI(ADC_MOSI), .SCLK(ADC_SCLK), .SS_n(ADC_SS_n), .MISO(ADC_MISO), .clk(clk), .rst_n(rst_n));

				  
	//////////////////////////////////////
	// Instantiate BT module interface //
	////////////////////////////////////
	BT_intf BT(.cmd_n(cmd_n),.TX(TX),.RX(RX),.next_n(next_n),.prev_n(prev_n), 
		.clk(clk), .rst_n(rst_n));

					
			
    //////////////////////////////////////
    // Instantiate I2S_Slave interface //
    ////////////////////////////////////
    I2S_Slave I2S(.vld(vld),.rght_chnnl(rght_chnnl),.lft_chnnl(lft_chnnl), .I2S_data(I2S_data), 
		.I2S_ws(I2S_ws), .I2S_sclk(I2S_sclk),.clk(clk), .rst_n(rst_n));


    //////////////////////////////////////////
    // Instantiate EQ_engine or equivalent //
    ////////////////////////////////////////
	EQ_engine engine(.clk(clk), .rst_n(rst_n), .POT_LP(POT_LP), .POT_B1(POT_B1), .POT_B2(POT_B2), 
		.POT_B3(POT_B3), .POT_HP(POT_HP), .VOLUME(VOLUME), .aud_in_lft(lft_chnnl), .aud_in_rght(rght_chnnl), .vld(vld), .aud_out_lft(aud_out_lft), .aud_out_rght(aud_out_rght));


	
	/////////////////////////////////////
	// Instantiate PDM speaker driver //
	///////////////////////////////////
        spkr_drv speaker(.lft_chnnl(aud_out_lft), .rght_chnnl(aud_out_rght), .vld(vld), .lft_PDM(lft_PDM), 
		.rght_PDM(rght_PDM), .rst_n(rst_n), .clk(clk), .lft_reg(lft_reg), .rght_reg(rght_reg));

	
	///////////////////////////////////////////////////////////////
	// Infer sht_dwn/Flt_n logic or incorporate into other unit //
	/////////////////////////////////////////////////////////////
	always@(negedge rst_n, posedge clk, negedge Flt_n)
	begin
		if(!rst_n) begin
			counter <= 18'h00000;
			sht_dwn = 0;
		end
		else if (!Flt_n) begin
			counter <= 18'h00000;
			sht_dwn = 0;
		end
		else if(counter <= 18'b111101000010010000) begin
			counter <= counter +1;
			sht_dwn = 1;
		end 
		else sht_dwn = 0;
	
	end
	
	//assign sht_dwn = (counter <= 18'b111101000010010000);
        
	
	
	assign LED = 8'h00;


endmodule
