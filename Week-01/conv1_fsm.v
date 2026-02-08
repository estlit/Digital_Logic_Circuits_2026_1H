// conv1_fsm.sv
// 28x28 이미지를 순차적으로 읽어서 data_in 스트림 생성
// conv1_core에 연결될 data_in, x_count, rom_addr 생성 FSM

`timescale 1ns / 1ps
module conv1_fsm #(
    parameter IMG_W   = 28,
    parameter IMG_SIZE = IMG_W * IMG_W
)(
    input  logic clk,
    input  logic reset,
    input  logic start,            // slide_switch == 1 같은 의미

    output logic rom_rd_en,
    output logic [13:0] rom_addr,
    output logic [7:0]  x_count,   // col index (0~27)
    output logic done
);

    typedef enum logic [1:0] {
        S_IDLE,
        S_RUN,
        S_DONE
    } state_t;

    state_t state, nstate;

    logic [13:0] pixel_cnt;

    // ----------------------------------------
    // Sequential
    // ----------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= S_IDLE;
            pixel_cnt <= 0;
        end else begin
            state <= nstate;
            if (state == S_RUN) begin
                if (pixel_cnt < IMG_SIZE)
                    pixel_cnt <= pixel_cnt + 1;
            end
        end
    end

    // ----------------------------------------
    // Combinational
    // ----------------------------------------
    always_comb begin
        nstate    = state;
        rom_rd_en = 1'b0;
        done      = 1'b0;

        rom_addr  = pixel_cnt;
        x_count   = pixel_cnt % IMG_W;

        case (state)
            S_IDLE: begin
                if (start)
                    nstate = S_RUN;
            end

            S_RUN: begin
                rom_rd_en = 1'b1;
                if (pixel_cnt == IMG_SIZE-1)
                    nstate = S_DONE;
            end

            S_DONE: begin
                done = 1'b1;
                if (!start)
                    nstate = S_IDLE;
            end
        endcase
    end

endmodule
