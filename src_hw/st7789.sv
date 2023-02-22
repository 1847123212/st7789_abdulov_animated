`timescale 1ns / 1ps



module st7789 #(
    parameter integer X_LIMIT = 240,
    parameter integer Y_LIMIT = 240
) (
    input  logic                                         CLK              ,
    input  logic                                         RESET            ,
    // external interface
    input  logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] WRITE_RAM_ADDRESS,
    input  logic [                                  7:0] WRITE_RAM_COLOR_R,
    input  logic [                                  7:0] WRITE_RAM_COLOR_G,
    input  logic [                                  7:0] WRITE_RAM_COLOR_B,
    input  logic                                         WRITE_RAM        ,
    //
    input  logic                                         UPDATE           ,
    //
    input  logic                                         SCLK             , // slowly clk
    output logic                                         LCD_BLK          ,
    output logic                                         LCD_RST          ,
    output logic                                         LCD_DC           ,
    output logic                                         LCD_SDA          ,
    output logic                                         LCD_SCK
);

    logic [7:0] tdata ;
    logic       tkeep ;
    logic       tuser ;
    logic       tvalid;
    logic       tlast ;
    logic       tready;

    logic [($clog2(X_LIMIT*Y_LIMIT))-1:0] read_ram_address;
    logic [                          7:0] read_ram_color_r;
    logic [                          7:0] read_ram_color_g;
    logic [                          7:0] read_ram_color_b;

    buffer_ram #(
        .X_LIMIT(X_LIMIT),
        .Y_LIMIT(Y_LIMIT)
    ) buffer_ram_inst (
        .CLK              (CLK              ),
        .RESET            (RESET            ),
        // external interface
        .WRITE_RAM_ADDRESS(WRITE_RAM_ADDRESS),
        .WRITE_RAM_COLOR_R(WRITE_RAM_COLOR_R),
        .WRITE_RAM_COLOR_G(WRITE_RAM_COLOR_G),
        .WRITE_RAM_COLOR_B(WRITE_RAM_COLOR_B),
        .WRITE_RAM        (WRITE_RAM        ),
        // interface to st7789_painter
        .READ_RAM_ADDRESS (read_ram_address ),
        .READ_RAM_COLOR_R (read_ram_color_r ),
        .READ_RAM_COLOR_G (read_ram_color_g ),
        .READ_RAM_COLOR_B (read_ram_color_b )
    );     

    st7789_painter #(
        .X_LIMIT(X_LIMIT),
        .Y_LIMIT(Y_LIMIT)
    ) st7789_painter_inst (
        .CLK          (CLK             ),
        .RESET        (RESET           ),
        .RAM_ADDRESS  (read_ram_address),
        .RAM_COLOR_R  (read_ram_color_r),
        .RAM_COLOR_G  (read_ram_color_g),
        .RAM_COLOR_B  (read_ram_color_b),
        .UPDATE       (UPDATE          ),
        .M_AXIS_TDATA (tdata           ),
        .M_AXIS_TKEEP (tkeep           ),
        .M_AXIS_TUSER (tuser           ),
        .M_AXIS_TVALID(tvalid          ),
        .M_AXIS_TLAST (tlast           ),
        .M_AXIS_TREADY(tready          )
    );

    st7789_driver st7789_driver_inst (
        .CLK          (CLK    ),
        .RESET        (RESET  ),
        .SCLK         (SCLK   ), // slowly clk
        .S_AXIS_TDATA (tdata  ),
        .S_AXIS_TKEEP (tkeep  ),
        .S_AXIS_TUSER (tuser  ),
        .S_AXIS_TVALID(tvalid ),
        .S_AXIS_TLAST (tlast  ),
        .S_AXIS_TREADY(tready ),
        .LCD_BLK      (LCD_BLK),
        .LCD_RST      (LCD_RST),
        .LCD_DC       (LCD_DC ),
        .LCD_SDA      (LCD_SDA),
        .LCD_SCK      (LCD_SCK)
    );





endmodule
