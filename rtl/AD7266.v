/***************************************************
*	Module Name		:	AD7266		   
*	Engineer		   :	deamonyang
*	Tool versions	:	Quartus II 13.0
*	Create Date		:	2018-10-10
*	Revision		   :	v1.0
*	Description		:  ADC AD7266 驱动 
*							当ADC时钟为32MHz 采样率为2MSPS
****************************************************/
module AD7266(
	SCLK		,
	CS_N		,
	RANGE		,
	SGL_DIFN	,
	A0			,
	A1			,
	A2			,
	DOUTA		,
	DOUTB		,
	
	AD_GO		,
	AD_DONE	,
	DATAA		,
	DATAB		,
	rst_n		,
	clk
	
	);

	
	/*ADC 端口信号*/
	output wire SCLK		;
	output reg CS_N		;
	output RANGE	;
	output SGL_DIFN;
	output A0		;
	output A1		;
	output A2		;
	input	DOUTA		;
	input	DOUTB		;
	input AD_GO		;		//ADC开始转换
	output reg AD_DONE	;		//ADC转换完毕
	output reg[15:0]DATAA;//ADC数据口A
	output reg[15:0]DATAB;//ADC数据口B
	input rst_n		;
	input clk		;
	
	reg[4:0]cnt;
	reg[15:0]r_data_a;
	reg[15:0]r_data_b;
	reg smp;
	
	assign SCLK = clk;
	assign RANGE = 1'b0;// 1 -- xREF  0 -- x2REF	
	assign SGL_DIFN = 1'b1; //SINGLE
	
	/*  010  CH3-GND */
	assign A0 = 1'b0;		
	assign A1 = 1'b1;		
	assign A2 = 1'b0;		
	
	
	
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
		cnt <= 5'd0;
	else if((AD_GO == 1'b1)&(cnt < 5'd15))
		cnt <= cnt + 1'b1;
	else 
		cnt <= 5'd0;

	/*片选型号产生*/
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
		CS_N <= 1'b1;
	else if((cnt >= 5'd0)&(cnt <= 5'd13)&AD_GO)
		CS_N <= 1'b0;
	else
		CS_N <= 1'b1;
		
	/*读取数据 A B通道同时读取*/
	always@(posedge clk or negedge rst_n)
	if(!rst_n)begin
		r_data_a <= 16'd0;
		r_data_b <= 16'd1;
		smp <= 1'b0;
	end else if((cnt >= 5'd2) & cnt <= 5'd13)begin
		r_data_a <= {r_data_a[14:0],DOUTA}; //移位寄存器存储转化的数据
		r_data_b <= {r_data_b[14:0],DOUTB};
		smp <= 1'b1;
	end else
		smp <= 1'b0;
	
	/*数据输出*/
	always@(posedge clk or negedge rst_n)
	if(!rst_n)begin
		AD_DONE <= 1'd0;
		DATAA <= 16'd0;
		DATAB <= 16'd0;
	end else if(cnt == 6'd14)begin
		DATAA <= {4'd0,r_data_a[11:0]};
		DATAB <= {4'd0,r_data_b[11:0]};
		AD_DONE <= 1'b1;
	end else
		AD_DONE <= 1'b0;

endmodule


