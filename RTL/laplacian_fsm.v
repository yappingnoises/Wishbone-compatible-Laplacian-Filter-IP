`timescale 1ns / 1ps
//67 i lost the game, we are no strangers to love meow hahahah i am going insane

module laplacian_fsm #(
    parameter IMG_W = 256,
    parameter IMG_H = 256
)(
    input  wire            clk, rst,
    input  wire            start,
    output reg             done,

    output reg             wb_cyc_o,
    output reg             wb_stb_o,
    output reg             wb_we_o,
    input  wire            wb_ack_i,

    output reg signed [9:0] addr_i_o,
    output reg signed [9:0] addr_j_o,

    output wire            clear_acc_o,
    output wire            accum_en_o,
    output wire            kernel_const_o
);

    // state encoding
    localparam [3:0]
        IDLE   = 4'd0,
        S0     = 4'd1,
        RP2    = 4'd2,
        RP3    = 4'd3,
        RP4    = 4'd4,
        RP5    = 4'd5,
        RP6    = 4'd6,
        RP7    = 4'd7,
        RP8    = 4'd8,
        RP9    = 4'd9,
        CONV   = 4'd10;
       // INCR_J = 4'd11;

    reg [3:0] state;
    reg [7:0] i, j;

    // combinational outputs
    assign clear_acc_o   = (state==IDLE) | (state==S0);
    assign accum_en_o    = ((state==RP2)|(state==RP4)|(state==RP5)|
                            (state==RP6)|(state==RP8)) & wb_ack_i;
    assign kernel_const_o = (state==RP5); // RP5 (+4), everything else is -1

    // addr
    always @(*) begin
        case (state)
            S0  : begin addr_i_o=$signed({2'b0,i})-10'sd1; addr_j_o=$signed({2'b0,j})-10'sd1; end
            RP2 : begin addr_i_o=$signed({2'b0,i})-10'sd1; addr_j_o=$signed({2'b0,j});         end
            RP3 : begin addr_i_o=$signed({2'b0,i})-10'sd1; addr_j_o=$signed({2'b0,j})+10'sd1; end
            RP4 : begin addr_i_o=$signed({2'b0,i});         addr_j_o=$signed({2'b0,j})-10'sd1; end
            RP5,
            CONV: begin addr_i_o=$signed({2'b0,i});         addr_j_o=$signed({2'b0,j});         end
            RP6 : begin addr_i_o=$signed({2'b0,i});         addr_j_o=$signed({2'b0,j})+10'sd1; end
            RP7 : begin addr_i_o=$signed({2'b0,i})+10'sd1; addr_j_o=$signed({2'b0,j})-10'sd1; end
            RP8 : begin addr_i_o=$signed({2'b0,i})+10'sd1; addr_j_o=$signed({2'b0,j});         end
            RP9 : begin addr_i_o=$signed({2'b0,i})+10'sd1; addr_j_o=$signed({2'b0,j})+10'sd1; end
            default: begin addr_i_o=10'sd0; addr_j_o=10'sd0; end
        endcase
    end

    always @(posedge clk) begin //synchronous reset
        if (rst) begin
            state    <= IDLE;
            i        <= 8'd0;
            j        <= 8'd0;
            done     <= 1'b0;
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            wb_we_o  <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    done <= 1'b0;
                    if (start) begin i<=8'd0; j<=8'd0; state<=S0; end
                end

                // zero-coeff skip states, strobe is pre asserted for the next state since these get skipped anyways
                S0:  begin wb_cyc_o<=1; wb_stb_o<=1; state<=RP2; end
                RP3: begin wb_stb_o<=1; state<=RP4; end
                RP7: begin wb_stb_o<=1; state<=RP8; end
                RP9: begin wb_stb_o<=1; wb_we_o<=1; state<=CONV; end

                // 1 states, strobe is held low
                RP2: if (wb_ack_i) begin wb_stb_o<=0;            state<=RP3; end
                RP4: if (wb_ack_i) begin                          state<=RP5; end
                RP5: if (wb_ack_i) begin                          state<=RP6; end
                RP6: if (wb_ack_i) begin wb_stb_o<=0;            state<=RP7; end
                RP8: if (wb_ack_i) begin wb_stb_o<=0;            state<=RP9; end

                //writing the calculated value back to the RAM
                CONV: if (wb_ack_i) begin
                    wb_cyc_o<=0; wb_stb_o<=0; wb_we_o<=0;

                        if (j < (IMG_W-1)) begin
                            j<=j+1'b1; state<=S0;
                        end else begin
                            j<=8'd0;
                        if (i < (IMG_H-1)) begin i<=i+1'b1; state<=S0; end
                        else begin wb_cyc_o <= 0; done<=1'b1; state<=IDLE; end
                    end
                end

                default: state<=IDLE;
            endcase
        end
    end

endmodule
