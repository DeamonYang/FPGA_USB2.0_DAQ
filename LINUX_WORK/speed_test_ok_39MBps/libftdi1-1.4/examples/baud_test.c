/* baud_test.c
 *
 * test setting the baudrate and compare it with the expected runtime
 *
 * options:
 *  -p <devicestring> defaults to "i:0x0403:0x6001" (this is the first FT232R with default id)
 *       d:<devicenode> path of bus and device-node (e.g. "003/001") within usb device tree (usually at /proc/bus/usb/)
 *       i:<vendor>:<product> first device with given vendor and product id,
 *                            ids can be decimal, octal (preceded by "0") or hex (preceded by "0x")
 *       i:<vendor>:<product>:<index> as above with index being the number of the device (starting with 0)
 *                            if there are more than one
 *       s:<vendor>:<product>:<serial> first device with given vendor id, product id and serial string
 *  -d <datasize to send in bytes>
 *  -b <baudrate> (divides by 16 if bitbang as taken from the ftdi datasheets)
 *  -m <mode to use> r: serial a: async bitbang s:sync bitbang
 *  -c <chunksize>
 *
 * (C) 2009 by Gerd v. Egidy <gerd.von.egidy@intra2net.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <ftdi.h>

#define ONE_SEC 1024
#define BUF_NUM	10240
#define TOT_LEN (1024*1024)

double get_prec_time()
{
    struct timeval tv;
    double res;

    gettimeofday(&tv,NULL);

    res=tv.tv_sec;
    res+=((double)tv.tv_usec/1000000);

    return res;
}

int main(int argc, char **argv)
{
    struct ftdi_context *ftdi;
    int i, t;
    unsigned char *txbuf;
    unsigned char *rxbuf;
    double start, duration, plan;
    int retval= 0;

    // default values
    int baud=9600;
    int set_baud;
    int datasize=ONE_SEC*BUF_NUM;

    char default_devicedesc[] = "i:0x0403:0x6014";
    char *devicedesc=default_devicedesc;
    int txchunksize=256;
	int rxchunksize = TOT_LEN;
    enum ftdi_mpsse_mode test_mode=BITMODE_BITBANG;
	int sendsize= ONE_SEC;


	test_mode=BITMODE_SYNCBB;
	
    txbuf=malloc(txchunksize);
	
	
    rxbuf=malloc(rxchunksize);
    if (txbuf == NULL || rxbuf == NULL)
    {
        fprintf(stderr, "can't malloc\n");
        return EXIT_FAILURE;
    }

    if ((ftdi = ftdi_new()) == 0)
    {
        fprintf(stderr, "ftdi_new failed\n");
        retval = EXIT_FAILURE;
        goto done;
    }

    if (ftdi_usb_open_string(ftdi, devicedesc) < 0)
    {
        fprintf(stderr,"Can't open ftdi device: %s\n",ftdi_get_error_string(ftdi));
        retval = EXIT_FAILURE;
        goto do_deinit;
    }
	
	/*设置波特率*/
    if (ftdi_set_baudrate(ftdi, 960000) < 0)
    {
        fprintf(stderr,"Can't set mode: %s\n",ftdi_get_error_string(ftdi));
        retval = EXIT_FAILURE;
        goto do_close;
    }
	
	
	
	

	/*设置为同步模式*/
    if (ftdi_set_bitmode(ftdi, 0xFF,BITMODE_SYNCFF ) < 0)
    {
        fprintf(stderr,"Can't set mode: %s\n",ftdi_get_error_string(ftdi));
        retval = EXIT_FAILURE;
        goto do_close;
    }else
	{
		printf("set sync ok\r\n");
		
	}


	if( ftdi_setflowctrl(ftdi, SIO_RTS_CTS_HS) < 0)
	{
        fprintf(stderr,"Can't set ftdi_setflowctrl: %s\n",ftdi_get_error_string(ftdi));
        retval = EXIT_FAILURE;
        goto do_close;		
		
	}else
	{
		printf("set ftdi_setflowctrl ok\r\n");
		
	}
	
    // completely clear the receive buffer before beginning
 //   while (ftdi_read_data(ftdi, rxbuf, txchunksize)>0);

	printf("start read\r\n");
	
    start=get_prec_time();

    // don't wait for more data to arrive, take what we get and keep on sending
    // yes, we really would like to have libusb 1.0+ with async read/write...
    ftdi->usb_read_timeout=3;
	
	if( ftdi_read_data_set_chunksize(ftdi,1024*16) < 0)
	{
        fprintf(stderr,"Can't set ftdi_read_data_set_chunksize: %s\n",ftdi_get_error_string(ftdi));
        retval = EXIT_FAILURE;
        goto do_close;		
	}
	
    i=0;
	
	
	
	
	int test_num = 0;
	
	
	while(1)
	{
		while(test_num < 4)
		{
			test_num ++;
			
			i=0;
			sendsize = 10240;
			while (i < datasize)
			{
				
				
				
				   
				if (i+sendsize > datasize)
					sendsize=datasize-i;
				
				i+=sendsize;


				
				if (ftdi_read_data(ftdi, rxbuf, sendsize) < 0)
				{
					printf("ftdi_read_data over time \r\n");
					goto do_close;
				}
				
			}
		
		}
		duration=get_prec_time()-start;
		start=get_prec_time();
		printf("and took %.4f seconds, this is %.0f MB/s \n",duration,(TOT_LEN*4)/duration/(1024*1024));
		test_num = 0;
	}
	
	
	
do_close:
    ftdi_usb_close(ftdi);
do_deinit:
    ftdi_free(ftdi);
done:
    if(rxbuf)
        free(rxbuf);
    if(txbuf)
        free(txbuf);
    exit (retval);
}
