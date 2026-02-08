//=============================================================
// conv1_conv2_top.sv  (채널 인덱스를 [CHANNELS-1:0] 로 통일)
//=============================================================
`timescale 1ns/1ps

module conv1_conv2_top #(
    parameter int IMG_W    = 28,
    parameter int IMG_SIZE = IMG_W * IMG_W,
    parameter int DATA_W   = 16,
    parameter int CHANNELS = 4
)(
    input  logic                        clk,
    input  logic                        reset,
    input  logic                        start,
    output logic                        done,          // conv1 완료 신호

    // conv1 디버그용 포트
    // *** 여기: [CHANNELS] -> [CHANNELS-1:0]
    output logic [DATA_W-1:0]    mac_out      [CHANNELS-1:0],
    output logic                        rom_rd_en_dbg,
    output logic [13:0]                 rom_addr_dbg,
    output logic [7:0]                  x_count_dbg,

    // conv2 디버그용 포트
    output logic [DATA_W-1:0]    pool_out_dbg [CHANNELS-1:0],
    output logic                        pool_valid_dbg,
    output logic                        pool_last_dbg,
    output logic [15:0]                 pool_x_dbg,
    output logic [15:0]                 pool_y_dbg
);

    // ---------------------------------------------------------
    // 1) conv1_top 인스턴스
    //     conv1_top 의 mac_out 도 [3:0] 이라고 가정
    // ---------------------------------------------------------
    conv1_top #(
        .IMG_W   (IMG_W),
        .IMG_SIZE(IMG_SIZE)
    ) u_conv1_top (
        .clk          (clk),
        .reset        (reset),
        .start        (start),
        .done         (done),
        .mac_out      (mac_out),        // [3:0] <-> [3:0] 로 일치
        .rom_rd_en_dbg(rom_rd_en_dbg),
        .rom_addr_dbg (rom_addr_dbg),
        .x_count_dbg  (x_count_dbg)
    );

    // ---------------------------------------------------------
    // 2) conv_valid 생성 (기존과 동일)
    // ---------------------------------------------------------
    int row_idx;
    int col_idx;

    always_comb begin
        row_idx = rom_addr_dbg / IMG_W;  // 0..27
        col_idx = x_count_dbg;           // 0..27
    end

    logic conv2_valid;
    always_comb begin
        conv2_valid = rom_rd_en_dbg &&
                      (row_idx >= 2) && (row_idx <= IMG_W-1) &&
                      (col_idx >= 4) && (col_idx <= IMG_W-1);
    end

    // ---------------------------------------------------------
    // 3) conv2_top 인스턴스
    // ---------------------------------------------------------
    conv2_top #(
        .DATA_W  (DATA_W),
        .IN_W    (IMG_W-2),
        .IN_H    (IMG_W-2),
        .CHANNELS(CHANNELS)
    ) u_conv2 (
        .clk       (clk),
        .rst       (reset),
        .conv_in   (mac_out),        // 이제 conv2_top 의 [CHANNELS-1:0] 과 일치
        .conv_valid(conv2_valid),
        .pool_out  (pool_out_dbg),
        .pool_valid(pool_valid_dbg),
        .pool_last (pool_last_dbg),
        .pool_x    (pool_x_dbg),
        .pool_y    (pool_y_dbg)
    );

endmodule
