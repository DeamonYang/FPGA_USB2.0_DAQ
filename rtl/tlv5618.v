/***************************************************
*	Module Name		:	tlv5618		   
*	Engineer		   :	小梅哥
*	Target Device	:	EP4CE10F17C8
*	Tool versions	:	Quartus II 13.0
*	Create Date		:	2017-06-25
*	Revision		   :	v1.1
*	Description		:  TLV5618 DAC驱动
**************************************************/

`timescale 1ns/1ns

module tlv5618(
	Clk,
	Rst_n,
	
	DAC_DATA,
	Start,
	Set_Done,
	
	CS_N,
	DIN,
	SCLK,
	DAC_State
);
	
	parameter fCLK = 50;
	parameter DIV_PARAM = 2;

	input Clk;
	input Rst_n;
	input [15:0]DAC_DATA;
	input Start;
	output reg Set_Done;
	
	output reg CS_N;
	output reg DIN;
	output reg SCLK;
	output DAC_State;
	
	assign DAC_State = CS_N;
	
	reg [15:0]r_DAC_DATA;
	
	reg [3:0]DIV_CNT;//分频计数器
	reg SCLK2X;//2倍SCLK的采样时钟
	
	reg [5:0]SCLK_GEN_CNT;//SCLK生成暨序列机计数器
	
	reg en;//转换使能信号
	
	wire trans_done; //转换序列完成标志信号
	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		en  <= #1  1'b0;
	else if(Start)
		en  <= #1  1'b1;
	else if(trans_done)
		en  <= #1  1'b0;
	else
		en  <= #1  en;

	//生成2倍SCLK使能时钟计数器
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		DIV_CNT  <= #1  4'd0;
	else if(en)begin
		if(DIV_CNT == (DIV_PARAM - 1'b1))
			DIV_CNT  <= #1  4'd0;
		else 
			DIV_CNT  <= #1  DIV_CNT + 1'b1;
	end else	
		DIV_CNT  <= #1  4'd0;

	//生成2倍SCLK使能时钟计数器
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		SCLK2X  <= #1  1'b0;
	else if(en && (DIV_CNT == (DIV_PARAM - 1'b1)))
		SCLK2X  <= #1  1'b1;
	else
		SCLK2X  <= #1  1'b0;
		
	//生成序列计数器
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		SCLK_GEN_CNT  <= #1  6'd0;
	else if(SCLK2X && en)begin
		if(SCLK_GEN_CNT == 6'd33)
			SCLK_GEN_CNT  <= #1  6'd0;
		else
			SCLK_GEN_CNT  <= #1  SCLK_GEN_CNT + 1'd1;
	end else
		SCLK_GEN_CNT  <= #1  SCLK_GEN_CNT;

	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		r_DAC_DATA  <= #1  16'd0;
	else if(Start)//收到开始发送命令时，寄存DAC_DATA值	
		r_DAC_DATA  <= #1  DAC_DATA;
	else
		r_DAC_DATA  <= #1  r_DAC_DATA;
				
	//依次将数据移出到DAC芯片		
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)begin
		DIN  <= #1  1'b1;
		SCLK  <= #1  1'b0;
		CS_N <= #1 1'b1;
	end else if(!Set_Done && SCLK2X) begin
		case(SCLK_GEN_CNT)
			0:
				begin
					CS_N <= #1 1'b0;
					DIN  <= #1 r_DAC_DATA[15];
					SCLK  <= #1  1'b1;
				end
		
			1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31:
				begin
					SCLK  <= #1  1'b0;
				end
			
			2:  begin DIN  <= #1 r_DAC_DATA[14]; SCLK  <= #1 1'b1; end
			4:  begin DIN  <= #1 r_DAC_DATA[13]; SCLK  <= #1 1'b1; end
			6:  begin DIN  <= #1 r_DAC_DATA[12]; SCLK  <= #1 1'b1; end
			8:  begin DIN  <= #1 r_DAC_DATA[11]; SCLK  <= #1 1'b1; end			
			10: begin DIN  <= #1 r_DAC_DATA[10]; SCLK  <= #1 1'b1; end
			12: begin DIN  <= #1 r_DAC_DATA[9];  SCLK  <= #1 1'b1; end
			14: begin DIN  <= #1 r_DAC_DATA[8];  SCLK  <= #1 1'b1; end
			16: begin DIN  <= #1 r_DAC_DATA[7];  SCLK  <= #1 1'b1; end	
			18: begin DIN  <= #1 r_DAC_DATA[6];  SCLK  <= #1 1'b1; end
			20: begin DIN  <= #1 r_DAC_DATA[5];  SCLK  <= #1 1'b1; end				
			22: begin DIN  <= #1 r_DAC_DATA[4];  SCLK  <= #1 1'b1; end
			24: begin DIN  <= #1 r_DAC_DATA[3];  SCLK  <= #1 1'b1; end
			26: begin DIN  <= #1 r_DAC_DATA[2];  SCLK  <= #1 1'b1; end
			28: begin DIN  <= #1 r_DAC_DATA[1];  SCLK  <= #1 1'b1; end			
			30: begin DIN  <= #1 r_DAC_DATA[0];  SCLK  <= #1 1'b1; end
			
			32: SCLK  <= #1 1'b1; 
			33: CS_N  <= #1 1'b1;
			default:;
		endcase
	end
	
	assign trans_done = (SCLK_GEN_CNT == 33) && SCLK2X;
	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		Set_Done <= 1'b0;
	else if(trans_done)
		Set_Done <= 1'b1;
	else
		Set_Done <= 1'b0;
	
endmodule
