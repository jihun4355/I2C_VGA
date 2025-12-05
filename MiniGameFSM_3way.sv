

`timescale 1ns / 1ps

module MiniGameFSM_4way (
    input logic clk,
    input logic reset,
    input logic start,
    input logic vsync,

    // ColorDetector로부터 입력
    input logic detect_LT,
    input logic detect_RT,
    input logic detect_LB,
    input logic detect_RB,

    // Overlay로 출력
    output logic [2:0] fsm_state,   
    output logic [1:0] region,       
    output logic [1:0] result_type,  
    output logic [2:0] round_cnt,    
    output logic [2:0] score,        
    output logic [4:0] round_result 
);


    typedef enum logic [2:0] {
        IDLE       = 3'b000,
        READY      = 3'b001,
        PLAY       = 3'b010,
        ROUND_END  = 3'b011,
        SCOREBOARD = 3'b100
    } state_t;

    typedef enum logic [1:0] {
        RES_NONE    = 2'b00,
        RES_SUCCESS = 2'b01,
        RES_FAIL    = 2'b10
    } result_t;


    state_t state, next_state;

    // Timers (frame 단위)
    logic [7:0] ready_timer;
    logic [7:0] play_timer;
    logic [7:0] round_end_timer;
    logic [9:0] score_timer;

    // PLAY state counters
    logic [7:0] hold_cnt;     // 정답 유지 frame 수
    logic [3:0] skip_frames;  // 초기 안정화 frame skip


    localparam int HOLD_THRESHOLD = 45; 


    logic LT_d, RT_d, LB_d, RB_d;


    logic [7:0] lfsr;


    logic correct;


    logic vs_d, vs_rise;

    always_ff @(posedge clk) begin
        vs_d    <= vsync;
        vs_rise <= vsync & ~vs_d;
    end


    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            LT_d <= 0;
            RT_d <= 0;
            LB_d <= 0;
            RB_d <= 0;
        end else if (vs_rise) begin
            LT_d <= detect_LT;
            RT_d <= detect_RT;
            LB_d <= detect_LB;
            RB_d <= detect_RB;
        end
    end


    always_ff @(posedge clk or posedge reset) begin
        if (reset) lfsr <= 8'hA5;
        else if (vs_rise) lfsr <= {lfsr[6:0], ^(lfsr & 8'hB8)};
    end


    always_comb begin
        correct = 1'b0;
        
        case (region)
            // region 0 (LT): LT만 켜져야 함. RT, LB, RB는 꺼져야 함.
            2'd0: begin
                if (LT_d == 1'b1 && RT_d == 1'b0 && LB_d == 1'b0 && RB_d == 1'b0)
                    correct = 1'b1;
            end

            // region 1 (RT): RT만 켜져야 함.
            2'd1: begin
                if (RT_d == 1'b1 && LT_d == 1'b0 && LB_d == 1'b0 && RB_d == 1'b0)
                    correct = 1'b1;
            end

            // region 2 (LB): LB만 켜져야 함.
            2'd2: begin
                if (LB_d == 1'b1 && LT_d == 1'b0 && RT_d == 1'b0 && RB_d == 1'b0)
                    correct = 1'b1;
            end

            // region 3 (RB): RB만 켜져야 함.
            2'd3: begin
                if (RB_d == 1'b1 && LT_d == 1'b0 && RT_d == 1'b0 && LB_d == 1'b0)
                    correct = 1'b1;
            end
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else state <= next_state;
    end


    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start) next_state = READY;
            end

            READY: begin
                if (vs_rise && ready_timer >= 60) next_state = PLAY;
            end

            PLAY: begin
                if (vs_rise) begin
                    if (hold_cnt >= HOLD_THRESHOLD) next_state = ROUND_END;
                    else if (play_timer >= 120) next_state = ROUND_END;
                end
            end

            ROUND_END: begin
                if (vs_rise && round_end_timer >= 60) begin
                    if (round_cnt < 4) next_state = READY;
                    else next_state = SCOREBOARD;
                end
            end

            SCOREBOARD: begin
                if (vs_rise && score_timer >= 300) next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ready_timer     <= 0;
            play_timer      <= 0;
            round_end_timer <= 0;
            score_timer     <= 0;
            hold_cnt        <= 0;
            skip_frames     <= 0;
            round_cnt       <= 0;
            score           <= 0;
            round_result    <= 0;
            region          <= 0;
            result_type     <= RES_NONE;
        end else begin
            case (state)
                IDLE: begin
                    ready_timer     <= 0;
                    play_timer      <= 0;
                    round_end_timer <= 0;
                    score_timer     <= 0;
                    round_cnt       <= 0;
                    score           <= 0;
                    round_result    <= 0;
                    result_type     <= RES_NONE;
                end

                READY: begin
                    if (vs_rise) begin
                        ready_timer <= ready_timer + 1;
                        if (ready_timer >= 60) begin
                            region      <= lfsr % 4;
                            play_timer  <= 0;
                            hold_cnt    <= 0;
                            skip_frames <= 4;
                        end
                    end
                end

                PLAY: begin
                    if (vs_rise) begin
                        if (skip_frames != 0) begin
                            skip_frames <= skip_frames - 1;
                        end else begin
                            play_timer <= play_timer + 1;

                            if (correct) hold_cnt <= hold_cnt + 1;
                            else hold_cnt <= 0; 


                            if (hold_cnt >= HOLD_THRESHOLD) begin
                                result_type             <= RES_SUCCESS;
                                score                   <= score + 1;
                                round_result[round_cnt] <= 1;
                                round_end_timer         <= 0;
                            end 
                            else if (play_timer >= 120) begin
                                result_type             <= RES_FAIL;
                                round_result[round_cnt] <= 0;
                                round_end_timer         <= 0;
                            end
                        end
                    end
                end

                ROUND_END: begin
                    if (vs_rise) begin
                        round_end_timer <= round_end_timer + 1;
                        if (round_end_timer >= 60) begin
                            if (round_cnt < 4) begin
                                round_cnt   <= round_cnt + 1;
                                ready_timer <= 0;
                                result_type <= RES_NONE;
                            end else begin
                                score_timer <= 0;
                            end
                        end
                    end
                end

                SCOREBOARD: begin
                    if (vs_rise) begin
                        score_timer <= score_timer + 1;
                    end
                end
            endcase
        end
    end

    assign fsm_state = state;

endmodule