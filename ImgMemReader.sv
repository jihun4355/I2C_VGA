`timescale 1ns / 1ps
// module ImgMemReader (
//     input  logic                         DE,
//     input  logic [                  9:0] x_pixel,
//     input  logic [                  9:0] y_pixel,
//     output logic [$clog2(320*240)-1 : 0] addr,
//     input  logic [                 15:0] imgData,
//     output logic [                  3:0] r_port,
//     output logic [                  3:0] g_port,
//     output logic [                  3:0] b_port
// );

//     assign addr = DE ? (320 * y_pixel[9:1] + x_pixel[9:1]) : 'bz;
//     assign {r_port, g_port, b_port} = DE ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0;

// endmodule

`timescale 1ns / 1ps

module ImgMemReader (
    input  logic                         DE,
    input  logic [9:0]                   x_pixel,
    input  logic [9:0]                   y_pixel,
    input  logic                         output_sel, 

    output logic [$clog2(320*240)-1 : 0] addr,
    input  logic [15:0]                  imgData,     
    output logic [3:0]                   r_port,
    output logic [3:0]                   g_port,
    output logic [3:0]                   b_port
);

    logic img_display_en;

    always_comb begin
        img_display_en = DE &&
                         (x_pixel < 10'd640) &&
                         (y_pixel < 10'd480);
    end

    logic [8:0] x_sample;  
    logic [7:0] y_sample; 

    always_comb begin

        x_sample = '0;
        y_sample = '0;

        if (img_display_en) begin
            if (output_sel) begin

                if (x_pixel < 10'd320)
                    x_sample = x_pixel[8:0];
                else
                    x_sample = x_pixel[8:0] - 9'd320;


                if (y_pixel < 10'd240)
                    y_sample = y_pixel[7:0];
                else
                    y_sample = y_pixel[7:0] - 8'd240;

            end else begin

                x_sample = x_pixel[9:1]; 

                y_sample = y_pixel[8:1]; 
            end
        end
    end


    always_comb begin
        if (img_display_en) begin
            addr = ( (y_sample << 8) + (y_sample << 6) ) + x_sample;
        end else begin
            addr = '0;  
        end
    end


    logic [3:0] r_int;
    logic [3:0] g_int;
    logic [3:0] b_int;

    always_comb begin
        if (img_display_en) begin

            r_int = imgData[15:12];
            g_int = imgData[10:7];
            b_int = imgData[4:1];
        end else begin
            r_int = 4'd0;
            g_int = 4'd0;
            b_int = 4'd0;
        end
    end

    assign r_port = r_int;
    assign g_port = g_int;
    assign b_port = b_int;

endmodule






