`timescale 1ns / 1ps


module laplacian_addr_gen #(
    parameter IMG_W    = 256,
    parameter IMG_H    = 256,
    parameter RAM_BASE = 32'h0000_C014
)(
    input  wire signed [9:0] addr_i,
    input  wire signed [9:0] addr_j,
    output wire [31:0]       mem_addr
);


    wire [7:0] ci = (addr_i < 10'sd0) ? 8'd0 :
                    (addr_i > 10'sd255) ? 8'd255 : addr_i[7:0];
    wire [7:0] cj = (addr_j < 10'sd0) ? 8'd0 :
                    (addr_j > 10'sd255) ? 8'd255 : addr_j[7:0];

    // this needs to be changed if the image isnt 256x256 coz its utter stupidity 
    assign mem_addr = RAM_BASE + {14'b0, ci, cj, 2'b00};

endmodule 