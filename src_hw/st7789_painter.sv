`timescale 1ns / 1ps

module st7789_painter #(
    parameter integer X_LIMIT = 240,
    parameter integer Y_LIMIT = 240
) (
    input  logic                                         CLK          ,
    input  logic                                         RESET        ,
    // external RAM buffer for store picture 240x240 
    output logic [($clog2(X_LIMIT)+$clog2(Y_LIMIT))-1:0] RAM_ADDRESS  ,
    input  logic [                                  7:0] RAM_COLOR_R  ,
    input  logic [                                  7:0] RAM_COLOR_G  ,
    input  logic [                                  7:0] RAM_COLOR_B  ,
    // output interface to driver
    input  logic                                         UPDATE       ,
    output logic [                                  7:0] M_AXIS_TDATA ,
    output logic                                         M_AXIS_TKEEP ,
    output logic                                         M_AXIS_TUSER ,
    output logic                                         M_AXIS_TVALID,
    output logic                                         M_AXIS_TLAST ,
    input  logic                                         M_AXIS_TREADY
);


    localparam integer RAM_ADDR_LIMIT = (X_LIMIT * Y_LIMIT); // 240 x 240 
    localparam integer PAUSE_SIZE = 5000;

    typedef enum {
        RESET_ST, 
        PAUSE_ST, 
        IDLE_ST, 
        RESET_SW_ST, 
        SLEEP_OUT_ST, 
        CASET_ST, 
        RASET_ST, 
        INVON_ST, 
        DISPON_ST, 
        RAMWR_CMD_ST, 
        RAMWR_DATA_ST
    } fsm; 

    fsm current_state = RESET_ST; 

    logic [7:0] out_din_data = '{default:0};
    logic [0:0] out_din_user = '{default:0};
    logic       out_din_last = 1'b0        ;
    logic       out_wren     = 1'b0        ;
    logic       out_full                   ;
    logic       out_awfull                 ;

    logic [    $clog2(PAUSE_SIZE)-1:0] pause_counter = '{default:0};
    logic [$clog2(RAM_ADDR_LIMIT)-1:0] ram_addr      = '{default:0};
    logic [                       2:0] word_counter  = '{default:0};



    always_comb begin 
        RAM_ADDRESS = ram_addr;
    end 



    fifo_out_sync_tuser_xpm #(
        .DATA_WIDTH(8      ),
        .USER_WIDTH(1      ),
        .MEMTYPE   ("block"),
        .DEPTH     (16     )
    ) fifo_out_sync_tuser_xpm_inst (
        .CLK          (CLK          ),
        .RESET        (RESET        ),
        .OUT_DIN_DATA (out_din_data ),
        .OUT_DIN_KEEP (1'b0         ),
        .OUT_DIN_USER (out_din_user ),
        .OUT_DIN_LAST (out_din_last ),
        .OUT_WREN     (out_wren     ),
        .OUT_FULL     (out_full     ),
        .OUT_AWFULL   (out_awfull   ),
        
        .M_AXIS_TDATA (M_AXIS_TDATA ),
        .M_AXIS_TKEEP (M_AXIS_TKEEP ),
        .M_AXIS_TUSER (M_AXIS_TUSER ),
        .M_AXIS_TVALID(M_AXIS_TVALID),
        .M_AXIS_TLAST (M_AXIS_TLAST ),
        .M_AXIS_TREADY(M_AXIS_TREADY)
    );



    always_ff @(posedge CLK) begin : current_state_processing 
        if (RESET) begin 
            current_state <= RESET_ST;
        end else begin 

            case (current_state)

                RESET_ST : 
                    current_state <= RESET_SW_ST;

                RESET_SW_ST : 
                    if (!out_awfull) begin 
                        current_state <= PAUSE_ST;
                    end else begin 
                        current_state <= current_state;
                    end 

                PAUSE_ST : 
                    if (pause_counter < (PAUSE_SIZE-1)) begin 
                        current_state <= current_state;
                    end else begin 
                        current_state <= SLEEP_OUT_ST;
                    end 

                SLEEP_OUT_ST : 
                    if (!out_awfull) begin 
                        current_state <= INVON_ST;
                    end else begin 
                        current_state <= current_state;
                    end 

                INVON_ST : 
                    if (!out_awfull) begin 
                        current_state <= DISPON_ST;
                    end else begin 
                        current_state <= current_state;
                    end 

                DISPON_ST : 
                    if (!out_awfull) begin 
                        current_state <= IDLE_ST;
                    end else begin 
                        current_state <= current_state;
                    end 

                IDLE_ST :
                    if (UPDATE) begin 
                        current_state <= CASET_ST;
                    end else begin 
                        current_state <= current_state;
                    end 

                CASET_ST :
                    if (~out_awfull) begin 
                        if (word_counter == 4) begin 
                            current_state <= RASET_ST;
                        end else begin 
                            current_state <= current_state;
                        end 
                    end else begin 
                        current_state <= current_state;
                    end  

                RASET_ST : 
                    if (!out_awfull) begin 
                        if (word_counter == 4) begin 
                            current_state <= RAMWR_CMD_ST;
                        end else begin 
                            current_state <= current_state;
                        end 
                    end else begin 
                        current_state <= current_state;
                    end 

                RAMWR_CMD_ST : 
                    if (!out_awfull) begin 
                        current_state <= RAMWR_DATA_ST;
                    end else begin 
                        current_state <= current_state;
                    end

                RAMWR_DATA_ST : 
                    if (!out_awfull) begin 
                        if (ram_addr == (RAM_ADDR_LIMIT-1)) begin 
                            if (word_counter == 2) begin 
                                current_state <= IDLE_ST;
                            end else begin 
                                current_state <= current_state;
                            end 
                        end else begin 
                            current_state <= current_state;
                        end 
                    end else begin 
                        current_state <= current_state;
                    end

                default : 
                    current_state <= current_state;

            endcase // current_state

        end 
    end 



    always_ff @(posedge CLK) begin : ram_addr_processing  
        case (current_state)
            RAMWR_DATA_ST : 
                if (!out_awfull) begin
                    if (word_counter == 2) begin 
                        ram_addr  <= ram_addr + 1;
                    end else begin 
                        ram_addr <= ram_addr;
                    end  
                end else begin 
                    ram_addr <= ram_addr;
                end 

            default : 
                ram_addr <= '{default:0};
        endcase // current_state
    end 



    always_ff @(posedge CLK) begin : pause_counter_processing 
        case (current_state)
            PAUSE_ST : 
                pause_counter <= pause_counter + 1;

            default : 
                pause_counter <= '{default:0};

        endcase // current_state
    end 



    always_ff @(posedge CLK) begin : word_counter_processing 
        case (current_state)

            CASET_ST: 
                if (!out_awfull) begin 
                    if (word_counter == 4) begin 
                        word_counter <= '{default:0};
                    end else begin 
                        word_counter <= word_counter + 1;
                    end 
                end else begin 
                    word_counter <= word_counter;
                end 

            RASET_ST: 
                if (!out_awfull) begin 
                    if (word_counter == 4) begin 
                        word_counter <= '{default:0};
                    end else begin 
                        word_counter <= word_counter + 1;
                    end 
                end else begin 
                    word_counter <= word_counter;
                end 

            RAMWR_DATA_ST: 
                if (!out_awfull) begin 
                    if (word_counter == 2) begin 
                        word_counter <= '{default:0};
                    end else begin 
                        word_counter <= word_counter + 1;
                    end 
                end else begin 
                    word_counter <= word_counter;
                end 

        endcase // current_state
    end 


    always_ff @(posedge CLK) begin : out_din_data_processing    
        case (current_state)

            RESET_SW_ST: 
                out_din_data <= 8'h01;

            SLEEP_OUT_ST : 
                out_din_data <= 8'h11;

            RASET_ST : 
                case (word_counter)
                    'd0 : out_din_data <= 8'h2B;
                    'd1 : out_din_data <= 8'h00;
                    'd2 : out_din_data <= 8'h00;
                    'd3 : out_din_data <= 8'h00;
                    'd4 : out_din_data <= 8'hEF;
                    default : out_din_data <= out_din_data;
                endcase // current_state

            CASET_ST : 
                case (word_counter)
                    'd0 : out_din_data <= 8'h2A;
                    'd1 : out_din_data <= 8'h00;
                    'd2 : out_din_data <= 8'h00;
                    'd3 : out_din_data <= 8'h00;
                    'd4 : out_din_data <= 8'hEF;
                    default : out_din_data <= out_din_data;
                endcase // current_state

            INVON_ST : 
                out_din_data <= 8'h21;

            DISPON_ST : 
                out_din_data <= 8'h29;

            RAMWR_CMD_ST : 
                out_din_data <= 8'h2C;

            RAMWR_DATA_ST: 

                case (word_counter) 
                    'd0 : out_din_data <= RAM_COLOR_R; // R subpixel 
                    'd1 : out_din_data <= RAM_COLOR_G; // G subpixel 
                    'd2 : out_din_data <= RAM_COLOR_B; // B subpixel
                    default : out_din_data <= out_din_data;
                endcase // word_counter

            default : 
                out_din_data <= out_din_data;

        endcase // current_state
    end 



    // 0 - command , 1 - data
    always_ff @(posedge CLK) begin : out_din_user_processing 
        case (current_state)

            RESET_SW_ST : 
                out_din_user <= 1'b0;

            SLEEP_OUT_ST : 
                out_din_user <= 1'b0;

            INVON_ST : 
                out_din_user <= 1'b0;

            DISPON_ST : 
                out_din_user <= 1'b0;

            RASET_ST : 
                if (word_counter == 0) begin 
                    out_din_user <= 1'b0;
                end else begin 
                    out_din_user <= 1'b1;
                end 

            CASET_ST : 
                if (word_counter == 0) begin 
                    out_din_user <= 1'b0;
                end else begin 
                    out_din_user <= 1'b1;
                end

            RAMWR_CMD_ST : 
                out_din_user <= 1'b0;

            RAMWR_DATA_ST : 
                out_din_user <= 1'b1;

            default : 
                out_din_user <= out_din_user;

        endcase // current_state
    end 


    always_ff @(posedge CLK) begin : out_din_last_processing 
        case (current_state)
            RESET_SW_ST : 
                out_din_last <= 1'b1;

            SLEEP_OUT_ST : 
                out_din_last <= 1'b1;

            INVON_ST : 
                out_din_last <= 1'b1;

            DISPON_ST : 
                out_din_last <= 1'b1;

            RASET_ST : 
                if (word_counter == 4) begin 
                    out_din_last <= 1'b1;
                end else begin 
                    out_din_last <= 1'b0;
                end 

            CASET_ST : 
                if (word_counter == 4) begin 
                    out_din_last <= 1'b1;
                end else begin 
                    out_din_last <= 1'b0;
                end 

            RAMWR_DATA_ST : 
                if (ram_addr == (RAM_ADDR_LIMIT-1)) begin 
                    if (word_counter == 2) begin 
                        out_din_last <= 1'b1;
                    end else begin 
                        out_din_last <= 1'b0;
                    end 
                end else begin 
                    out_din_last <= 1'b0;
                end 

            default : 
                out_din_last <= 1'b0;

        endcase // current_state
    end 


    always_ff @(posedge CLK) begin : out_wren_processing 
        case (current_state)
            RESET_SW_ST : 
                if (!out_awfull) begin 
                    out_wren <= 1'b1;
                end else begin 
                    out_wren <= 1'b0;
                end 

            SLEEP_OUT_ST : 
                if (!out_awfull) begin 
                    out_wren <= 1'b1;
                end else begin 
                    out_wren <= 1'b0;
                end 

            INVON_ST : 
                if (!out_awfull) begin 
                    out_wren <= 1'b1;
                end else begin 
                    out_wren <= 1'b0;
                end 

            DISPON_ST : 
                if (!out_awfull) begin 
                    out_wren <= 1'b1;
                end else begin 
                    out_wren <= 1'b0;
                end 

            RASET_ST : 
                if (!out_awfull) begin 
                    out_wren <= 1'b1;
                end else begin 
                    out_wren <= 1'b0;
                end 

            CASET_ST : 
                if (!out_awfull) begin 
                    out_wren <= 1'b1;
                end else begin 
                    out_wren <= 1'b0;
                end 

            RAMWR_CMD_ST : 
                if (!out_awfull) begin 
                    out_wren <= 1'b1;
                end else begin 
                    out_wren <= 1'b0;
                end 

            RAMWR_DATA_ST : 
                if (!out_awfull) begin 
                    out_wren <= 1'b1;
                end else begin 
                    out_wren <= 1'b0;
                end 

            default : 
                out_wren <= 1'b0;

        endcase // current_state
    end 

endmodule
