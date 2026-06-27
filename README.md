# FPGA-Based-Image-Processing-with-Verilog-and-Python-Automation-
📌 Overview

This project implements an FPGA-based image processing system using Verilog HDL with a Python automation pipeline. The system converts input images into memory-compatible HEX format, processes pixel data using Verilog hardware logic, and generates the processed output image.

The project demonstrates the integration of hardware acceleration, image processing, and software automation.

🚀 Features
Image conversion from BMP/JPG/PNG to HEX format using Python
Automatic image size detection and Verilog configuration generation
Pixel-level image processing using Verilog HDL
Memory-based image storage and processing
Automated simulation workflow with ModelSim
Output image generation after FPGA processing
🏗️ System Architecture
Input Image
    ↓
Python Image Converter
    ↓
HEX Memory File + Configuration
    ↓
Verilog Image Processing Module
    ↓
Processed Pixel Data
    ↓
Output Image
🛠️ Technologies Used
Hardware Design
Verilog HDL
FPGA Design Concepts
Image Processing Algorithms
Memory Interface
Software Tools
Python
Pillow (PIL)
Intel Quartus Prime
ModelSim Simulation
⚙️ Working Principle
User provides an input image.
Python script automatically:
Reads image dimensions
Converts RGB pixel values into HEX format
Generates Verilog configuration file
Verilog module loads image data into memory.
Pixel data is processed using hardware logic.
Processed output is generated and converted back into an image.
📂 Project Structure
FPGA-Image-Processing/
│
├── Verilog/
│   ├── image_processing.v
│   ├── image_read.v
│   └── testbench.v
│
├── Python/
│   ├── image_to_hex.py
│   └── hex_to_image.py
│
├── Memory/
│   ├── image.hex
│   └── config.vh
│
└── README.md
▶️ How to Run
1. Install Python dependency
pip install pillow
2. Convert image to HEX
python image_to_hex.py
3. Run Verilog simulation

Compile and simulate using:

Quartus Prime
ModelSim
4. View Output

Generated processed image can be viewed after HEX-to-image conversion.

📈 Applications
FPGA-based image processing
Embedded vision systems
Hardware acceleration
Real-time image processing
Computer vision applications
🔮 Future Improvements
Real-time camera input support
VGA display interface
Edge detection implementation
CNN-based image classification acceleration
FPGA hardware deployment
👨‍💻 Author

Adhareddy Y
Electronics & Communication Engineering
Interested in FPGA Design, VLSI, Embedded Systems, and Digital Hardware Acceleration
