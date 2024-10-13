module user_in(keypress, clk, SW);
    input logic clk, SW;
    output logic keypress;
	 logic hold;
	 
	 always_ff @(posedge clk) begin
	     hold <= SW;
		  keypress <= SW & ~hold;
	 end

endmodule

module user_in_testbench();
    logic keypress, clk, SW;
    user_in dut (keypress, clk, SW);
    parameter CLOCK_PERIOD=100;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD/2) clk <= ~clk; // Forever toggle the clock
    end

    initial begin
        SW <= 0;
        repeat(5) @(posedge clk);
        SW <= 1; 
        repeat(30) @(posedge clk);  
        SW <= 0;  
        repeat(10) @(posedge clk);
        SW <= 1;  
        repeat(5) @(posedge clk);
        SW <= 0;  
        repeat(10) @(posedge clk);
        $stop; // End simulation
    end
endmodule