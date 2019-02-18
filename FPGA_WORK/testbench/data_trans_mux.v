/*数据为每个缓冲区64k*/
module data_trans_mux(
	ad7266dataa	,
	ad7266datab	,
	ad7266sdclk	,
	ad7266wren	,
	usbdata		,
	usbdadd		,
	usbdataclk	,
	send_go		,
	rst_n
	);
	
	input[15:0]ad7266dataa;
	input[15:0]ad7266datab;
	input ad7266sdclk;
	input ad7266wren;
	
	output[7:0] usbdata;
	input[10:0]usbdadd;
	input usbdataclk;
	input rst_n;
	output reg send_go;//当缓冲区填满 send_en 置1 只到这个缓冲区数据读取完
	reg rd_sw_flag;
	
	reg[9:0]ad7266add;
	reg rd_buf_ch; //读取数据的BUF切换 0-A  1-B
	reg wr_buf_ch; //写数据的BUF切换 0-A  1-B
	reg ram_full;	//缓冲区数据满
	wire [7:0]usbdata_cha;//存储A通道数据输出
	wire [7:0]usbdata_chb;//存储A通道数据输出
	wire ad7266wren_cha;//存储A通道数据输入
	wire ad7266wren_chb;//存储B通道数据输入
	
	
	localparam [10:0]ad7266data_len = 10'd1023;
	localparam [11:0]usbdatard_len = 12'd2047;
	
	/*通道数据读取完毕*/
	always@(posedge usbdataclk or negedge rst_n)
	if(!rst_n)
		rd_sw_flag <= 1'b0;
	else if(usbdadd == usbdatard_len)
		rd_sw_flag <= 1'b1;
	else
		rd_sw_flag <= 1'b0;
	
	
	/*AD7266 数据地址产生 用于存储数据的RAM地址*/
	always@(posedge ad7266sdclk or negedge rst_n)
	if(!rst_n)
		ad7266add <= 10'd0;
	else if(ad7266wren == 1'b1)
		ad7266add <= ad7266add + 1'b1;
		
	
	/*开始默认先写通道A数据*/
	always@(posedge ad7266sdclk or negedge rst_n)
	if(!rst_n)
		wr_buf_ch <= 1'b0;
	else if(ad7266add == ad7266data_len && ad7266wren == 1'b1)
		wr_buf_ch = ~wr_buf_ch;//切换为下一个通道

	/*开始默认先读通道B数据*/
	always@(posedge usbdataclk or negedge rst_n)
	if(!rst_n)
		rd_buf_ch <= 1'b0;
	else if(rd_sw_flag)
		rd_buf_ch <= ~rd_buf_ch;
		
	/* 控制中 使用的 ad7266sdclk 为36MHz  为慢时钟 当数据满 输出标志 持续一个ad7266sdclk时钟*/
	always@(posedge ad7266sdclk or negedge rst_n)
	if(!rst_n)
		ram_full <= 1'b0;
	else if(ad7266add == ad7266data_len - 1'b1)
		ram_full <= 1'b1;
	else
		ram_full <= 1'b0;
		
	
	/*双RAM 乒乓操作 */
	
	/*A 通道数据*/
	rambuf ad7266bufA(
		.data			(ad7266dataa),
		.rdaddress	(usbdadd),
		.rdclock		(usbdataclk),
		.wraddress	(ad7266add),
		.wrclock		(ad7266sdclk),
		.wren			(ad7266wren_cha),
		.q				(usbdata_cha)
		);
	/*B 通道数据*/
	rambuf ad7266bufB(
		.data			(ad7266dataa),
		.rdaddress	(usbdadd),
		.rdclock		(usbdataclk),
		.wraddress	(ad7266add),
		.wrclock		(ad7266sdclk),
		.wren			(ad7266wren_chb),
		.q				(usbdata_chb)
		);
	
	/*输出数据有效*/
	always@(posedge usbdataclk or negedge rst_n)
	if(!rst_n)
		send_go <= 1'b0;
	else if(ram_full)
		send_go <= 1'b1;
	else //if(usbdadd == usbdatard_len)
		send_go <= 1'b0;
	
	/*数据输出选择器 when rd_buf_ch==1 output usbdata_chb */
	assign usbdata = rd_buf_ch?usbdata_chb:usbdata_cha;
	
	/*数据输入选择器*/
	assign ad7266wren_cha = (wr_buf_ch)?1'b0:ad7266wren;
	
	assign ad7266wren_chb = (wr_buf_ch)?ad7266wren:1'b0;
		
endmodule
