module high_freq_queue(lft_out,rght_out,sequencing, wrt_smpl, lft_smpl, rght_smpl, clk, rst_n);
output reg[15:0] lft_out,rght_out;
output reg sequencing;

input wrt_smpl, clk, rst_n;
input [15:0] lft_smpl, rght_smpl;

logic full, we, new_ptr_add, old_ptr_add;
logic [10:0] new_ptr, old_ptr, rd_ptr,  end_ptr;
logic [11:0] end_ptr_tmp;
logic ld_rd_ptr, inc_rd_ptr;

typedef enum reg {WRITE, READ} state_t;

state_t state,nxt_state;

dualPort1536x16 left (.clk(clk),.we(we),.waddr(new_ptr),.raddr(rd_ptr),.wdata(lft_smpl),.rdata(lft_out));
dualPort1536x16 rihgt (.clk(clk),.we(we),.waddr(new_ptr),.raddr(rd_ptr),.wdata(rght_smpl),.rdata(rght_out));
//SM
always@(posedge clk, negedge rst_n)
	if(!rst_n)
	begin	// Default Outputs
		state <= WRITE;
		new_ptr <= 11'h0;
		old_ptr <= 11'h0;
	end
	else 
	begin	// Pointer wrapping logic
		if(new_ptr_add && new_ptr != 11'd1535)
			new_ptr <= new_ptr + 1'b1;
		else if(new_ptr_add)
			new_ptr <=11'd0;

		if(old_ptr_add && old_ptr != 11'd1535)
			old_ptr <= old_ptr + 1'b1;	
		else if(old_ptr_add)
			old_ptr <=11'd0;

		state <= nxt_state;
	end
// Start reading at old pointer
always @(posedge clk)
	if (ld_rd_ptr)
		rd_ptr <= old_ptr;
	else if (inc_rd_ptr && rd_ptr != 11'd1535) 
		rd_ptr <= rd_ptr + 1;	
	else if (inc_rd_ptr)
		rd_ptr <=11'd0;

		

//SM transition
always_comb
begin
	// Default Outputs
      	sequencing =1'b0;
	nxt_state = WRITE;
	we = 1'b0;
	new_ptr_add = 1'b0;
	old_ptr_add = 1'b0;
	ld_rd_ptr = 1'b0;
	inc_rd_ptr = 1'b0;

	case(state)
		WRITE:	// Write data into circular queue
		if(!full && wrt_smpl) // Load data into the circular queue
		begin
			new_ptr_add = 1'b1;
			we = 1'b1;
		end
		else if(full && wrt_smpl) // If queue is full, go to read state
		begin
			old_ptr_add = 1'b1;
			new_ptr_add =  1'b1;
			ld_rd_ptr = 1'b1;
			we = 1'b1;
			nxt_state = READ;
		end

		default: // READ STATE : Read 1021 cells of data from circular queue
		if(rd_ptr != end_ptr) // If we have not reached the end of the sample (1021), continue reading
		begin
			nxt_state = READ;
			inc_rd_ptr = 1'b1;
			sequencing = 1'b1;
		end
		else	// When 1021 cells have been read, done reading for this sample
		begin
		    sequencing = 1'b1;
			nxt_state = WRITE;
		end
	endcase
end

// Deal with wrap around
assign end_ptr_tmp = old_ptr + 11'd1020;
assign end_ptr = (end_ptr_tmp > 11'h5ff) ?  (end_ptr_tmp - 11'h600) : end_ptr_tmp; //if larger than 1535, must be 1536, so adjust back to 0

// When queue has 1021 cells, signal full
always@(posedge clk, negedge rst_n)
if (!rst_n)
	full <= 1'b0;
else if(!full && (new_ptr == 11'd1531))
	full <= 1'b1;
endmodule
