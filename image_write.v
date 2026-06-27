`timescale 1ns/1ps
`include "parameter.v"


module image_write
#(
    parameter WIDTH =`IMG_WIDTH,
    parameter HEIGHT =`IMG_HEIGHT,
    parameter BMP_HEADER_NUM = 54
)
(
    input HCLK,
    input HRESETn,
    input hsync,

    input [7:0] DATA_WRITE_R0,
    input [7:0] DATA_WRITE_G0,
    input [7:0] DATA_WRITE_B0,
    input [7:0] DATA_WRITE_R1,
    input [7:0] DATA_WRITE_G1,
    input [7:0] DATA_WRITE_B1,

    output reg Write_Done
);

//-------------------------------------------------
// DECLARATIONS (MOVED HERE)
//-------------------------------------------------
integer file;
integer status;
integer filesize;

integer i, k;
integer l, m;

reg [7:0] BMP_header [0:BMP_HEADER_NUM-1];
reg [7:0] out_BMP [0:WIDTH*HEIGHT*3-1];

reg [31:0] data_count;
reg done;

//-------------------------------------------------
// INITIAL BLOCK
//-------------------------------------------------
initial begin
    // file size calculation
    filesize = WIDTH * HEIGHT * 3 + BMP_HEADER_NUM;

    // BMP header
    BMP_header[0] = "B";
    BMP_header[1] = "M";

    BMP_header[2] = filesize[7:0];
    BMP_header[3] = filesize[15:8];
    BMP_header[4] = filesize[23:16];
    BMP_header[5] = filesize[31:24];

    BMP_header[10] = BMP_HEADER_NUM;
    BMP_header[14] = 40;

    BMP_header[18] = WIDTH[7:0];
    BMP_header[19] = WIDTH[15:8];

    BMP_header[22] = HEIGHT[7:0];
    BMP_header[23] = HEIGHT[15:8];

    BMP_header[26] = 1;
    BMP_header[28] = 24;

    // open file
    file = $fopen(`OUTPUTFILENAME, "wb");
end

//-------------------------------------------------
// ROW / COLUMN TRACKING
//-------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        l <= 0;
        m <= 0;
    end
    else if(hsync) begin
        if(m == WIDTH/2 - 1) begin
            m <= 0;
            l <= l + 1;
        end
        else begin
            m <= m + 1;
        end
    end
end

//-------------------------------------------------
// STORE PIXELS
//-------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        for(k=0; k<WIDTH*HEIGHT*3; k=k+1)
            out_BMP[k] <= 0;
    end
    else if(hsync) begin
        out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+2] <= DATA_WRITE_R0;
        out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+1] <= DATA_WRITE_G0;
        out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m  ] <= DATA_WRITE_B0;

        out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+5] <= DATA_WRITE_R1;
        out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+4] <= DATA_WRITE_G1;
        out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+3] <= DATA_WRITE_B1;
    end
end

//-------------------------------------------------
// DATA COUNT
//-------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn)
        data_count <= 0;
    else if(hsync)
        data_count <= data_count + 1;
end

//-------------------------------------------------
// DONE FLAG
//-------------------------------------------------
always @(*) begin
    done = (data_count >= (WIDTH*HEIGHT/2));
end

always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn)
        Write_Done <= 0;
    else
        Write_Done <= done;
end

//-------------------------------------------------
// WRITE FILE
//-------------------------------------------------
always @(posedge Write_Done) begin
    if(Write_Done) begin
        for(i=0; i<BMP_HEADER_NUM; i=i+1)
            $fwrite(file, "%c", BMP_header[i]);

        for(i=0; i<WIDTH*HEIGHT*3; i=i+6) begin
            $fwrite(file, "%c", out_BMP[i]);
            $fwrite(file, "%c", out_BMP[i+1]);
            $fwrite(file, "%c", out_BMP[i+2]);
            $fwrite(file, "%c", out_BMP[i+3]);
            $fwrite(file, "%c", out_BMP[i+4]);
            $fwrite(file, "%c", out_BMP[i+5]);
        end

        $display("BMP file created successfully!");
    end
end

endmodule
