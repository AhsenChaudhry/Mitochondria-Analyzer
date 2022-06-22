/*
Author: Ahsen Chaudhry
Last updated: April 27, 2022
This macro performs analysis on a thresholded 4D (xyzt) stack, meaning 3D stacks acquired over several time frames.
*/

macro TimeLapseAnalysis3D
{
	macroFolder = getDirectory("plugins") + "MitochondriaAnalyzer/Macros/";
	input = getTitle();
	Stack.getDimensions(w, h, channels, slices, frames);
	if (frames==1 || slices==1) exit("Input must be 4D (xyzt)");

	morphParameters = newArray("Count","Total Volume","Mean Volume","Total Surface Area","Mean Surface Area","Sphericity (Weighted)");
	enabledMorphParameters = newArray(0);
	networkParameters = newArray("Branches","Total Branch Length","Mean Branch Length","Branch Junctions","Branch End Points","Mean Branch Diameter");
	enabledNetworkParameters = newArray(0);

	mitoMorphP = newArray("Volume","Surface Area","Sphericity");
	enabledMitoMorphP = newArray(0);
    mitoNetworkP = newArray("Branches","Total Branch Length","Mean Branch Length","Branch Junctions","Branch End Points","Mean Branch Diameter","Longest Shortest Path");
	enabledMitoNetworkP = newArray(0);

	doPerCell = true;
	doPerMito = false;

	Dialog.create("3D TimeLapse (4D) Analysis");
		Dialog.setInsets(-5, 0, 0);
	    Dialog.addMessage("This function will perform morphological and networking analysis on a thresholded 3D TimeLapse (4D - xyzt) stack.");
		
Dialog.setInsets(-5, 15, 0);
	    Dialog.addMessage("The selected input is: " + input);
		
	Dialog.setInsets(2, 20, 0);
	   		Dialog.addCheckbox("Perform analysis on a per-cell basis?", doPerCell);

			Dialog.setInsets(0, 35, 0);
	    	Dialog.addMessage("Per-cell morphologic descriptors:");
		    Dialog.setInsets(0, 40, 0);
		    Dialog.addCheckboxGroup(2,3,morphParameters,Array.fill(newArray(morphParameters.length),true));
	
			Dialog.setInsets(5, 35, 0);
	    	Dialog.addMessage("Per-cell network descriptors:");
		    Dialog.setInsets(0, 40, 0);
		    Dialog.addCheckboxGroup(2,3,networkParameters,Array.fill(newArray(networkParameters.length),true));

			normItems = newArray("Count", "Volume", "Show Both");
			Dialog.setInsets(0, 35, 0);
		    Dialog.addRadioButtonGroup("If analyzing per-cell, then normalize network descriptors to:", normItems, 1, 3, "Count");

			Dialog.setInsets(10, 20, 0);
		    Dialog.addCheckbox("Perform analysis on a per-mito basis?", doPerMito);
		    
			Dialog.setInsets(0, 35, 0);
	    	Dialog.addMessage("Per-mito morphologic descriptors:");
		    Dialog.setInsets(0, 40, 0);
		    Dialog.addCheckboxGroup(1,3,mitoMorphP,Array.fill(newArray(mitoMorphP.length),true));
	
			Dialog.setInsets(5, 35, 0);
	    	Dialog.addMessage("Per-mito network descriptors:");
		    Dialog.setInsets(0, 40, 0);
		    Dialog.addCheckboxGroup(2,4,mitoNetworkP,Array.fill(newArray(mitoNetworkP.length),true));
		    
			Dialog.setInsets(5, 35, 0);
		    Dialog.addMessage("Multiple Channel Analysis for Simultaneous Functional Measurement - requires per-mito analysis");    
			listImages = getList("image.titles");
			listImages = Array.concat(listImages,newArray("None"));
			Dialog.setInsets(0, 40, 0);
			Dialog.addChoice("Mask Channel: ",listImages,listImages[listImages.length-1]);
			Dialog.addToSameRow();
			Dialog.addString("Mask Channel Name","Mask");
			Dialog.setInsets(0, 40, 0);
			Dialog.addChoice("Second Channel: ",listImages,listImages[listImages.length-1]);
			Dialog.addToSameRow();
			Dialog.addString("Second Channel Name","Channel 2");
			Dialog.setInsets(0, 40, 0);
			Dialog.addChoice("Third Channel: ",listImages,listImages[listImages.length-1]);
			Dialog.addToSameRow();
			Dialog.addString("Third Channel Name","Channel 3");
			Dialog.setInsets(0, 40, 0);
			Dialog.addMessage("Ratiometric analysis");
			ratiometricChoices = newArray("Mask Channel","Second Channel","Third Channel","None");
			Dialog.setInsets(0, 0, 0);
			Dialog.addChoice("",ratiometricChoices, ratiometricChoices[3]);
			Dialog.addChoice(" to: ",ratiometricChoices,ratiometricChoices[3]);
			Dialog.addChoice("then to: ",ratiometricChoices, ratiometricChoices[3]);
	Dialog.show();
	

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
		
	if (enabledNetworkParameters.length==0 && enabledMorphParameters.length==0) exit("No analysis parameters selected");

	//Functional Analysis Variables
	Channel_mask = Dialog.getChoice();
	Channel_mask_Name = Dialog.getString();
	Channel_2 = Dialog.getChoice();
	Channel_2_Name = Dialog.getString();
	Channel_3 = Dialog.getChoice();
	Channel_3_Name = Dialog.getString();
	firstRatio = Dialog.getChoice();
	secondRatio = Dialog.getChoice();
	thirdRatio = Dialog.getChoice();

	tmpBatchFile = File.open(getDirectory("temp") + "3DBatchAnalysisTemp.txt");
	print(tmpBatchFile, doPerCell);
	print(tmpBatchFile, printArray(enabledMorphParameters));
	print(tmpBatchFile, printArray(enabledNetworkParameters));
	print(tmpBatchFile, normalChoice );
	print(tmpBatchFile, doPerMito);
	print(tmpBatchFile, printArray(enabledMitoMorphP));
	print(tmpBatchFile, printArray(enabledMitoNetworkP));
	File.close(tmpBatchFile);

	tmpIntensioFile = File.open(getDirectory("temp") + "3DIntensiometricTemp.txt");
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
	
	for (i=1;i<=frames;i++)
	{
		transferMask = "None";
		transferCh2 = "None";
		transferCh3 = "None";
		
			if (Channel_mask!="None")
			{
				selectWindow(Channel_mask);
				Stack.setFrame(i);
				run("Duplicate...", "duplicate frames=" + i);
				transferMask = Channel_mask + " Frame: " + i;
				rename(transferMask);
			}

			if (Channel_2!="None")
			{
				selectWindow(Channel_2);
				Stack.setFrame(i);
				run("Duplicate...", "duplicate frames=" + i);
				transferCh2 = Channel_2 + " Frame: " + i;
				rename(transferCh2);
			}

			if (Channel_3!="None")
			{
				selectWindow(Channel_3);
				Stack.setFrame(i);
				run("Duplicate...", "duplicate frames=" + i);
				transferCh3 = Channel_3 + " Frame: " + i;
				rename(transferCh3);
			}

			tmpIntensioFile = File.open(getDirectory("temp") + "3DIntensiometricTemp.txt");
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
		
		
		selectWindow(input);
		Stack.setFrame(i);
		run("Duplicate...", "duplicate frames=" + i);
		name = input + " Frame: " + i;
		rename(name);

		runMacro(macroFolder + "3DAnalysis.ijm","Batch");
		close(name);
		if (isOpen(transferMask)) close(transferMask);
		if (isOpen(transferCh2)) close(transferCh2);
		if (isOpen(transferCh3)) close(transferCh3);
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
