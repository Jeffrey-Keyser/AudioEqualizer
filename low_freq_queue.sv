module low_freq_queue(lft_out,rght_out,sequencing, wrt_smpl, lft_smpl, rght_smpl, clk, rst_n);
output reg[15:0] lft_out,rght_out;
output reg sequencing;

input wrt_smpl, clk, rst_n;
input [15:0] lft_smpl, rght_smpl;

logic full, we, new_ptr_add, old_ptr_add;
logic [9:0]new_ptr, old_ptr, rd_ptr, end_ptr;
logic ld_rd_ptr, inc_rd_ptr;

typedef enum reg {WRITE, READ} state_t;

state_t state,nxt_state;

dualPort1024x16 left (.clk(clk),.we(we),.waddr(new_ptr),.raddr(rd_ptr),.wdata(lft_smpl),.rdata(lft_out));
dualPort1024x16 rihgt (.clk(clk),.we(we),.waddr(new_ptr),.raddr(rd_ptr),.wdata(rght_smpl),.rdata(rght_out));
//SM
always@(posedge clk, negedge rst_n)
	if(!rst_n)
	begin
		// Default Outputs
		state <= WRITE;
		new_ptr <= 10'h0;
		old_ptr <= 10'h0;
	end
	else 
	begin	// Incrementing pointer after adding data
		if(new_ptr_add)
			new_ptr <= new_ptr + 1'b1;
		if(old_ptr_add)
			old_ptr <= old_ptr + 1'b1;	

		state <= nxt_state;
	end
// Set read pointer as old pointer
always @(posedge clk)
	if (ld_rd_ptr)
		rd_ptr <= old_ptr;
	else if (inc_rd_ptr)
		rd_ptr <= rd_ptr + 1;
		

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
		WRITE:	// Loading data into circular queue
		if(!full && wrt_smpl)	
		begin
			new_ptr_add = 1'b1;
			we = 1'b1;
		end
		else if(full && wrt_smpl) // When queue is full, begin reading
		begin
			old_ptr_add = 1'b1;
			new_ptr_add =  1'b1;
			ld_rd_ptr = 1'b1;
			we = 1'b1;
			nxt_state = READ;
		end

		default: // READ STATE
		if(rd_ptr != end_ptr) // Continue reading until (1021) cells reached
		begin
			nxt_state = READ;
			inc_rd_ptr = 1'b1;
			sequencing = 1'b1;
		end
		else	// When (1021) cells have been read, done reading this sample
		begin
		    sequencing = 1'b1;
			nxt_state = WRITE;
		end
	endcase
end

// Set endpoint
assign end_ptr = old_ptr + 10'd1020;


// When queue has 1021 cells, signal full
always@(posedge clk, negedge rst_n)
if(!rst_n)
	full <= 1'b0;
else if(!full && (new_ptr == 10'd1021))
	full <= 1'b1;
endmodule