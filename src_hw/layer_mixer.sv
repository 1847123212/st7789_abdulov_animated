`timescale 1ns / 1ps


module layer_mixer #(
    parameter integer X_LIMIT    = 240,
    parameter integer Y_LIMIT    = 240,
    parameter integer BANK_LIMIT = 9
) (
    input  logic                                         CLK              ,
    input  logic                                         RESET            ,
    // refresh interval in CLK periods
    input  logic [                                 31:0] UPDATE_LIMIT     ,
    // Enable/Disable layer printing
    input  logic [                                  3:0] LAYER_CONTROL    ,
    // interface to LAYER MIXER
    output logic [             ($clog2(BANK_LIMIT)-1):0] LAYER0_BANK      ,
    output logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] LAYER0_ADDRESS   ,
    input  logic [                     (BANK_LIMIT-1):0] LAYER0_DATA      ,
    // interface to LAYER MIXER
    output logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] LAYER1_ADDRESS   ,
    input  logic [                                  1:0] LAYER1_DATA      ,
    // interface to LAYER MIXER
    output logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] LAYER2_ADDRESS   ,
    input  logic                                         LAYER2_DATA      ,
    //
    output logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] LAYER3_ADDRESS   ,
    input  logic                                         LAYER3_DATA      ,
    // external interface
    output logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] WRITE_RAM_ADDRESS,
    output logic [                                  7:0] WRITE_RAM_COLOR_R,
    output logic [                                  7:0] WRITE_RAM_COLOR_G,
    output logic [                                  7:0] WRITE_RAM_COLOR_B,
    output logic                                         WRITE_RAM
);

    
    parameter integer PIXEL_LIMIT = (X_LIMIT*Y_LIMIT);
    
    logic [31:0] update_counter;

    (* dont_touch="true" *) logic layer0_data_muxed;
    logic transparency_factor; 

    logic [$clog2(PIXEL_LIMIT)-1:0] address;

    typedef enum{
        IDLE_ST,
        UPDATE_PROCESS_ST
    } fsm;

    fsm current_state = IDLE_ST;


    always_comb begin 
        case (LAYER0_BANK) 
            'd0 : layer0_data_muxed <= LAYER0_DATA[0];
            'd1 : layer0_data_muxed <= LAYER0_DATA[1];
            'd2 : layer0_data_muxed <= LAYER0_DATA[2];
            'd3 : layer0_data_muxed <= LAYER0_DATA[3];
            'd4 : layer0_data_muxed <= LAYER0_DATA[4];
            'd5 : layer0_data_muxed <= LAYER0_DATA[5];
            'd6 : layer0_data_muxed <= LAYER0_DATA[6];
            'd7 : layer0_data_muxed <= LAYER0_DATA[7];
            'd8 : layer0_data_muxed <= LAYER0_DATA[8];
        endcase // LAYER0_BANK
    end 

  
    always_comb begin 
        transparency_factor = LAYER1_DATA[1];
    end 

  
    always_ff @(posedge CLK) begin 
        WRITE_RAM_ADDRESS <= address;
    end 

    always_ff @(posedge CLK) begin : WRITE_RAM_processing 
        case (current_state)
            UPDATE_PROCESS_ST : 
                WRITE_RAM <= 1'b1;

            default :   
                WRITE_RAM <= 1'b0;

        endcase // current_state
    end 

    always_comb begin 
        LAYER0_ADDRESS = address;
        LAYER1_ADDRESS = address;
        LAYER2_ADDRESS = address;
        LAYER3_ADDRESS = address;
    end 

    always_ff @(posedge CLK) begin : current_state_processing 
        if (RESET) begin 
            current_state <= IDLE_ST;
        end else begin 
            case (current_state)

                IDLE_ST : 
                    if (update_counter < (UPDATE_LIMIT-1)) begin 
                        current_state <= current_state;
                    end else begin 
                        current_state <= UPDATE_PROCESS_ST;
                    end 

                UPDATE_PROCESS_ST : 
                    if (address == (PIXEL_LIMIT-1)) begin 
                        current_state <= IDLE_ST;
                    end else begin 
                        current_state <= current_state;
                    end

                default : 
                    current_state <= current_state;

            endcase // current_state
        end 
    end 


    always_ff @(posedge CLK) begin : address_processing
        case (current_state)
            UPDATE_PROCESS_ST : 
                address <= address + 1;

            default : 
                address <= '{default:0};

        endcase // current_state
    end 


    always_ff @(posedge CLK) begin : update_counter_processing 
        if (RESET) begin 
            update_counter <= '{default:0};
        end else begin 
            case (current_state)
                IDLE_ST : 
                    if (update_counter < (UPDATE_LIMIT-1)) begin 
                        update_counter <= update_counter + 1;
                    end else begin 
                        update_counter <= update_counter;
                    end 

                default : 
                    update_counter <= '{default:0};
            endcase // current_state

        end 
    end 


    always_ff @(posedge CLK) begin : LAYER0_BANK_processing 
        if (RESET) begin 
            LAYER0_BANK <= '{default:0};
        end else begin 

            case (current_state)
                UPDATE_PROCESS_ST : 
                    if (address == (PIXEL_LIMIT-1)) begin 
                        if (LAYER0_BANK < (BANK_LIMIT-1)) begin 
                            LAYER0_BANK <= LAYER0_BANK + 1;
                        end else begin 
                            LAYER0_BANK <= '{default:0};
                        end 
                    end else begin 
                        LAYER0_BANK <= LAYER0_BANK;
                    end 

                default : 
                    LAYER0_BANK <= LAYER0_BANK;
            endcase // current_state

        end 
    end 


    // each color 
    always_ff @(posedge CLK) begin : WRITE_RAM_COLOR_R_processing 
        if (LAYER3_DATA & LAYER_CONTROL[3]) begin // draw text LAYER
            WRITE_RAM_COLOR_R <= '{default:1}; 
        end else begin 
            if (LAYER2_DATA & LAYER_CONTROL[2]) begin // draw red eyes LAYER
                WRITE_RAM_COLOR_R <= '{default:1}; // ONLY FOR RED COLOR = 1 , in other cases = 0
            end else begin 
                if (transparency_factor & LAYER_CONTROL[1]) begin // if NO DRAWING LAYER1, we draw LAYER0 used as background
                    // rules for painting layer0
                    if (layer0_data_muxed) begin 
                        WRITE_RAM_COLOR_R <= '{default:1};
                    end else begin 
                        WRITE_RAM_COLOR_R <= '{default:0};
                    end 
                end else begin 
                    if (LAYER1_DATA[0]) begin // painting LAYER 1 data 
                        WRITE_RAM_COLOR_R <= '{default:0}; // Black color = no color 
                    end else begin 
                        WRITE_RAM_COLOR_R <= '{default:1}; // white pixel drawing 
                    end 
                end 
            end 
        end 
    end 


    always_ff @(posedge CLK) begin : WRITE_RAM_COLOR_G_processing 
        if (LAYER3_DATA & LAYER_CONTROL[3]) begin // draw text LAYER
            WRITE_RAM_COLOR_G <= '{default:0}; // The font is red color only 
        end else begin 
            if (LAYER2_DATA & LAYER_CONTROL[2]) begin // draw red eyes LAYER
                WRITE_RAM_COLOR_G <= '{default:0}; // ONLY FOR RED COLOR = 1 , in other cases = 0
            end else begin 
                if (transparency_factor & LAYER_CONTROL[1]) begin // if NO DRAWING LAYER1, we draw LAYER0 used as background
                    // rules for painting layer0
                    if (layer0_data_muxed) begin 
                        WRITE_RAM_COLOR_G <= '{default:1};
                    end else begin 
                        WRITE_RAM_COLOR_G <= '{default:0};
                    end 
                end else begin 
                    if (LAYER1_DATA[0]) begin // painting LAYER 1 data 
                        WRITE_RAM_COLOR_G <= '{default:0}; // Black color = no color 
                    end else begin 
                        WRITE_RAM_COLOR_G <= '{default:1}; // white pixel drawing 
                    end 
                end 
            end 
        end 
    end 



    always_ff @(posedge CLK) begin : WRITE_RAM_COLOR_B_processing 
        if (LAYER3_DATA & LAYER_CONTROL[3]) begin // draw text LAYER
            WRITE_RAM_COLOR_B <= '{default:0}; // The font is red color only 
        end else begin 
            if (LAYER2_DATA & LAYER_CONTROL[2]) begin // draw red eyes LAYER
                WRITE_RAM_COLOR_B <= '{default:0}; // ONLY FOR RED COLOR = 1 , in other cases = 0
            end else begin 
                if (transparency_factor & LAYER_CONTROL[1]) begin // if NO DRAWING LAYER1, we draw LAYER0 used as background
                    // rules for painting layer0
                    if (layer0_data_muxed) begin 
                        WRITE_RAM_COLOR_B <= '{default:1};
                    end else begin 
                        WRITE_RAM_COLOR_B <= '{default:0};
                    end 
                end else begin 
                    if (LAYER1_DATA[0]) begin // painting LAYER 1 data 
                        WRITE_RAM_COLOR_B <= '{default:0}; // Black color = no color 
                    end else begin 
                        WRITE_RAM_COLOR_B <= '{default:1}; // white pixel drawing 
                    end 
                end 
            end 
        end 
    end 



endmodule
