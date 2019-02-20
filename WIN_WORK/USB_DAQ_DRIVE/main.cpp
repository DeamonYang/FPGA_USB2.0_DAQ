#include <windows.h>
#include <time.h>
#include <stdio.h>
#include "usb_daq_drv.h"




int main(int argc, char* argv[])
{
	int res = 0;
	int data_len = 0;
	char dataBuf[127*2*8];
	short *pd;
	res = UsbDaqOpen();
	if (res != 0)
	{
		printf("open error\r\n");
	}
	else
	{
		printf("open success\r\n");
	}

	while (1)
	{
		/*更新缓冲区数据*/
		res = readDataUpdate();

		if (res != 0)
		{
			printf("read error\r\n");
			exit(0);
		}


		/*一次读取所有通道数据*/
		res = readAllChData1278(dataBuf);
		pd = (short*)dataBuf;
		for (int i = 0; i < 8; i++)
		{
			printf("%2.3f ",10.0*(pd[i]+1)/32768); 
		}
		printf("\r\n");



		/*依次读取8个通道数据*/
		short temp;
		for (int i = 0; i < 8; i++)
		{
			res = readOneChData127((short*)dataBuf, i);
			pd = (short*)dataBuf;
			printf("%2.3f ", 10.0*(pd[0]) / 32768);
		}

		printf("\r\n");
		
	}

}