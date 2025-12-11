# 📘 License Plate Recognition in MATLAB

*A Homework Assignment for Image & Signal Processing (Category 3 Task)*

## 🎯 Overview

This project implements a **License Plate Recognition (LPR)** system in **MATLAB**, created as part of the **ELTE MSc Image & Signal Processing – Homework A3** assignment.

The goal is to **detect**, **segment**, and **recognize** characters from license plates using classical image-processing techniques such as:

* contrast enhancement (CLAHE)
* edge detection (Sobel)
* morphological filtering
* connected component analysis
* Otsu thresholding
* character segmentation
* template-based character recognition (correlation)

This solution was developed under the constraints of **Category 3**, meaning **advanced MATLAB functions may be used**, but the approach must combine **core image processing steps creatively**.

---

## 📁 Repository Structure

```
📦 License-Plate-Recognition-MATLAB
 ┣ 📂 data/                # Test images provided for evaluation
 ┣ 📂 templates/           # Character template data (imgfildata.mat)
 ┣ 📂 results/             # Generated text outputs and figures
 ┣ 📜 license_plate_recognition.m
 ┣ 📜 README.md
 ┗ 📜 number_Plate_Optimized.txt
```

---

## 🧪 Example Input Images (from /data)

Here are some example license plate images included in the repository:

| Example 1                 | Example 2                 | Example 3                 |
| ------------------------- | ------------------------- | ------------------------- |
| ![1st Car](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/data/car_image.JPG) | ![2nd Car](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/data/P9170019.JPG) | ![3rd Car](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/data/P9170033.JPG) |

These images contain different lighting conditions, contrast levels, and backgrounds to test robustness.

---

## 🧩 Method Pipeline

The processing pipeline follows these steps:

### **1. Load + Preprocess Templates**

* Load `imgfildata.mat`
* Convert to grayscale, binarize, and resize to a uniform **42×24** template size

![Original Image](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-original.png)


### **2. Load Image & Convert to Grayscale**

* Read photo using `uigetfile`
* Convert using `im2gray`

### **3. Local Contrast Enhancement**

* Apply CLAHE (`adapthisteq`)
* Improves visibility of plate edges

![Contrast Enhancement](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-contrast-enhanced.png)

### **4. Sobel Edge Detection**

* Generate an edge map
* Enhances horizontal and vertical plate boundaries


![Edges](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-edges.png)

### **5. Morphological Closing**

* Connect fragmented edges using `strel` + `imclose`

![Morphological Closing](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-closing.png)

### **6. License Plate Region Detection**

* Identify connected components

* Use constraints:

  * area
  * aspect ratio
  * edge-density score

* Select the best candidate bounding box

![Plate Region Detection](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-plate-detected.png)

### **7. Extract Plate with Generous Padding**

Ensures the crop includes the full plate area without cutting letters.


![Extracted Plate](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-extracted-plate.png)

### **8. Binarization and Noise Cleaning**

* Otsu thresholding
* Border removal (`imclearborder`)
* Dilation/erosion to separate characters
* Small noise removal (`bwareaopen`)


![Binarized Plate](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-binarized-plate.png)

### **9. Character Segmentation**

* Connected component filtering based on:

  * area
  * height ratio
  * aspect ratio
  * Croatian emblem filtering
* Sort bounding boxes left-to-right


![Character Segmentation](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-binarized-characters-bounding.png)

### **10. Character Recognition**

* Resize each character → match template size
* Use normalized correlation (`corr2`)
* Best match above confidence threshold ⇒ accepted
* Otherwise ⇒ `?`

![Recognized characters](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-recognized-characters.png)

### **11. Save Results & Visualize**

* Output recognized text
* Save to `number_Plate_Optimized.txt`
* Display:

  * original image
  * extracted plate
  * cleaned binary image with character boxes

![Results](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-whole.png)
---

## ▶️ Running the Program

Open MATLAB and run:

```matlab
recognized_chars = license_plate_recognition();
```

You will be prompted to select a test image.

### **Dependencies**

✔ MATLAB R2021+
✔ Image Processing Toolbox

### **Template File**

Ensure that `imgfildata.mat` is in the templates directory.

---

## 📌 Example Output

```
=== 11. FINAL RESULT ===
Loaded character database with 62 templates

=== ALL DETECTED COMPONENTS ===
Component 1: x=110.5, w=28.0, h=53.0, aspect=0.53, area=713
Component 2: x=145.5, w=29.0, h=52.0, aspect=0.56, area=754
Component 3: x=189.5, w=20.0, h=8.0, aspect=2.50, area=87
Component 4: x=222.5, w=27.0, h=52.0, aspect=0.52, area=605
Component 5: x=266.5, w=10.0, h=50.0, aspect=0.20, area=336
Component 6: x=292.5, w=29.0, h=52.0, aspect=0.56, area=677
Component 7: x=329.5, w=10.0, h=6.0, aspect=1.67, area=60
Component 8: x=347.5, w=29.0, h=54.0, aspect=0.54, area=610
Component 9: x=382.5, w=30.0, h=53.0, aspect=0.57, area=844
Median character height: 52.0

=== FINAL SEGMENTED CHARACTERS ===
Char 1: x=110.5, w=28.0, h=53.0
Char 2: x=145.5, w=29.0, h=52.0
Char 3: x=222.5, w=27.0, h=52.0
Char 4: x=266.5, w=10.0, h=50.0
Char 5: x=292.5, w=29.0, h=52.0
Char 6: x=347.5, w=29.0, h=54.0
Char 7: x=382.5, w=30.0, h=53.0

=== 10. CHARACTER RECOGNITION ===
Char 1: S (confidence: 0.386) - MATCH
Char 2: K (confidence: 0.387) - MATCH
Char 3: 3 (confidence: 0.519) - MATCH
Char 4: j (confidence: 0.416) - MATCH
Char 5: 4 (confidence: 0.458) - MATCH
Char 6: C (confidence: 0.465) - MATCH
Char 7: K (confidence: 0.392) - MATCH

=== 11. FINAL RESULT ===
Recognized License Plate: SK3j4CK
Total execution time: 6.497 seconds
Results saved to number_Plate_Optimized.txt

ans = 'SK3j4CK'
```

### Example Visualization

*(Auto-generated by the script)*

| Original                      | Plate Crop                  | Final Binary + Boxes          |
| ----------------------------- | --------------------------- | ----------------------------- |
| ![orig](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/data/car_image.JPG) | ![plate](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-crop.png) | ![seg](https://github.com/Raphtildai/Licence-Plate-Recognition-Matlab/blob/master/results/SK314CK-Binary+Boxes.png) |
---

## 📄 Assignment Details (ELTE – Homework A3)

This project corresponds to the **Category 3 – License Plate Recognition** task:

> Solve a complex problem creatively using classical signal & image processing
> (FFT, filtering, edge & keypoint detection, segmentation, thresholding, pattern matching…)
---

## 🙏 Acknowledgments

* ELTE MSc Computer Science for Autonomous Systems - "Image and Signal Processing" course
* Task description: [https://bognargergo.web.elte.hu/mscsignal/homeworks/](https://bognargergo.web.elte.hu/mscsignal/homeworks/)
* Dataset: [Test Images](http://www.zemris.fer.hr/projects/LicensePlates/english/results.shtml)

## 📜 License

This project uses the character template file `imgfildata.mat` created by Nishant Kumar (2016) under the BSD License. 

Redistribution and use of the template file must retain the copyright notice and BSD conditions. The MATLAB code in this repository is released for educational purposes and is provided as-is.

The BSD license for the character templates is included in `templates/LICENSE-Kumar.txt`.

---

