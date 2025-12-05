`timescale 1ns / 1ps

module Gaussian_Filter #(
    parameter int H_RES = 640
) (
    input  logic       clk,
    input  logic       reset,

    input  logic       de_in,
    input  logic [9:0] x_in,
    input  logic [9:0] y_in,
    input  logic [3:0] r_in,
    input  logic [3:0] g_in,
    input  logic [3:0] b_in,


    output logic       de_out,
    output logic [3:0] r_out,
    output logic [3:0] g_out,
    output logic [3:0] b_out
);

    logic [3:0] line_r0[0:H_RES-1];  
    logic [3:0] line_g0[0:H_RES-1];
    logic [3:0] line_b0[0:H_RES-1];

    logic [3:0] line_r1[0:H_RES-1]; 
    logic [3:0] line_g1[0:H_RES-1];
    logic [3:0] line_b1[0:H_RES-1];


    logic [3:0] w_r[0:2][0:2];
    logic [3:0] w_g[0:2][0:2];
    logic [3:0] w_b[0:2][0:2];

    logic       img_de;
    logic       img_de_d;
    logic [9:0] x_d, y_d;

    assign img_de = de_in
              && (x_in >= 2)
              && (y_in >= 2)
              && (x_in < H_RES)
              && (y_in < 480);
    wire line_start = de_in && (x_in == 10'd0); 


    integer i, j;
    always_ff @(posedge clk) begin
        if (reset) begin

            for (i = 0; i < 3; i++) begin
                for (j = 0; j < 3; j++) begin
                    w_r[i][j] <= '0;
                    w_g[i][j] <= '0;
                    w_b[i][j] <= '0;
                end
            end
        end else if (de_in) begin

            line_r0[x_in] <= line_r1[x_in];
            line_g0[x_in] <= line_g1[x_in];
            line_b0[x_in] <= line_b1[x_in];

            line_r1[x_in] <= r_in;
            line_g1[x_in] <= g_in;
            line_b1[x_in] <= b_in;

            if (line_start) begin

                for (i = 0; i < 3; i++) begin
                    for (j = 0; j < 3; j++) begin
                        w_r[i][j] <= '0;
                        w_g[i][j] <= '0;
                        w_b[i][j] <= '0;
                    end
                end
            end else begin

                w_r[0][0] <= w_r[0][1];
                w_r[0][1] <= w_r[0][2];
                w_r[0][2] <= line_r0[x_in];
                w_g[0][0] <= w_g[0][1];
                w_g[0][1] <= w_g[0][2];
                w_g[0][2] <= line_g0[x_in];
                w_b[0][0] <= w_b[0][1];
                w_b[0][1] <= w_b[0][2];
                w_b[0][2] <= line_b0[x_in];


                w_r[1][0] <= w_r[1][1];
                w_r[1][1] <= w_r[1][2];
                w_r[1][2] <= line_r1[x_in];
                w_g[1][0] <= w_g[1][1];
                w_g[1][1] <= w_g[1][2];
                w_g[1][2] <= line_g1[x_in];
                w_b[1][0] <= w_b[1][1];
                w_b[1][1] <= w_b[1][2];
                w_b[1][2] <= line_b1[x_in];

                w_r[2][0] <= w_r[2][1];
                w_r[2][1] <= w_r[2][2];
                w_r[2][2] <= r_in;
                w_g[2][0] <= w_g[2][1];
                w_g[2][1] <= w_g[2][2];
                w_g[2][2] <= g_in;
                w_b[2][0] <= w_b[2][1];
                w_b[2][1] <= w_b[2][2];
                w_b[2][2] <= b_in;
            end
        end
    end


    always_ff @(posedge clk) begin
        if (reset) begin
            img_de_d <= 1'b0;
            x_d      <= '0;
            y_d      <= '0;
        end else begin
            img_de_d <= img_de;
            if (de_in) begin
                x_d <= x_in;
                y_d <= y_in;
            end
        end
    end


    function automatic logic [3:0] gauss_1ch(input logic [3:0] W[0:2][0:2]);
        logic [11:0] sum;
        begin
            sum = (W[0][0] + (W[0][1] << 1) + W[0][2]
                 + (W[1][0] << 1) + (W[1][1] << 2) + (W[1][2] << 1)
                 + W[2][0] + (W[2][1] << 1) + W[2][2]);
            gauss_1ch = sum[11:4];
        end
    endfunction


    always_ff @(posedge clk) begin
        if (reset) begin
            r_out  <= '0;
            g_out  <= '0;
            b_out  <= '0;
            de_out <= 1'b0;
        end else begin
            de_out <= img_de_d;  

            if (img_de_d && (x_d > 2) && (y_d > 2)) begin

                r_out <= gauss_1ch(w_r);
                g_out <= gauss_1ch(w_g);
                b_out <= gauss_1ch(w_b);
            end else begin

                r_out <= r_in;
                g_out <= g_in;
                b_out <= b_in;
            end
        end
    end

endmodule
