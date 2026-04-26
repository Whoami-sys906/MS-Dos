#ifndef TYPES_H
#define TYPES_H

typedef unsigned char  uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int   uint32_t;
typedef signed char    int8_t;
typedef signed short   int16_t;
typedef signed int     int32_t;

typedef enum { false = 0, true = 1 } bool;

#define NULL ((void*)0)

typedef struct {
    uint16_t offset;
    uint16_t segment;
} __attribute__((packed)) seg_offset_t;

#endif
