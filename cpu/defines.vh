`ifndef DEFINES_H
`define DEFINES_H

`define RESET 0
`define RUN 1

`define NONE 0
`define ADD 1
`define SUB 2
`define AND 3
`define XOR 4
`define XNOR 5
`define OR 6
`define REM 7
`define LSHIFT 8
`define ARSHIFT 9
`define LRSHIFT 10
`define MUL 11
`define DIV 12
`define SUBU 13
`define DIVU 14
`define REMU 15

`define MACHINE 2'b11
`define SUPERV 2'b01
`define USER 2'b00

`define BYTE 1
`define HALF 2
`define WORD 3

`define FETCH 0
`define MISS 2
`define HIT 1
`define REPLACE 3
`define WRITE_BACK 4

`endif
