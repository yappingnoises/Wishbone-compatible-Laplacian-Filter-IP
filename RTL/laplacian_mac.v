`timescale 1ns / 1ps

module laplacian_mac (
    input  wire        clk, rst,
    input  wire        clear_acc,
    input  wire        accum_en,
    input  wire        kernel_const, // 0 for -1 , 1 for 4
    input  wire [7:0]  pixel_in,
    output wire [7:0]  pixel_out
);

    // 20 bits in case of worst case 
    reg signed [19:0] add_mul_result;

    wire signed [19:0] pix    = $signed({12'b0, pixel_in});
    
    wire signed [19:0] contrib = kernel_const ? (pix<<<2) : (-pix); //bit shifting for 4x, negation for -1x, skipping x0 (only for genius?)

    always @(posedge clk or posedge rst) begin
        if (rst)             add_mul_result <= 20'sd0;
        else if (clear_acc)  add_mul_result <= 20'sd0;
        else if (accum_en)   add_mul_result <= add_mul_result + contrib;
    end

    // saturate to [0,255]
    assign pixel_out = (add_mul_result < 20'sd0)  ? 8'h00 :
                       (add_mul_result > 20'sd255) ? 8'hFF : add_mul_result[7:0];

endmodule