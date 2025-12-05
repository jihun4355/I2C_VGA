`timescale 1ns / 1ps

module MirrorFilter (
    input  logic       mode_quad,   
    input logic [1:0] mirror_sel,  
    input logic [9:0] x_pixel_in,  
    input logic [9:0] y_pixel_in, 
    output logic [9:0] x_pixel_out,
    output logic [9:0] y_pixel_out
);

    localparam int H_TILE_MAX = 10'd319; 
    localparam int V_TILE_MAX = 10'd239;  
    localparam int H_MIDPOINT = 10'd160;  
    localparam int V_MIDPOINT = 10'd120; 


    logic [9:0] base_x, base_y;
    logic [9:0] local_x, local_y;
    logic [9:0] local_x_dec, local_y_dec;
    logic [9:0] x_mirror, y_mirror;

    always_comb begin
        if (!mode_quad) begin

            x_pixel_out = x_pixel_in;
            y_pixel_out = y_pixel_in;
        end else begin

            if (x_pixel_in < 10'd320) base_x = 10'd0;
            else base_x = 10'd320;

            if (y_pixel_in < 10'd240) base_y = 10'd0;
            else base_y = 10'd240;


            local_x = x_pixel_in - base_x;
            local_y = y_pixel_in - base_y;


            x_mirror = H_TILE_MAX - local_x;  
            y_mirror = V_TILE_MAX - local_y; 


            local_x_dec = local_x;
            local_y_dec = local_y;


            if (mirror_sel[0]) begin
                local_x_dec = (local_x < H_MIDPOINT) ? local_x : x_mirror;
            end

            if (mirror_sel[1]) begin
                local_y_dec = (local_y < V_MIDPOINT) ? local_y : y_mirror;
            end


            x_pixel_out = base_x + local_x_dec;
            y_pixel_out = base_y + local_y_dec;
        end
    end

endmodule

module RetroFilter (
    input  logic [3:0] r_in,
    input  logic [3:0] g_in,
    input  logic [3:0] b_in,
    output logic [3:0] r_out,
    output logic [3:0] g_out,
    output logic [3:0] b_out
);
    // logic [3:0] r_retro = {r_in[3:1], 1'b1};
    // logic [3:0] g_retro = {g_in[3:1], 1'b1};
    // logic [3:0] b_retro = {b_in[3:1], 1'b1};

    logic [3:0] r_retro = {
        r_in[3:2], 2'b11
    }; 
    logic [3:0] g_retro = {g_in[3:2], 2'b11};  
    logic [3:0] b_retro = {b_in[3:2], 2'b11};  

    assign r_out = r_retro;
    assign g_out = g_retro;
    assign b_out = b_retro;

endmodule
