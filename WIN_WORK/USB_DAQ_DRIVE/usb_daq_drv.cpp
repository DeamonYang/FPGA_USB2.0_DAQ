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


/*��������ͬ��֡ͷ*/
static int findHeader(char * dataBuf)
{
	FT_STATUS ftStatus;
	DWORD BytesReceived;
	char data;
	int res;
	int ck_cnt = 1;
	char ck_ch;
	/*һ�ζ�ȡ����ֱ��֡ͷƥ��*/
	while (1)
	{
		/*��������ȡָ����������*/
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
			break; //�Ѿ���ѯ����һ�ֽ�
		}
	}

	/*ƥ����ȡ����������*/
	ftStatus = FT_Read(ftHandle, (dataBuf + CK_LEN), OneSector - CK_LEN, &BytesReceived);

	return 0;
}

/*����Ƿ�Ϊ����ͬ��֡ͷ*/
static int checkHeader(char data[])
{
	int res = 0;
	res = memcmp(data, header_g, CK_LEN);
	return res;
}

/*��������ͬ��֡ͷ*/
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

/*��USB���ݲɼ���*/
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

	/*��������ȡָ����������*/
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
*���ƣ���ȡһ��ͨ�������� ÿ�ι̶���ȡ127���� ��254Byte
*������data_buf ���ݻ�������ַ chNum ͨ���� 0-7
*����ֵ��res<0 ��ȡ���� res > 0 Ϊ��ȡ�����ݳ���
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

