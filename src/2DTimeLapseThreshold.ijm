/*
Author: Ahsen Chaudhry
Last updated: April 27, 2022
This macro performs a threshold on a timelapse of 2D slices (xyt).
*/

macro TimeLapseThreshold2D
{
	input = getTitle();
	macroFolder = getDirectory("plugins") + "MitochondriaAnalyzer/Macros/";
	
	//The default block size is set to 1.25um, which is slightly larger than the upper-range of mitochondrial sizes
	baseSize = 1.25;
	baseSubtract = 10;

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

	//Perform automatic analysis?
	canAnalyze = false;
	
	methodChoices = newArray("Weighted Mean","Mean","Median","MidGrey");
	method = methodChoices[0];

	Dialog.create("2D TimeLapse Threshold");
		Dialog.setInsets(-5, 0, 0);
	    Dialog.addMessage("This function will perform a threshold on a timelapse of 2D slices (xyt stack).");
	    Dialog.setInsets(-5, 15, 0);
		Dialog.addMessage("The selected input is: " + input);

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
	
			Dialog.addMessage("Please select the local threshold method:");
			Dialog.setInsets(0, 30, 0);
			Dialog.addChoice("Method:",methodChoices,method);
			
			Dialog.setInsets(5, 30, 0);
			Dialog.addNumber("Block Size", baseSize,3,4,"microns");
			Dialog.addToSameRow() ;
			Dialog.addNumber("C-Value", baseSubtract,0,3,"");
			
	  		Dialog.setInsets(20, 20, 0);
			Dialog.addMessage("Post-processing commands:");
			labels = newArray("Despeckle","Remove Outliers");
			defaults = newArray(canDespeckle,canRemove);
			Dialog.setInsets(0, 30, 0);
		    Dialog.addCheckboxGroup(1,2,labels,defaults);
	
			Dialog.addMessage("");
			Dialog.addCheckbox("Automatically perform analysis?", canAnalyze);
			Dialog.setInsets(-5, 35, 0);
			Dialog.addMessage("(using default analysis settings)");
		Dialog.show();

	canSubtract = Dialog.getCheckbox();
	rolling = Dialog.getNumber();
	canSigma = Dialog.getCheckbox();
	canEnhance = Dialog.getCheckbox();
	slope = Dialog.getNumber();
	canGamma = Dialog.getCheckbox();
	gamma = Dialog.getNumber();
	method = Dialog.getChoice();
	adaptiveSize = Dialog.getNumber();
	adaptiveSubtract = Dialog.getNumber();
	canDespeckle = Dialog.getCheckbox();
	canRemove = Dialog.getCheckbox();
	canAnalyze = Dialog.getCheckbox();
	//The default block size is set to 1.25um, which is slightly larger than the upper-range of mitochondrial sizes
	getPixelSize(unit, pixelWidth, pixelHeight);
	baseSize = 1.25;
	baseSubtract = 10;

	TransferSettings();

	original = getTitle();
	Stack.getDimensions(w, h, channels, slices, frames);
	if ( (slices>1 && frames>1) || (frames==1)) exit("Needs XYT input");

	if (canAnalyze) 
	{
		tmpBatchFile = File.open(getDirectory("temp") + "2DBatchAnalysisTemp.txt");
		print(tmpBatchFile, "Default");
		File.close(tmpBatchFile);
	}
	
	for (i=1;i<=frames;i++)
	{
		selectWindow(original);
		Stack.setFrame(i);
		Stack.getPosition(c,s,f);
 		run("Duplicate...", "duplicate channels=" + c + " frames=" + f);
		name = original + " Frame: " + i;
		rename(name);
		runMacro(macroFolder + "2DThreshold.ijm","Batch");

		if (canAnalyze) runMacro(macroFolder + "2DAnalysis.ijm","Batch");

		if (i>1)
		{
			run("Concatenate...", "open image1=[" + original+ " Frame: " + (i-1) + " thresholded] image2=[" + name + " thresholded] image3=[-- None --]");
			rename(name + " thresholded");
		}
		close(name);
	}
	selectWindow(original + " Frame: " + frames + " thresholded");
	rename(original + " XYT-thresholded");

	function TransferSettings()
	{
		tmpBatchFile = File.open(getDirectory("temp") + "2DBatchThresholdTemp.txt");
		print(tmpBatchFile, canSubtract );
		print(tmpBatchFile, rolling );
		print(tmpBatchFile, canSigma );
		print(tmpBatchFile, canEnhance );
		print(tmpBatchFile, slope );
		print(tmpBatchFile, canGamma );
		print(tmpBatchFile, method );
		print(tmpBatchFile, adaptiveSize );
		print(tmpBatchFile, adaptiveSubtract );
		print(tmpBatchFile, canDespeckle );
		print(tmpBatchFile, canRemove );
		File.close(tmpBatchFile);
	}
}
