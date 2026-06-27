# FPGA-Based-Image-Processing-with-Verilog-and-Python-Automation-
# FPGA-Based Image Processing with Verilog and Python Automation

##  Overview

This project implements an FPGA-based image processing system using **Verilog HDL** and **Python automation**.

The system converts input images into HEX memory format, processes pixel data using Verilog hardware logic, and generates the processed output image.

This project demonstrates the integration of:
- FPGA hardware acceleration
- Digital image processing
- Software automation

---

##  Features

✅ Image conversion (BMP/JPG/PNG → HEX) using Python  
✅ Automatic image size detection  
✅ Automatic Verilog configuration generation  
✅ Memory-based image processing using Verilog HDL  
✅ ModelSim simulation support  
✅ Output image generation after processing  

---

##  System Workflow
Input Image
|
↓
Python Image Converter
|
↓
image.hex + config.vh
|
↓
Verilog Image Processing Module
|
↓
Processed Pixel Data
|
↓
Output Image


---

##  Technologies Used

### Hardware
- Verilog HDL
- FPGA Architecture
- Image Processing Logic
- Memory Interface

### Software
- Python
- Pillow Library
- Intel Quartus Prime
- ModelSim

---

##  Working Principle

1. User provides an input image.

2. Python automation:
   - Reads image dimensions
   - Converts RGB pixel values into HEX format
   - Generates configuration file for Verilog

3. Verilog module:
   - Loads image data into memory
   - Processes pixels using hardware logic

4. Processed data is generated and converted back into an image.

---

## 📂 Project Structure
FPGA-Image-Processing/

│
├── Verilog/
│ ├── image_processing.v
│ ├── image_read.v
│ └── testbench.v
│
├── Python/
│ ├── image_to_hex.py
│ └── hex_to_image.py
│
├── Memory/
│ ├── image.hex
│ └── config.vh
│
└── README.md
