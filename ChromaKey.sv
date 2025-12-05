
`timescale 1ns / 1ps

module ChromaKey (
    input  logic         clk,
    input  logic         reset,       
    input  logic [3:0]   i_red,
    input  logic [3:0]   i_green,
    input  logic [3:0]   i_blue,
    input  logic [9:0]   x_pixel,
    input  logic [9:0]   y_pixel,
    input  logic         DE,          
    output logic [3:0]   red_port,
    output logic [3:0]   green_port,
    output logic [3:0]   blue_port
);

    parameter logic [3:0] G_THRESHOLD    = 4'd10; 
    parameter logic [3:0] DIFF_THRESHOLD = 4'd4;  
    
    logic [11:0] rgb;             
    logic [11:0] rgb_o;           
    logic [16:0] image_addr;     
    logic [15:0] bg_image_data; 
    logic [11:0] bg_rgb;          
    logic DE_1;                   
    logic chroma_en;              

    logic [3:0] r_in, g_in, b_in;
    logic is_chroma_key_pixel;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            chroma_en <= 1'b0;  
        else
            chroma_en <= 1'b1;  
    end

    assign rgb = {i_red, i_green, i_blue};

    assign bg_rgb = {
        bg_image_data[15:12], 
        bg_image_data[10:7],  
        bg_image_data[4:1]   
    };
    
    assign r_in = i_red;
    assign g_in = i_green;
    assign b_in = i_blue;

    assign is_chroma_key_pixel = (g_in >= G_THRESHOLD) && 
                                 ((g_in - r_in) >= DIFF_THRESHOLD) && 
                                 ((g_in - b_in) >= DIFF_THRESHOLD);

    assign rgb_o = (chroma_en && is_chroma_key_pixel)
                  ? bg_rgb : rgb;

    assign image_addr = 320 * (239 - y_pixel) + x_pixel;

    assign DE_1 = (x_pixel < 640 && y_pixel <   480) ? DE : 1'b0;

    assign {red_port, green_port, blue_port} = DE_1 ? rgb_o : 12'b0;

    bg_image_rom U_BG_ROM (
        .clk(clk),
        .addr(image_addr),
        .data(bg_image_data)
    );

endmodule


module bg_image_rom (
    input  logic         clk,
    input  logic [16:0]  addr,
    output logic [15:0]  data
);

    logic [15:0] rom[0:320*240-1]; 

    initial begin
        $readmemh("Background_1.mem", rom); 

    end

    always_ff @(posedge clk) begin
        data <= rom[addr]; 
    end

endmodule