/*
Author: Ahsen Chaudhry
Last updated: November 25, 2022
This macro allows for batch thresholding and analysis of 2D images.
*/

macro Batch2D
{
	macroFolder = getDirectory("plugins") + "MitochondriaAnalyzer/Macros/";
	inputD = getDirectory("Choose which folder to analyze:");
	outputD = inputD; 
	suffix = ".tif";
	
	list = getFileList(inputD);
	if (list.length==0) exit("No images to analyze were found in this folder. Note, this function will only search for .tif files by default");
	
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
	
	methodChoices = newArray("Weighted Mean","Mean","Median","MidGrey");
	method = methodChoices[0];

	morphParameters = newArray("Count","Total Area","Mean Area","Total Perimeter","Mean Perimeter","Mean Aspect Ratio","Mean Form Factor");
	enabledMorphParameters = newArray(0);
	networkParameters = newArray("Branches","Total Branch Length","Mean Branch Length","Branch Junctions","Branch End Points","Mean Branch Diameter");
	enabledNetworkParameters = newArray(0);

	mitoMorphP = newArray("Area","Perimeter","Form Factor","Aspect Ratio");
	enabledMitoMorphP = newArray(0);
    mitoNetworkP = newArray("Branches","Total Branch Length","Mean Branch Length","Branch Junctions","Branch End Points","Mean Branch Diameter","Longest Shortest Path");
	enabledMitoNetworkP = newArray(0);

	doPerCell = true;
	doPerMito = false;


	Dialog.create("2D Batch Threshold and Analysis");
		Dialog.setInsets(-5, 0, 0);
	    Dialog.addMessage("This function allows for batch threshold and/or analysis on a folder of 2D images.");
	    Dialog.setInsets(-5, 0, 0);
	    Dialog.addMessage("Please begin by selecting threshold settings (this step can be omitted for folder of thresholded images).");
	    Dialog.setInsets(5, 5, 0);
	    Dialog.addCheckbox("Perform Batch 2D Threshold",true);
	    
	    Dialog.setInsets(0, 20, 0);
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
		labels = newArray("Despeckle","Remove Outliers");
		defaults = newArray(canDespeckle,canRemove);
		Dialog.setInsets(0, 30, 0);
	    Dialog.addCheckboxGroup(1,2,labels,defaults);

	    Dialog.addMessage("");
		Dialog.setInsets(0, 20, 0);
		Dialog.addCheckbox("Save thresholded images? (will be stored in same folder)", false);
	Dialog.show();
	
	toThreshold = Dialog.getCheckbox();
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
	saveFile = Dialog.getCheckbox();

	Dialog.create("2D Batch Threshold and Analysis");
		Dialog.setInsets(-5, 0, 0);
	    Dialog.addMessage("Proceed by selecting analysis settings (this step can be omitted if only thresholding).");
	    Dialog.setInsets(0, 5, 0);
	    Dialog.addCheckbox("Perform Batch 2D Analysis",true);
	    
		Dialog.addCheckbox("Perform analysis on a per-cell basis?", doPerCell);

		Dialog.setInsets(0, 35, 0);
    	Dialog.addMessage("Per-cell morphologic descriptors:");
	    Dialog.setInsets(0, 40, 0);
	    Dialog.addCheckboxGroup(2,4,morphParameters,Array.fill(newArray(morphParameters.length),true));

		Dialog.setInsets(5, 35, 0);
    	Dialog.addMessage("Per-cell network descriptors:");
	    Dialog.setInsets(0, 40, 0);
	    Dialog.addCheckboxGroup(2,4,networkParameters,Array.fill(newArray(networkParameters.length),true));

		normItems = newArray("Count", "Volume", "Show Both");
		Dialog.setInsets(0, 35, 0);
	    Dialog.addRadioButtonGroup("If analyzing per-cell, then normalize network descriptors to:", normItems, 1, 3, "Count");

		Dialog.setInsets(10, 20, 0);
	    Dialog.addCheckbox("Perform analysis on a per-mito basis?", doPerMito);
	    
		Dialog.setInsets(0, 35, 0);
    	Dialog.addMessage("Per-mito morphologic descriptors:");
	    Dialog.setInsets(0, 40, 0);
	    Dialog.addCheckboxGroup(1,4,mitoMorphP,Array.fill(newArray(mitoMorphP.length),true));

		Dialog.setInsets(5, 35, 0);
    	Dialog.addMessage("Per-mito network descriptors:");
	    Dialog.setInsets(0, 40, 0);
	    Dialog.addCheckboxGroup(2,4,mitoNetworkP,Array.fill(newArray(mitoNetworkP.length),true));

		Dialog.setInsets(5, 40, 0);
		Dialog.addCheckbox("Multiple Channel Analysis?",false);
	    Dialog.setInsets(-5, 40, 0);
		Dialog.addMessage("All channels should be combined in the same file, and requires per-mito analysis enabled");
	    Dialog.setInsets(-5, 40, 0);
		Dialog.addMessage("Note: The selected mask channel will be used for the threholding step.");
		Dialog.setInsets(0, 40, 0);
		Dialog.addNumber("Morphological Mask Channel", 1);
		Dialog.addToSameRow();
		Dialog.addString("Mask Channel Name","Mask");
		Dialog.setInsets(0, 40, 0);
		Dialog.addNumber("Second Channel", 0);
		Dialog.addToSameRow();
		Dialog.addString("Second Channel Name","Channel 2");
		Dialog.setInsets(0, 40, 0);
		Dialog.addNumber("Third Channel", 0);
		Dialog.addToSameRow();
		Dialog.addString("Third Channel Name","Channel 3");
		Dialog.setInsets(0, 40, 0);
		Dialog.addMessage("Ratiometric analysis");
		ratiometricChoices = newArray("Mask Channel","Second Channel","Third Channel","None");
		Dialog.setInsets(0, 0, 0);
		Dialog.addChoice("",ratiometricChoices, ratiometricChoices[3]);
		Dialog.addChoice(" to: ",ratiometricChoices,ratiometricChoices[3]);
		Dialog.addChoice("then to: ",ratiometricChoices, ratiometricChoices[3]);
		//Dialog.setInsets(0, 20, 0);
		//Dialog.addString("Name of save file:", "2D Analysis Data.csv",25);
	Dialog.show();

	toAnalyze = Dialog.getCheckbox();
	doPerCell = Dialog.getCheckbox();
	for (i = 0; i < morphParameters.length; i++) 
	{ 
		if (Dialog.getCheckbox()==1) enabledMorphParameters=Array.concat(enabledMorphParameters,morphParameters[i]);
	}
	for (i = 0; i < networkParameters.length; i++) 
	{ 
		if (Dialog.getCheckbox()==1) enabledNetworkParameters=Array.concat(enabledNetworkParameters,networkParameters[i]);
	}
	normalChoice = Dialog.getRadioButton();	
	
	doPerMito = Dialog.getCheckbox();
	for (i = 0; i < mitoMorphP.length; i++) 
	{ 
		if (Dialog.getCheckbox()==1) enabledMitoMorphP=Array.concat(enabledMitoMorphP,mitoMorphP[i]);
	}
	for (i = 0; i < mitoNetworkP.length; i++) 
	{ 
		if (Dialog.getCheckbox()==1) enabledMitoNetworkP=Array.concat(enabledMitoNetworkP,mitoNetworkP[i]);
	}
	enabledMitoParameters = Array.concat(enabledMitoMorphP , enabledMitoNetworkP);

	//Functional Analysis Variables
	isMultipleCh = Dialog.getCheckbox();
	Channel_mask = Dialog.getNumber();
	Channel_mask_Name = Dialog.getString();
	Channel_2 = Dialog.getNumber();
	Channel_2_Name = Dialog.getString();
	Channel_3 = Dialog.getNumber();
	Channel_3_Name = Dialog.getString();
	firstRatio = Dialog.getChoice();
	secondRatio = Dialog.getChoice();
	thirdRatio = Dialog.getChoice();

	//Error Handling
	if (enabledNetworkParameters.length==0 && enabledMorphParameters.length==0)  toAnalyze=false;
	if (doPerCell==false && doPerMito==false) toAnalyze=false;
	if (doPerMito==false) isMultipleCh=false;
	
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

	tmpBatchFile = File.open(getDirectory("temp") + "2DBatchAnalysisTemp.txt");
	print(tmpBatchFile, doPerCell);
	print(tmpBatchFile, printArray(enabledMorphParameters));
	print(tmpBatchFile, printArray(enabledNetworkParameters));
	print(tmpBatchFile, normalChoice );
	print(tmpBatchFile, doPerMito);
	print(tmpBatchFile, printArray(enabledMitoMorphP));
	print(tmpBatchFile, printArray(enabledMitoNetworkP));
	print(tmpBatchFile, inputD);
	File.close(tmpBatchFile);

	tmpIntensioFile = File.open(getDirectory("temp") + "2DIntensiometricTemp.txt");
	print(tmpIntensioFile, "None" );
	print(tmpIntensioFile, Channel_mask_Name);
	print(tmpIntensioFile, "None");
	print(tmpIntensioFile, Channel_2_Name);
	print(tmpIntensioFile, "None");
	print(tmpIntensioFile, Channel_3_Name);
	print(tmpIntensioFile, "None");
	print(tmpIntensioFile, "None");
	print(tmpIntensioFile, "None");
	File.close(tmpIntensioFile);

	processFolder(inputD);

	function processFolder(inputD) 
	{
		list = getFileList(inputD);

		path = inputD;
		for (i = 0; i < list.length; i++) 
		{
			if(File.isDirectory(inputD + list[i]))
			{
				path = inputD + list[i];
				processFolder(inputD + list[i]);
			}
			else if(endsWith(list[i], suffix))
				processFile(inputD, outputD, path + list[i]);
		}
	}

	function processFile(inputD, outputD, file) 
	{
		open(file);
		inputName = getTitle();
		/*//Experimental Code
		folder = getDirectory("image");
		folderA = split(folder,"\\");
		folderLength = lengthOf(folderA);
		folderFinal = folderA[folderLength-1];
		fF2 = split(folderFinal,"/");
		folderFinal = fF2[0];
		tmpHistoFile = File.open(getDirectory("temp") + "2DHistoTemp.txt");
		print(tmpHistoFile, folderFinal );
		File.close(tmpHistoFile);
		*/
		isThresholded = false;

		getHistogram(values,counts,256);
		counter = 0;
		for (i = 0; i < values.length; i++) {if (counts[i]>1) counter++;}
		if (counter<=2) isThresholded = true;

		transferMask = "None";
		transferCh2 = "None";
		transferCh3 = "None";
		Stack.getDimensions(width, height, channels, slices, frames);
		if (isMultipleCh) 
		{				
			selectWindow(inputName);	
			if (channels>1) Stack.setChannel(Channel_mask);
			run("Duplicate...", " ");
			transferMask = inputName + " ChMask";
			rename(transferMask);
			
			if (Channel_2!=0)
			{
				selectWindow(inputName);
				Stack.setChannel(Channel_2);
				run("Duplicate...", " ");
				transferCh2 = inputName + " Ch2";
				rename(transferCh2);
			}
			if (Channel_3!=0)
			{
				selectWindow(inputName);
				Stack.setChannel(Channel_3);
				run("Duplicate...", " ");
				transferCh3 = inputName + " Ch3";
				rename(transferCh3);
			}

			tmpIntensioFile = File.open(getDirectory("temp") + "2DIntensiometricTemp.txt");
			print(tmpIntensioFile, transferMask );
			print(tmpIntensioFile, Channel_mask_Name);
			print(tmpIntensioFile, transferCh2);
			print(tmpIntensioFile, Channel_2_Name);
			print(tmpIntensioFile, transferCh3);
			print(tmpIntensioFile, Channel_3_Name);
			print(tmpIntensioFile, firstRatio);
			print(tmpIntensioFile, secondRatio);
			print(tmpIntensioFile, thirdRatio);
			File.close(tmpIntensioFile);
		}

		selectWindow(inputName);
		if (isMultipleCh && channels>1) Stack.setChannel(Channel_mask);
		if (toThreshold && !isThresholded) runMacro(macroFolder + "2DThreshold.ijm","Batch");
		if (isOpen(inputName + " thresholded")) selectWindow(inputName + " thresholded");
		if (toAnalyze) runMacro(macroFolder + "2DAnalysis.ijm","Batch");

		if (!toThreshold && !toAnalyze) exit("No commands selected");
	
		close(inputName);
		if (isOpen(transferMask)) close(transferMask);
		if (isOpen(transferCh2)) close(transferCh2);
		if (isOpen(transferCh3)) close(transferCh3);
		if (isOpen(inputName + " thresholded"))
		{
			selectWindow(inputName + " thresholded");
			if (saveFile) saveAs("tiff",inputD + inputName + " thresholded");
			close();
		}
	}

	function printArray(array1)
	{
		result ="";
		for (i = 0; i < array1.length; i++)
		{
			result += array1[i];
			if (i<(array1.length-1)) result += ",";
		}
		return result;
	}
}
