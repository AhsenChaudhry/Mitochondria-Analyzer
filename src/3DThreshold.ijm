/*
Author: Ahsen Chaudhry
Last updated: November 25, 2022
This macro performs a threshold on a 3D stack using local threshold algorithms based on variants of mean-based thresholding.
It takes two important parameters: block size (expressed as a diameter for Weighted Mean and as radius for the rest), and C-value.
These parameters can be chosen using the Optimize Threshold macros.
*/

macro Threshold3D
{
	macroFolder = getDirectory("plugins") + "MitochondriaAnalyzer/Macros/";
	regularMode=true;
	batchMode = false;
	optimizeMode = false;
	preProcessOnly = false;
	if (getArgument()=="Batch") batchMode=true;
	if (getArgument()=="Optimize") optimizeMode=true;
	if (getArgument()=="PrePro") preProcessOnly=true;

	if (getArgument()!="") regularMode=false;
	
	input = getTitle();

	//The default block size is set to 1.25um, which is slightly larger than the upper-range of mitochondrial sizes
	getPixelSize(unit, pixelWidth, pixelHeight);
	baseSize = 1.25;//(1.25 / pixelWidth);
	adaptiveSize = baseSize;
	baseSubtract = 10;
	adaptiveSubtract = baseSubtract;

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

	if (regularMode)
	{
		Dialog.create("3D Threshold");
			Dialog.setInsets(-5, 0, 0);
		    Dialog.addMessage("This function will perform a threshold on a 3D stack.");
		    Dialog.setInsets(-5, 15, 0);
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
			Dialog.addCheckbox("Show comparison of threshold to original?", showComparison) 
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
		showComparison = Dialog.getCheckbox();
		canAnalyze = Dialog.getCheckbox();
	}
		
	if (batchMode==true || optimizeMode==true || preProcessOnly==true)
    { 
        parameters = File.openAsString(getDirectory("temp") + "3DBatchThresholdTemp.txt"); 
        parLines = split(parameters,"\n"); 
		
		canSubtract = parseInt(parLines[0]); 
		rolling = parseFloat(parLines[1]); 
	    canSigma = parseInt(parLines[2]); 
		canEnhance = parseInt(parLines[3]); 
		slope = parseFloat(parLines[4]);
		canScaleEnhance =parseFloat(parLines[5]);
		scaleSlopeTo =parseFloat(parLines[6]);
		scaleBegin = parseFloat(parLines[7]);
		scaleEnd = parseFloat(parLines[8]);
		canGamma = parseInt(parLines[9]); 
		method = parLines[10]; 
		adaptiveSize = parseFloat(parLines[11]); 
		adaptiveSubtract = parseFloat(parLines[12]); 
		canDespeckle = parseInt(parLines[13]); 
		canRemove = parseInt(parLines[14]); 
		canFill = parseInt(parLines[15]); 
    }	



	setBatchMode(true);
	
		input = getTitle();
		output = input + " thresholded";
		Stack.getPosition(c,s,f);
		run("Duplicate...", "duplicate channels=" + c + "-" + c + "frames=" + f + "-" + f);
		rename(output);
		


		//Pre-processing steps
			//Convert values for pre-processing plugins to pixels
			getPixelSize(unit, pixelWidth, pixelHeight);
			sRadius = 2;// * (0.06 / pixelWidth); //uses the default values of the sigma filter plugin, and scales to pixel size.
				//I removed the scale feature as it was casuing issues with pixelwidth values >0.2 microns
			rolling = rolling / pixelWidth;
			maxSlices = nSlices;

			adaptiveSize = (adaptiveSize / pixelWidth);
			//if (!preProcessOnly) round(adaptiveSize);

			if (optimizeMode==false)
			{
			    //Reduces background noise. Adjust the rolling parameter if needed.
				if (canSubtract) run("Subtract Background...", "rolling=" + rolling + " stack sliding");
				//Smooths object edges and improves contrast between signal and background noise. Essential for thresholding.
				if (canSigma) run("Sigma Filter Plus", "radius=" + sRadius + " use=2.0 minimum=0.2 outlier stack");
				//Enhances signal-to-noise contrast, great for areas of mitochondria with heterogenous intensity	
				if (canEnhance) 	
				{	
					slopeValue = slope;
					startS = round(maxSlices*scaleBegin);
					endS = round(maxSlices*scaleEnd);
					if (startS<1 || endS<1 || startS>=endS) canScaleEnhance=false;
					for (i = 1;i<=maxSlices;i++)
					{
						setSlice(i);
						if (i>1 && canScaleEnhance && i>=startS && i<=endS)
						{
							slopeM = ( (scaleSlopeTo-slope) / ( endS - startS ) );
							slopeValue = slope + ( (i-startS)*slopeM);
						}
						enhanceBS=64;
						width = getWidth(); height = getHeight();
						if (width<33 || height<33)
						{
							if (width<height) enhanceBS = (width*2)-1;
							else enhanceBS = (height*2)-1;
						}
						run("Enhance Local Contrast (CLAHE)", "blocksize=" + enhanceBS + " histogram=256 maximum=" + slopeValue + " mask=*None* fast_(less_accurate)");
					}
				}	
				//Gamma correction enhances recognition of dim mitochondria. For 2D this has been set to 0.8, whereas it is 0.9 in 3D
				//as we do not wish to capture mitochonrdria that are bleeding in from adjacent planes.
				if (canGamma) run("Gamma...", "value=" + gamma + " stack");
				//The next step is optional and is only useful for images with heavy noise, as it further removes background.
				setMinAndMax(5,255);
				run("Apply LUT", "stack");
			}
			if (preProcessOnly) exit();
		//Thresholding step
			if (method=="Weighted Mean")
			{
				//Weighted Mean method is done using the Adaptive Threshold plugin
				//Note that adaptiveSize = diameter here
				for (i = 1;i<=maxSlices;i++)
				{
					setSlice(i);
					run("adaptiveThr ", "using=[Weighted mean] from=" + adaptiveSize + " then=-" + adaptiveSubtract + " slice");
				}
			}
			else
			{
				//The other methods are done using the native ImageJ/Fiji local threshold methods
				//Note that adaptiveSize = radius here so we need to divide the block size, which is expressed as a diameter
				run("Auto Local Threshold", "method=" + method + " radius=" + (adaptiveSize/2) + " parameter_1=-" + adaptiveSubtract + " parameter_2=0 white stack");
			}
	
		//Post thresholding clean-up to remove any enclosed holes and small particles
			outlierRadius = 3 ;//* ( 0.055 / pixelWidth);
			if (canDespeckle) run("Despeckle", "stack");
			if (canRemove) run("Remove Outliers...", "radius=" + (outlierRadius) + " threshold=50 which=Bright stack");
			if (canFill) run("3D Fill Holes");

			
		if (showComparison==true)
		{
			selectWindow(input);
			run("Duplicate...", "duplicate");
			rename(input + "$$TEMP");
			selectWindow(output);
			run("Duplicate...", "duplicate");
			rename(output + "$$TEMP");
			run("Merge Channels...", "c1=[" + output + "$$TEMP]" + " c2=[" + input + "$$TEMP]" + " create ignore");
			Stack.setDisplayMode("color");
			rename(output + "_COMPARISON");
			
		}
		
	if (optimizeMode==false) setBatchMode("exit and display");
	
	if (canAnalyze==true)
	{
		selectWindow(output);
		tmpBatchFile = File.open(getDirectory("temp") + "3DBatchAnalysisTemp.txt");
		print(tmpBatchFile, "Default");
		File.close(tmpBatchFile);
		runMacro(macroFolder + "3DAnalysis.ijm","Batch");
	}

    //logThreshold();

    function logThreshold()
    {
    	print(" ");
    	print(input + " 3D Threshold Settings Log");
    	print("Subtract Background? " +  canSubtract );
		print("Rolling: " +   (rolling * pixelWidth));
		print("Sigma Filter? " +  canSigma );
		print("Enhance: " +  canEnhance );
		print("Slope: " +  slope );
		print("Scale Enhance? " +  canScaleEnhance );
		print("Scale To: " +  scaleSlopeTo );
		print("Scale begin: " +  scaleBegin );
		print("Scale end: " +  scaleEnd );
		print("Adjust Gamma: " +  canGamma );
		print("Threshold Method: " +  method );
		print("Block Size: " +  adaptiveSize );
		print("Block Size: " +  (adaptiveSize*pixelWidth) );
		print("Despeckle? " +  canDespeckle );
		print("Remove Outliers? " +  canRemove );
		print("3D Fill? " +  canFill );
    }
}
