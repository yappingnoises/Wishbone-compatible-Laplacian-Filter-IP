`timescale 1ns / 1ps

module wb_laplacian_top #(
    parameter IMG_W    = 256,
    parameter IMG_H    = 256,
    parameter RAM_BASE = 32'h0000_C014
)(
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        start_i, // SoC kicks off a frame
    output wire        done_o,

    // Wishbone master
    output wire [31:0] wbm_adr_o,
    output wire [31:0] wbm_dat_o,
    input  wire [31:0] wbm_dat_i,
    output wire        wbm_we_o,
    output wire [3:0]  wbm_sel_o,
    output wire        wbm_stb_o,
    output wire        wbm_cyc_o,
    input  wire        wbm_ack_i
);

    assign wbm_sel_o = 4'b1111;

    wire signed [9:0] addr_i, addr_j;
    wire              kernel_const, clear_acc, accum_en;
    wire [7:0]        pixel_out;

    assign wbm_dat_o = {24'h0, pixel_out}; 

    
    laplacian_fsm #(.IMG_W(IMG_W), .IMG_H(IMG_H)) u_fsm (
        .clk            (clk_i),
        .rst            (rst_i),
        .start          (start_i),
        .done           (done_o),
        .wb_cyc_o       (wbm_cyc_o),
        .wb_stb_o       (wbm_stb_o),
        .wb_we_o        (wbm_we_o),
        .wb_ack_i       (wbm_ack_i),
        .addr_i_o       (addr_i),
        .addr_j_o       (addr_j),
        .clear_acc_o    (clear_acc),
        .accum_en_o     (accum_en),
        .kernel_const_o (kernel_const)
    );

    laplacian_addr_gen #(.IMG_W(IMG_W), .IMG_H(IMG_H), .RAM_BASE(RAM_BASE)) u_addr_gen (
        .addr_i   (addr_i),
        .addr_j   (addr_j),
        .mem_addr (wbm_adr_o)
    );

    laplacian_mac u_mac (
        .clk          (clk_i),
        .rst          (rst_i),
        .clear_acc    (clear_acc),
        .accum_en     (accum_en),
        .kernel_const (kernel_const),
        .pixel_in     (wbm_dat_i[7:0]),
        .pixel_out    (pixel_out)
    );

endmodule