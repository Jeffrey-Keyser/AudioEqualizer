module PDM(clk, rst_n, duty, PDM);
  
  input clk, rst_n;
  input [15:0] duty;
  output PDM;
  reg count_o;
  reg [15:0] ff1_o, ff2_o;
  wire update;
  wire [15:0] B1, B2, A1, A2, mux2_o;

  //3-bit counter
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) count_o <= 1'b0;
    else count_o <= count_o + 1;
  end
  
  //3-bit counter output 
  assign update = (count_o == 1'h1) ? 1 : 0;

  //FF to input duty
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) ff1_o <= 16'h0;
    else if (update) ff1_o <= duty + 16'h8000;
  end

  //Handle the duty input
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) ff2_o <= 16'h0;
    else if (update) ff2_o <=  A2 + B2;
  end 

  assign B1 = (PDM) ? 16'hffff : 16'h0000;
  assign A1 = ff1_o;

  assign B2 = B1 - A1;
  assign A2 = ff2_o;
  
  assign PDM = (ff1_o >= ff2_o) ? 1 : 0;

endmodule