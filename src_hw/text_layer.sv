`timescale 1ns / 1ps

module text_layer #(
    parameter integer X_LIMIT = 240,
    parameter integer Y_LIMIT = 240
) (
    input  logic                                         CLK              ,
    input  logic                                         RESET            ,
    // stub interface, required for using this component AS BRAM memory
    input  logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] WRITE_ROM_ADDRESS,
    input  logic                                         WRITE_ROM_DATA   ,
    input  logic                                         WRITE_ROM        ,
    // interface to LAYER MIXER
    input  logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] ROM_ADDRESS      ,
    output logic                                         ROM_DATA
);

    parameter integer PIXEL_LIMIT = (X_LIMIT*Y_LIMIT);
    // ROM memory declaration 
    (* ram_style="block" *)logic [0:0] rom_memory[PIXEL_LIMIT];

    initial begin 
        $display("loading rom_memory layer <red eyes>");
        $readmemb("C:/BiboranExperience/st7789_layer_animation/resources/text_layer.memory", rom_memory);
    end 

    always_ff @(posedge CLK) begin : ROM_DATA_processing 
        ROM_DATA <= rom_memory[ROM_ADDRESS];
    end 

    always_ff @(posedge CLK) begin : rom_memory_processing 
        if (WRITE_ROM) begin 
            rom_memory[WRITE_ROM_ADDRESS] <= WRITE_ROM_DATA;
        end else begin 
            rom_memory[WRITE_ROM_ADDRESS] <= rom_memory[WRITE_ROM_ADDRESS];
        end 
    end 


endmodule
