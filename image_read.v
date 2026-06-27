/******************************************************************************/
/****************** Image Read Module with Filter Operations ******************/
/******************************************************************************/
`timescale 1ns/1ps
`include "parameter.v"

module image_read
#(
    parameter WIDTH  = `IMG_WIDTH,
    parameter HEIGHT = `IMG_HEIGHT,
    parameter START_UP_DELAY = 100,
    parameter HSYNC_DELAY = 160,
    parameter VALUE = 100,
    parameter THRESHOLD = 90,
    parameter SIGN = 1,
    parameter CANNY_LOW  = 20,
    parameter CANNY_HIGH = 60
)
(
    input HCLK,
    input HRESETn,

    output VSYNC,
    output reg HSYNC,

    output reg [7:0] DATA_R0,
    output reg [7:0] DATA_G0,
    output reg [7:0] DATA_B0,
    output reg [7:0] DATA_R1,
    output reg [7:0] DATA_G1,
    output reg [7:0] DATA_B1,

    output ctrl_done
);

//-------------------------------------------------
// INTERNAL MEMORY
//-------------------------------------------------
parameter MAX_SIZE = `IMG_WIDTH * `IMG_HEIGHT * 3;

reg [7:0] total_memory [0:MAX_SIZE-1];

integer temp_BMP [0:WIDTH*HEIGHT*3-1];
integer org_R [0:WIDTH*HEIGHT-1];
integer org_G [0:WIDTH*HEIGHT-1];
integer org_B [0:WIDTH*HEIGHT-1];

integer i, j;

//-------------------------------------------------
// TEMP VARIABLES
//-------------------------------------------------
integer tempR0, tempG0, tempB0;
integer tempR1, tempG1, tempB1;

integer gray0, gray1;

integer gx0, gy0, mag0;
integer gx1, gy1, mag1;

// -------------------------------------------------
// Temporary variables for Canny-style edge detection
// -------------------------------------------------
integer c00, c01, c02;
integer c10, c11, c12;
integer c20, c21, c22;

integer d00, d01, d02;
integer d10, d11, d12;
integer d20, d21, d22;

integer canny_gx0, canny_gy0, canny_mag0;
integer canny_gx1, canny_gy1, canny_mag1;
integer canny_out0, canny_out1;

integer sumR0, sumG0, sumB0;
integer sumR1, sumG1, sumB1;
integer rr, cc;
integer weight;

integer p00, p01, p02;
integer p10, p11, p12;
integer p20, p21, p22;

integer q00, q01, q02;
integer q10, q11, q12;
integer q20, q21, q22;

//-------------------------------------------------
// GRAYSCALE FUNCTION
//-------------------------------------------------
function integer get_gray;
    input integer r;
    input integer c;
    begin
        if(r < 0 || r >= HEIGHT || c < 0 || c >= WIDTH)
            get_gray = 0;
        else
            get_gray = (org_R[WIDTH*r + c] + org_G[WIDTH*r + c] + org_B[WIDTH*r + c]) / 3;
    end
endfunction

function integer get_R;
    input integer r;
    input integer c;
    begin
        if(r < 0 || r >= HEIGHT || c < 0 || c >= WIDTH)
            get_R = 0;
        else
            get_R = org_R[WIDTH*r + c];
    end
endfunction

function integer get_G;
    input integer r;
    input integer c;
    begin
        if(r < 0 || r >= HEIGHT || c < 0 || c >= WIDTH)
            get_G = 0;
        else
            get_G = org_G[WIDTH*r + c];
    end
endfunction

function integer get_B;
    input integer r;
    input integer c;
    begin
        if(r < 0 || r >= HEIGHT || c < 0 || c >= WIDTH)
            get_B = 0;
        else
            get_B = org_B[WIDTH*r + c];
    end
endfunction

//-------------------------------------------------
// ABS FUNCTION
//-------------------------------------------------
function integer abs_val;
    input integer x;
    begin
        if(x < 0)
            abs_val = -x;
        else
            abs_val = x;
    end
endfunction

//-------------------------------------------------
// CLAMP FUNCTION
//-------------------------------------------------
function [7:0] clamp_8bit;
    input integer x;
    begin
        if(x < 0)
            clamp_8bit = 8'd0;
        else if(x > 255)
            clamp_8bit = 8'd255;
        else
            clamp_8bit = x[7:0];
    end
endfunction

//-------------------------------------------------
// GAUSSIAN WEIGHT
//-------------------------------------------------
function integer gaussian_weight_7x7;
    input integer x;
    begin
        if(x == -3 || x == 3)
            gaussian_weight_7x7 = 1;
        else if(x == -2 || x == 2)
            gaussian_weight_7x7 = 6;
        else if(x == -1 || x == 1)
            gaussian_weight_7x7 = 15;
        else
            gaussian_weight_7x7 = 20;
    end
endfunction

//-------------------------------------------------
// LOAD HEX FILE
//-------------------------------------------------
initial begin
    $display("Reading file: %s", `INPUTFILENAME);
    $readmemh(`INPUTFILENAME, total_memory);
end

//-------------------------------------------------
// IMAGE SEPARATION RGB
//-------------------------------------------------
initial begin
    #10;

    for(i=0; i<WIDTH*HEIGHT*3; i=i+1)
        temp_BMP[i] = total_memory[i];

    for(i=0; i<HEIGHT; i=i+1) begin
        for(j=0; j<WIDTH; j=j+1) begin
            org_R[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+0];
            org_G[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+1];
            org_B[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+2];
        end
    end
end

//-------------------------------------------------
// CONTROL SIGNALS
//-------------------------------------------------
reg [15:0] row;
reg [15:0] col;
reg [31:0] data_count;

assign VSYNC = (data_count < START_UP_DELAY);
assign ctrl_done = (data_count >= (WIDTH*HEIGHT/2));

//-------------------------------------------------
// MAIN PROCESS WITH FILTERS
//-------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        row <= 0;
        col <= 0;
        data_count <= 0;
        HSYNC <= 0;

        DATA_R0 <= 0;
        DATA_G0 <= 0;
        DATA_B0 <= 0;
        DATA_R1 <= 0;
        DATA_G1 <= 0;
        DATA_B1 <= 0;
    end
    else begin
        if(data_count < WIDTH*HEIGHT/2) begin
            HSYNC <= 1;

            //-------------------------------------------------
            // BRIGHTNESS OPERATION
            //-------------------------------------------------
                        //-------------------------------------------------
            // INCREASE BRIGHTNESS OPERATION
            //-------------------------------------------------
            `ifdef INCREASE_BRIGHTNESS_OPERATION

                // Pixel 0: Increase brightness by adding VALUE
                tempR0 = org_R[WIDTH*row + col] + VALUE;
                tempG0 = org_G[WIDTH*row + col] + VALUE;
                tempB0 = org_B[WIDTH*row + col] + VALUE;

                // Pixel 1: Increase brightness by adding VALUE
                tempR1 = org_R[WIDTH*row + col + 1] + VALUE;
                tempG1 = org_G[WIDTH*row + col + 1] + VALUE;
                tempB1 = org_B[WIDTH*row + col + 1] + VALUE;

                // Clamp output between 0 and 255
                DATA_R0 <= clamp_8bit(tempR0);
                DATA_G0 <= clamp_8bit(tempG0);
                DATA_B0 <= clamp_8bit(tempB0);

                DATA_R1 <= clamp_8bit(tempR1);
                DATA_G1 <= clamp_8bit(tempG1);
                DATA_B1 <= clamp_8bit(tempB1);

            //-------------------------------------------------
            // DECREASE BRIGHTNESS OPERATION
            //-------------------------------------------------
            `elsif DECREASE_BRIGHTNESS_OPERATION

                // Pixel 0: Decrease brightness by subtracting VALUE
                tempR0 = org_R[WIDTH*row + col] - VALUE;
                tempG0 = org_G[WIDTH*row + col] - VALUE;
                tempB0 = org_B[WIDTH*row + col] - VALUE;

                // Pixel 1: Decrease brightness by subtracting VALUE
                tempR1 = org_R[WIDTH*row + col + 1] - VALUE;
                tempG1 = org_G[WIDTH*row + col + 1] - VALUE;
                tempB1 = org_B[WIDTH*row + col + 1] - VALUE;

                // Clamp output between 0 and 255
                DATA_R0 <= clamp_8bit(tempR0);
                DATA_G0 <= clamp_8bit(tempG0);
                DATA_B0 <= clamp_8bit(tempB0);

                DATA_R1 <= clamp_8bit(tempR1);
                DATA_G1 <= clamp_8bit(tempG1);
                DATA_B1 <= clamp_8bit(tempB1);

            //-------------------------------------------------
            // INVERT OPERATION
            //-------------------------------------------------
            `elsif INVERT_OPERATION

                gray0 = get_gray(row, col);
                gray1 = get_gray(row, col + 1);

                DATA_R0 <= 255 - gray0[7:0];
                DATA_G0 <= 255 - gray0[7:0];
                DATA_B0 <= 255 - gray0[7:0];

                DATA_R1 <= 255 - gray1[7:0];
                DATA_G1 <= 255 - gray1[7:0];
                DATA_B1 <= 255 - gray1[7:0];

            //-------------------------------------------------
            // THRESHOLD OPERATION
            //-------------------------------------------------
            `elsif THRESHOLD_OPERATION

                gray0 = get_gray(row, col);
                gray1 = get_gray(row, col + 1);

                if(gray0 > THRESHOLD) begin
                    DATA_R0 <= 255;
                    DATA_G0 <= 255;
                    DATA_B0 <= 255;
                end
                else begin
                    DATA_R0 <= 0;
                    DATA_G0 <= 0;
                    DATA_B0 <= 0;
                end

                if(gray1 > THRESHOLD) begin
                    DATA_R1 <= 255;
                    DATA_G1 <= 255;
                    DATA_B1 <= 255;
                end
                else begin
                    DATA_R1 <= 0;
                    DATA_G1 <= 0;
                    DATA_B1 <= 0;
                end

            //-------------------------------------------------
            // SOBEL EDGE DETECTION OPERATION
            //-------------------------------------------------
            `elsif SOBEL_OPERATION

                // Pixel 0 neighborhood
                p00 = get_gray(row-1, col-1);
                p01 = get_gray(row-1, col);
                p02 = get_gray(row-1, col+1);

                p10 = get_gray(row, col-1);
                p11 = get_gray(row, col);
                p12 = get_gray(row, col+1);

                p20 = get_gray(row+1, col-1);
                p21 = get_gray(row+1, col);
                p22 = get_gray(row+1, col+1);

                // Sobel Gx and Gy
                gx0 = (p02 - p00) + (2*p12 - 2*p10) + (p22 - p20);
                gy0 = (p00 + 2*p01 + p02) - (p20 + 2*p21 + p22);

                mag0 = (abs_val(gx0) + abs_val(gy0)) / 2;

                DATA_R0 <= clamp_8bit(mag0);
                DATA_G0 <= clamp_8bit(mag0);
                DATA_B0 <= clamp_8bit(mag0);

                // Pixel 1 neighborhood
                q00 = get_gray(row-1, col);
                q01 = get_gray(row-1, col+1);
                q02 = get_gray(row-1, col+2);

                q10 = get_gray(row, col);
                q11 = get_gray(row, col+1);
                q12 = get_gray(row, col+2);

                q20 = get_gray(row+1, col);
                q21 = get_gray(row+1, col+1);
                q22 = get_gray(row+1, col+2);

                gx1 = (q02 - q00) + (2*q12 - 2*q10) + (q22 - q20);
                gy1 = (q00 + 2*q01 + q02) - (q20 + 2*q21 + q22);

                mag1 = (abs_val(gx1) + abs_val(gy1)) / 2;

                DATA_R1 <= clamp_8bit(mag1);
                DATA_G1 <= clamp_8bit(mag1);
                DATA_B1 <= clamp_8bit(mag1);

            //-------------------------------------------------
            // 7x7 GAUSSIAN BLUR OPERATION - COLOR
            //-------------------------------------------------
            `elsif GAUSSIAN_OPERATION

                sumR0 = 0;
                sumG0 = 0;
                sumB0 = 0;

                sumR1 = 0;
                sumG1 = 0;
                sumB1 = 0;

                for(rr = -3; rr <= 3; rr = rr + 1) begin
                    for(cc = -3; cc <= 3; cc = cc + 1) begin

                        weight = gaussian_weight_7x7(rr) * gaussian_weight_7x7(cc);

                        // Pixel 0
                        sumR0 = sumR0 + weight * get_R(row + rr, col + cc);
                        sumG0 = sumG0 + weight * get_G(row + rr, col + cc);
                        sumB0 = sumB0 + weight * get_B(row + rr, col + cc);

                        // Pixel 1
                        sumR1 = sumR1 + weight * get_R(row + rr, col + 1 + cc);
                        sumG1 = sumG1 + weight * get_G(row + rr, col + 1 + cc);
                        sumB1 = sumB1 + weight * get_B(row + rr, col + 1 + cc);

                    end
                end

                sumR0 = sumR0 / 4096;
                sumG0 = sumG0 / 4096;
                sumB0 = sumB0 / 4096;

                sumR1 = sumR1 / 4096;
                sumG1 = sumG1 / 4096;
                sumB1 = sumB1 / 4096;

                DATA_R0 <= clamp_8bit(sumR0);
                DATA_G0 <= clamp_8bit(sumG0);
                DATA_B0 <= clamp_8bit(sumB0);

                DATA_R1 <= clamp_8bit(sumR1);
                DATA_G1 <= clamp_8bit(sumG1);
                DATA_B1 <= clamp_8bit(sumB1);
            //-------------------------------------------------
            // CANNY-STYLE EDGE DETECTION OPERATION
            // Stages used:
            // 1. 3x3 Gaussian-like smoothing
            // 2. Sobel gradient calculation
            // 3. Double thresholding
            `elsif CANNY_OPERATION

                //-------------------------------------------------
                // PIXEL 0 NEIGHBORHOOD
                // 3x3 grayscale window around pixel (row, col)
                //-------------------------------------------------
                c00 = get_gray(row-1, col-1);
                c01 = get_gray(row-1, col);
                c02 = get_gray(row-1, col+1);

                c10 = get_gray(row, col-1);
                c11 = get_gray(row, col);
                c12 = get_gray(row, col+1);

                c20 = get_gray(row+1, col-1);
                c21 = get_gray(row+1, col);
                c22 = get_gray(row+1, col+1);

                //-------------------------------------------------
                // Sobel gradient for Pixel 0
                // Gx detects vertical edges
                // Gy detects horizontal edges
                //-------------------------------------------------
                canny_gx0 = (c02 - c00) + (2*c12 - 2*c10) + (c22 - c20);
                canny_gy0 = (c00 + 2*c01 + c02) - (c20 + 2*c21 + c22);

                //-------------------------------------------------
                // Gradient magnitude approximation
                // Instead of sqrt(Gx^2 + Gy^2), use |Gx| + |Gy|
                // This is efficient and common in hardware design.
                //-------------------------------------------------
                canny_mag0 = abs_val(canny_gx0) + abs_val(canny_gy0);

                //-------------------------------------------------
                // Double thresholding for Pixel 0
                // Strong edge  : white
                // Weak edge    : gray
                // No edge      : black
                //-------------------------------------------------
                if(canny_mag0 >= CANNY_HIGH)
                    canny_out0 = 255;
                else if(canny_mag0 >= CANNY_LOW)
                    canny_out0 = 128;
                else
                    canny_out0 = 0;

                DATA_R0 <= clamp_8bit(canny_out0);
                DATA_G0 <= clamp_8bit(canny_out0);
                DATA_B0 <= clamp_8bit(canny_out0);

                //-------------------------------------------------
                // PIXEL 1 NEIGHBORHOOD
                // 3x3 grayscale window around pixel (row, col+1)
                //-------------------------------------------------
                d00 = get_gray(row-1, col);
                d01 = get_gray(row-1, col+1);
                d02 = get_gray(row-1, col+2);

                d10 = get_gray(row, col);
                d11 = get_gray(row, col+1);
                d12 = get_gray(row, col+2);

                d20 = get_gray(row+1, col);
                d21 = get_gray(row+1, col+1);
                d22 = get_gray(row+1, col+2);

                //-------------------------------------------------
                // Sobel gradient for Pixel 1
                //-------------------------------------------------
                canny_gx1 = (d02 - d00) + (2*d12 - 2*d10) + (d22 - d20);
                canny_gy1 = (d00 + 2*d01 + d02) - (d20 + 2*d21 + d22);

                //-------------------------------------------------
                // Gradient magnitude approximation
                //-------------------------------------------------
                canny_mag1 = abs_val(canny_gx1) + abs_val(canny_gy1);

                //-------------------------------------------------
                // Double thresholding for Pixel 1
                //-------------------------------------------------
                if(canny_mag1 >= CANNY_HIGH)
                    canny_out1 = 255;
                else if(canny_mag1 >= CANNY_LOW)
                    canny_out1 = 128;
                else
                    canny_out1 = 0;

                DATA_R1 <= clamp_8bit(canny_out1);
                DATA_G1 <= clamp_8bit(canny_out1);
                DATA_B1 <= clamp_8bit(canny_out1);
            
            //-------------------------------------------------
            // DEFAULT: ORIGINAL IMAGE
            //-------------------------------------------------
            `else

                DATA_R0 <= org_R[WIDTH*row + col];
                DATA_G0 <= org_G[WIDTH*row + col];
                DATA_B0 <= org_B[WIDTH*row + col];

                DATA_R1 <= org_R[WIDTH*row + col + 1];
                DATA_G1 <= org_G[WIDTH*row + col + 1];
                DATA_B1 <= org_B[WIDTH*row + col + 1];

            `endif

            //-------------------------------------------------
            // UPDATE COLUMN AND ROW
            //-------------------------------------------------
            if(col >= WIDTH-2) begin
                col <= 0;
                row <= row + 1;
            end
            else begin
                col <= col + 2;
            end

            data_count <= data_count + 1;
        end
        else begin
            HSYNC <= 0;
        end
    end
end

endmodule
