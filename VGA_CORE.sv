`timescale 1ns / 1ps

module VGA_CORE (
    // glob sig
    input  logic       clk,
    input  logic       reset,
    // mode swithches
    input  logic       output_sel,
    input  logic       cart_sel,
    input  logic [1:0] mirror_sel,
    //OV7670 sig
    input  logic       pclk,
    input  logic       href,
    input  logic       vsync,
    input  logic [7:0] data,
    output logic       xclk,
    output logic       sys_clk,
    // VGA sig
    output logic h_sync,
    output logic v_sync,
    output logic DE,
    output logic [9:0] o_x_pixel, 
    output logic [9:0] o_y_pixel,
    output logic [3:0] r_raw,
    output logic [3:0] g_raw,
    output logic [3:0] b_raw,
    output logic [15:0] pix00, pix01, pix02,
    output logic [15:0] pix10, pix11, pix12,
    output logic [15:0] pix20, pix21, pix22,

    output logic [9:0] x_raw,
    output logic [9:0] y_raw
);


    logic we;
    

    logic [9:0] x_pixel, y_pixel;


    logic [9:0] x_pixel_mirrored;
    logic [9:0] y_pixel_mirrored;
    

    logic [9:0] x_muxed, y_muxed;

    logic [9:0] final_x, final_y;

    logic is_retro_region;
    

    localparam int BLOCK_SIZE = 4; 

    logic [16:0] rAddr_c;
    logic [16:0] rAddr_n;
    logic [16:0] rAddr;
    logic [15:0] rData;
    logic [16:0] wAddr;
    logic [15:0] wData;
    logic mux_sel;


    assign xclk = sys_clk;
    

    assign x_raw = x_pixel;
    assign y_raw = y_pixel;
    assign o_x_pixel = x_muxed;
    assign o_y_pixel = y_muxed;


    assign mux_sel = |mirror_sel;

    assign is_retro_region = output_sel && (x_pixel < 320) && (y_pixel >= 240);


    assign final_x = is_retro_region ? (x_muxed - (x_muxed % BLOCK_SIZE)) : x_muxed;
    assign final_y = is_retro_region ? (y_muxed - (y_muxed % BLOCK_SIZE)) : y_muxed;



    pixel_clk_gen U_PXL_CLK_GEN (
        .clk  (clk),
        .reset(reset),
        .pclk (sys_clk)
    );

    VGA_Sycher U_VGA_Syncher (
        .clk(sys_clk),
        .reset(reset),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel), 
        .y_pixel(y_pixel)
    );

    OV7670_Mem_Controller U_OV7670_Mem_Controller (
        .pclk(pclk),
        .reset(reset),
        .href(href),
        .vsync(vsync),
        .data(data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );

    frame_buffer U_Frame_Buffer (
        .wclk(pclk),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(sys_clk),
        .oe(1'b1),
        .rAddr(rAddr),
        .rData(rData)
    );

    PixelWindow3x3 U_Pixel_Window_3x3(
        .clk(sys_clk),
        .reset(reset),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .rAddr(rAddr_c),
        .rData(rData),
        .*
    );

    mux_2x1 #(.WIDTH(17)) U_MUX_ADDR(
        .sel(cart_sel),
        .x0(rAddr_n), 
        .x1(rAddr_c), 
        .y(rAddr)
    );

    MirrorFilter U_MirrorFilter (
        .mode_quad(output_sel),
        .mirror_sel (mirror_sel),
        .x_pixel_in (x_pixel),
        .y_pixel_in (y_pixel),
        .x_pixel_out(x_pixel_mirrored),
        .y_pixel_out(y_pixel_mirrored)
    );

    ImgMemReader U_IMG_Reader (
        .DE(DE),
        .x_pixel(final_x),  
        .y_pixel(final_y),  
        .output_sel(output_sel),
        .addr(rAddr_n),
        .imgData(rData),
        .r_port(r_raw),
        .g_port(g_raw),
        .b_port(b_raw)
    );


    mux_2x1 U_MUX_X_Y_2X1 (
        .sel(mux_sel),
        .x0 ({x_pixel, y_pixel}),               
        .x1 ({x_pixel_mirrored, y_pixel_mirrored}), 
        .y  ({x_muxed, y_muxed})          
    );

endmodule

module mux_2x1 #(
    parameter int WIDTH = 20
) (
    input  logic             sel,
    input  logic [WIDTH-1:0] x0,
    input  logic [WIDTH-1:0] x1,
    output logic [WIDTH-1:0] y
);
    assign y = sel ? x1 : x0;
endmodule