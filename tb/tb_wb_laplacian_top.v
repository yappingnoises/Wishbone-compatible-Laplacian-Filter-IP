`timescale 1ns / 1ps
//ai written, too lazy

module tb_wb_laplacian_top;

    parameter IMG_W    = 256;
    parameter IMG_H    = 256;
    parameter RAM_BASE = 32'h0000_C014;

    reg  clk = 0;
    reg  rst = 1;
    reg  start = 0;
    wire done;

    wire [31:0] wbm_adr;
    wire [31:0] wbm_dat_o;
    wire [31:0] wbm_dat_i;
    wire        wbm_we;
    wire [3:0]  wbm_sel;
    wire        wbm_stb;
    wire        wbm_cyc;
    wire        wbm_ack;

    wb_laplacian_top #(
        .IMG_W(IMG_W), .IMG_H(IMG_H), .RAM_BASE(RAM_BASE)
    ) dut (
        .clk_i(clk),     .rst_i(rst),
        .start_i(start), .done_o(done),
        .wbm_adr_o(wbm_adr),
        .wbm_dat_o(wbm_dat_o),
        .wbm_dat_i(wbm_dat_i),
        .wbm_we_o(wbm_we),
        .wbm_sel_o(wbm_sel),
        .wbm_stb_o(wbm_stb),
        .wbm_cyc_o(wbm_cyc),
        .wbm_ack_i(wbm_ack)
    );


    // addr_gen guarantees wbm_adr >= RAM_BASE always, so no underflow
    reg [7:0] mem [0:65535]; // 256x256 frame buffer, pixels as bytes

    wire [15:0] mem_idx = (wbm_adr - RAM_BASE) >> 2;

    assign wbm_ack   = wbm_cyc & wbm_stb;
    assign wbm_dat_i = {24'd0, mem[mem_idx]};

    always @(posedge clk)
        if (wbm_cyc & wbm_stb & wbm_we)
            mem[mem_idx] <= wbm_dat_o[7:0];

   
    function [15:0] px;
        input [7:0] row, col;
        px = {row, col}; // row*256 + col
    endfunction

    integer i, j, err;

    always #5 clk = ~clk; // 100 MHz

    task run_frame;
        begin
            @(posedge clk); start = 1;
            @(posedge clk); start = 0;
            wait(done);
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("tb_laplacian.vcd");
        $dumpvars(0, tb_wb_laplacian_top);

        rst = 1; repeat(4) @(posedge clk);
        rst = 0; @(posedge clk);

        // ── TEST 1: uniform image → all zeros ────────────────────
        // uniform region: Laplacian = 4*k - k - k - k - k = 0
        for (i = 0; i < 65536; i = i+1) mem[i] = 8'd128;

        run_frame;

        err = 0;
        for (i = 1; i < IMG_H-1; i = i+1)
            for (j = 1; j < IMG_W-1; j = j+1)
                if (mem[px(i,j)] !== 8'd0) begin
                    $display("FAIL t1 [%0d][%0d] = %0d (expected 0)", i, j, mem[px(i,j)]);
                    err = err + 1;
                end
        if (!err) $display("PASS test1: uniform region → all zeros bussin");

        // ── TEST 2: impulse at (4,4) ─────────────────────────────
        // expected: (4,4)=255 (4*255=1020 saturated), neighbours=0 (-255 clamped)
        // in-place caveat: by the time (4,4) is written, N=(3,4) and W=(4,3) have
        // already been processed and written 0 — so center still reads clean ✓
        for (i = 0; i < 65536; i = i+1) mem[i] = 8'd0;
        mem[px(4,4)] = 8'd255;

        run_frame;

        err = 0;
        if (mem[px(4,4)] !== 8'd255) begin
            $display("FAIL t2 center (4,4): got %0d expected 255", mem[px(4,4)]); err = err + 1; end
        if (mem[px(3,4)] !== 8'd0) begin
            $display("FAIL t2 N (3,4): got %0d expected 0", mem[px(3,4)]); err = err + 1; end
        if (mem[px(5,4)] !== 8'd0) begin
            $display("FAIL t2 S (5,4): got %0d expected 0", mem[px(5,4)]); err = err + 1; end
        if (mem[px(4,3)] !== 8'd0) begin
            $display("FAIL t2 W (4,3): got %0d expected 0", mem[px(4,3)]); err = err + 1; end
        if (mem[px(4,5)] !== 8'd0) begin
            $display("FAIL t2 E (4,5): got %0d expected 0", mem[px(4,5)]); err = err + 1; end
        if (!err) $display("PASS test2: impulse response correct");

        // ── TEST 3: step edge — column of 255 on left half ───────
        // pixels at j<128: value=255, j>=128: value=0
        // at the boundary (j=127,128): Laplacian fires, rest is uniform → 0
        for (i = 0; i < 65536; i = i+1)
            mem[i] = (i[7:0] < 8'd128) ? 8'd255 : 8'd0; // i[7:0] = col = j

        run_frame;

        err = 0;
        // interior of left half (far from edge) — should all be 0
        for (i = 1; i < IMG_H-1; i = i+1)
            for (j = 1; j < 126; j = j+1)
                if (mem[px(i,j)] !== 8'd0) begin
                    $display("FAIL t3 interior left [%0d][%0d] = %0d", i, j, mem[px(i,j)]);
                    err = err + 1;
                end
        // interior of right half — should all be 0
        for (i = 1; i < IMG_H-1; i = i+1)
            for (j = 130; j < IMG_W-1; j = j+1)
                if (mem[px(i,j)] !== 8'd0) begin
                    $display("FAIL t3 interior right [%0d][%0d] = %0d", i, j, mem[px(i,j)]);
                    err = err + 1;
                end
        if (!err) $display("PASS test3: step edge uniform regions are zero");

        $display("──────────────────────────────────");
        $display("simulation done, all done no cap");
        $finish;
    end

endmodule
