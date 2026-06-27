`timescale 1ns/1ps
/**************************************************************************/
/******************** Testbench for simulation ****************************/
/**************************************************************************/
`include "parameter.v"

module tb_simulation;

//-------------------------------------------------
// Internal Signals
//-------------------------------------------------
reg HCLK, HRESETn;

wire vsync;
wire hsync;

wire [7:0] data_R0;
wire [7:0] data_G0;
wire [7:0] data_B0;
wire [7:0] data_R1;
wire [7:0] data_G1;
wire [7:0] data_B1;

wire enc_done;
wire write_done;   // ? added

//-------------------------------------------------
// Instantiate image_read
//-------------------------------------------------
image_read u_image_read
( 
    .HCLK      (HCLK),
    .HRESETn   (HRESETn),
    .VSYNC     (vsync),
    .HSYNC     (hsync),
    .DATA_R0   (data_R0),
    .DATA_G0   (data_G0),
    .DATA_B0   (data_B0),
    .DATA_R1   (data_R1),
    .DATA_G1   (data_G1),
    .DATA_B1   (data_B1),
    .ctrl_done (enc_done)
); 

//-------------------------------------------------
// Instantiate image_write
//-------------------------------------------------
image_write u_image_write
(
    .HCLK(HCLK),
    .HRESETn(HRESETn),
    .hsync(hsync),

    .DATA_WRITE_R0(data_R0),
    .DATA_WRITE_G0(data_G0),
    .DATA_WRITE_B0(data_B0),

    .DATA_WRITE_R1(data_R1),
    .DATA_WRITE_G1(data_G1),
    .DATA_WRITE_B1(data_B1),

    .Write_Done(write_done)   // ? connected
);	

//-------------------------------------------------
// Clock Generation (50 MHz)
//-------------------------------------------------
initial begin 
    HCLK = 0;
    forever #10 HCLK = ~HCLK;
end

//-------------------------------------------------
// Reset Generation (50ns)
//-------------------------------------------------
initial begin
    HRESETn = 0;
    #50;
    HRESETn = 1;
end

//-------------------------------------------------
// Debug (optional)
//-------------------------------------------------
initial begin
    $display("Starting Simulation...");
    $display("Input File  : %s", `INPUTFILENAME);
    $display("Output File : %s", `OUTPUTFILENAME);
end

//-------------------------------------------------
// Simulation Control
//-------------------------------------------------
initial begin
    wait(write_done);   // wait for file writing complete
    #200;
    $display("Simulation Finished Successfully");
    $stop;
end

endmodule
