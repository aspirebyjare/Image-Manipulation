# Image Manipulation Project

## Description

This was school project for an Assembly course at my univeristy. It is a C++ program that interfaces with assembly language routines to manipulate BMP image files. The program provides several functionalities, including converting an image to grayscale, brightening an image, and darkening an image. The imageCvt.cpp was provided for the assignment. I crafted the logic in the .asm files. ast11 is primarily about getting my .asm file to work correctly with the provided .cpp file. ast11b was an exercise to introduce us students to the importance of buffer size, as we changed the buffer capacity from 1,000,000 to 2! 



## Features

- **Grayscale Conversion**: Converts the image to a grayscale version by averaging the RGB values for each pixel.
- **Brighten Image**: Increases the brightness of the image by adjusting the pixel values.
- **Darken Image**: Reduces the brightness of the image by halving the pixel values.

## Installation

To run this project, you need to have `g++` installed on your machine. Use the following steps to compile and run the program:

1. **Install g++**:
    ```bash
    sudo apt-get install g++
    ```

2. **Compile the program**:
    ```bash
    g++ main.cpp -o imageCvt -no-pie
    ```

3. **Run the program** with the appropriate arguments:
    ```bash
    ./imageCvt <-gr|-br|-dk> <inputFile.bmp> <outputFile.bmp>
    ```

    - `-gr`: Convert the image to grayscale
    - `-br`: Brighten the image
    - `-dk`: Darken the image

## Usage Example

Here’s how to use the program with a BMP image:

```bash
./imageCvt -gr inputImage.bmp outputImage.bmp