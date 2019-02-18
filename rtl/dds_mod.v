module dds_mod(
	clk,
	rst_n,
	f_word,
	pword,
	dds_en,
	outclk,
	out_data
	);
	
	input clk;
	input rst_n;
	input [16:0]f_word;  /*频率分辨率 Fclk/2^N  */
	input [11:0]pword;
	input dds_en;
	output	wire outclk;
	output	wire[11:0]out_data;
	
	reg [31:0] fcnt;
	reg [11:0] rom_add;
	
	/*相位累加器*/
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
		fcnt <= 32'd0;
	else if(dds_en)
		fcnt <= fcnt + f_word;
	else 
		fcnt <= 32'd0;
		
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
		rom_add <= 32'd0;
	else if(dds_en)
		rom_add <= fcnt[31:20] + pword;
	
	
	assign outclk = dds_en?clk:1'b1;
	
	dds_sin_tab dds_wav_tab_lab1(
		.address(rom_add),
		.clock(outclk),
		.q(out_data));

			
endmodule

	