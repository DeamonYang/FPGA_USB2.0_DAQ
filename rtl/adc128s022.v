/***************************************************
*	Module Name		:	adc128s022		   
*	Engineer		   :	小梅哥
*	Target Device	:	EP4CE10F17C8
*	Tool versions	:	Quartus II 13.0
*	Create Date		:	2017-3-31
*	Revision		   :	v1.0
*	Description		:  ADC adc128s022驱动设计
**************************************************/

module adc128s022(
			Clk,
			Rst_n,
			
			Channel,
			Data,
			
			En_Conv,
			Conv_Done,
			ADC_State,
			DIV_PARAM,
			
			ADC_SCLK,
			ADC_DOUT,
			ADC_DIN,
			ADC_CS_N	
		);

	input Clk;	//输入时钟
	input Rst_n; //复位输入，低电平复位
	input [2:0]Channel;	//ADC转换通道选择
	output reg [11:0]Data;	//ADC转换结果
	
	input En_Conv;	//使能单次转换，该信号为单周期有效，高脉冲使能一次转换
	output reg Conv_Done;	//转换完成信号，完成转换后产生一个时钟周期的高脉冲
	output ADC_State;	//ADC工作状态，ADC处于转换时为低电平，空闲时为高电平
	input [7:0]DIV_PARAM;	//时钟分频设置，实际SCLK时钟 频率 = fclk / （DIV_PARAM * 2）
	
	output reg ADC_SCLK;	//ADC 串行数据接口时钟信号
	output reg ADC_CS_N;  //ADC 串行数据接口使能信号
	input  ADC_DOUT;		//ADC转换结果，由ADC输给FPGA
	output reg ADC_DIN;	//ADC控制信号输出，由FPGA发送通道控制字给ADC
	
	reg [2:0]r_Channel; //通道选择内部寄存器
	reg [11:0]r_data;	//转换结果读取内部寄存器
	
	reg [7:0]DIV_CNT;//分频计数器
	reg SCLK2X;//2倍SCLK的采样时钟
	
	reg [5:0]SCLK_GEN_CNT;//SCLK生成暨序列机计数器

	
	reg en;//转换使能信号
	
	//在每个使能转换的时候，寄存Channel的值，防止在转换过程中该值发生变化
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		r_Channel <= 3'd0;
	else if(En_Conv)
		r_Channel <= Channel;
	else
		r_Channel <= r_Channel;

	//产生使能转换信号
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		en  <= 1'b0;
	else if(En_Conv)
		en  <= 1'b1;
	else if(Conv_Done)
		en  <= 1'b0;
	else
		en  <= en;
		
	//生成2倍SCLK使能时钟计数器
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		DIV_CNT  <= 8'd0;
	else if(en)begin
		if(DIV_CNT == (DIV_PARAM - 1'b1))
			DIV_CNT  <= 8'd0;
		else 
			DIV_CNT  <= DIV_CNT + 1'b1;
	end else	
		DIV_CNT  <= 8'd0;

	//生成2倍SCLK使能时钟
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		SCLK2X  <= 1'b0;
	else if(en && (DIV_CNT == (DIV_PARAM - 1'b1)))
		SCLK2X  <= 1'b1;
	else
		SCLK2X  <= 1'b0;
		
	//生成序列计数器
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		SCLK_GEN_CNT  <= 6'd0;
	else if(SCLK2X && en)begin
		if(SCLK_GEN_CNT == 6'd33)
			SCLK_GEN_CNT  <= 6'd0;
		else
			SCLK_GEN_CNT  <= SCLK_GEN_CNT + 1'd1;
	end else
		SCLK_GEN_CNT  <= SCLK_GEN_CNT;
	
	//序列机实现ADC串行数据接口的数据发送和接收	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)begin
		ADC_SCLK <= 1'b1;
		ADC_CS_N <= 1'b1;
		ADC_DIN  <= 1'b1;
	end else if(en) begin
		if(SCLK2X)begin
			case(SCLK_GEN_CNT)
				6'd0:begin ADC_CS_N <= 1'b0; end
				6'd1:begin ADC_SCLK <= 1'b0; ADC_DIN  <= 1'b0; end
				6'd2:begin ADC_SCLK <= 1'b1; end
				6'd3:begin ADC_SCLK <= 1'b0; end
				6'd4:begin ADC_SCLK <= 1'b1; end
				6'd5:begin ADC_SCLK <= 1'b0; ADC_DIN  <= r_Channel[2];end	//addr[2]
				6'd6:begin ADC_SCLK <= 1'b1; end
				6'd7:begin ADC_SCLK <= 1'b0; ADC_DIN  <= r_Channel[1];end	//addr[1]
				6'd8:begin ADC_SCLK <= 1'b1; end
				6'd9:begin ADC_SCLK <= 1'b0; ADC_DIN  <= r_Channel[0];end	//addr[0]

				//每个上升沿，寄存ADC串行数据输出线上的转换结果
				6'd10,6'd12,6'd14,6'd16,6'd18,6'd20,6'd22,6'd24,6'd26,6'd28,6'd30,6'd32:
					begin ADC_SCLK <= 1'b1; r_data <= {r_data[10:0], ADC_DOUT}; end	//循环移位寄存DOUT上的12个数据
				
				6'd11,6'd13,6'd15,6'd17,6'd19,6'd21,6'd23,6'd25,6'd27,6'd29,6'd31:
					begin ADC_SCLK <= 1'b0; end
				
				6'd33:begin ADC_CS_N <= 1'b1; end
				default:begin ADC_CS_N <= 1'b1; end //将转换结果输出
			endcase
		end
		else ;
	end else begin
		ADC_CS_N <= 1'b1;
	end
	
	//转换完成时，将转换结果输出到Data端口，同时产生一个时钟周期的高脉冲信号
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)begin
		Data <= 12'd0; 
		Conv_Done <= 1'b0;
	end else if(en && SCLK2X && (SCLK_GEN_CNT == 6'd33))begin
		Data <= r_data; 
		Conv_Done <= 1'b1;
	end else begin
		Data <= Data; 
		Conv_Done <= 1'b0;
	end
	
	//产生ADC工作状态指示信号
	assign ADC_State = ADC_CS_N;

endmodule
