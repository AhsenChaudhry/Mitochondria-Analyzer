/*
Author: Ahsen Chaudhry
Last updated: June 1, 2019
This macro performs a montage comparison of different threshold paramaters on a 2D slice.
It takes two important parameters: block size (expressed as a diameter for Weighted Mean and as radius for the rest), and C-value.
These values are empirically determined using this macro for each image set acquired and processed under similair conditions,
and may be used in the 2D Threshold macro.
*/

macro ThresholdOptimize2D
{
	macroFolder = getDirectory("plugins") + "MitochondriaAnalyzer\\Macros\\";
	input = getTitle();

	//Pre-process command variables, see futher explaination later.
	canSubtract = true;
	rolling = 1.25; //corresponds to a value of 1.25 microns.
	canSigma = true;
	canEnhance = true;
	slope = 1.8; //use a higher slope if want to capture more dim mitochondria
	canGamma = true;
	gamma = 0.8;

	//Post-process command variables
	canDespeckle = true;
	canRemove = true;
	
	methodChoices = newArray("Weighted Mean","Mean","Median","MidGrey");
	method = methodChoices[0];
	
	getPixelSize(unit, pixelWidth, pixelHeight);
	baseSize = 1.25;//(1.25 / pixelWidth);
	baseSubtract = 5;
	
	numS = 5;
	numC = 5;
	
	sIncrement = 0.1;
	cIncrement = 2;
	
	fontSize = 20;

	Dialog.create("2D Threshold Optimize");
		Dialog.setInsets(0, 0, 0);
	    Dialog.addMessage("This function will test a range of threshold parameters on a 2D image to determine optimal settings\nby allowing visual comparison to the raw image.");
		Dialog.addMessage("The selected image is: " + input);
	
		Dialog.addMessage("Pre-processing commands:");
	
	    Dialog.setInsets(0, 30, 0);
		Dialog.addCheckbox("Subtract Background", canSubtract);
		Dialog.addToSameRow() ;
		Dialog.addSlider("Rolling (microns):",0.02,2.5,rolling);
		
	    Dialog.setInsets(-5, 30, 0); 
	    Dialog.addCheckbox("Sigma Filter Plus", canSigma);
	
	    Dialog.setInsets(-5, 30, 0); 
	    Dialog.addCheckbox("Enhance Local Contrast", canEnhance);
	    Dialog.addToSameRow() ;
	    Dialog.addSlider("Max Slope:",1.0,3.0,slope);
	
	    Dialog.setInsets(-5, 30, 0); 
	    Dialog.addCheckbox("Adjust Gamma", canGamma);
	    Dialog.addToSameRow() ;
	    Dialog.addSlider("Gamma:",0.1,1.0,gamma);
	
		Dialog.setInsets(0, 20, 0);
		Dialog.addMessage("Post-processing commands:");
		labels = newArray("Despeckle","Remove Outliers");
		defaults = newArray(canDespeckle,canRemove);
		Dialog.setInsets(0, 30, 0);
	    Dialog.addCheckboxGroup(1,2,labels,defaults);
	    
		Dialog.setInsets(20, 20, 0);
		Dialog.addMessage("Please select the threshold method:");
		Dialog.setInsets(0, 30, 0);
		Dialog.addChoice("Method:",methodChoices,method);

		Dialog.setInsets(0, 20, 0);
		Dialog.addMessage("Please select the parameters:");
		
		Dialog.setInsets(10, 30, 0);
		Dialog.addMessage("The default block size diameter in microns is:  " + baseSize + ". The size range will be tested around this.");
		Dialog.setInsets(0, 30, 0);
		Dialog.addNumber("Increment size by:", sIncrement);
		Dialog.setInsets(0, 30, 0);
		Dialog.addNumber("Number of size values to test:", numS);

		Dialog.setInsets(10, 30, 0);
		Dialog.addNumber("Initial C-value:", baseSubtract);
		Dialog.setInsets(0, 30, 0);
		Dialog.addNumber("Increment C-value by:", cIncrement);
		Dialog.setInsets(0, 30, 0);
		Dialog.addNumber("Number of C-values to test:", numC);
	Dialog.show();

	canSubtract = Dialog.getCheckbox();
	rolling = Dialog.getNumber();
	canSigma = Dialog.getCheckbox();
	canEnhance = Dialog.getCheckbox();
	slope = Dialog.getNumber();
	canGamma = Dialog.getCheckbox();
	gamma = Dialog.getNumber();
	canDespeckle = Dialog.getCheckbox();
	canRemove = Dialog.getCheckbox();
	method = Dialog.getChoice();
	sIncrement=Dialog.getNumber();
	numS=Dialog.getNumber();
	baseSubtract=Dialog.getNumber();
	cIncrement=Dialog.getNumber();
	numC=Dialog.getNumber();
	baseSize = baseSize - floor((numS/2))*sIncrement;

    setJustification("left");
    setFont("SansSerif", fontSize);
    setColor(255, 255, 255);

	setBatchMode(true);

		curSlice=getSliceNumber();

		TransferSettings(baseSize,baseSubtract);
		runMacro(macroFolder + "2DThreshold.ijm","PrePro");
		template = input + " template";
		rename(template);

		for (j=0;j<numS;j++)
		{
			for (k=0;k<numC;k++)
			{
				selectWindow(template);
				adaptiveSize = baseSize + (j*sIncrement);
				adaptiveSubtract = baseSubtract + (k*cIncrement);
				TransferSettings(adaptiveSize,adaptiveSubtract);
				runMacro(macroFolder + "2DThreshold.ijm","Optimize");
				rename(template + j + "-" + k);
				drawString("Block Size (pixels) = " + adaptiveSize, 2, fontSize + 2, "black");
		        drawString("Block Size (microns) = " + adaptiveSize*pixelWidth, 2, fontSize*2 + 4, "black");
		        drawString("C value = " + adaptiveSubtract, 2, fontSize*3 + 6, "black");

				selectWindow(input);
				run("Duplicate...", "duplicate range=" + curSlice + "-" + curSlice);
				inputTemp = input + "$$";
				rename(inputTemp + j + "-" + k);
				drawString("Block Size (pixels) = " + adaptiveSize, 2, fontSize + 2, "black");
		        drawString("Block Size (microns) = " + adaptiveSize*pixelWidth, 2, fontSize*2 + 4, "black");
		        drawString("C value = " + adaptiveSubtract, 2, fontSize*3 + 6, "black");
			
				if (k>0)
				{
					run("Concatenate...", "  title=[" + template + j + "-" + k + "] image1=[" + template + j + "-" + (k-1) + "] image2=[" + template + j + "-" + k + "] image3=[-- None --]");	
					run("Concatenate...", "  title=[" + inputTemp + j + "-" + k + "] image1=[" + inputTemp + j + "-" + (k-1) + "] image2=[" + inputTemp + j + "-" + k + "] image3=[-- None --]");
				}
				if (k==0 && j>0)
				{
					run("Concatenate...", "  title=[" + template + j + "-" + k + "] image1=[" + template + (j-1) + "-" + (numC-1) + "] image2=[" + template + j + "-" + k + "] image3=[-- None --]");
					run("Concatenate...", "  title=[" + inputTemp + j + "-" + k + "] image1=[" + inputTemp + (j-1) + "-" + (numC-1) + "] image2=[" + inputTemp + j + "-" + k + "] image3=[-- None --]");
				}
			}
		}
		selectWindow(template + (numS-1) + "-" + (numC-1));
		rename(input + " thresholded stack");
		selectWindow(inputTemp + (numS-1) + "-" + (numC-1));
		rename(input + " original stack");


	close(template);
	
	run("Merge Channels...", "c1=[" + input + " thresholded stack]" + " c2=[" + input + " original stack]" + " create ignore");
	run("Make Montage...", "columns=" + numC + " rows=" + numS + " scale=1 label");
	Stack.setDisplayMode("color");
	rename(input + "_2D-Threshold Test with " + method);
	setBatchMode(false);

	function TransferSettings(size,c)
	{
		tmpBatchFile = File.open(getDirectory("temp") + "2DBatchThresholdTemp.txt");
		print(tmpBatchFile, canSubtract );
		print(tmpBatchFile, rolling );
		print(tmpBatchFile, canSigma );
		print(tmpBatchFile, canEnhance );
		print(tmpBatchFile, slope );
		print(tmpBatchFile, canGamma );
		print(tmpBatchFile, method );
		print(tmpBatchFile, size );
		print(tmpBatchFile, c );
		print(tmpBatchFile, canDespeckle );
		print(tmpBatchFile, canRemove );
		File.close(tmpBatchFile);
	}
}


