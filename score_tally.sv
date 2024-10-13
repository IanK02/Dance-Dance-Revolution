//sets 3 hex displays to display the player's current score, takes two inputs, the 16 bit array of which
//rows the user has pressed on and another that determines if the user hit the winning row
//this needs to be updated to take 4 different user_entries and 4 different big_score inputs, 1 for each column
//ok nvm, I'll just modify user_entries to be 64 long and big_score to be 4 long
module score_tally(hex1, hex10, hex100, user_entries, light_lost, empty_press, clk, reset);
	output logic [6:0] hex1, hex10, hex100;
	input logic [63:0] user_entries;
	input logic [3:0] light_lost, empty_press;
	input logic clk, reset;
	logic [9:0] score;
	logic [2:0] big_score_count, light_lost_count, user_miss_count, empty_press_count;
	logic [3:0] user_miss, big_score;
	logic [7:0] user_partial;
	logic [2:0] user_partial_count;
	
	assign user_miss = {|user_entries[12:0],
							  |user_entries[28:16],
							  |user_entries[44:32],
							  |user_entries[60:48]};
	assign user_partial = {user_entries[13],
								 user_entries[15],
								 user_entries[29],
								 user_entries[31],
								 user_entries[45],
								 user_entries[47],
								 user_entries[61],
								 user_entries[63]};
	assign big_score = {user_entries[14],
							  user_entries[30],
							  user_entries[46],
							  user_entries[62]};
								 
								 
	
	seg7 ones_hex (score % 10, hex1);
	seg7 tens_hex ((score%100)/10, hex10);
	seg7 hunds_hex (score/100, hex100);
	
	
	always_ff @(posedge clk) begin
		if(reset) begin
			score <= 10'b0000000000;
		end
		if(|big_score[3:0]) begin
			big_score_count = (big_score[0] + big_score[1] + big_score[2] + big_score[3])*2;
			if((score + big_score_count) > 999) begin
				score <= 0;
			end else begin
				score <= score + big_score_count;
			end
		end else if(|user_partial[7:0]) begin
			user_partial_count = user_partial[0] + user_partial[1] + user_partial[2] + user_partial[3] + 
										user_partial[4] + user_partial[5] + user_partial[6] + user_partial[7];
			if((score + user_partial_count) > 999) begin
				score <= 0;
			end else begin
				score <= score + user_partial_count;
			end
		end else if(|user_miss[3:0]) begin
			user_miss_count = (user_miss[0] + user_miss[1] + user_miss[2] + user_miss[3])*2;
			if(user_miss_count > score) begin
				score <= 0;
			end else begin
				score <= score - user_miss_count;
			end
		end else if(|light_lost[3:0]) begin
			light_lost_count = (light_lost[0] + light_lost[1] + light_lost[2] + light_lost[3])*2;
			if(light_lost_count > score) begin
				score <= 0;
			end else begin
				score <= score - light_lost_count;
			end
		end else if(|empty_press[3:0])begin
			empty_press_count = (empty_press[0] + empty_press[1] + empty_press[2] + empty_press[3])*2;
			if(empty_press_count > score) begin
				score <= 0;
			end else begin
				score <= score - empty_press_count;
			end			
		end 
	end
endmodule

module score_tally_testbench();
	logic [6:0] hex1, hex10, hex100;
	logic [15:0] user_entries;
	logic [3:0] light_lost, empty_press;
	logic clk, reset;
	
	score_tally dut (hex1, hex10, hex100, user_entries, light_lost, empty_press, clk, reset);
	
	parameter CLOCK_PERIOD=100;
   initial begin
       clk <= 0;
       forever #(CLOCK_PERIOD/2) clk <= ~clk; // Forever toggle the clock
   end
	
	initial begin
		reset <= 1; @(posedge clk);
		reset <= 0; user_entries <= 16'b0; @(posedge clk); //reset machine, set user_entries to all 0
		
		repeat(3) @(posedge clk);
		
		repeat(10) begin
			user_entries[14] <= 1; @(posedge clk);
			user_entries[14] <= 0; @(posedge clk); //user gets 20 points
		end
		
		repeat(3) begin
			user_entries[1] <= 1; @(posedge clk);
			user_entries[1] <= 0; @(posedge clk); //user loses 6 points
		end
		
		repeat(3) @(posedge clk);
		
		user_entries[13] <= 1; @(posedge clk);
		user_entries[13] <= 0; @(posedge clk); //user gets 1 point
		user_entries[15] <= 1; @(posedge clk);
		user_entries[15] <= 0; @(posedge clk); //user gets another point
		
		repeat(5) @(posedge clk); 
		
		light_lost <= 4'b1000; @(posedge clk); //user lets light overflow
		light_lost <= 4'b0000; @(posedge clk);
		light_lost <= 4'b1000; @(posedge clk); //user lets light overflow again
		light_lost <= 4'b0000; @(posedge clk);
		
		repeat(5) @(posedge clk);
		
		empty_press <= 4'b0001; @(posedge clk);
		empty_press <= 4'b0000; @(posedge clk); //user presses when no lights are present
		
		repeat(5) @(posedge clk);
		
		user_entries[0] <= 1; @(posedge clk);
		user_entries[0] <= 1; @(posedge clk); //user mistakenly presses while light is present
		
		repeat(5) @(posedge clk);
		
		
		$stop; //end simulation
	end
	
endmodule