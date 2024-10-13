//this module is a row of lights 4 lights long, it will light up when row_below is active, it will stay lit
//for a set hold time (light_hold) and then it will activate its next_up signal to tell the light above it(if there
//is one) to light up, if you stack these modules on top of each other they'll create a domino effect of lighting up
module light_row(pxls, next_up, user_press, immense_failure, row_below, light_speed, clk, reset);
	output logic [3:0] pxls;
	output logic next_up;
	output logic immense_failure;
	input logic [3:0] light_speed;
	input logic user_press, row_below, clk, reset;
	logic [8:0] light_hold;
	
	enum{light, dark} ps, ns;
	
	
	//calculate next state and outputs
	always_comb begin
		case (ps)
			light:
				if(light_hold != 0) begin //holding in the light state
					ns = light;
					pxls = 4'b1111;
					next_up = 0;
					if(user_press) begin
						immense_failure = 1;
					end else begin
						immense_failure = 0;
					end
				end else begin //switching from light to dark, that's why we turn on next_up
					ns = dark;
					pxls = 4'b0000;
					next_up = 1;
					immense_failure = 0;
				end
			dark: 
				if(row_below) begin //switch from dark to light
					ns = light;
					pxls = 4'b1111;
					next_up = 0;
					if(user_press) begin
						immense_failure = 1;
					end else begin
						immense_failure = 0;
					end					
				end else begin //holding in the dark state
					ns = dark;
					pxls = 4'b0000;
					next_up = 0;
					immense_failure = 0;
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
			if(ps == light) begin
				light_hold <= light_hold - 1'b1;  //increment the light_on countdown
			end else begin
				light_hold <= {light_speed[3], 1'b1, light_speed[2:0], 4'b0000}; //reset countdown when light goes dark
				//light_hold <= 9'b000000100;
			end
			ps <= ns;
		end
	end
endmodule

module light_row_testbench();
	logic [3:0] pxls;
	logic immense_failure;
	logic [3:0] light_speed;
	logic user_press, row_below, next_up, clk, reset;
	
	light_row dut (pxls, next_up, user_press, immense_failure, row_below, light_speed, clk, reset);
	
	parameter CLOCK_PERIOD=100;
   initial begin
       clk <= 0;
       forever #(CLOCK_PERIOD/2) clk <= ~clk; // Forever toggle the clock
   end
	
	initial begin
		reset <= 1; row_below <= 0; @(posedge clk);
		repeat(5) @(posedge clk);
		reset <= 0; @(posedge clk);
		repeat(5) @(posedge clk);
		
		row_below <= 1; @(posedge clk);
		row_below <= 0; @(posedge clk);
		
		user_press <= 1; @(posedge clk);
		user_press <= 0; @(posedge clk);
		
		repeat(3) @(posedge clk);
		
		$stop; //end simuation
	end
endmodule