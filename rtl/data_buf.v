module data_buf(
	datain	,
	data_inv	,
	
	dataout	,
	data_add	,
	
	clk		,
	rst_n		,
	);

	
	input [15:0]datain;
	input data_inv	;
	output dataout	;
	input[8:0]data_add;
	input clk		;
	input rst_n		;

endmodule

