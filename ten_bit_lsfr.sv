module ten_bit_lsfr #(parameter START_NUM = 1)(out_num, clk, reset);
    input logic clk, reset;
    output logic [17:0] out_num;
    logic [17:0] feedback;
    logic next_bit;
   
	 
	 //next state
    assign next_bit = feedback[0] ~^ feedback[7];
    
	 //present state
    always_ff @(posedge clk) begin
        if(reset) begin
            feedback <= START_NUM;
        end else begin
            feedback <= {next_bit, feedback[17:1]};
        end
    end
    
	 //output
    assign out_num = feedback;
	 
endmodule

module ten_bit_lsfr_testbench();
	logic [12:0] out_num;
	logic clk, reset;
	parameter CLOCK_PERIOD=100;
	logic detected;
	
	ten_bit_lsfr #(.START_NUM(12'b011110000011)) dut (out_num, clk, reset);
	
   initial begin
       clk <= 0;
       forever #(CLOCK_PERIOD/2) clk <= ~clk; // Forever toggle the clock
   end
	

	
	initial begin
		detected <= 0; @(posedge clk);
		reset <= 1; @(posedge clk);
		reset <= 0; @(posedge clk);
		repeat(150) @(posedge clk);
		$stop;
	end
	
endmodule