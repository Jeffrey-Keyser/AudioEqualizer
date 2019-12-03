module FIR_HP(rght_out, lft_out, lft_in, rght_in, seq, clk, rst_n);

input signed [15:0] lft_in, rght_in;
input seq, clk, rst_n;

output signed[15:0] lft_out, rght_out;

typedef enum reg [1:0] {IDLE, GARB, CALC} state_t;
state_t state,nxt_state;

// SM output wires
logic ROM_clr, ROM_inc, MAC_add, MAC_clr;

// ROM input, output
logic [9:0] ROM_in;
logic signed [15:0] ROM_o;

// Create ROM
ROM_HP ROMMY(.clk(clk),.addr(ROM_in),.dout(ROM_o));

// MAC output
logic signed [31:0] MAC_lft_o, MAC_rght_o;

// SM
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) 
		state <= IDLE;
	else
		state <= nxt_state;
end

// SM logic
always_comb begin
// Default Outputs
ROM_inc = 1'b0;
ROM_clr = 1'b1;
MAC_add = 1'b0;
MAC_clr = 1'b0;
nxt_state = IDLE;
case(state)
	IDLE:
		if (seq)
		begin
			nxt_state = GARB;
			ROM_inc = 1'b1; 
			ROM_clr = 1'b0;
			MAC_add = 1'b0;
			MAC_clr = 1'b1;
		end
	// Else if !seq stay in IDLE state
	GARB:	// Waiting one clock cycle for ROM to access
	begin
		nxt_state = CALC;
		ROM_inc = 1'b1;
		ROM_clr = 1'b0;
		MAC_add = 1'b1;
		MAC_clr = 1'b0;

	end
	default:
		if (!seq)
		begin
		// Done calculating, Enter IDLE state output logic early
			
			ROM_inc = 1'b0;
			ROM_clr = 1'b0;
			MAC_add = 1'b0;
			MAC_clr = 1'b0; 
			nxt_state = IDLE;
		end
		else
		begin	// Sequencing isn't done, continue calculating
			
			// Continue to assert inc
			ROM_clr = 1'b0;
			ROM_inc = 1'b1;
			MAC_add = 1'b1;//TODO
			MAC_clr = 1'b0;
			nxt_state = CALC; // Need another GARB state for ROM to load new val
		end
endcase
end

// ROM LOGIC
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		ROM_in <=10'h000; 
	else if(ROM_clr)
		ROM_in <=10'h000;
	else if(ROM_inc)
		ROM_in <= ROM_in + 1'b1;
end

// MAC LOGIC
// Need two copies, one for left and right
always @ (posedge clk, negedge rst_n) begin
	if(!rst_n)
	MAC_lft_o <= 32'h00000000;
	else if (MAC_clr)
	MAC_lft_o <= 32'h00000000;
	else if (MAC_add)
	MAC_lft_o <= MAC_lft_o + (ROM_o * lft_in);
end

always @ (posedge clk, negedge rst_n) begin

	if(!rst_n)
		MAC_rght_o <= 32'h00000000;
	else if (MAC_clr)
	MAC_rght_o <= 32'h00000000;
	else if (MAC_add)	
	MAC_rght_o <= MAC_rght_o + (ROM_o * rght_in);
	//else retains value
end

// Assign final output
assign rght_out = MAC_rght_o[30:15];
assign lft_out = MAC_lft_o[30:15];

endmodule