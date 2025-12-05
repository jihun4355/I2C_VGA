
`timescale 1ns / 1ps

module Sobel_edge #(
    parameter int H_RES = 640
) (
    input  logic       clk,
    input  logic       reset,

    // Gaussian Side
    input  logic       de_in,
    input  logic [9:0] x_in,
    input  logic [9:0] y_in,
    input  logic [3:0] r_in,
    input  logic [3:0] g_in,
    input  logic [3:0] b_in,

    // output 
    output logic       de_out,
    output logic [3:0] r_out,
    output logic [3:0] g_out,
    output logic [3:0] b_out
);

    localparam logic [7:0] TH_EDGE = 8'd16; 


    logic safe_de;

    assign safe_de = de_in
                  && (x_in >= 10'd2)
                  && (y_in >= 10'd2)
                  && (x_in <  H_RES - 2)
                  && (y_in <  10'd478);

    logic [6:0] gray_tmp;
    logic [5:0] gray_in; 

    always_comb begin
        gray_tmp = r_in + (g_in << 1) + b_in;  
        gray_in  = gray_tmp[5:0];             
    end


    logic [5:0] line0[0:H_RES-1]; 
    logic [5:0] line1[0:H_RES-1]; 


    logic [5:0] w[0:2][0:2];


    wire line_start = de_in && (x_in == 10'd0);

    integer i, j;
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 3; i++) begin
                for (j = 0; j < 3; j++) begin
                    w[i][j] <= '0;
                end
            end
        end else if (de_in) begin

            line0[x_in] <= line1[x_in];
            line1[x_in] <= gray_in;

            if (line_start) begin

                for (i = 0; i < 3; i++) begin
                    for (j = 0; j < 3; j++) begin
                        w[i][j] <= '0;
                    end
                end
            end else begin

                w[0][0] <= w[0][1];
                w[0][1] <= w[0][2];
                w[0][2] <= line0[x_in];

                w[1][0] <= w[1][1];
                w[1][1] <= w[1][2];
                w[1][2] <= line1[x_in];

                w[2][0] <= w[2][1];
                w[2][1] <= w[2][2];
                w[2][2] <= gray_in;
            end
        end
    end


    logic       de_d;
    logic [9:0] x_d, y_d;

    always_ff @(posedge clk) begin
        if (reset) begin
            de_d <= 1'b0;
            x_d  <= '0;
            y_d  <= '0;
        end else begin
            de_d <= safe_de;       
            if (safe_de) begin   
                x_d <= x_in;
                y_d <= y_in;
            end
        end
    end


    logic signed [9:0] gx, gy;
    logic       [9:0] abs_gx, abs_gy;
    logic       [9:0] mag10;  
    logic       [7:0] mag8;

    logic       is_edge;     

    always_comb begin

        gx = -$signed({4'b0, w[0][0]}) - ($signed({4'b0, w[1][0]}) <<< 1) -
              $signed({4'b0, w[2][0]}) + $signed({4'b0, w[0][2]}) +
             ($signed({4'b0, w[1][2]}) <<< 1) + $signed({4'b0, w[2][2]});

        gy = -$signed({4'b0, w[0][0]}) - ($signed({4'b0, w[0][1]}) <<< 1) -
              $signed({4'b0, w[0][2]}) + $signed({4'b0, w[2][0]}) +
             ($signed({4'b0, w[2][1]}) <<< 1) + $signed({4'b0, w[2][2]});


        abs_gx = gx[9] ? -gx : gx;
        abs_gy = gy[9] ? -gy : gy;

        mag10 = abs_gx + abs_gy;  


        if (mag10 > 10'd255) mag8 = 8'hFF;
        else                 mag8 = mag10[7:0];

        is_edge = (mag8 >= TH_EDGE);
    end

    logic is_edge_d;          
    logic edge_now, edge_d1;   
    logic thick_edge;          
    always_ff @(posedge clk) begin
        if (reset) begin
            de_out     <= 1'b0;
            r_out      <= '0;
            g_out      <= '0;
            b_out      <= '0;

            is_edge_d  <= 1'b0;
            edge_now   <= 1'b0;
            edge_d1    <= 1'b0;
            thick_edge <= 1'b0;
        end else begin

            is_edge_d <= is_edge;
            de_out    <= de_d;


            if (de_d) begin
 
                if (x_d == 10'd0) begin
                    edge_now <= 1'b0;
                    edge_d1  <= 1'b0;
                end else begin
                    edge_d1  <= edge_now;
                    edge_now <= is_edge_d;
                end
            end else begin
                edge_now <= 1'b0;
                edge_d1  <= 1'b0;
            end

            thick_edge <= edge_now | edge_d1;


            if (de_d && (x_d >= 10'd2) && (y_d >= 10'd2)) begin
                if (thick_edge) begin
                    r_out <= 4'hF;
                    g_out <= 4'hF;
                    b_out <= 4'hF;
                end else begin
                    r_out <= 4'd0;
                    g_out <= 4'd0;
                    b_out <= 4'd0;
                end
            end else begin
                r_out <= 4'd0;
                g_out <= 4'd0;
                b_out <= 4'd0;
            end
        end
    end

endmodule
