//almost identical to light_row except that the lights are always on, and this module can detect a user's button press
//and will sent out a scored signal if user_press is active while the machine is in the light state, note that both
//the dark and light states will have the lights turned on at all times, so the 2 states are useful here to know
//if the user has correctly pressed or not
//this module as well as light_row only will register user presses while they're lit up, empty presses
//are handled by the light_column module
module uin_light_row(pxls, next_up, scored, top_row, user_press, row_below, light_speed, clk, reset);
	output logic [3:0] pxls;
	output logic next_up;
	output logic scored;
	input logic [3:0] light_speed;
	input logic top_row, user_press, row_below, clk, reset;
	logic [8:0] light_hold;
	logic cancel_nup;
	
	enum{light, dark} ps, ns;
	
	//calculate next state and outputs
	always_comb begin
		case (ps)
			light:
				if(light_hold != 0) begin //holding in the light state
					ns = light;
					pxls = 4'b1111;
					if(user_press) begin //check for user button press
						scored = 1;
					end else begin
						scored = 0;
					end
					//if(cancel_nup) begin
					//	next_up = 0;
					//end else begin
					//	next_up = 1;
					next_up = 0;
				end else begin //switching from light to dark, this is the ONLY time next_up can be turned on
					ns = dark;
					if(top_row) begin
						pxls = 4'b0000;
					end else begin
						pxls = 4'b1111;
					end
					if(user_press) begin //check for user button press 
						scored = 1;
					end else begin
						scored = 0;
					end
					if(user_press || cancel_nup) begin
						next_up = 0;
					end else begin
						next_up = 1;
					end
				end
			dark: 
				if(row_below) begin 
					//switch from dark to light, keep next_up at 0 and DO NOT check for user score
					ns = light;
					pxls = 4'b1111;
					next_up = 0;
					scored = 0;
				end else begin //holding in the dark state
					ns = dark;
					if(top_row) begin
						pxls = 4'b0000;
					end else begin
						pxls = 4'b1111;
					end
					next_up = 0;
					scored = 0;
				end
		endcase
	end
	
	//calculate present state
	//CHANGE light_hold TO MAX VALUE OF 9BIT BEFORE FLASHING TO FPGA, IT IS ONLY AT 3 FOR TESTING
	always_ff @(posedge clk) begin
		if(reset) begin
			ps <= dark;
			light_hold <= {light_speed[3], 1'b1, light_speed[2:0], 4'b0000}; //reset countdown when reset is pressed
			//light_hold <= 9'b000000100;
		end else begin
			if(ps == light) begin //in the light state
				light_hold <= light_hold - 1'b1;  //increment the light_on countdown
				if(user_press) begin
					cancel_nup <= 1;
				end else begin
					cancel_nup <= cancel_nup;
				end
			end else begin
				light_hold <= {light_speed[3], 1'b1, light_speed[2:0], 4'b0000}; //reset countdown when light goes dark
				//light_hold <= 9'b000000100;
				cancel_nup <= 0; //put cancel_nup back to 0 while in the dark state
			end
			ps <= ns;
		end
	end
endmodule

module uin_light_row_testbench();
	logic [3:0] pxls, light_speed;
	logic next_up, scored, user_press, row_below, clk, reset;
	
	uin_light_row dut (pxls, next_up, scored, 1, user_press, row_below, light_speed, clk, reset);
	
	parameter CLOCK_PERIOD=100;
   initial begin
       clk <= 0;
       forever #(CLOCK_PERIOD/2) clk <= ~clk; // Forever toggle the clock
   end
	
	initial begin
		reset <= 1; row_below <= 0; @(posedge clk);
		reset <= 0; @(posedge clk);
		repeat(5) @(posedge clk);
		
		row_below <= 1;  @(posedge clk);
		row_below <= 0;  @(posedge clk);
		repeat(2) @(posedge clk);
		user_press <= 1; @(posedge clk);
		user_press <= 0; @(posedge clk); //this should make sure next_up doesn't go positive once we reach dark
													//state again
		
		repeat(6) @(posedge clk); //wait till we're back into the dark state
		user_press <= 1; @(posedge clk); //make sure user press doesn't register in dark state
		user_press <= 0; @(posedge clk);
		repeat(3) @(posedge clk);
		
		$stop; //end simuation
	end
endmodule	