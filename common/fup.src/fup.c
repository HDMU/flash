/**************************************************************************/
/* Name :   fup                                                           */
/*                                                                        */
/* Author:  Schischu, enhanced by Audioniek                               */
/*                                                                        */
/* Licence: This file is subject to the terms and conditions of the       */
/*          GNU General Public License version 2.                         */
/**************************************************************************/
/*
 * Changes in Version 1.8.1:
 * + Fixed two compiler warnings.
 * + Squashfs dummy file now padded with 0xFF in stead of 0x00.
 *
 * Changes in Version 1.8:
 * + If the file dummy.squash.signed.padded does not exist in the
 *   current directory at program start, it is created;
 * + -r option can now change all four reseller ID bytes;
 * + -ce suboptions now have numbered aliases;
 * + On opening a file, the result is tested: no more crashes
 *   on non existent files, but a neat error message;
 * + -n can change version number in IRD;
 * + Silent operation now possible on -x, -s, -n, -c, -r and -ce;
 * + Errors in mtd numbering corrected.
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
//#include <gcrypt.h> /* sha1 / crc32 */
#include <fcntl.h>

#include <zlib.h>

#include "crc16.h"
#include "dummy.h"

#define VERSION "1.8.1"
#define DATE "18.04.2014"

//#define USE_ZLIB

uint16_t blockCounter= 0;
uint16_t blockCounterTotal = 0;
uint16_t have;
char zlibt[10];
uint8_t verbose = 1;
uint16_t partBlocksize;
uint16_t totalBlockCount;
uint16_t headerDataBlockLen;
uint16_t len;
uint16_t crc;
uint16_t type;
uint16_t temp;
int32_t pos;
uint8_t firstBlock;
int32_t i;
uint16_t decLen;
uint8_t appendPartCount;
uint8_t * dataBuf;
uint32_t resellerId;
uint16_t fpVersion;
uint16_t systemId1;
uint16_t systemId2;
uint16_t blockcount1;
uint16_t blockcount2;
uint32_t softwareversion0;
uint16_t softwareversion1;
uint16_t softwareversion2;
uint16_t softwareversion3;
uint16_t blockHeaderPos;
uint16_t nextBlockHeaderPos;
uint16_t compressedDataLen;
uint16_t uncompressedDataLen;
uint8_t * blockHeader;
uint16_t dataCrc;
FILE* file;
FILE* signedFile;
FILE* irdFile;

#define MAX_PART_NUMBER 0x0a
#define EXTENSION_LEN 32

#define PART_SIGN 1
#define PART_FLASH 2

#define DATA_BLOCKSIZE 0x7FFA

#if 0
struct {
uint32_t Id;
char Extension[EXTENSION_LEN];
char Description[EXTENSION_LEN];
uint32_t Offset;
uint32_t Size;
uint32_t Flags;
} tPartition;

# 32MB flash (1st generation models, FS9000, FS9200, HS9510)
(0x00,  ".loader.mtd0",  "Loader", 0x00000000, 0x00300000, (PART_FLASH)),
#(---,     ".appb.mtd9",   "Appb", 0x00600000, 0x00500000, (),
(0x01,     ".app.mtd2",     "App", 0x00b00000, 0x00500000, (PART_FLASH | PART_SIGN)),
(0x02, ".config0.mtd5", "Config0", 0x01b00000, 0x00040000, (PART_FLASH)),
(0x03, ".config4.mtd5", "Config4", 0x01b40000, 0x00040000, (PART_FLASH)),
(0x04, ".config8.mtd5", "Config8", 0x01b80000, 0x00020000, (PART_FLASH)),
(0x05, ".configA.mtd5", "ConfigA", 0x01ba0000, 0x00020000, (PART_FLASH)),
(0x06,  ".kernel.mtd1",  "Kernel", 0x00300000, 0x00300000, (PART_FLASH)),
(0x07,     ".dev.mtd4",     "Dev", 0x01800000, 0x00300000, (PART_FLASH | PART_SIGN)),
(0x08,  ".rootfs.mtd3",    "Root", 0x01000000, 0x00800000, (PART_FLASH | PART_SIGN)),
(0x09,    ".user.mtd6",    "User", 0x01c00000, 0x00400000, (PART_FLASH)),

# 32MB flash (2nd generation models, HS7110, HS7810, loader 5.XX)
(0x00,  ".loader.mtd0",  "Loader", 0x00000000, 0x00300000, (PART_FLASH)),
#(---,     ".appb.mtd9",   "Appb", 0x00600000, 0x00500000, (),
(0x01,     ".app.mtd2",     "App", 0x00b00000, 0x00500000, (PART_FLASH | PART_SIGN)),
(0x02, ".config0.mtd5", "Config0", 0x02100000, 0x00040000, (PART_FLASH)),
(0x03, ".config4.mtd5", "Config4", 0x02140000, 0x00040000, (PART_FLASH)),
(0x04, ".config8.mtd5", "Config8", 0x02180000, 0x00020000, (PART_FLASH)),
(0x05, ".configA.mtd5", "ConfigA", 0x021a0000, 0x00020000, (PART_FLASH)),
(0x06,  ".kernel.mtd1",  "Kernel", 0x00300000, 0x00300000, (PART_FLASH)),
(0x07,     ".dev.mtd4",     "Dev", 0x01e00000, 0x00300000, (PART_FLASH | PART_SIGN)),
(0x08,  ".rootfs.mtd3",    "Root", 0x01000000, 0x00800000, (PART_FLASH | PART_SIGN)),
(0x09,    ".user.mtd6",    "User", 0x01c00000, 0x00400000, (PART_FLASH)),

# 64MB flash (HS8200, loader 5.0X)
(0x00,  ".loader.mtd0",  "Loader", 0x000000000, 0x00030000, (PART_FLASH)),
#(---,    ".appb.mtd9",    "Appb", 0x000400000, 0x00700000, (PART_FLASH | PART_SIGN)),
(0x01,     ".app.mtd2",     "App", 0x000b00000, 0x00700000, (PART_FLASH | PART_SIGN)),
(0x02, ".config0.mtd5", "Config0", 0x002100000, 0x00040000, (PART_FLASH)),
(0x03, ".config4.mtd5", "Config4", 0x002140000, 0x00040000, (PART_FLASH)),
(0x04, ".config8.mtd5", "Config8", 0x002180000, 0x00020000, (PART_FLASH)),
(0x05, ".configA.mtd5", "ConfigA", 0x0021a0000, 0x00020000, (PART_FLASH)),
(0x06,  ".kernel.mtd1",  "Kernel", 0x000100000, 0x00300000, (PART_FLASH)),
(0x07,     ".dev.mtd4",     "Dev", 0x001e00000, 0x00300000, (PART_FLASH | PART_SIGN)),
(0x08,  ".rootfs.mtd3",    "Root", 0x001200000, 0x00C00000, (PART_FLASH | PART_SIGN)),
(0x09,    ".user.mtd6",    "User", 0x002200000, 0x01E00000, (PART_FLASH)),
#                                  0x010000000, 0x40000000   RAM? 

# 64MB flash (HS8200, loader 6.00)
(0x00,  ".loader.mtd0",  "Loader", 0x000000000, 0x00030000, (PART_FLASH)),
(0x01,     ".app.mtd2",     "App", var        , var       , (PART_FLASH | PART_SIGN)),
(0x02, ".config0.mtd5", "Config0", 0x002100000, 0x00040000, (PART_FLASH)),
(0x03, ".config4.mtd5", "Config4", 0x002140000, 0x00040000, (PART_FLASH)),
(0x04, ".config8.mtd5", "Config8", 0x002180000, 0x00020000, (PART_FLASH)),
(0x05, ".configA.mtd5", "ConfigA", 0x0021a0000, 0x00020000, (PART_FLASH)),
#(0x05, ".configC.mtd5", "ConfigC", 0x0021c0000, 0x00040000, (PART_FLASH)),
(0x06,  ".kernel.mtd1",  "Kernel", 0x000600000, var       , (PART_FLASH)),
(0x07,     ".dev.mtd4",     "Dev", var        , var       , (PART_FLASH | PART_SIGN)),
(0x08,  ".rootfs.mtd3",    "Root", var        , var       , (PART_FLASH | PART_SIGN)),
(0x09,    ".user.mtd6",    "User", 0x002200000, 0x01E00000, (PART_FLASH)),
#                                  0x080000000, 0x40000000   RAM? 

# 256MB flash (third generation, HS7119, HS7819..., loader 7.X6 or 7.X7) # to be checked
(0x00, ".loader.mtd0",   "Loader", 0x00000000, 0x00400000, (PART_FLASH)),
(0x01, ".app.mtd2",         "App", 0x00800000, 0x06000000, (PART_FLASH | PART_SIGN)),
(0x02, ".config0.mtd5", "Config0", 0x02100000, 0x00040000, (PART_FLASH)), # not writeable by IRD?
(0x03, ".config4.mtd5", "Config4", 0x02140000, 0x00040000, (PART_FLASH)), # not writeable by IRD?
(0x04, ".config8.mtd5", "Config8", 0x02180000, 0x00020000, (PART_FLASH)), # not writeable by IRD?
(0x05, ".configA.mtd5", "ConfigA", 0x021A0000, 0x00020000, (PART_FLASH)), # not writeable by IRD?
(0x06,  ".kernel.mtd1",  "Kernel", 0x00500000, 0x00300000, (PART_FLASH)),
(0x07,     ".dev.mtd4",   "Devs",  0x00000000, 0x00100000, (PART_FLASH | PART_SIGN)), # not writeable by IRD?
(0x08,  ".rootfs.mtd3",   "Root",  0x???00000, 0x0??00000, (PART_FLASH | PART_SIGN)), # not writeable by IRD?
(0x09,    ".user.mtd6",   "User",  0x???00000, 0x0??00000, (PART_FLASH)),
#endif

uint8_t has[MAX_PART_NUMBER];
FILE* fd[MAX_PART_NUMBER];
char ext[MAX_PART_NUMBER][EXTENSION_LEN] =
{
".loader.mtd0",
".app.mtd2",
".config0.mtd5", //F mtd5 offset 0x00000000
".config4/mdt5", //E mtd5 offset 0x00040000
".config8.mtd5", //E mtd5 offset 0x00080000
".configA.mtd5", //C mtd5 offset 0x000A0000
".kernel.mtd1",
".dev.mtd4",
".rootfs.mtd3",
".user.mtd6",
};

#if 0
void fromint16_t(uint8_t ** int16_tBuf, uint16_t val)
{
  *int16_tBuf[0] = val >> 8;
  *int16_tBuf[1] = val & 0xFF;
}
#endif

uint16_t toShort(uint8_t int16_tBuf[2])
{
   return (uint16_t)(int16_tBuf[1] + (int16_tBuf[0] << 8));
}

uint16_t extractShort(uint8_t dataBuf[], uint16_t pos)
{
   uint8_t int16_tBuf[2];
   memcpy(int16_tBuf, dataBuf + pos, 2);
   return toShort(int16_tBuf);
}

uint16_t readShort(FILE* file)
{
   uint8_t int16_tBuf[2];
   if (fread(int16_tBuf, 1, 2, file) == 2)
      return toShort(int16_tBuf);
   else return 0;
}

int32_t extractAndWrite(FILE* file, uint8_t * buffer, uint16_t len, uint16_t decLen)
{
#ifdef USE_ZLIB
   if (len != decLen)
   {
      //zlib
      z_stream strm;
      uint8_t out[decLen];

      strm.zalloc = Z_NULL;
      strm.zfree = Z_NULL;
      strm.opaque = Z_NULL;
      strm.avail_in = 0;
      strm.next_in = Z_NULL;
      inflateInit(&strm);

      strm.avail_in = len;
      strm.next_in = buffer;

      strm.avail_out = decLen;
      strm.next_out = out;
      inflate(&strm, Z_NO_FLUSH);
      have = decLen - strm.avail_out;

      inflateEnd(&strm);

      fwrite(out, 1, decLen, file);
      if (verbose == 1)
      {
         printf ("z");
      }
      return decLen;
   }
   else 
#endif
   {
      fwrite(buffer, 1, len, file);
      if (verbose == 1)
      {
         printf (".");
      }
      return len;
   }
}

uint16_t readAndCompress(FILE * file, uint8_t ** dataBuf, uint16_t pos, uint16_t * uncompressedDataLen) {

   *uncompressedDataLen = fread((*dataBuf) + pos, 1, *uncompressedDataLen, file);
#ifdef USE_ZLIB
   // So now we have to check if zlib can compress this or not
   z_stream strm;
   uint8_t in[*uncompressedDataLen];
   uint8_t out[*uncompressedDataLen];
   
   strm.zalloc = Z_NULL;
   strm.zfree = Z_NULL;
   strm.opaque = Z_NULL;
   deflateInit(&strm, Z_DEFAULT_COMPRESSION);
   
   strm.avail_in = *uncompressedDataLen;
   memcpy(in, (*dataBuf) + pos, *uncompressedDataLen);
   strm.next_in = in;
   
   have = 0;

   strm.avail_out = *uncompressedDataLen;
   strm.next_out = out + have;

   deflate(&strm, Z_FINISH);
   have = *uncompressedDataLen - strm.avail_out;
   
   deflateEnd(&strm);
   
   if (have < *uncompressedDataLen)
   {
      memcpy((*dataBuf) + pos, out, have);
   } else 
#endif
   {
      have = *uncompressedDataLen;
   }
   if (verbose == 1)
   {
      printf (".");
   }

   if ((*uncompressedDataLen != DATA_BLOCKSIZE) && (verbose == 1)) //Last block of compressed partition was written
   {
      printf("\n"); //Terminate progress bar
   }
   return have;
}

uint16_t insertint16_t(uint8_t ** dataBuf, uint16_t pos, uint16_t value)
{
   (*dataBuf)[pos] = value >> 8;
   (*dataBuf)[pos + 1] = value & 0xFF;
   return 2;
}

uint32_t insertint32_t(uint8_t ** dataBuf, uint16_t pos, uint32_t value)
{
   (*dataBuf)[pos] = value >> 24;
   (*dataBuf)[pos + 1] = value >> 16;
   (*dataBuf)[pos + 2] = value >> 8;
   (*dataBuf)[pos + 3] = value & 0xFF;
   return 2;
}

int32_t writeBlock(FILE* irdFile, FILE* file, uint8_t firstBlock, uint16_t type)
{
   blockHeaderPos = 0;
   nextBlockHeaderPos = 0;
   compressedDataLen = 0;
   uncompressedDataLen = DATA_BLOCKSIZE;
   dataCrc = 0;

   uint8_t * blockHeader = (uint8_t *)malloc(4);
   uint8_t * dataBuf = (uint8_t *)malloc(DATA_BLOCKSIZE + 4);
   
   if (firstBlock && type == 0x10)
   { // header
      resellerId = 0x230200A0; //Octagon SF1028P Noblence L6.00
      
      insertint16_t(&dataBuf, 0, type);
      insertint32_t(&dataBuf, 2, resellerId);
      insertint16_t(&dataBuf, 6, 0);
      insertint16_t(&dataBuf, 8, 0xFFFF);
      insertint16_t(&dataBuf, 10, 0);
      insertint16_t(&dataBuf, 12, 0); //version 1
      insertint16_t(&dataBuf, 14, 0); //version 2
      compressedDataLen = 12;
      uncompressedDataLen = compressedDataLen;
   }
   else
   {
      compressedDataLen = readAndCompress(file, &dataBuf, 4, &uncompressedDataLen);
      insertint16_t(&dataBuf, 0, type);
      insertint16_t(&dataBuf, 2, uncompressedDataLen);
   }
   
   dataCrc = crc16(dataCrc, dataBuf, compressedDataLen + 4);
   
   insertint16_t(&blockHeader, 0, compressedDataLen + 6);
   insertint16_t(&blockHeader, 2, dataCrc);
   fwrite(blockHeader, 1, 4, irdFile);
   fwrite(dataBuf, 1, compressedDataLen + 4, irdFile);
   
   free(blockHeader);
   free(dataBuf);
   
   return uncompressedDataLen;
}

int32_t readBlock(FILE* file, const char * name, uint8_t firstBlock)
{
   len = 0;
   crc = 0;
   type = 0;
   
   len = readShort(file);
   if (len == 0) return 0;
   crc = readShort(file);

   uint8_t dataBuf[len - 2];
   if (fread(dataBuf, 1, len - 2, file) != len - 2)
   {
      return 0;
   }   
   dataCrc = 0;
   dataCrc = crc16(dataCrc, dataBuf, len - 2);

   type = extractShort(dataBuf, 0);

   if (crc != dataCrc)
   {
      printf("\nCRC data error occurred in block #%d (type %d)!\n", blockCounter, type);
      getchar();
   }
   
   type = extractShort(dataBuf, 0);
   
   blockCounterTotal++;
   
   if (firstBlock && type == 0x10)
   {
      if (verbose == 1)
      {
         printf("-> header\n");
      }

      fpVersion = extractShort(dataBuf, 0);
      systemId1 = extractShort(dataBuf, 2);
      systemId2 = extractShort(dataBuf, 4);

      blockcount1 = extractShort(dataBuf, 6);
      blockcount2 = extractShort(dataBuf, 8);

      softwareversion1 = extractShort(dataBuf, 10);
      softwareversion2 = extractShort(dataBuf, 12);
      softwareversion3 = extractShort(dataBuf, 14);
         
      if (verbose == 1)
      {
         printf("\n Header data:\n");
         printf("  fpVersion       : %04X\n", fpVersion);
         printf("  Reseller ID     : %04X%04X\n", systemId1, systemId2);
         printf("  Blockcount      : %d (%04X%04X) blocks\n", (blockcount1*256+blockcount2), blockcount1, blockcount2);
         printf("  SoftwareVersion : V%X.%02X.%02X", softwareversion2, softwareversion3>>8, softwareversion3&0xFF);
      }
   }
   else
   {
      if (type < MAX_PART_NUMBER)
      {
         if (!has[type])
         {
            blockCounter = 1;
            has[type] = 1;
            if (verbose == 1)
            {
               printf ("\nNew partition, type %02X ", type);
               if (type==0x00)
                  printf ("-> Loader (mtd0)");
               if (type==0x01)
                  printf ("-> Application (mtd2, squashfs)");
               if (type==0x02)
                  printf ("-> Config0 (mtd5, offset 0x00000)");
               if (type==0x03)
                  printf ("-> Config4 (mtd5, offset 0x40000)");
               if (type==0x04)
                  printf ("-> Config8 (mtd5, offset 0x80000)");
               if (type==0x05)
                  printf ("-> ConfigA (mtd5, offset 0xA0000)");
               if (type==0x06)
                  printf ("-> Kernel (mtd1)");
               if (type==0x07)
                  printf ("-> Dev (mtd4, squashfs)");
               if (type==0x08)
                  printf ("-> Rootfs (mtd3, squashfs)");
               if (type==0x09)
                  printf ("-> User data (mtd6)");
               printf("\n");
            }
            char nameOut[strlen(name) + 1 + strlen(ext[type])];
            strncpy(nameOut, name, strlen(name));
            strncpy(nameOut + strlen(name), ext[type], strlen(ext[type]));
            nameOut[strlen(name) + strlen(ext[type])] = '\0';
            fd[type] = fopen(nameOut, "wb");
            if (verbose == 1)
            {
               printf("\n-> %s\n", nameOut);
            }
         }

         decLen = extractShort(dataBuf, 2);
         extractAndWrite(fd[type], dataBuf + 4, len -6, decLen);
      }
      else
      {
         printf("\nIllegal partition type %04X found, quitting...\n", type);
         //getchar();
         return 0;
      }
   }
   return len;
}

int32_t main(int32_t argc, char* argv[])
{ 
   pos = 0;
   firstBlock = 1;
      
// Check if the file dummy.squash.signed.padded exists. If not, create it
   file = fopen("dummy.squash.signed.padded", "rb");
   if (file == NULL)
   {
      if (verbose == 1)
      {
         printf("\nSigned dummy squashfs headerfile does not exist.\n");
        printf("Creating it...");
      }
      file = fopen("dummy.squash.signed.padded", "w");
      if (verbose == 1)
      {
         printf(".");
      }
      fwrite(dummy, 1, dummy_size, file);
      if (verbose == 1)
      {
         printf(".");
      }
      if (verbose == 1)
      {
         fclose(file);
      }
      printf(".");
      file = fopen("dummy.squash.signed.padded", "rb");
      printf(".");
      if (file != NULL)
      {
         printf("\n\nCreating signed dummy squashfs header file successfully completed.\n");
      }
      else
      {
         printf("\nCould not write signed dummy squashfs header file.\n");
         remove("dummy.squash.signed.padded");
      }
   }

   if ((argc == 3 && strlen(argv[1]) == 2 && strncmp(argv[1], "-s", 2) == 0)
      || (argc == 3 && strlen(argv[1]) == 3 && strncmp(argv[1], "-sv", 3) == 0)) // sign squashfs part
   {

      if (strncmp(argv[1], "-sv", 3) == 0)
      {
          verbose = 1;
      }
      else
      {
         verbose = 0;
      }

      uint32_t crc = 0;
      char signedFileName[128];
      strcpy(signedFileName, argv[2]);
      strcat(signedFileName, ".signed");
      
      signedFile = fopen(signedFileName, "wb");
      file = fopen(argv[2], "r");
      if (file==NULL)
      {
         printf("Error while opening input file %s\n", argv[2]);
         return -1;
      }
      
      if (signedFile==NULL)
      {
         printf("Error while opening output file %s\n", argv[3]);
         return -1;
      }
      uint8_t buffer[10000];
      while (!feof(file))
      {
         int32_t count = fread(buffer, 1, 10000, file); //Actually it would be enough to fseek and only to read q byte.
         fwrite(buffer, 1, count, signedFile);
         crc = crc32(crc, buffer, 1);
      }
   
      if (verbose == 1)
      {
         printf("Signature in footer: 0x%8x\n", crc);
         printf("Output file name is: %s\n", signedFileName);
      }
      fwrite(&crc, 1, 4, signedFile);
      
      fclose(file);
      fclose(signedFile);
   }
   else if (argc == 3 && strlen(argv[1]) == 2 && strncmp(argv[1], "-t", 2) == 0) // test signed squashfs part
   {
      uint32_t crc = 0;
      uint32_t orgcrc = 0;
      file = fopen(argv[2], "r");
      if (file==NULL)
      {
         printf("Error while opening input file %s\n", argv[2]);
         return -1;
      }

      uint8_t buffer[10000];
      while (!feof(file))
      { // Actually we would need to remove the sign at the end
         int32_t count = fread(buffer, 1, 10000, file);
         if (count != 10000)
         {
             orgcrc = (buffer[count - 1] << 24) + (buffer[count - 2] << 16) + (buffer[count - 3] << 8) + (buffer[count - 4]);
         }
         crc = crc32(crc, buffer, 1);
      }
   
      if (verbose == 1)
      {
         printf("Signed footer: 0x%8x\n", crc);
         printf("Original Signed footer: 0x%8x\n", orgcrc);
      }
      else
      {
         if ( crc != orgcrc )
         {
            printf("Signature is wrong, correct signature: 0x%8x, signature found: 0x%8x.\n", crc, orgcrc);
         }
      }
      fclose(file);
   }
   else if ((argc == 3 && strlen(argv[1]) == 2 && strncmp(argv[1], "-x", 2) == 0)
         || (argc == 3 && strlen(argv[1]) == 3 && strncmp(argv[1], "-xv", 3) == 0)) //extract IRD into composing parts
   {
      if (strncmp(argv[1], "-xv", 3) == 0)
      {
          verbose = 1;
      }
      else
      {
         verbose = 0;
      }

      for (i = 0; i < MAX_PART_NUMBER; i++)
      {
         has[i] = 0;
         fd[i] = NULL;
      }
      
      file = fopen(argv[2], "r");
      if (file==NULL)
      {
         printf("Error while opening input file %s\n", argv[2]);
         return -1;
      }
      
      while (!feof(file))
      {
         pos = ftell(file);
         len = readBlock(file, argv[2], firstBlock);
         firstBlock = 0;
         if (len > 0)
         {
            pos += len + 2;
            fseek(file, pos, SEEK_SET);
         }
         else
         {
//            printf("\n");
            break;
            //getchar();
         }
      }
      fclose(file);
      
      for(i = 0; i < MAX_PART_NUMBER; i++)
      {
          if (fd[i] != NULL)
          {
             fclose(fd[i]);
          }
      }
      if (verbose == 1)
      {
         printf("\n");
      }
      verbose = 1;
   }
   else if (argc == 2 && strlen(argv[1]) == 2 && strncmp(argv[1], "-v", 2) == 0) // print version info
   {
      printf("Version: %s Date: %s\n", VERSION, DATE);
   }
   else if (argc >= 3 && strlen(argv[1]) == 2 && strncmp(argv[1], "-c", 2) == 0) // create Fortis IRD
   {
      verbose = 0;
      irdFile = fopen(argv[2], "wb+");
      if (irdFile==NULL)
      {
         printf("Error while opening output file %s\n", argv[2]);
         return -1;
      }
      
      totalBlockCount = 0;
      headerDataBlockLen = 0;
      
      // Header
      headerDataBlockLen = writeBlock(irdFile, NULL, 1, 0x10);
      headerDataBlockLen+=4;
      
      appendPartCount = argc - 3;
      //search for -v
      for (i=0; i < appendPartCount; i+=2)
      {
         if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-v", 2)) == 0)
         {
            verbose = 1;
         }
      }
      //evaluate other options
      for (i=0; i < appendPartCount; i+=2)
      {
         type = 0x99;
         
         if (strlen(argv[3 + i]) == 3 && (strncmp(argv[3 + i], "-ll", 3) && strncmp(argv[3 + i], "-00", 3)) == 0)
         {
            type = 0x00;
         }
         else if (strlen(argv[3 + i]) == 13 && (strncmp(argv[3 + i], "-feelinglucky", 13)) == 0)
         {
            type = 0x00;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-a", 2) && strncmp(argv[3 + i], "-1", 2)) == 0)
         {
            type = 0x01;
         }
         else if (strlen(argv[3 + i]) == 3 && (strncmp(argv[3 + i], "-c0", 3)) == 0)
         {
            type = 0x02;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-2", 2)) == 0)
         {
            type = 0x02;
         }
         else if (strlen(argv[3 + i]) == 3 && (strncmp(argv[3 + i], "-c4", 3)) == 0)
         {
            type = 0x03;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-3", 2)) == 0)
         {
            type = 0x03;
         }
         else if (strlen(argv[3 + i]) == 3 && (strncmp(argv[3 + i], "-c8", 3)) == 0)
         {
            type = 0x04;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-4", 2)) == 0)
         {
            type = 0x04;
         }
         else if (strlen(argv[3 + i]) == 3 && (strncmp(argv[3 + i], "-ca", 3)) == 0)
         {
            type = 0x05;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-5", 2)) == 0)
         {
            type = 0x05;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-k", 2) && strncmp(argv[3 + i], "-6", 2)) == 0)
         {
            type = 0x06;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-d", 2) && strncmp(argv[3 + i], "-7", 2)) == 0)
         {
            type = 0x07;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-r", 2) && strncmp(argv[3 + i], "-8", 2)) == 0)
         {
            type = 0x08;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-u", 2) && strncmp(argv[3 + i], "-9", 2)) == 0)
         {
            type = 0x09;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-v", 2)) == 0)
         {
            type = 0x88; //flag verbose found
            i-=1;
         }

         if (type == 0x99)
         {
            printf("Unknown suboption %s.\n", argv[3+i]);
            fclose(irdFile);
            irdFile = fopen(argv[2], "rb");
            if (irdFile != NULL)
            {
               fclose (irdFile);
               remove(argv[2]);
            }
            return -1;
         }
         if (type != 0x88)
         {
            file = fopen(argv[3 + i + 1], "rb");
            if (file==NULL)
            {
               printf("Error opening input file %s\n", argv[3+i+1]);
               return -1;
            }

            if (verbose == 1)
            {
               printf("Adding type %d block, file: %s\n", type, argv[3 + i + 1]);
            }
            partBlocksize = totalBlockCount;
            while (writeBlock(irdFile, file, 0, type) == DATA_BLOCKSIZE)
            {
               totalBlockCount++;
               if (verbose == 1)
               {
                  printf(".");
               }
            }
            totalBlockCount++;
            partBlocksize = totalBlockCount - partBlocksize;
            if (verbose == 1)
            {
               printf("Added %d blocks, total is now %d blocks\n", partBlocksize, totalBlockCount);
            }
            fclose(file);
         }
      }
      
      // Refresh Header
      uint8_t * dataBuf = (uint8_t *)malloc(headerDataBlockLen);
      
      // Read Header Data Block
      fseek(irdFile, 0x04, SEEK_SET);
      fread(dataBuf, 1, headerDataBlockLen, irdFile);
      
      // Update Blockcount
      insertint16_t(&dataBuf, 8, totalBlockCount);
      
      // Rewrite Header Data Block
      fseek(irdFile, 0x04, SEEK_SET);
      fwrite(dataBuf, 1, headerDataBlockLen, irdFile);
      
      // Update CRC
      dataCrc = crc16(0, dataBuf, headerDataBlockLen);
      insertint16_t(&dataBuf, 0, dataCrc);
      
      // Rewrite CRC
      fseek(irdFile, 0x02, SEEK_SET);
      fwrite(dataBuf, 1, 2, irdFile);
      
      free(dataBuf);
      fclose(irdFile);

      if (verbose == 1)
      {
         printf("Creating IRD file %s succesfully completed.\n", argv[2]);
      }
      verbose = 1;
   }
   else if (argc >= 3 && strlen(argv[1]) == 3 && strncmp(argv[1], "-ce", 3) == 0) // Create Enigma2 IRD
   {
      verbose = 0;
      irdFile = fopen(argv[2], "w+");
      if (irdFile==NULL)
      {
         printf("Error while opening output file %s\n", argv[2]);
         return -1;
      }

      totalBlockCount = 0;
      headerDataBlockLen = 0;
      
      // Header
      headerDataBlockLen = writeBlock(irdFile, NULL, 1, 0x10);
      headerDataBlockLen+=4;
      
      appendPartCount = argc - 3;
      //search for -v
      for (i=0; i < appendPartCount; i+=2)
      {
        if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-v", 2)) == 0)
         {
            verbose = 1;
         }
      }
      for (i=0; i < appendPartCount; i+=2)
      {
         type = 0x99;
         
         if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-f", 2) && strncmp(argv[3 + i], "-1", 2) == 0))
         { // Original APP now FW
            type = 0x01;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-k", 2) && strncmp(argv[3 + i], "-6", 2)) == 0)
         { // KERNEL
            type = 0x06;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-e", 2) && strncmp(argv[3 + i], "-8", 2)) == 0)
         { //Original ROOT now EXT
            type = 0x08;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-g", 2) && strncmp(argv[3 + i], "-7", 2)) == 0)
         { //Original DEV now G
            type = 0x07;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-r", 2) && strncmp(argv[3 + i], "-9", 2)) == 0)
         { //Original USER now ROOT
            type = 0x09;
         }
         else if (strlen(argv[3 + i]) == 2 && (strncmp(argv[3 + i], "-v", 2)) == 0)
         {
            type = 0x88; //flag verbose found
            i-=1;
         }
         
         if (type==0x99)
         {
            printf("Unknown suboption %s.\n", argv[3+i]);
            fclose(irdFile);
            irdFile = fopen(argv[2], "rb");
            if (irdFile != NULL)
            {
               fclose (irdFile);
               remove(argv[2]);
            }
            return -1;
         }
         if (type != 0x88)
         {
            if (verbose == 1)
            {
               printf("\nNew partition, type %02X\n", type);
            }
            if (type == 0x01 || type == 0x08 || type== 0x07) // these must be signed squashfs
            {
               if (verbose == 1)
               {
                  printf("Adding signed dummy squashfs header");
               }
               file = fopen("dummy.squash.signed.padded", "rb");
               if (verbose == 1)
               {
                  printf(".");
               }
               if (file != NULL)
               {
                  while (writeBlock(irdFile, file, 0, type) == DATA_BLOCKSIZE)
                  {
                     if (verbose == 1)
                     {
                        printf(".");
                     }
                     totalBlockCount++;
                  }
                  totalBlockCount++;
                  fclose(file);
               }
               else
               {
                  printf("\nCould not read signed dummy squashfs header file.\n");
                  remove("dummy.squash.signed.padded");
               }
            }
         
            if (strncmp(argv[3 + i + 1], "foo", 3) != 0)
            {
               file = fopen(argv[3 + i + 1], "rb");
               if (file != NULL)
               {
                  if (verbose == 1)
                  {
                     printf("Adding type %d block, file: %s\n", type, argv[3 + i + 1]);
                  }
                  partBlocksize = totalBlockCount;
                  while (writeBlock(irdFile, file, 0, type) == DATA_BLOCKSIZE)
                  {
                     totalBlockCount++;
                     if (verbose == 1)
                     {
                        printf(".");
                     }
                  }
                  totalBlockCount++;
                  partBlocksize = totalBlockCount - partBlocksize;

                  if (verbose == 1)
                  {
                    printf("\nAdded %d blocks, total is now %d blocks\n", partBlocksize, totalBlockCount);
                  }
                  fclose(file);
               }
               else
               {
                  printf("\nCould not append input file %s\n", argv[3 + i + 1]);
                  printf("\n");
               }
            }
            else
            {
               if (verbose == 1)
               {
                  printf("This is a foo partition\n");
               }
            }
         }
      }
      
      // Refresh Header
      uint8_t * dataBuf = (uint8_t *)malloc(headerDataBlockLen);
      
      // Read Header Data Block
      fseek(irdFile, 0x04, SEEK_SET);
      fread(dataBuf, 1, headerDataBlockLen, irdFile);
      
      // Update Blockcount
      insertint16_t(&dataBuf, 8, totalBlockCount);
      
      // Rewrite Header Data Block
      fseek(irdFile, 0x04, SEEK_SET);
      fwrite(dataBuf, 1, headerDataBlockLen, irdFile);
      
      // Update CRC
      dataCrc = crc16(0, dataBuf, headerDataBlockLen);
      insertint16_t(&dataBuf, 0, dataCrc);
      
      // Rewrite CRC
      fseek(irdFile, 0x02, SEEK_SET);
      fwrite(dataBuf, 1, 2, irdFile);
      
      free(dataBuf);
      
      fclose(irdFile);
      if (verbose == 1)
      {
         printf("Output file name is: %s\n", argv[2]);
      }
      verbose = 1;
   }
   else if ((argc == 4 && strlen(argv[1]) == 2 && strncmp(argv[1], "-r", 2) == 0)
      || (argc == 4 && strlen(argv[1]) == 3 && strncmp(argv[1], "-rv", 3) == 0)) // Change reseller ID
   {
      if (strncmp(argv[1], "-rv", 3) == 0)
      {
          verbose = 1;
      }
      else
      {
         verbose = 0;
      }

      headerDataBlockLen = 0;
      resellerId = 0;
      
      if (strlen(argv[3]) != 4 && strlen(argv[3]) != 8)
      {
         printf("Reseller ID must be 4 or 8 characters long.\n");
         return -1;
      }

      sscanf(argv[3], "%X", &resellerId);

      if (strlen(argv[3]) == 4)
      {
         resellerId = resellerId * 0x10000;
      }
      
      irdFile = fopen(argv[2], "r+");
      if (irdFile == NULL)
      {
         printf("Error while opening IRD file %s\n", argv[2]);
         return -1;
      }

      headerDataBlockLen = readShort(irdFile);
      headerDataBlockLen -= 2;
      
      if (verbose == 1)
      {
         printf("Changing reseller ID in file %s to %04X.\n", argv[2], resellerId);
      }
      
      /// Refresh Header
      uint8_t * dataBuf = (uint8_t *)malloc(headerDataBlockLen);
      
      // Read Header Data Block
      fseek(irdFile, 0x04, SEEK_SET);
      fread(dataBuf, 1, headerDataBlockLen, irdFile);
      
      // Update Reseller ID
      insertint32_t(&dataBuf, 2, resellerId);
      
      // Rewrite Header Data Block
      fseek(irdFile, 0x04, SEEK_SET);
      fwrite(dataBuf, 1, headerDataBlockLen, irdFile);
      
      // Update CRC
      dataCrc = crc16(0, dataBuf, headerDataBlockLen);
      insertint16_t(&dataBuf, 0, dataCrc);
      
      // Rewrite CRC
      fseek(irdFile, 0x02, SEEK_SET);
      fwrite(dataBuf, 1, 2, irdFile);
      
      free(dataBuf);
      
      fclose(irdFile);
   }
   else if ((argc == 4 && strlen(argv[1]) == 2 && strncmp(argv[1], "-n", 2) == 0)
      || (argc == 4 && strlen(argv[1]) == 3 && strncmp(argv[1], "-nv", 3) == 0)) // Change SW version number
   {
      if (strncmp(argv[1], "-nv", 3) == 0)
      {
          verbose = 1;
      }
      else
      {
         verbose = 0;
      }

      headerDataBlockLen = 0;
      resellerId = 0;
      
      sscanf(argv[3], "%x", &softwareversion0);
      softwareversion2 = softwareversion0 & 0x0000FFFF;  //Split the entire long version number into two words
      softwareversion1 = softwareversion0 >> 16;

      irdFile = fopen(argv[2], "r+");
      if (irdFile == NULL)
      {
         printf("Error while opening IRD file %s\n", argv[2]);
         return -1;
      }

      headerDataBlockLen = readShort(irdFile);
      headerDataBlockLen -= 2;
      
      if (verbose == 1)
      {
         printf("Changing SW version number in file %s to %04x.\n", argv[2], resellerId);
      }
      
      /// Refresh Header
      uint8_t * dataBuf = (uint8_t *)malloc(headerDataBlockLen);
      
      // Read Header Data Block
      fseek(irdFile, 0x04, SEEK_SET);
      fread(dataBuf, 1, headerDataBlockLen, irdFile);
      
      resellerId = extractShort(dataBuf, 12);	   //Get SW version hi from file
      temp = extractShort(dataBuf, 14);    //Get SW version lo from file
      if (verbose == 1)
      {
         printf("Current Software version number is V%X.%02X.%02X\n", resellerId&0xFFFF, temp>>8, temp&0xFF);
         printf("Changing Software version number to V%X.%02X.%02X\n", softwareversion1&0xFFFF, softwareversion2>>8, softwareversion2&0xFF);
      }

      // Update Software version number
      insertint16_t(&dataBuf, 12, (softwareversion1&0xFFFF));
      insertint16_t(&dataBuf, 14, (softwareversion2&0xFFFF));

      // Rewrite Header Data Block
      fseek(irdFile, 0x04, SEEK_SET);
      fwrite(dataBuf, 1, headerDataBlockLen, irdFile);

      // Update CRC
      dataCrc = crc16(0, dataBuf, headerDataBlockLen);
      insertint16_t(&dataBuf, 0, dataCrc);

      // Rewrite CRC
      fseek(irdFile, 0x02, SEEK_SET);
      fwrite(dataBuf, 1, 2, irdFile);

      free(dataBuf);

      fclose(irdFile);
   }
   else //show usage
   {
#ifdef USE_ZLIB
      strcpy(zlibt, "yes");
#else
      strcpy(zlibt, "no ");
#endif
      printf("\n");
      printf("Version: %s Date: %s\nUse ZLIB: %s\n", VERSION, DATE, zlibt);
      printf("\n");
      printf("Usage: %s -xcstrnv []\n", argv[0]);
      printf("       -x [update.ird]            Extract IRD\n");
      printf("       -xv [update.ird]           As -x, verbose\n");
      printf("       -c [update.ird] Options    Create Fortis IRD\n");
      printf("         Options for -c:\n");
      printf("          -ll [file.part]          Append Loader   (0) -> mtd0\n");
      printf("          -k  [file.part]          Append Kernel   (6) -> mtd1\n");
      //printf(" *        -ao [file.part]          Append App low  (*) -> mtd7\n");
      printf(" s        -a  [file.part]          Append App      (1) -> mtd2\n");
      printf(" s        -r  [file.part]          Append Root     (8) -> mtd3\n");
      printf(" s        -d  [file.part]          Append Dev      (7) -> mdt4\n");
      printf("          -c0 [file.part]          Append Config0  (2) -> mtd5, offset 0\n");
      printf("          -c4 [file.part]          Append Config4  (3) -> mtd5, offset 0x40000\n");
      printf("          -c8 [file.part]          Append Config8  (4) -> mtd5, offset 0x80000\n");
      printf("          -ca [file.part]          Append ConfigA  (5) -> mtd5, offset 0xA0000\n");
      //printf(" *        -cc [file.part]         Append ConfigC  (*)\n");
      printf("          -u  [file.part]          Append User     (9) -> mtd6\n");
      printf("          -00 [file.part]          Append Type 0   (0) (alias for -ll)\n");
      printf("          -1  [file.part]          Append Type 1   (1) (alias for -a)\n");
      printf("          ...\n");
      printf("          -9  [file.part]          Append Type 9   (9) (alias for -u)\n");
      printf("          -v                       Verbose operation\n");
      printf("       -ce [update.ird] Options   Create Enigma2 IRD\n");
      printf("         Options for -ce:                              HS8200 L6.00 memory layout\n");
      printf("          -k|-6 [file.part]        Append Kernel   (6) 0x00600000 + length\n");
      printf("          -f|-1 [file.part]        Append FW       (1)\n");
      printf("          -r|-9 [file.part]        Append Root     (9) 0x02200000 - 0x03FFFFFF (30 MB)\n");
      printf("          -e|-8 [file.part]        Append Ext      (8)\n");
      printf("          -g|-7 [file.part]        Append G        (7)\n");
      printf("          -v                       Verbose operation\n");
      printf("       -s [unsigned.squashfs]     Sign squashfs part\n");
      printf("       -sv [unsigned.squashfs]    Sign squashfs part, verbose\n");
      printf("       -t [signed.squashfs]       Test signed squashfs part\n");
      printf("       -r [update.ird] id         Change reseller id (e.g. 230300A0 for Atevio AV7500 L6.00)\n");
      printf("       -rv [update.ird] id        As -r, verbose\n");
      printf("       -n [update.ird] versionnr  Change SW version number\n");
      printf("       -nv [update.ird] versionnr As -n, verbose\n");
      printf("       -v                         Display program version\n");
      printf("\n");
      printf("Note: To create squashfs part, use mksquashfs v3.3:\n");
      printf("      ./mksquashfs3.3 squashfs-root flash.rootfs.own.mtd8 -nopad -le\n");
      printf("\n");
      printf("Examples:\n");
      printf("  Creating a new Fortis IRD file with rootfs and kernel:\n");
      printf("   %s -c my.ird [-v] -r flash.rootfs.own.mtd8.signed -k uimage.mtd6\n", argv[0]);
      printf("\n");
      printf("  Extracting a IRD file:\n");
      printf("   %s -x[v] my.ird\n", argv[0]);
      printf("\n");
      printf("  Signing a squashfs partition:\n");
      printf("   %s -s[v] my.squashfs\n", argv[0]);
      return -1;
   }

   return 0;
}
