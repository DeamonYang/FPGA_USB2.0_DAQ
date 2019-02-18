module DDS(
	rst_n,
	clk,
	dac_din,
	dac_sclk,
	dac_cs_n
	);

	input rst_n;
	input clk;
	output dac_din;
	output dac_sclk;
	output dac_cs_n;
	
	
	wire clk_20M;
	wire clk_200M;
	reg dac_go;
	wire dac_done;
	wire [11:0]out_data;
	
	assign dac_sclk = clk_20M;
	
	pll_20M	pll_20M_inst (
	.areset ( 1'b0 ),
	.inclk0 ( clk ),
	.c0 ( clk_20M ),
	.c1(clk_200M)
	);
	
	DAC_TLV5618 dac_lab(
		.rst_n(rst_n),
		.clk(clk_20M),
		.data({4'd0,out_data}),
		.chsl(1'b1),
		.dac_go(dac_go),
		.dac_done(dac_done),
		.tlv_sclk(),
		.tlv_din(dac_din),
		.tlv_cs(dac_cs_n)
		);
	
	dds_mod dds_lab1( 
		.clk(clk_200M),
		.rst_n(rst_n),
		.f_word(17'h1FFFF),
		.pword(12'd0),
		.dds_en(1'd1),
		.outclk(),
		.out_data(out_data)
		);
	
	always@(posedge clk_20M or negedge rst_n)
	if(!rst_n)
		dac_go <= 1'b1;
	else if(dac_done == 1'b1)
		dac_go <= 1'b1;
	else
		dac_go <= 1'b0;
	
	
	
endmodule

	