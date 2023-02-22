`timescale 1ns / 1ps



module st7789_layer_animation_top (
    input  logic MAIN_CLK,
    output logic LCD_BLK ,
    output logic LCD_RST ,
    output logic LCD_DC  ,
    output logic LCD_SDA ,
    output logic LCD_SCK
);



    logic        clk_100       ;
    logic        clk_50        ;

    localparam integer X_LIMIT    = 240;
    localparam integer Y_LIMIT    = 240;
    localparam integer BANK_LIMIT = 9  ;


    logic [               $clog2(BANK_LIMIT)-1:0] write_rom_bank   ;
    logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] write_rom_address;
    logic                                         write_rom_data   ;
    logic                                         write_rom        ;

    logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] write_ram_address;
    logic [                                  7:0] write_ram_color_r;
    logic [                                  7:0] write_ram_color_g;
    logic [                                  7:0] write_ram_color_b;
    logic                                         write_ram        ;

    // interface to LAYER MIXER
    logic [             ($clog2(BANK_LIMIT)-1):0] layer0_bank      ;
    logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] layer0_address   ;
    logic [                     (BANK_LIMIT-1):0] layer0_data      ;
    // interface to LAYER MIXER
    logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] layer1_address   ;
    logic [                                  1:0] layer1_data      ;
    // interface to LAYER MIXER
    logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] layer2_address   ;
    logic                                         layer2_data      ;
    //
    logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] layer3_address   ;
    logic                                         layer3_data      ;


    logic        reset        ;
    logic        update       ;
    logic [31:0] update_limit ;
    logic [ 3:0] layer_control;





    clk_wiz_100 clk_wiz_100_inst (
        .clk_out1(clk_100 ), // output clk_out1
        .clk_out2(clk_50  ), // output clk_out2
        .clk_in1 (MAIN_CLK)
    );



    // TODO need modify
    vio_control vio_control_inst (
        .clk       (clk_100      ), // input wire clk
        .probe_out0(reset        ), // output wire [0 : 0] probe_out0
        .probe_out1(update       ), // output wire [0 : 0] probe_out1
        .probe_out2(update_limit ),
        .probe_out3(layer_control)
    );


    vio_write_memory vio_write_memory_inst (
        .clk       (clk_100          ), // input wire clk
        .probe_out0(write_rom_bank   ), // output wire [8 : 0] probe_out0
        .probe_out1(write_rom_address), // output wire [15 : 0] probe_out1
        .probe_out2(write_rom_data   ), // output wire [0 : 0] probe_out2
        .probe_out3(write_rom        )  // output wire [0 : 0] probe_out3
    );


    rotation_star_layer_rom #(
        .X_LIMIT   (X_LIMIT   ),
        .Y_LIMIT   (Y_LIMIT   ),
        .BANK_LIMIT(BANK_LIMIT)
    ) rotation_star_layer_rom_inst (
        .CLK              (clk_100          ),
        .RESET            (reset            ),
        // stub interface, required for using this component AS BRAM memory
        .WRITE_ROM_BANK   (write_rom_bank   ),
        .WRITE_ROM_ADDRESS(write_rom_address),
        .WRITE_ROM_DATA   (write_rom_data   ),
        .WRITE_ROM        (write_rom        ),
        // interface to LAYER MIXER
        .ROM_BANK         (layer0_bank      ),
        .ROM_ADDRESS      (layer0_address   ),
        .ROM_DATA         (layer0_data      )
    );

    abdulov_layer #(
        .X_LIMIT(X_LIMIT),
        .Y_LIMIT(Y_LIMIT)
    ) abdulov_layer_inst (
        .CLK              (clk_100          ),
        .RESET            (reset            ),
        // stub interface, required for using this component AS BRAM memory
        .WRITE_ROM_ADDRESS(write_rom_address),
        .WRITE_ROM_DATA   (write_rom_data   ),
        .WRITE_ROM        (write_rom        ),
        // interface to LAYER MIXER
        .ROM_ADDRESS      (layer1_address   ),
        .ROM_DATA         (layer1_data      )
    );

    red_eyes #(
        .X_LIMIT(X_LIMIT),
        .Y_LIMIT(Y_LIMIT)
    ) red_eyes_inst (
        .CLK              (clk_100          ),
        .RESET            (reset            ),
        // stub interface, required for using this component AS BRAM memory
        .WRITE_ROM_ADDRESS(write_rom_address),
        .WRITE_ROM_DATA   (write_rom_data   ),
        .WRITE_ROM        (write_rom        ),
        // interface to LAYER MIXER
        .ROM_ADDRESS      (layer2_address   ),
        .ROM_DATA         (layer2_data      )
    );

    text_layer #(
        .X_LIMIT(X_LIMIT),
        .Y_LIMIT(Y_LIMIT)
    ) text_layer_inst (
        .CLK              (clk_100          ),
        .RESET            (reset            ),
        // stub interface, required for using this component AS BRAM memory
        .WRITE_ROM_ADDRESS(write_rom_address),
        .WRITE_ROM_DATA   (write_rom_data   ),
        .WRITE_ROM        (write_rom        ),
        // interface to LAYER MIXER
        .ROM_ADDRESS      (layer3_address   ),
        .ROM_DATA         (layer3_data      )
    );

    layer_mixer #(
        .X_LIMIT   (X_LIMIT   ),
        .Y_LIMIT   (Y_LIMIT   ),
        .BANK_LIMIT(BANK_LIMIT)
    ) layer_mixer_inst (
        .CLK              (clk_100          ),
        .RESET            (reset            ),
        // refresh interval in CLK periods
        .UPDATE_LIMIT     (update_limit     ),
        // Enable/Disable layer printing
        .LAYER_CONTROL    (layer_control    ),
        // interface to LAYER MIXER
        .LAYER0_BANK      (layer0_bank      ),
        .LAYER0_ADDRESS   (layer0_address   ),
        .LAYER0_DATA      (layer0_data      ),
        
        .LAYER1_ADDRESS   (layer1_address   ),
        .LAYER1_DATA      (layer1_data      ),
        
        .LAYER2_ADDRESS   (layer2_address   ),
        .LAYER2_DATA      (layer2_data      ),
        
        .LAYER3_ADDRESS   (layer3_address   ),
        .LAYER3_DATA      (layer3_data      ),
        // external interface
        .WRITE_RAM_ADDRESS(write_ram_address),
        .WRITE_RAM_COLOR_R(write_ram_color_r),
        .WRITE_RAM_COLOR_G(write_ram_color_g),
        .WRITE_RAM_COLOR_B(write_ram_color_b),
        .WRITE_RAM        (write_ram        )
    );


    st7789 #(
        .X_LIMIT(X_LIMIT),
        .Y_LIMIT(Y_LIMIT)
    ) st7789_inst (
        .CLK              (clk_100          ),
        .RESET            (reset            ),
        // external interface from layer mixer
        .WRITE_RAM_ADDRESS(write_ram_address),
        .WRITE_RAM_COLOR_R(write_ram_color_r),
        .WRITE_RAM_COLOR_G(write_ram_color_g),
        .WRITE_RAM_COLOR_B(write_ram_color_b),
        .WRITE_RAM        (write_ram        ),
        //
        .UPDATE           (update           ),
        //
        .SCLK             (clk_50           ),
        .LCD_BLK          (LCD_BLK          ),
        .LCD_RST          (LCD_RST          ),
        .LCD_DC           (LCD_DC           ),
        .LCD_SDA          (LCD_SDA          ),
        .LCD_SCK          (LCD_SCK          )
    );



endmodule
