#include <windows.h>
#include "ftd2xx.h"
#pragma comment(lib, "FTD2XX.lib")
#include "FTD2XX.h"
#include "usb_daq_drv.h"


#define CK_LEN 16
#define OneSector	2048

const short header_g[CK_LEN / 2] = { 0x55AA, 0x55AA, 0x55AA, 0x55AA, 0x55AA, 0x55AA, 0x55AA, 0x55AA };

FT_HANDLE ftHandle = NULL;
static char tempBuf[OneSector];


/*查找数据同步帧头*/
static int findHeader(char * dataBuf)
{
	FT_STATUS ftStatus;
	DWORD BytesReceived;
	char data;
	int res;
	int ck_cnt = 1;
	char ck_ch;
	/*一次读取数据直到帧头匹配*/
	while (1)
	{
		/*阻塞至读取指定长度数据*/
		ftStatus = FT_Read(ftHandle, &data, 1, &BytesReceived);
		if (ftStatus != FT_OK)
		{
			return -2;

		}

		ck_ch = ck_cnt % 2;
		if (ck_ch == 1 && data == -86)
		{
			ck_cnt++;
		}
		else if ((ck_ch == 0) && (data == 0x55))
		{
			ck_cnt++;
		}
		else
		{
			ck_cnt = 1;
		}

		if (ck_cnt == CK_LEN + 1)
		{
			break; //已经查询到第一字节
		}
	}

	/*匹配后读取缓冲区数据*/
	ftStatus = FT_Read(ftHandle, (dataBuf + CK_LEN), OneSector - CK_LEN, &BytesReceived);

	return 0;
}

/*检查是否为数据同步帧头*/
static int checkHeader(char data[])
{
	int res = 0;
	res = memcmp(data, header_g, CK_LEN);
	return res;
}

/*处理数据同步帧头*/
static int dealHeader(char *data)
{
	int res = 0;

	res = checkHeader(data);

	if (res != 0)
	{
		findHeader(data);
	}

	return 1;
}

/*打开USB数据采集卡*/
int UsbDaqOpen(void)
{
	FT_STATUS ftStatus;
	UCHAR Mask = 0xff;
	UCHAR Mode;
	UCHAR LatencyTimer = 3; //our default setting is 16
	ftStatus = FT_Open(0, &ftHandle);
	if (ftStatus != FT_OK)
	{
		return -1;
	}
	Mode = 0x00; //reset mode   
	ftStatus = FT_SetBitMode(ftHandle, Mask, Mode);
	Mode = 0x40; //Sync FIFO mode
	ftStatus = FT_SetBitMode(ftHandle, Mask, Mode);
	if (ftStatus == FT_OK)
	{
		ftStatus = FT_SetLatencyTimer(ftHandle, LatencyTimer);
		ftStatus = FT_SetUSBParameters(ftHandle, 0x10000, 0x10000);
		ftStatus = FT_SetFlowControl(ftHandle, FT_FLOW_RTS_CTS, 0, 0);
	}
	else
	{
		return -1;
	}

	return 0;
}



static int readOneSector(char *data_buf)
{
	FT_STATUS ftStatus;
	DWORD BytesReceived;

	/*阻塞至读取指定长度数据*/
	ftStatus = FT_Read(ftHandle, data_buf, OneSector, &BytesReceived);
	if (ftStatus != FT_OK)
	{
		return -2;
	}
	return BytesReceived;
}


int readDataUpdate(void)
{
	FT_STATUS ftStatus;
	DWORD BytesReceived;

	int res;
	res = readOneSector(tempBuf);
	if (res != OneSector)
	{
		return -1;
	}

	dealHeader(tempBuf);

	return 0;
}



int readAllChData1278(char *data_buf)
{

	memcpy(data_buf, (const void*)(tempBuf + CK_LEN), OneSector - CK_LEN);

	return OneSector - CK_LEN;
}

/*******************************************************
*名称：读取一个通道的数据 每次固定读取127个点 共254Byte
*参数：data_buf 数据缓冲区地址 chNum 通道号 0-7
*返回值：res<0 读取错误； res > 0 为读取的数据长度
*****************************************************/
int readOneChData127(short *data_buf, char chNum)
{
	int i;
	short* sour = (short*)tempBuf;
	if (chNum < 0 || chNum > 7)
	{
		return -1;
	}

	for (i = 0; i < (OneSector - CK_LEN) / 16; i++)
	{
		data_buf[i] = sour[i * 8 + chNum + 8];
	}
	return 127;
}

