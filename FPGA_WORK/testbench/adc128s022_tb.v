`timescale 1ns/1ps
module adc128s022_tb;


	reg rst_n	;
	reg clk	;
	reg cv_go	;
	reg[2:0]chx	;
	reg  dout	;
	
	wire din	;
	wire cs		;
	wire sclk;
	wire done	;
	wire [11:0]data	;
	reg [11:0]r_data	;
	reg[15:0] cnt;
	adc128s022 adc(
		.rst_n(rst_n),
		.clk	(clk	),
		.cv_go(cv_go),
		.data	(data	),
		.chx	(chx	),
		.cs	(cs	),
		.sclk	(sclk	),
		.din	(din	),
		.dout	(dout	),
		.done	(done	)	
	);
	
	initial begin
		rst_n = 0;
		clk = 0;
		chx = 0;
		dout = 0;
		cv_go = 1;
		#1000;
		rst_n = 1;
		chx = 4;
		#40000;
		$stop;
	end
	
	
	always #20 clk = ~clk;
	
	always @(posedge clk or negedge rst_n)
	if(!rst_n)
		cv_go <= 0;
	else if(done | cnt == 15)
		cv_go <= 1;
	else
		cv_go <= 0;

	always @(posedge clk or negedge rst_n)
	if(!rst_n)
		r_data <= 1;
	else if(cnt < 30)
		r_data <= data;	
	
	always @(posedge clk or negedge rst_n)
	if(!rst_n)
		cnt <= 1;
	else if(cnt < 30)
		cnt <= cnt + 1;	
	

endmodule

