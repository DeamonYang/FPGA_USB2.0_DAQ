`timescale 1ns/1ns

module usb_daq_tb;

	wire  SCLK		;
	wire  CS_N		;
	wire  RANGE	;
	wire  SGL_DIFN;
	wire  A0		;
	wire  A1		;
	wire  A2		;
	wire  AD_DONE	;		//ADC转换完毕
	wire [15:0]DATAA;//ADC数据口A
	wire [15:0]DATAB;//ADC数据口B
	
	reg rst_n		;
	reg clk		;
	reg DOUTA		;
	reg DOUTB		;
//	reg AD_GO		;		//ADC开始转换
	reg[3:0]tcnt;
	
	
	/*USB*/
	wire [7:0]adbus;
	reg txe;
	wire wr;
	reg clockout;
	wire siwu;
	wire led;
	
	parameter [15:0]da = 16'h5a5a;
	parameter [15:0]db = 16'ha5a5;


	usb_daq usbsys(
		.rst_n	(rst_n	),
		.clk	(clk	),
		
		.SCLK	(SCLK	),	
		.CS_N	(CS_N	),	
		.RANGE	(RANGE	),	
		.A0		(A0		),	
		.A1		(A1		),	
		.A2		(A2		),
		.DOUTA	(DOUTA	),	
		.DOUTB	(DOUTB	),
		
		.adbus	(adbus	),
		.txe	(txe	),
		.wr		(wr		),
		.clockout(clockout),
		.siwu	(siwu	),
		.led   (led	)
		); 
	
	
	
	
	

	initial begin
		rst_n = 0;
		clk = 0;
 
		clockout = 0;
		txe = 1;
		#1000;
		rst_n = 1;
 
		txe = 0;
		#20000;
 
		#4000000;
		$stop;
	end
	
	
	always #20 clk = ~clk;
	always #17 clockout = ~clockout;
	
	
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
		tcnt <= 4'd0;
	else
		tcnt <= tcnt + 1'b1;
		
	always@(posedge clk or negedge rst_n)
	if(!rst_n)begin
		DOUTA = 1'b0;
		DOUTB = 1'b0;
	end else begin
		DOUTA = da[tcnt];
		DOUTB = db[tcnt];
	end
		
		




















endmodule 

