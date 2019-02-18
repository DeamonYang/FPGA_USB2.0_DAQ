// I2CTEST.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

#include <windows.h>
#include "ftd2xx.h"
#include <time.h>
#pragma comment(lib, "FTD2XX.lib")
#include "FTD2XX.h"

#define OneSector 2048
#define NUM		  10240
#define tot_len 104857600	//256*4*1024*100 = 100M
long err_times = 0;


long check_error(unsigned char *pd, long len)
{
	long i = 0;
	unsigned char data = 0;
	long err_cnt = 0;
	for (i = 0; i < len - 1; i++)
	{
		data = pd[i];
		data += 1;
		if (data != pd[i + 1])
		{
			err_cnt++;
			printf("%02x  %02x| ", pd[i], pd[i+1]);
		
		}
			
	}
	
	if (err_cnt != 0)
	{
		printf("\r\n\r\n");
		system("pause");
	}
		
	
	return err_cnt;
}
  
int _tmain(int argc, _TCHAR* argv[])
{
	FT_HANDLE ftHandle;
	FT_STATUS ftStatus;
	UCHAR Mask = 0xff;
	UCHAR Mode;
	UCHAR LatencyTimer = 3; //our default setting is 16

	DWORD BytesReceived;
	unsigned char RxBuffer[OneSector];
	//	unsigned char data_base[tot_len];
	int i;
	long ti = 0;
	//unsigned short *pdata = (unsigned short *)RxBuffer;
	unsigned char *pd = (unsigned char *)malloc(OneSector*NUM);
	long tot_len_data = 0;
	long long err_num_cnt = 0;
	if (pd == NULL)
		printf("malloc error\r\n");

	ftStatus = FT_Open(0, &ftHandle);
	if (ftStatus != FT_OK)
	{
		// FT_Open failed return;
	}
	Mode = 0x00; //reset mode   
	ftStatus = FT_SetBitMode(ftHandle, Mask, Mode);
	Mode = 0x40; //Sync FIFO mode
	ftStatus = FT_SetBitMode(ftHandle, Mask, Mode);
	if (ftStatus == FT_OK)
	{
		printf("open ft232 success\r\n");
		ftStatus = FT_SetLatencyTimer(ftHandle, LatencyTimer);
		ftStatus = FT_SetUSBParameters(ftHandle, 0x10000, 0x10000);
//		ftStatus = FT_SetUSBParameters(ftHandle, OneSector, OneSector);
		ftStatus = FT_SetFlowControl(ftHandle, FT_FLOW_RTS_CTS, 0, 0);
		//access data from here
		clock_t start = clock();
		clock_t end;
		float time;
		char dis_str[100];


		while (1)
		{


			ftStatus = FT_Read(ftHandle, RxBuffer, OneSector, &BytesReceived);
			if (ftStatus == FT_OK)
			{



				for (i = 0; i < 16; i++)
				{
					if (i % 16 == 0)
					{
						printf("\r\n");
					}

					//if (RxBuffer[i] == 0x55 || RxBuffer[i] == 0xAA)
					//{
					//	printf("*");
					//}
					//else
					{
						printf("%02x ", RxBuffer[i]);
					}
					
				}
			}
			else
			{
				printf("xx", ftStatus);
				exit(0);
			}
		}















		while (1)
		{
			while (1)
			{
				
				
				ftStatus = FT_Read(ftHandle, RxBuffer, OneSector, &BytesReceived);
				if (ftStatus == FT_OK)
				{

//					printf("%04x \r\n", (unsigned short)(RxBuffer[1] << 8 | RxBuffer[0]));
					//for (i = 0; i < 16*32; i++)
					//{
					//	printf("%02x ", (unsigned char )RxBuffer[i] );
					//	if (i % 32 == 0)
					//	{
					//		printf("\r\n");
					//	}
					//} 


					for (i = 0; i < 16 ; i ++)
					{
//						printf("%04x ", (RxBuffer[i+1] << 8 | RxBuffer[i]));
						if (i % 16== 0)
						{
							printf("\r\n");
						}
						printf("%02x ",  RxBuffer[i]);
					}


					//for (i = 0; i < 16; i++)
					//{
					//	itoa(RxBuffer[i], dis_str, 2);
					//	printf("%s\r\n", dis_str);
					//	//printf("%04x ", (RxBuffer[i] << 8 | RxBuffer[i+1]));
					//	//if (i % 32 == 0)
					//	//{
					//	//	printf("\r\n");
					//	//}
					//}



					//printf("\r\n\r\n");

//					printf(".");
					//if (BytesReceived != OneSector)
					//{
					//	printf("real len %d",OneSector);
					//}


					//memcpy(&pd[ti*OneSector], RxBuffer, OneSector);
					//ti++;
					//if (ti == NUM)
					//{
					//	//Sleep(10);
					//	ti = 0;
					//	//					printf("x");
					//	end = clock();
					//	time = (float)(end - start) / CLOCKS_PER_SEC;
					//	printf("speed %f M/s ", NUM*OneSector / (1024 * 1024) / time);
					//	
					//break;
					//}
				}
				else
				{
					printf("xx", ftStatus);
					exit(0);
				}



			}



#define SEL


#ifdef SEL 

			for (i = 0; i < OneSector*NUM - 16; i = i + 16)
			{
				if ((pd[i] & 0x0F) != (pd[i + 16] & 0x0F))
				{
					printf("raw %d\r\n", i);
					err_times++;
					for (int j = 0; j < 16 * 2; j++)
					{
						printf("%02x ", (unsigned char)pd[i + j]);
						if (j % 16 == 15)
							printf("\r\n");

					}

					printf("\r\n\r\n");

				}
			}
#else 
			for (i = 0; i < OneSector*NUM - 1; i ++)
			{
				printf("%02x ", (unsigned char)pd[i]);
				if (i % 16 == 15)
					printf("\r\n");
			}
#endif


			err_num_cnt += check_error(pd, OneSector*NUM);
			
			tot_len_data = tot_len_data + (OneSector*NUM/1024/1024);

			printf("tot %d Mbyte(s) err %d byte(s)   \r\n", tot_len_data,err_num_cnt );



			start = clock();




		}




	}
	else
	{
		printf("open ft232 error\r\n");
	}
	FT_Close(ftHandle);
	free(pd);
}




//long check_error(unsigned char *pd, long len)
//{
//	long i;
//	unsigned char data;
//	long err_cnt;
//	for (i = 0; i < len-1; i++)
//	{
//		data = pd[i];
//		data += 1;
//		if (data != pd[i + 1])
//			err_cnt++;
//	}
//
//	return err_cnt;
//}









