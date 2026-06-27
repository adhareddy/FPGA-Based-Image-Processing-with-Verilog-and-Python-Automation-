from PIL import Image, ImageOps, ImageSequence
from pathlib import Path
import os

# --------------------------------------------------
# PROJECT OUTPUT FILE NAMES
# --------------------------------------------------
HEX_FILE_NAME = "input.hex"
PARAM_FILE_NAME = "parameter.v"
OUTPUT_BMP_NAME = "output.bmp"

# --------------------------------------------------
# PATH CLEANING FUNCTION
# --------------------------------------------------
def clean_path(path):
    """
    Accepts paths with or without quotes.
    Example:
    "C:\\Users\\AdhaReddy Y\\Desktop\\image.jpeg"
    C:\\Users\\AdhaReddy Y\\Desktop\\image.jpeg
    """
    path = path.strip()
    path = path.strip('"').strip("'")

    # Sometimes copied paths from PowerShell start with &
    if path.startswith("& "):
        path = path[2:].strip().strip('"').strip("'")

    return os.path.normpath(path)


# --------------------------------------------------
# IMAGE COMPATIBILITY FUNCTION
# --------------------------------------------------
def make_image_compatible(img):
    """
    Your Verilog design processes 2 pixels per clock.
    Also, 24-bit BMP rows are easiest when width is multiple of 4.

    So this function pads image width to next multiple of 4.
    It does NOT crop the image, so no image content is lost.
    """

    width, height = img.size

    # Minimum width required for stable 2-pixel processing
    if width < 4:
        new_width = 4
    else:
        remainder = width % 4
        if remainder == 0:
            new_width = width
        else:
            new_width = width + (4 - remainder)

    new_height = height

    if new_width != width:
        print(f"⚠ Image width adjusted from {width} to {new_width} for Verilog compatibility.")

        # Create new image with black padding
        new_img = Image.new("RGB", (new_width, new_height), (0, 0, 0))

        # Paste original image at left side
        new_img.paste(img, (0, 0))

        return new_img

    return img


# --------------------------------------------------
# USER INPUT
# --------------------------------------------------
img_path = input("Enter image path: ")
img_path = clean_path(img_path)

if not os.path.isfile(img_path):
    print("❌ Error: File not found!")
    print("Entered path:", img_path)
    exit()

# --------------------------------------------------
# LOAD IMAGE SAFELY
# --------------------------------------------------
try:
    img = Image.open(img_path)

    # If image is animated GIF/WebP/TIFF, take first frame
    try:
        img = next(ImageSequence.Iterator(img))
    except Exception:
        pass

    # Fix phone camera EXIF rotation
    img = ImageOps.exif_transpose(img)

    # Convert any image type to RGB
    img = img.convert("RGB")

except Exception as e:
    print("❌ Error: Cannot open or process image!")
    print(e)
    exit()

# --------------------------------------------------
# MAKE IMAGE SIZE COMPATIBLE WITH VERILOG
# --------------------------------------------------
original_width, original_height = img.size
img = make_image_compatible(img)

width, height = img.size

print(f"\nOriginal Image Size : {original_width} x {original_height}")
print(f"Verilog Image Size  : {width} x {height}")

# --------------------------------------------------
# SELECT FILTER
# --------------------------------------------------
print("\nSelect filter:")
print("1. Brightness")
print("2. Invert")
print("3. Threshold")
print("4. Sobel Edge Detection")
print("5. Gaussian Blur")
print("6. Canny Edge Detection")

choice = input("Enter choice (1-6): ").strip()

# --------------------------------------------------
# BRIGHTNESS SUB-OPTION
# --------------------------------------------------
brightness_choice = ""

if choice == "1":
    print("\nSelect Brightness Operation:")
    print("1. Increase Brightness")
    print("2. Decrease Brightness")
    brightness_choice = input("Enter brightness choice (1-2): ").strip()

# --------------------------------------------------
# SAVE FILES IN SAME FOLDER AS THIS PYTHON SCRIPT
# --------------------------------------------------
project_folder = Path(__file__).resolve().parent

hex_file_path = project_folder / HEX_FILE_NAME
param_file_path = project_folder / PARAM_FILE_NAME

# --------------------------------------------------
# GENERATE HEX FILE
# --------------------------------------------------
# Pixel order: bottom-to-top to match BMP/Verilog image flow
with open(hex_file_path, "w") as f:
    for y in range(height - 1, -1, -1):
        for x in range(width):
            r, g, b = img.getpixel((x, y))
            f.write(f"{r:02X}\n")
            f.write(f"{g:02X}\n")
            f.write(f"{b:02X}\n")

print(f"\n✅ HEX file created: {hex_file_path}")

# --------------------------------------------------
# GENERATE parameter.v
# --------------------------------------------------
with open(param_file_path, "w") as f:
    # File configuration
    f.write(f'`define INPUTFILENAME "{HEX_FILE_NAME}"\n')
    f.write(f'`define OUTPUTFILENAME "{OUTPUT_BMP_NAME}"\n\n')

    # Image size configuration
    f.write(f'`define IMG_WIDTH {width}\n')
    f.write(f'`define IMG_HEIGHT {height}\n\n')

    # --------------------------------------------------
    # Filter selection
    # Only one operation must be active at a time
    # --------------------------------------------------

    if choice == "1":
        if brightness_choice == "1":
            f.write('`define INCREASE_BRIGHTNESS_OPERATION\n')
            f.write('//`define DECREASE_BRIGHTNESS_OPERATION\n')
            print("✅ Selected Filter: Increase Brightness")

        elif brightness_choice == "2":
            f.write('//`define INCREASE_BRIGHTNESS_OPERATION\n')
            f.write('`define DECREASE_BRIGHTNESS_OPERATION\n')
            print("✅ Selected Filter: Decrease Brightness")

        else:
            print("⚠ Invalid brightness choice, defaulting to Increase Brightness")
            f.write('`define INCREASE_BRIGHTNESS_OPERATION\n')
            f.write('//`define DECREASE_BRIGHTNESS_OPERATION\n')

        f.write('//`define INVERT_OPERATION\n')
        f.write('//`define THRESHOLD_OPERATION\n')
        f.write('//`define SOBEL_OPERATION\n')
        f.write('//`define GAUSSIAN_OPERATION\n')
        f.write('//`define CANNY_OPERATION\n')

    elif choice == "2":
        f.write('//`define INCREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define DECREASE_BRIGHTNESS_OPERATION\n')
        f.write('`define INVERT_OPERATION\n')
        f.write('//`define THRESHOLD_OPERATION\n')
        f.write('//`define SOBEL_OPERATION\n')
        f.write('//`define GAUSSIAN_OPERATION\n')
        f.write('//`define CANNY_OPERATION\n')
        print("✅ Selected Filter: Invert Operation")

    elif choice == "3":
        f.write('//`define INCREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define DECREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define INVERT_OPERATION\n')
        f.write('`define THRESHOLD_OPERATION\n')
        f.write('//`define SOBEL_OPERATION\n')
        f.write('//`define GAUSSIAN_OPERATION\n')
        f.write('//`define CANNY_OPERATION\n')
        print("✅ Selected Filter: Threshold Operation")

    elif choice == "4":
        f.write('//`define INCREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define DECREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define INVERT_OPERATION\n')
        f.write('//`define THRESHOLD_OPERATION\n')
        f.write('`define SOBEL_OPERATION\n')
        f.write('//`define GAUSSIAN_OPERATION\n')
        f.write('//`define CANNY_OPERATION\n')
        print("✅ Selected Filter: Sobel Edge Detection")

    elif choice == "5":
        f.write('//`define INCREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define DECREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define INVERT_OPERATION\n')
        f.write('//`define THRESHOLD_OPERATION\n')
        f.write('//`define SOBEL_OPERATION\n')
        f.write('`define GAUSSIAN_OPERATION\n')
        f.write('//`define CANNY_OPERATION\n')
        print("✅ Selected Filter: Gaussian Blur")

    elif choice == "6":
        f.write('//`define INCREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define DECREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define INVERT_OPERATION\n')
        f.write('//`define THRESHOLD_OPERATION\n')
        f.write('//`define SOBEL_OPERATION\n')
        f.write('//`define GAUSSIAN_OPERATION\n')
        f.write('`define CANNY_OPERATION\n')
        print("✅ Selected Filter: Canny Edge Detection")

    else:
        print("⚠ Invalid choice, defaulting to Increase Brightness")
        f.write('`define INCREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define DECREASE_BRIGHTNESS_OPERATION\n')
        f.write('//`define INVERT_OPERATION\n')
        f.write('//`define THRESHOLD_OPERATION\n')
        f.write('//`define SOBEL_OPERATION\n')
        f.write('//`define GAUSSIAN_OPERATION\n')
        f.write('//`define CANNY_OPERATION\n')

print(f"✅ parameter.v updated automatically: {param_file_path}")

# --------------------------------------------------
# FINAL MESSAGE
# --------------------------------------------------
print("\n✅ Python preprocessing completed successfully.")
print("Generated files:")
print(f"1. {HEX_FILE_NAME}")
print(f"2. {PARAM_FILE_NAME}")

print("\n🚀 Now go to ModelSim:")
print("➡️  In transcript window type: do run.do.txt")