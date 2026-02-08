//=============================================================
// conv1_lastpixel_helper.sv
//  - Conv1 출력 스트림(conv_valid + mac_in + pixel_idx)을 받아
//    마지막 valid 픽셀의 값과 index를 레지스터에 고정해 주는 Helper.
//  - conv1 자체는 전혀 수정하지 않고, 옆에 붙이는 "로직 어낼라이저" 역할.
//=============================================================
`timescale 1ns/1ps

module conv1_lastpixel_helper #(
    parameter int OUT_W  = 26,   // 출력 feature map 가로 길이 (예: 26)
    parameter int PIX_W  = 16    // pixel index 비트폭 (예: 0~675 → 16bit면 충분)
)(
    input  logic                  clk,
    input  logic                  reset,        // sync or async 상관 없이 사용 가능

    // Conv1 쪽에서 들어오는 스트림
    input  logic                  conv_valid,   // 이 사이클의 mac_in[*]가 유효
    input  logic                  done,         // Conv1 전체 완료 (처음 1 되는 순간 latch)
    input  logic [PIX_W-1:0]      pixel_idx,    // 0 .. (OUT_W*OUT_W-1)
    input  logic [15:0]           mac_in [3:0], // ch0..ch3

    // Helper가 만들어 주는 "마지막 픽셀" 정보
    output logic [PIX_W-1:0]      last_idx,
    output logic [15:0]           last_mac [3:0],
    output logic                  last_valid,   // done 이후 1로 유지 (FPGA에서 상태 확인용)
    output logic [PIX_W-1:0]      sample_count  // 총 몇 개의 conv_valid를 봤는지
);

    // 내부 상태: done이 한 번이라도 들어왔는지
    logic done_seen;

    integer ch;

    // 메인 캡처 로직
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            last_idx      <= '0;
            for (ch = 0; ch < 4; ch++) begin
                last_mac[ch] <= '0;
            end
            sample_count  <= '0;
            last_valid    <= 1'b0;
            done_seen     <= 1'b0;
        end
        else begin
            // 아직 done을 만나기 전까지만 계속 갱신
            if (!done_seen) begin

                // conv_valid가 1이면 "현재 픽셀"을 last_*로 갱신
                if (conv_valid) begin
                    last_idx <= pixel_idx;
                    for (ch = 0; ch < 4; ch++) begin
                        last_mac[ch] <= mac_in[ch];
                    end
                    sample_count <= sample_count + 1'b1;
                end

                // done이 1이 되는 순간:
                //  - last_* 값은 그대로 두고
                //  - last_valid를 1로 세우며
                //  - 이후로는 더 이상 갱신하지 않도록 done_seen을 1로
                if (done) begin
                    done_seen  <= 1'b1;
                    last_valid <= 1'b1;
                end
            end
            // done 이후에는 아무것도 변경하지 않음
        end
    end

endmodule
