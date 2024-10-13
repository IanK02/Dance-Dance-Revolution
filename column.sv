//used to determine whether or not you should spawn a light in the column, my b for the misleading naming
module column (spawn_light, diff_setting, clk, reset, lsfr_num);
	input logic clk, reset;
	input logic [17:0] lsfr_num;
	input logic [2:0] diff_setting;
	output logic spawn_light;
	
	//define states
	enum{spawn, no_spawn} ps, ns;
	
	//calculate next state
	always_comb begin
		case (ps)
			spawn: begin
						ns = no_spawn;
						spawn_light = 0;
			end
			no_spawn: begin
						 if(lsfr_num <= diff_setting) begin
								ns = spawn;
								spawn_light = 1;
						 end else begin
								ns = no_spawn;
								spawn_light = 0;
						 end
			end			
		endcase
	end
	
	//set present state
	always_ff @(posedge clk) begin
		if (reset) begin
			ps <= no_spawn;
		end else begin
			ps <= ns;
		end
	end
	
endmodule

module column_testbench();
	logic clk, reset, spawn_light;
	logic [12:0] lsfr_num;
	logic [12:0] diff_setting;
	
	column dut (spawn_light, diff_setting, clk, reset, lsfr_num);
	
	parameter CLOCK_PERIOD=100;
   initial begin
       clk <= 0;
       forever #(CLOCK_PERIOD/2) clk <= ~clk; // Forever toggle the clock
   end
	
	ten_bit_lsfr #(.START_NUM(12'b010011100011)) lsfr (lsfr_num, clk, reset); //make the lsfr to test the column
	
	initial begin
		reset <= 1; @(posedge clk);
		reset <= 0; @(posedge clk); //reset machine
		//-------------------------------------
		repeat(4) @(posedge clk); //wait a bit
		//-------------------------------------
		//diff_setting <= 4'b1111; @(posedge clk); //set difficulty to maximum
		//-------------------------------------
		repeat(1024) @(posedge clk); //see how many lights get spawned in a full rotation of the lsfr
		$stop; //end simulation
	end
	
endmodule