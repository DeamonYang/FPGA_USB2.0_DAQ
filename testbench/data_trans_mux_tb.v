`timescale 1ns/1ns
module data_trans_mux_tb;

	reg[15:0]ad7266dataa;
	reg[15:0]ad7266datab;
	reg ad7266sdclk;
	reg ad7266wren;
	reg[14:0]usbdadd;
	reg usbdataclk;
	reg rst_n;
	wire send_go;//当缓冲区填满 send_en 置1 只到这个缓冲区数据读取完
	wire usbdata;
	reg send_en;

	reg[4:0]adc_cnt;

	
//	assign ad7266dataa = {1'b0,usbdadd};
//	assign ad7266datab = {1'b0,usbdadd};

 data_trans_mux mux(
	.ad7266dataa(ad7266dataa),
	.ad7266datab(ad7266datab),
	.ad7266sdclk(ad7266sdclk),
	.ad7266wren	(ad7266wren	),
	.usbdata	(usbdata	),
	.usbdadd	(usbdadd	),
	.usbdataclk	(usbdataclk	),
	.send_go	(send_go	),
	.rst_n      (rst_n      )
	);

	initial begin
		ad7266sdclk = 0;
		usbdataclk = 0;
		rst_n = 0;
		#2000;
		rst_n = 1;
	
		#40000000;
		$stop;
	end

	always #17 usbdataclk = ~usbdataclk;
	
	always #28 ad7266sdclk = ~ad7266sdclk;
	
	
	always @(posedge ad7266sdclk or negedge rst_n)
	if(!rst_n)
		adc_cnt <= 5'd0;
	else if(adc_cnt < 5'd15)
		adc_cnt <= adc_cnt + 1'b1;
	else
		adc_cnt <= 5'd0;
	
	always @(posedge ad7266sdclk or negedge rst_n)
	if(!rst_n)
		ad7266wren <= 1'b0;
	else if(adc_cnt == 5'd15)
		ad7266wren <= 1'b1;
	else
		ad7266wren <= 1'b0;
		
		
	always @(posedge ad7266sdclk or negedge rst_n)
	if(!rst_n)begin
		ad7266dataa <= 1'b0;
		ad7266datab <= 1'b0;
	end else if(adc_cnt == 5'd15)begin
		ad7266dataa <= ad7266dataa + 1'b1;
		ad7266datab <= ad7266datab + 1'b1;
	end 
		
	
	always@(posedge usbdataclk or negedge rst_n)
	if(!rst_n)
		usbdadd <= 15'd0;
	else if(send_en)
		usbdadd <= usbdadd + 1'b1;
	
	always@(posedge usbdataclk or negedge rst_n)
	if(!rst_n)
		send_en <= 1'd0;
	else if(send_go)
		send_en <= 1'b1;
	else if(usbdadd == 15'd32767-1'b1)
		send_en <= 15'd0;


endmodule

