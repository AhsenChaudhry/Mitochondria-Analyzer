/*
Author: Ahsen Chaudhry
Last updated: July 1, 2019
This macro performs a threshold on a 4D (xyzt) stack, meaning 3D stacks acquired over several time frames.
*/

macro TimeLapseThreshold3D
{
	input = getTitle();
	macroFolder = getDirectory("plugins") + "MitochondriaAnalyzer\\Macros\\";

	Stack.getDimensions(w, h, channels, slices, frames);
	if (frames==1 || slices==1) exit("Input must be 4D (xyzt)");

	//The default block size is set to 1.25um, which is slightly larger than the upper-range of mitochondrial sizes
	getPixelSize(unit, pixelWidth, pixelHeight);
	baseSize = 1.25;
	baseSubtract = 10;

	//Pre-process command variables, see futher explaination later.
	canSubtract = true;
	rolling = 1.25; //corresponds to a value of 1.25 microns.
	canSigma = true;
	canEnhance = true;
	canScaleEnhance = false;
	slope = 1.4; //use a higher slope if want to capture more dim mitochondria
	scaleSlopeTo = 2.6;
	scaleBegin = 0.5; //means the position corresponding to 60% of stack's height
	scaleEnd = 0.8;
	canGamma = true;
	gamma = 0.9;

	//Post-process command variables
	canDespeckle = true;
	canRemove = true;
	canFill = true;

	//Show comparison will produce a combined stack with both the raw and thresholded image in seperate channels.
	showComparison = false;

	//Perform automatic analysis?
	canAnalyze = false;
	
	methodChoices = newArray("Weighted Mean","Mean","Median","MidGrey");
	method = methodChoices[0];

	Dialog.create("3D TimeLapse (4D) Threshold");
		Dialog.setInsets(-5, 0, 0);
	    Dialog.addMessage("This function will perform a threshold on a 4D input containing 3D stacks imaged over time.");
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

        Dialog.setInsets(-5, 50, 0); 
        Dialog.addCheckbox("Scale Max Slope through stack", canScaleEnhance);
        Dialog.setInsets(0, 30, 0); 
        Dialog.addNumber("Scale to",scaleSlopeTo);
       	Dialog.setInsets(0, 30, 0); 
        Dialog.addNumber("From slice",scaleBegin,2,2,"(fraction of max slice)");
        Dialog.addToSameRow() ;
        Dialog.addNumber("To slice",scaleEnd,2,2,"(fraction of max slice)");


        Dialog.setInsets(0, 30, 0); 
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
		labels = newArray("Despeckle","Remove Outliers     ", "Fill 3D Holes");
		defaults = newArray(canDespeckle,canRemove,canFill);
		Dialog.setInsets(0, 30, 0);
	    Dialog.addCheckboxGroup(1,3,labels,defaults);

		Dialog.addMessage("");
		//Dialog.addCheckbox("Show comparison of threshold to original?", showComparison) 
		Dialog.addCheckbox("Automatically perform analysis?", canAnalyze);
		Dialog.setInsets(-5, 35, 0);
		Dialog.addMessage("(using default analysis settings)");
	Dialog.show();
			
	canSubtract = Dialog.getCheckbox();
	rolling = Dialog.getNumber();
	canSigma = Dialog.getCheckbox();
	canEnhance = Dialog.getCheckbox();
	slope = Dialog.getNumber();
	canScaleEnhance = Dialog.getCheckbox();
	scaleSlopeTo = Dialog.getNumber();
	scaleBegin = Dialog.getNumber();
	scaleEnd = Dialog.getNumber();
	canGamma = Dialog.getCheckbox();
	gamma = Dialog.getNumber();
	method = Dialog.getChoice();
	adaptiveSize = Dialog.getNumber();
	adaptiveSubtract = Dialog.getNumber();
	canDespeckle = Dialog.getCheckbox();
	canRemove = Dialog.getCheckbox();
	canFill = Dialog.getCheckbox();

	canAnalyze = Dialog.getCheckbox();

	TransferSettings();

	original = getTitle();
	Stack.getDimensions(w, h, channels, slices, frames);

	if (canAnalyze) 
	{
		tmpBatchFile = File.open(getDirectory("temp") + "3DBatchAnalysisTemp.txt");
		print(tmpBatchFile, "Default");
		File.close(tmpBatchFile);
	}
	
	for (i=1;i<=frames;i++)
	{
		selectWindow(original);
		Stack.setFrame(i);
		run("Duplicate...", "duplicate frames=" + i);
		name = original + " Frame: " + i;
		rename(name);
		runMacro(macroFolder + "3DThreshold.ijm","Batch");

		if (canAnalyze) runMacro(macroFolder + "3DAnalysis.ijm","Batch");

		if (i>1)
		{
			run("Concatenate...", "open image1=[" + original+ " Frame: " + (i-1) + " thresholded] image2=[" + name + " thresholded] image3=[-- None --]");
			rename(name + " thresholded");
		}
		close(name);
	}
	selectWindow(original + " Frame: " + frames + " thresholded");
	rename(original + " 4D-thresholded");

	function TransferSettings()
	{
		tmpBatchFile = File.open(getDirectory("temp") + "3DBatchThresholdTemp.txt");
		print(tmpBatchFile, canSubtract );
		print(tmpBatchFile, rolling );
		print(tmpBatchFile, canSigma );
		print(tmpBatchFile, canEnhance );
		print(tmpBatchFile, slope );
		print(tmpBatchFile, canScaleEnhance );
		print(tmpBatchFile, scaleSlopeTo );
		print(tmpBatchFile, scaleBegin );
		print(tmpBatchFile, scaleEnd );
		print(tmpBatchFile, canGamma );
		print(tmpBatchFile, method );
		print(tmpBatchFile, adaptiveSize );
		print(tmpBatchFile, adaptiveSubtract );
		print(tmpBatchFile, canDespeckle );
		print(tmpBatchFile, canRemove );
		print(tmpBatchFile, canFill );
		File.close(tmpBatchFile);
	}
}
