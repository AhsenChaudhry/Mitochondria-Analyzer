# Mitochondria Analyzer

Mitochondria Analyzer is a plugin for ImageJ/Fiji that enables quantitative analysis of mitochondrial morphology, dynamics, and function from confocal microscope acquired images of fluorescently labelled mitochondria.

It entails a set of commands that allows for identifying mitochondrial objects from images through a validated pipeline of processing & thresholding, extraction of morphological and networking descriptors on a per-cell or per-mito basis, and simultaneous "morpho-functional" assessment of mitochondria co-stained with structural and functional probes.

This plugin facilitates some of the key steps in an overall pipeline of image-based mitochondrial analysis, which begins with rigorously optimized acquisiton conditions and deconvolution for 3D/4D files (mainly to improve axial resolution). Importantly, the pipeline and this plugin have been optimized for axially thick cells, such as pancreatic beta-cells. More details can be found in the accompanying paper.

## Features
* Handles 2D, 3D, 2D Timelapse, and 3D Timelapse (4D) images
* Commands to identify mitochondrial objects based on a pipeline of image processing and adaptive thresholding, which can be further tailored by the user
* Commands to extract morphological and networking descriptors on a per-cell or per-mito basis
* Ability to perform morpho-functional assessment by simultaneous morphologic quantification with functional probe intensity measurement
* Commands to test and identify optimal processing and thresholding settings to maximize accuracy of threshold
* Source code for commands are written in ImageJ macro language, allowing user to easily view and modify them as desired.
* Support for automated batch processing of multiple images and folders
* Optimized for axially thick cells

## Installation
There are 2 methods for installation.

**Method 1 (Preferred)**

Add the Mitochondria Analyzer Update Site to download all required files and automatically receive updates when available. To do this:
1)	On the ImageJ menu, go to Help -> Update… to open the ImageJ Updater window
2)	Select ‘Manage Update Sites’
3)	Select the checkboxes beside the following:
    1) 3D ImageJ Suite
    2)	Press “Add Update Site’ at the bottom. This will create a new entry.
    3)	Under ‘Name’ column, type in “MiochondriaAnalyzer”
    4)	Under URL column, copy and paste this: http://sites.imagej.net/ACMito/
    5)	Note: this also installs Adaptive Thresholding and Sigma Filter Plus
5)	Press ‘Close’, then press ‘Apply Changes’ in the ImageJ Updater window
6)	Restart ImageJ, and the installation process should be complete.

**Method 2**

Download and open the MitochondriaAnalyzer.zip file and copy its contents to the ImageJ/FIJI “plugins” folder. This includes the MitochondriaAnalyzer folder as well as the dependent plugins listed above. 
*	The imagescience.jar file (required for the 3D ImageJ Suite) must be downloaded separately here [(Link)](https://imagescience.org/meijering/software/featurej/)

## Usage
Please refer to the Mitochondria Analyzer Manual and accompanying paper for guidance on use.
