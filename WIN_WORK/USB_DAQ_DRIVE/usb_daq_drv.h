#ifndef _USB_DAQ_DRV_H_
#define _USB_DAQ_DRV_H_

/*******************************************************
*名称：读取一个通道的数据 每次固定读取127个点 共254Byte
*参数：data_buf 数据缓冲区地址 chNum 通道号 0-7
*返回值：res<0 读取错误； res > 0 为读取的数据长度
*注意：不会更新缓冲区即不会从USB端口读取数据
*****************************************************/
int readOneChData127(short *data_buf, char chNum);

/****************************************************************
*名称：读取一个通道的数据 每次固定读取127个点 共254Byte
*参数：data_buf 数据缓冲区地址 
*返回值：res<0 读取错误； res > 0 为读取的数据长度
*注意：不会更新缓冲区即不会从USB端口读取数据
*		数据的排列顺序为 CH0 CH1 ... CH7 每组数据位宽16bits
****************************************************************/
int readAllChData1278(char *data_buf);

/*******************************************************
*名称：更新本地缓冲区
*参数：无
*返回值：0 操作成功  其他 操作失败
*注意：此操作会从USB端口读取数据
*****************************************************/
int readDataUpdate(void);

/*******************************************************
*名称：打开USB数据采集卡
*参数：无
*返回值：0 操作成功  其他 操作失败
*****************************************************/
int UsbDaqOpen(void);



#endif


