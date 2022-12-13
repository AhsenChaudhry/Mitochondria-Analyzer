/*
Author: Ahsen Chaudhry
Last updated: November 25, 2022
This macro analyzes a thresholded 3D stack to obtain morphological and networking information.
*/
	
macro Analysis3D
{
	batchMode = false;
	if (getArgument()=="Batch") batchMode=true;
	
	input = getTitle();

	setBatchMode(true);
	
	//Make sure input is a thresholded image before proceeding
	run("Z Project...", "projection=[Max Intensity]");
	getHistogram(values,counts,256);
	counter = 0;
	for (i = 0; i < values.length; i++) {if (counts[i]>1) counter++;}
	close("MAX_" + input);
	if (counter>2) exit("Please use a thresholded image as an input");
	setBatchMode(false);

	selectWindow(input);
	
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

	var saveFile = true;
	var batchFolderPath = "";
	Channel_2  = "None";
	Channel_1 = "None";

	mitoCount = 0;
	TotalVolume = 0;
	TotalSA = 0;
	sphericity = 0;
	w_sphericity = 0;
	Branches = 0;
	BranchLength = 0;
	BranchPoints = 0;
	BranchDiameter= 0;
	BranchEndPoints = 0;

	if (batchMode==false)
	{
		Dialog.create("3D Analysis");
			Dialog.setInsets(-5, 0, 0);
		    Dialog.addMessage("This function will perform morphological and networking analysis on a thresholded 3D stack.");
			Dialog.setInsets(-5, 15, 0);
		    Dialog.addMessage("The selected image is: " + input);
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

			listImages = getList("image.titles");
			listImages = Array.concat(listImages,newArray("None"));
			Dialog.setInsets(5, 35, 0);
		    Dialog.addMessage("Multiple Channel Analysis for Simultaneous Functional Measurement - requires per-mito analysis");
		    Dialog.setInsets(-5, 35, 0);
			Dialog.addMessage("Will measure weighted mean intensity of other channels for regions corresponding to each mito object.");
			//Dialog.setInsets(-5, 35, 0);
			//Dialog.addCheckbox("Show Std. dev for each measurement?", false);
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
		//	Dialog.setInsets(-23, 150, 0);
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
		
		//Functional Analysis Variables
		//showSD = Dialog.getCheckbox();
		Channel_mask = Dialog.getChoice();
		Channel_mask_Name = Dialog.getString();
		Channel_2 = Dialog.getChoice();
		Channel_2_Name = Dialog.getString();
		Channel_3 = Dialog.getChoice();
		Channel_3_Name = Dialog.getString();
		firstRatio = Dialog.getChoice();
		secondRatio = Dialog.getChoice();
		thirdRatio = Dialog.getChoice();

		//Error Handling
		if (ArrayContains(enabledMorphParameters,"Count")==false && ArrayContains(enabledMorphParameters,"Total Volume")==false) normalChoice = "None";
		if (enabledNetworkParameters.length==0 && enabledMorphParameters.length==0) exit("No analysis parameters selected");
		if (doPerCell==false && doPerMito==false) exit("Please select per-cell basis and/or per-mito basis");
	}

	if (batchMode==true)
	{
		parameters = File.openAsString(getDirectory("temp") + "3DBatchAnalysisTemp.txt"); 
        parLines = split(parameters,"\n");
        if (parLines.length>1)
        {
        	doPerCell = parLines[0];
	        enabledMorphParameters = split(parLines[1],",");
	        enabledNetworkParameters = split(parLines[2],",");
	        normalChoice = parLines[3];
        	doPerMito = parLines[4];
	        enabledMitoMorphP = split(parLines[5],",");
	        enabledMitoNetworkP = split(parLines[6],",");
	        if (parLines.length>7) batchFolderPath = parLines[7];
        }
        
        if (parLines[0]=="Default")
        {
    	    enabledMorphParameters = morphParameters;
	        enabledNetworkParameters = networkParameters;
	        normalChoice = "Count";     	
        }
        else
        {
			iParameters = File.openAsString(getDirectory("temp") + "3DIntensiometricTemp.txt"); 
	        iParLines = split(iParameters,"\n");
	        Channel_mask = iParLines[0];
			Channel_mask_Name = iParLines[1];
			Channel_2 = iParLines[2];
			Channel_2_Name =iParLines[3];
			Channel_3 = iParLines[4];
			Channel_3_Name = iParLines[5];
			firstRatio = iParLines[6];
			secondRatio = iParLines[7];
			thirdRatio = iParLines[8];
        }
	}

	enabledNetworkParameters = FinalizeNetworkParameters(enabledNetworkParameters,normalChoice);

	Analysis();

	function Analysis()
	{
		setBatchMode(true);
		//3D volume and morphology analysis
			selectWindow(input);
			run("3D OC Options", "volume surface nb_of_obj._voxels mean_distance_to_surface dots_size=5 font_size=10 " + 
				"redirect_to=none");
			getVoxelSize(width, height, depth, unit);
			voxel = width*height*depth;
			sizeFilter = 0.05 / voxel;
			run("3D Objects Counter", "threshold=50 slice=1 min.=" + sizeFilter + " max.=13369344 objects statistics summary");
			close("Results");
	
			//Do Morphological Analysis on colour coded Objects Map from previous step
			selectWindow("Objects map of " + input);
			run("Analyze Regions 3D", "volume surface_area mean_breadth sphericity euler_number surface_area_method=[Crofton (13 dirs.)] euler_connectivity=26");
			morphoName = getInfo("window.title");
			/*
			oMap = "Objects map of " + input;
			morphoName = substring(oMap, 0, indexOf(oMap,".tif")) + "-morpho";
			morphoName = replace(morphoName, " ", "");
			*/
			mitoCount = Table.size(morphoName);

			if (doPerCell)
			{
				//Get total SA, sphericity, and weighted sphericity (weighted to object volume)
				for (i = 0;i < mitoCount;i++) 
				{
					TotalVolume += parseFloat(Table.get("Volume",i,morphoName));
					TotalSA += parseFloat(Table.get("SurfaceArea",i,morphoName));
					sphericity += parseFloat(Table.get("Sphericity",i,morphoName));
					w_sphericity += ( parseFloat(Table.get("Sphericity",i,morphoName)) * parseFloat(Table.get("Volume",i,morphoName)));
				}
				sphericity /= mitoCount;
				w_sphericity /= TotalVolume;
			}
	
			mitoVolume = newArray(mitoCount+1);
			mitoSA = newArray(mitoCount+1);
			mitoSphericity = newArray(mitoCount+1);
			if (doPerMito)
			{
				//Get total SA, sphericity, and weighted sphericity (weighted to object volume)
				for (i = 0;i < mitoCount;i++) 
				{
					mitoVolume[i] += parseFloat(Table.get("Volume",i,morphoName));
					mitoSA[i] = parseFloat(Table.get("SurfaceArea",i,morphoName));
					mitoSphericity[i] = parseFloat(Table.get("Sphericity",i,morphoName));
					//mito_w_sphericity[i] = ( parseFloat(Table.get("Sphericity",i,morphoName)) * parseFloat(Table.get("Volume",i,morphoName)));
				}
			}
			
			close(morphoName);

		//Networking and skeleton analysis
		if (enabledNetworkParameters.length>0)
		{
			if (doPerCell)
			{
				selectWindow("Objects map of " + input);
				run("Duplicate...", "duplicate");
				rename(input + " skeleton");
				setThreshold(1, 255);
				run("8-bit");
				run("Skeletonize (2D/3D)");

				//Calculate mean branch diameter
				if (ArrayContains(enabledNetworkParameters,"Mean Branch Diameter")==true)
				{
					BranchDiameter = calculateMeanBranchDiameter("Objects map of " + input,input + " skeleton");
				}

				selectWindow(input + " skeleton");
				run("Analyze Skeleton (2D/3D)", "prune=[none] calculate show");
	
				//From the detailed branch info window, calculate average branch length
				nResult = Table.size("Branch information");
				BranchLength = 0;
				for (i = 0;i < nResult;i++) 
				{
					BranchLength += parseFloat(Table.get("Branch length",i,"Branch information"));
				}
				close("Branch information");
				if (isOpen("Tagged skeleton")) close("Tagged skeleton");
				if (isOpen("Longest shortest paths")) close("Longest shortest paths");

				//Get number of branches and branch points of each skeleton
				nResult = Table.size("Results");
				skeletons = 0;
				for (i = 0;i < nResult;i++) 
				{
					Branches += parseInt(Table.get("# Branches",i,"Results"));
					BranchPoints += parseInt(Table.get("# Junctions",i,"Results"));
					BranchEndPoints += parseInt(Table.get("# End-point voxels",i,"Results"));
					//Sphericals have a skeleton with zero branches, but we want to count them as a branch
						if (parseInt((Table.get("# Branches",i,"Results")))==0) Branches++;
					skeletons++;
				}
				if (isOpen(input + " skeleton")) close(input + " skeleton");
			}
			
			mitoBranches = newArray(mitoCount + 1);
			mitoBranchLength = newArray(mitoCount + 1);
			mitoBranchPoints = newArray(mitoCount + 1);
			mitoBranchDiameter= newArray(mitoCount + 1);
			mitoBranchEndPoints = newArray(mitoCount + 1);
			mitoBranchLongShort = newArray(mitoCount + 1);
			
			ChMask =  newArray(mitoCount + 1);
			//ChMaskSD = newArray(mitoCount + 1);
			Ch2 =  newArray(mitoCount + 1);
			//Ch2SD = newArray(mitoCount + 1);
			Ch3  =  newArray(mitoCount + 1);
			//Ch3SD = newArray(mitoCount + 1);

			if (doPerMito)
			{
				for (i = 0; i < mitoCount;i++)
				{
					selectWindow("Objects map of " + input);
					run("Duplicate...", "duplicate");
					rename(input + "$t$");
	
					setThreshold(i+1, i+1);
					run("Convert to Mask", "method=Default background=Dark black");
					run("8-bit");
	
					if (Channel_mask!="None") ChMask[i] = channelAnalysis(input + "$t$",Channel_mask);
					if (Channel_2!="None") Ch2[i] = channelAnalysis(input + "$t$",Channel_2);
					if (Channel_3!="None") Ch3[i] = channelAnalysis(input + "$t$",Channel_3);
	
					selectWindow(input + "$t$");
					run("Z Project...", "projection=[Max Intensity]");
					run("Create Selection");
					close();
					selectWindow(input + "$t$");
					run("Restore Selection");
					//run("Make Inverse");
					run("Crop");	
					getDimensions(w, h, c, s, f);
					run("Canvas Size...", "width=" + (w+2) + " height=" + (h+2) + " position=Center zero");
					run("Duplicate...", "duplicate");
					run("Skeletonize (2D/3D)");
					rename(input + "$t$ skeleton");

					if (ArrayContains(enabledMitoNetworkP,"Mean Branch Diameter")==true)
					{
						mitoBranchDiameter[i] = calculateMeanBranchDiameter(input + "$t$",input + "$t$ skeleton");
					}
	
					selectWindow(input + "$t$ skeleton");
					run("Analyze Skeleton (2D/3D)", "prune=[none] calculate show");
					close(input + "$t$ skeleton");
					close(input + "$t$");
	
					nResult = Table.size("Branch information");
					for (j = 0;j < nResult;j++) 
					{
						mitoBranchLength[i] += parseFloat(Table.get("Branch length",j,"Branch information"));
					}
					
					if (isOpen("Tagged skeleton")) close("Tagged skeleton");
					if (isOpen("Longest shortest paths")) close("Longest shortest paths");
	
					//Get number of branches and branch points of each skeleton
					nResult = Table.size("Results");
					for (j = 0;j < nResult;j++) 
					{
						mitoBranches[i] += parseInt(Table.get("# Branches",j,"Results"));
	
						mitoBranchLongShort[i] += parseFloat(Table.get("Longest Shortest Path",j,"Results"));
						if (mitoBranchLongShort[i]==0 && mitoBranchLength[i]>0) mitoBranchLongShort[i]=mitoBranchLength[i];
						mitoBranchPoints[i] += parseInt(Table.get("# Junctions",j,"Results"));
						mitoBranchEndPoints[i] += parseInt(Table.get("# End-point voxels",j,"Results"));
					}
					//Sphericals have a skeleton with zero branches, but we want to count them as a branch
					if (mitoBranches[i]==0) mitoBranches[i]++;
				}
				close("Branch information");
				close("Objects map of " + input);
			}
		}
		if(isOpen("Objects map of " + input)) close("Objects map of " + input);
		if (isOpen("Results")) 	close("Results");
		setBatchMode(false);
	
		var tableName = "3D Analysis Data";// for " + input;
		var tablePerCell = tableName + " - per Cell";
		var tablePerMito = tableName + " - per Mito";

		//Display the final results in a table
		if (doPerCell)
		{
			if (isOpen(tablePerCell)==false) { Table.create(tablePerCell);}
			row = Table.size(tablePerCell);
			Table.set("Image Name", row, input,tablePerCell);

			finalParam = Array.concat(enabledMorphParameters,enabledNetworkParameters);

			for (i = 0; i < finalParam.length; i++) 
			{
				Table.set(finalParam[i],row,getCellVariable(finalParam[i]),tablePerCell);
			}

			Table.update;
		}

		if (doPerMito)
		{
			if (isOpen(tablePerMito)==false) { Table.create(tablePerMito);}
			print(input);
			print(mitoCount);
			for (i=0;i< mitoCount;i++)
			{
				row = Table.size(tablePerMito);
				Table.set("Image Name", row, input,tablePerMito);
				Table.set("Mito #", row, "Mito #" + (i + 1),tablePerMito);
				enabledMitoParameters = Array.concat(enabledMitoMorphP , enabledMitoNetworkP);
				for (c = 0; c<enabledMitoParameters.length; c++) 
				{
					Table.set(enabledMitoParameters[c],row,getMitoVariable(enabledMitoParameters[c],i),tablePerMito);
				}
	
				//For showing functional analysis results
				if (Channel_mask!="None") { Table.set(Channel_mask_Name + " Intensity",row,ChMask[i],tablePerMito); }
				if (Channel_2!="None") { Table.set(Channel_2_Name + " Intensity",row,Ch2[i],tablePerMito); }
				if (Channel_3!="None") { Table.set(Channel_3_Name + " Intensity",row,Ch3[i],tablePerMito); }

				if (firstRatio!="None" && secondRatio!="None") 
				{
					var N1,N2,N1_Name,N2_Name,N3,N3_Name;
					if (firstRatio=="Mask Channel"){ N1=ChMask[i]; N1_Name=Channel_mask_Name;}
					if (firstRatio=="Second Channel"){ N1=Ch2[i]; N1_Name=Channel_2_Name;}
					if (firstRatio=="Third Channel"){ N1=Ch3[i]; N1_Name=Channel_3_Name;}
					if (secondRatio=="Mask Channel"){ N2=ChMask[i]; N2_Name=Channel_mask_Name;}
					if (secondRatio=="Second Channel"){ N2=Ch2[i]; N2_Name=Channel_2_Name;}
					if (secondRatio=="Third Channel"){ N2=Ch3[i]; N2_Name=Channel_3_Name;}
					ratio1 = N1/N2;
					Table.set(N1_Name + " / " + N2_Name,row,ratio1,tablePerMito);
	
					if (thirdRatio!="None")
					{
						if (thirdRatio=="Mask Channel"){ N3=ChMask[i]; N3_Name=Channel_mask_Name;}
						if (thirdRatio=="Second Channel"){ N3=Ch2[i]; N3_Name=Channel_2_Name;}
						if (thirdRatio=="Third Channel"){ N3=Ch3[i]; N3_Name=Channel_3_Name;}
						ratio2 = ratio1/N3;
						Table.set("(" + N1_Name + " / " +  N2_Name + ") / " + N3_Name,row,ratio2,tablePerMito);
					}
				}
			}
			Table.update;
			//if (saveFile) Table.save(batchFolderPath + tableName + ".csv");
		}

		//A fix for an intermittent error in ImageJ not updating tables
			if (doPerCell) { selectWindow(tablePerCell); Table.update; }
			if (doPerMito) { selectWindow(tablePerMito); Table.update; }
	}

	function getCellVariable(varName)
	{
		ans = 0;

		if (varName=="Count") ans = mitoCount;
		if (varName=="Total Volume") ans = TotalVolume;
		if (varName=="Mean Volume") ans = TotalVolume/mitoCount;
		if (varName=="Total Surface Area") ans = TotalSA;
		if (varName=="Mean Surface Area") ans = TotalSA/mitoCount;
		if (varName=="Sphericity (Weighted)") ans = w_sphericity;
		if (varName=="Branches") ans = Branches;
		if (varName=="Total Branch Length") ans = BranchLength;
		if (varName=="Branch Junctions") ans = BranchPoints;
		if (varName=="Branch End Points") ans = BranchEndPoints;
		if (varName=="Mean Branch Length") ans = BranchLength/Branches;
		if (varName=="Mean Branch Diameter") ans = BranchDiameter;

		//This code will recursively call the function to normalize branch variables to count or volume
		//The '/' as in 'Branches/mito' flags it as a variable that will be used in this code black
			new = split(varName,"/");
			if (new.length>1)
			{
				denom = 1;
				if (new[1]=="mito") denom = mitoCount;
				if (new[1]=="volume") denom = TotalVolume;
				ans = getCellVariable(new[0]) / denom;
			}
		return ans;
	}

	function getMitoVariable(varName,mitoNum)
	{
		ans = 0;
		
		if (varName=="Volume") ans = mitoVolume[mitoNum];
		if (varName=="Surface Area") ans = mitoSA[mitoNum];
		if (varName=="Sphericity") ans = mitoSphericity[mitoNum];
		if (varName=="Branches") ans = mitoBranches[mitoNum];
		if (varName=="Total Branch Length") ans = mitoBranchLength[mitoNum];
		if (varName=="Branch Junctions") ans = mitoBranchPoints[mitoNum];
		if (varName=="Longest Shortest Path") ans = mitoBranchLongShort[mitoNum];
		if (varName=="Branch End Points") ans = mitoBranchEndPoints[mitoNum];
		if (varName=="Mean Branch Length") ans =  mitoBranchLength[mitoNum] / mitoBranches[mitoNum];
		if (varName=="Mean Branch Diameter") ans =  mitoBranchDiameter[mitoNum];
			
		return ans;
	}

	function calculateMeanBranchDiameter(image_original,image_skeleton)
	{
		//Make 3D Euclidean Distance Map
		selectWindow(image_original);
		run("Duplicate...", "duplicate");
		rename("tempedt");
		run("3D Distance Map", "map=EDT image=tempedt Segmentation threshold=1");
		Stack.getStatistics(count, mean, min, dMax, std); 
		close("tempedt");

		//Calculate distance values from skeleton
		selectWindow(image_skeleton);
		//Duplicate the skeleton into a 32-bit form
		run("Duplicate...", "duplicate");
		rename("32bit-skeleton");
		run("32-bit");
		//Set the skeleton values to 1
		run("Macro...", "code=[if (v==255) v=1] stack");
		selectWindow("EDT");
		//Take all values in the EDT map and removes any not overlapping with skeleton values
		imageCalculator("Multiply 32-bit stack", "EDT","32bit-skeleton");
		selectWindow("EDT");
		//Set background black pixels to NaN so they won't be calculated in mean distance value
		run("Macro...", "code=[if (v==0) v=NaN] stack");
		Stack.getStatistics(count, mean, min, max, std); 
		//The mean distance of the skeleton from surface of object is radius, now multiply by 2
		meanBD = mean*2;
		if (isNaN(meanBD)) meanBD=0;
		//For punctate objects, the branch count can be 0, so we use use the maximum value from the EDT map instead.
		if (meanBD==0) meanBD=dMax*2;
	 	close("EDT");
	 	close("32bit-skeleton");

	 	return meanBD;
	}

	function FinalizeNetworkParameters (network_Parameters, normal_Choice)
	{
		toChange = newArray("Branches","Total Branch Length","Branch Junctions","Branch End Points");
		if (normal_Choice!="None")
		{
			normalNetworkParameters = newArray(0);
			for (i = 0; i < network_Parameters.length; i++) 
			{ 
				for (j=0;j<toChange.length;j++)
				{
					normalNetworkParameters=Array.concat(normalNetworkParameters,networkParameters[i]);
					if (network_Parameters[i]==toChange[j]) 
					{
						if (normal_Choice=="Count" || normal_Choice=="Show Both")
							normalNetworkParameters=Array.concat(normalNetworkParameters,network_Parameters[i] + "/mito");
						if (normal_Choice=="Volume" || normal_Choice=="Show Both")
							normalNetworkParameters=Array.concat(normalNetworkParameters,network_Parameters[i] + "/volume");
					}
				}
			}
		}
		return normalNetworkParameters;
	}

	function ArrayContains (array1,string)
	{
		answer=false;
		strings = split(string,",");
		for (i = 0; i < array1.length; i++) 
		{
			for (j=0;j<strings.length;j++)
			{
				if (array1[i] == strings[j]) answer = true;
			}
		}
		return answer;
	}

	function channelAnalysis(thresh,channel)
	{		
		selectWindow(thresh);
		slices = nSlices;

		run("Set Measurements...", "area mean redirect=None decimal=3");
	
		for (i=1;i<=slices;i++)
		{
			selectWindow(thresh);
			setSlice(i);
			
			getStatistics(area, mean, min, max);
			
			if (max>0) 
			{
				run("Create Selection");
				run("Make Inverse");
	
				selectWindow(channel);
				setSlice(i);
				run("Restore Selection");
				run("Measure");
				run("Select None");
			}
			//selectWindow(thresh);
			run("Select None");
		}
		
		nResult = Table.size("Results");
		weightedMeasure=0;
		TotalArea=0;
		for (m=0;m<nResult;m++)
		{
			weightedMeasure += (parseFloat(Table.get("Mean",m,"Results")) * parseFloat(Table.get("Area",m,"Results")));
			TotalArea += parseFloat(Table.get("Area",m,"Results"));
		}
		weightedMeasure = weightedMeasure / TotalArea;
		Table.reset("Results");
		return weightedMeasure;
	}
}
