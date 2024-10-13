// This module combines 16 of the light row_modules into one 4x16 column outputting a 4x16 array 
// of which leds are on (active high), the led at the bottom of the column can be triggered by root_spawn_signal
// and I've added in user_button to see if I could implement a system where the system knows which row is active
// and can check if the user presses the button when the light is at the correct row
//-------------------------------------------------------------------------------
// each column on the display will be either just red or just green
//-------------------------------------------------------------------------------
// also you NEED to implement that the user will lose 2 points if the light goes over the top
// likely will have to make a new top_row module that will flick on the immense_failure signal
// if it's next_up signal is triggerede
module light_column(pixls, user_press, light_lost, empty_press, root_spawn_signal, user_button, light_speed, clk, reset);
	output logic [15:0][3:0] pixls;
	output logic [15:0] user_press; //the corresponding light in the column will turn to 1 when the user presses
											 //the button while the light is on that row
	output logic light_lost, empty_press;
	input logic [3:0] light_speed;
	input logic root_spawn_signal, user_button, clk, reset;
	logic [15:0] nup_signals;
	
	//instantiate the starting lightrow connected to the root spawn signal
	light_row bottom_row (.pxls(pixls[0]), 
					.next_up(nup_signals[0]),
					.user_press(user_button),
					.immense_failure(user_press[0]),
					.row_below(root_spawn_signal),
					.light_speed(light_speed),
					.clk(clk), 
					.reset(reset));
	
	//instantiate 12 light row modules, each connected to the ones on top and below them
	genvar i;
	generate
		for(i=1; i<13; i++) begin: eachRow
			light_row row (.pxls(pixls[i]), 
								.next_up(nup_signals[i]),
								.user_press(user_button),
								.immense_failure(user_press[i]),
								.row_below(nup_signals[i-1]), 
								.light_speed(light_speed),
								.clk(clk), 
								.reset(reset));
		end
	endgenerate
	
	uin_light_row partial_row (.pxls(pixls[13]), .next_up(nup_signals[13]), .scored(user_press[13]), .top_row(1'b1), .user_press(user_button), .row_below(nup_signals[12]), .light_speed(light_speed), .clk(clk), .reset(reset));
	
	//instantiate the row that always stays lit up
	uin_light_row press_row (.pxls(pixls[14]), .next_up(nup_signals[14]), .scored(user_press[14]), .top_row(1'b0), .user_press(user_button), .row_below(nup_signals[13]), .light_speed(light_speed), .clk(clk), .reset(reset));

	//instantiate the very last top row of lights
	uin_light_row top_row (.pxls(pixls[15]), .next_up(light_lost), .scored(user_press[15]), .top_row(1'b1), .user_press(user_button), .row_below(nup_signals[14]), .light_speed(light_speed), .clk(clk), .reset(reset));
	
	always_ff @(posedge clk) begin //check if the user has pressed while none of the lights are lit up
		if((user_press == 16'b0) && (user_button ==1))begin
			empty_press <= 1;
		end else begin
			empty_press <= 0;
		end
	end
	
endmodule

module light_column_testbench();
	logic [15:0][3:0] pixls;
	logic root_spawn_signal, user_button, clk, reset, light_lost, empty_press;
	logic [15:0] nup_signals, user_press;
	logic [3:0] light_speed;
	
	light_column dut (pixls, user_press, light_lost, empty_press, root_spawn_signal, user_button, light_speed, clk, reset);
	
	parameter CLOCK_PERIOD=100;
   initial begin
       clk <= 0;
       forever #(CLOCK_PERIOD/2) clk <= ~clk; // Forever toggle the clock
   end
	
	initial begin
		reset <= 1; @(posedge clk);
		reset <= 0; @(posedge clk); //reset the simulation
		
		repeat(4) @(posedge clk); //wait a bit
		
		user_button <= 1; @(posedge clk);
		user_button <= 0; @(posedge clk); //should trigger empty press
		
		root_spawn_signal <= 1; @(posedge clk); //start simulation
		root_spawn_signal <= 0; @(posedge clk);
		repeat(20) @(posedge clk);
		user_button <= 1; @(posedge clk); //user press (they mess up)
		user_button <= 0; @(posedge clk);
		repeat(40) @(posedge clk); 
		user_button <= 1; @(posedge clk); //user messes up again
		user_button <= 0; @(posedge clk);
		repeat(68) @(posedge clk); //nothing should happen at all here
		
		$stop; //end simulation
	end
endmodule