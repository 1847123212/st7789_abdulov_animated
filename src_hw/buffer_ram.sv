`timescale 1ns / 1ps



module buffer_ram #(
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
    // interface to st7789_painter
    input  logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] READ_RAM_ADDRESS ,
    output logic [                                  7:0] READ_RAM_COLOR_R ,
    output logic [                                  7:0] READ_RAM_COLOR_G ,
    output logic [                                  7:0] READ_RAM_COLOR_B
);  

    localparam integer PIXEL_LIMIT = (X_LIMIT * Y_LIMIT); // 240 x 240 

    logic [7:0] buffer_ram_r [(PIXEL_LIMIT-1):0];
    logic [7:0] buffer_ram_g [(PIXEL_LIMIT-1):0];
    logic [7:0] buffer_ram_b [(PIXEL_LIMIT-1):0];

    always_ff @(posedge CLK) begin : READ_RAM_COLOR_R_processing 
        READ_RAM_COLOR_R <= buffer_ram_r[READ_RAM_ADDRESS];
    end

    always_ff @(posedge CLK) begin : READ_RAM_COLOR_G_processing 
        READ_RAM_COLOR_G <= buffer_ram_g[READ_RAM_ADDRESS];
    end

    always_ff @(posedge CLK) begin : READ_RAM_COLOR_B_processing 
        READ_RAM_COLOR_B <= buffer_ram_b[READ_RAM_ADDRESS];
    end

    always_ff @(posedge CLK) begin : buffer_ram_r_processing 
        if (WRITE_RAM) begin 
            buffer_ram_r[WRITE_RAM_ADDRESS] <= WRITE_RAM_COLOR_R;
        end else begin 
            buffer_ram_r[WRITE_RAM_ADDRESS] <= buffer_ram_r[WRITE_RAM_ADDRESS];
        end 
    end

    always_ff @(posedge CLK) begin : buffer_ram_g_processing 
        if (WRITE_RAM) begin 
            buffer_ram_g[WRITE_RAM_ADDRESS] <= WRITE_RAM_COLOR_G;
        end else begin 
            buffer_ram_g[WRITE_RAM_ADDRESS] <= buffer_ram_g[WRITE_RAM_ADDRESS];
        end 
    end

    always_ff @(posedge CLK) begin : buffer_ram_b_processing 
        if (WRITE_RAM) begin 
            buffer_ram_b[WRITE_RAM_ADDRESS] <= WRITE_RAM_COLOR_B;
        end else begin 
            buffer_ram_b[WRITE_RAM_ADDRESS] <= buffer_ram_b[WRITE_RAM_ADDRESS];
        end 
    end





endmodule
