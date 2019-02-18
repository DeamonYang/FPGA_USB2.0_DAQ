module usb_daq(
	rst_n		,
	clk		,
	/*AD7266*/
	SCLK		,	
	CS_N		,	
	RANGE		,	
	A0			,	
	A1			,	
	A2			,
	DOUTA		,	
	DOUTB		,
	
	/*USB*/
	adbus		,
	txe		,
	wr			,
	clockout	,
	siwu		,
	
	
	led
	);


	
	input rst_n;
	input	clk;
	output led;
	reg cv_go	;
	wire done	;
	wire [11:0]data;
	reg [11:0]r_data;
	reg[15:0] cnt;
	
	

	output wire SCLK		;
	output wire CS_N		;
	output wire RANGE	;
	 wire SGL_DIFN;
	output wire A0		;
	output wire A1		;
	output wire A2		;
	input	DOUTA		;
	input	DOUTB		;
	
	
	
	
	output[7:0] adbus;//D7 to D0 bidirectional FIFO data. This bus is normally input unless OE# is low. 
	input txe;//When high, do not write data into the FIFO
	output wr;//Enables the data byte on the D0...D7 pins to be written into the transmit FIFO buffer
	input clockout;//60 MHz Clock driven from the chip
	output siwu;
	
	/*FPGA 端FIFO  缓冲数据 处理跨时钟域*/
	wire[7:0]usbdata;
	wire rd_clk;
//	output reg [8:0]rd_add;
	wire [10:0]rd_add;
	
	wire tr_go; //开始传输 高有效
	wire tr_done;
	
	assign usbdata = rd_add[7:0];
	
	
	
	assign led = r_data[1];
	wire 	AD_GO		;		//ADC开始转换
	wire  AD_DONE	;		//ADC转换完毕
	wire [15:0]DATAA;//ADC数据口A
	wire [15:0]DATAB;//ADC数据口B
	wire ad7266_clk;
	wire send_go;
	reg [7:0]data_cnt;
	
	assign AD_GO = 1'b1;
	
	pll pll_1(
		.inclk0(clk),
		.c0(ad7266_clk));
	

		
 data_trans_mux mux(
//	.ad7266dataa(16'h55AA),  
//	.ad7266dataa({data_cnt[0],data_cnt[1],data_cnt[2],data_cnt[3],data_cnt[4],data_cnt[5],data_cnt[6],data_cnt[7],data_cnt[7:0]}),
//	.ad7266dataa({data_cnt[3:0],data_cnt[7:4],data_cnt[7:0]}),
	.ad7266dataa({data_cnt[7:0],data_cnt[7:0]}),
	.ad7266datab(DATAB),
	.ad7266sdclk(ad7266_clk),
	.ad7266wren	(AD_DONE	),
	.usbdata	( ),
	.usbdadd	(rd_add	),
	.usbdataclk	(clockout	),
	.send_go	(send_go	),
	.rst_n   (rst_n )
	);
		
		
		
		
		
	
	AD7266 ADC1(
		.SCLK			(SCLK			),
		.CS_N			(CS_N			),
		.RANGE		(RANGE		),
		.SGL_DIFN	(SGL_DIFN	),
		.A0			(A0			),
		.A1			(A1			),
		.A2			(A2			),
		.DOUTA		(DOUTA		),
		.DOUTB		(DOUTB		),
		.AD_GO		(AD_GO		),
		.AD_DONE		(AD_DONE		),
		.DATAA		(DATAA		),
		.DATAB		(DATAB		),
		.rst_n		(rst_n		),
		.clk			(ad7266_clk	) 
		
		);
	
	
	/*USB 端口*/
	ft232ram_send usb_send(
		.adbus	(adbus	 ),
		.txe		(txe	 ),
		.wr		(wr		 ),
		.clockout(clockout),
		.siwu		(siwu	 	),
		.data		(usbdata	 ),
		.rd_clk	(rd_clk	 ),
		.rd_add	(rd_add	 ),
		.tr_go	(send_go	 ),
		.tr_done	(tr_done ),
		.rst_n	(rst_n	 )
		);               
	
	
	/*用于产生仿真测试数据*/
	always @(posedge SCLK or negedge rst_n)
	if(!rst_n)
		data_cnt <= 8'd0;
	else if( AD_DONE == 1'b1)
		data_cnt <= data_cnt +  1'b1;

	
	
	
	always @(posedge clk or negedge rst_n)
	if(!rst_n)
		cv_go = 0;
	else if(done | cnt == 15)
		cv_go = 1;
	else
		cv_go = 0;
		
		
	always @(posedge clk or negedge rst_n)
	if(!rst_n)
		r_data <= 1;
	else if(cnt < 30)
		r_data <= data;

	
	always @(posedge clk or negedge rst_n)
	if(!rst_n)
		cnt = 1;
	else if(cnt < 30)
		cnt = cnt + 1;	


endmodule
