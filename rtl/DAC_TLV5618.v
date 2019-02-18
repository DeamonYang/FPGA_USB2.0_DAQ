module DAC_TLV5618(
	rst_n,
	clk,
	
	data,
	chsl,
	dac_go,
	dac_done,
	/*DAC  相关*/
	tlv_sclk,
	tlv_din,
	tlv_cs
	);

	input rst_n;
	input clk;			/*参考时钟*/
	input chsl;			/*通道选择 0  为DACB  1 为 DACA*/
	input [15:0]data;
	input dac_go;
	output reg dac_done;
	output wire tlv_sclk;
	output reg tlv_din;   
	output reg tlv_cs;  
	
	reg [7:0]cnt;
	reg cnt_en;
	reg [11:0]r_data;
	
	assign tlv_sclk = clk;
	/*计数允许*/
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
		cnt_en <= 1'b0;
	else if(dac_go)
		cnt_en <= 1'b1;
	else if(dac_done)
		cnt_en <= 1'b0;
	
	/*输出完毕提示信号*/
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
		dac_done <= 1'b0;
	else if(cnt == 7'hf)
		dac_done <= 1'b1;
	else 
		dac_done <= 1'b0;	
	
	/*序列机计数器*/
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
		cnt <= 1'b0;
	else if(cnt_en)
		cnt <= cnt + 1'b1;
	else 
		cnt <= 1'b0;	
	
	
	/*线性序列机*/
	always@(posedge clk or negedge rst_n)
	if(!rst_n)begin
		tlv_din <= 1'd0; 
		tlv_cs <= 1'd1;
		r_data <= 12'd0;
	end else
		case(cnt)
			0 :begin
					tlv_cs <= 1'd1;
			end
			
			/*开始转换*/
			1 :begin
					tlv_cs <= 1'd0;
					tlv_din <= chsl;
					r_data <= data[11:0];
			end
			
			2 : tlv_din <= 1'd1;//高速模式
			3 : tlv_din <= 1'd0;//正常模式
			4 : tlv_din <= 1'd0;//正常模式
			
			5,6,7,8,9,10,11,12,13,14,15,16:begin
			
				if((r_data << (cnt-5))&12'b1000_0000_0000)
					tlv_din <= 1'd1;
				else
					tlv_din <= 1'd0;
			end
			
			17:
				tlv_cs <= 1'd1;
			default:begin
				tlv_cs <= 1'd1;
			
			end
		
		endcase
			
endmodule

