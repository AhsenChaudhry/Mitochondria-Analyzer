/*
Author: Ahsen Chaudhry
Last updated: September 6, 2020
This macro analyzes a thresholded 2D slice to obtain morphological and networking information.
*/

//Global Variables
var intensityMean = 0;
var intensitySD = 0;
var perPixelSD = 0;

macro Analysis2D
{
	batchMode = false;
	if (getArgument()=="Batch") batchMode=true;
	
	//Make sure input is a thresholded image before proceeding
	getHistogram(values,counts,256);
	counter = 0;
	for (i = 0; i < values.length; i++) {if (counts[i]>1) counter++;}
	if (counter>2) exit("Please use a thresholded image as an input");
	input = getTitle();

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
	
	Channel_mask = "None";
	Channel_2 = "None";
	Channel_3  = "None";

	var saveFile = false;

	mitoCount = 0;
	TotalArea = 0;
	TotalPerimeter = 0;
	FF = 0;
	AR = 0;
	Branches = 0;
	BranchLength = 0;
	BranchPoints = 0;
	BranchDiameter= 0;
	BranchEndPoints = 0;

	if (batchMode==false)
	{
		Dialog.create("2D Analysis");
			Dialog.setInsets(-5, 0, 0);
		    Dialog.addMessage("This function will perform morphological and networking analysis on thresholded 2D slices.");
			Dialog.setInsets(-5, 15, 0);
		    Dialog.addMessage("The selected image is: " + input);
			Dialog.setInsets(2, 20, 0);
		    Dialog.addCheckbox("Perform analysis on a per-cell basis?", doPerCell);

			Dialog.setInsets(0, 35, 0);
	    	Dialog.addMessage("Per-cell morphologic descriptors:");
		    Dialog.setInsets(0, 40, 0);
		    Dialog.addCheckboxGroup(2,4,morphParameters,Array.fill(newArray(morphParameters.length),true));
	
			Dialog.setInsets(5, 35, 0);
	    	Dialog.addMessage("Per-cell network descriptors:");
		    Dialog.setInsets(0, 40, 0);
		    Dialog.addCheckboxGroup(2,4,networkParameters,Array.fill(newArray(networkParameters.length),true));

			normItems = newArray("Count", "Area", "Show Both");
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


			listImages = getList("image.titles");
			listImages = Array.concat(listImages,newArray("None"));
			
			Dialog.setInsets(5, 35, 0);
		    Dialog.addMessage("Multiple Channel Analysis for Simultaneous Functional Measurement - requires per-mito analysis");
		    Dialog.setInsets(-5, 35, 0);
			Dialog.addMessage("Will measure mean intensity + St. dev of regions corresponding to each mito object in the selected channels.");
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

		//Error Handling
		if (ArrayContains(enabledMorphParameters,"Count")==false && ArrayContains(enabledMorphParameters,"Total Area")==false) normalChoice = "None";
		if (enabledNetworkParameters.length==0 && enabledMorphParameters.length==0) exit("No analysis parameters selected");
		if (doPerCell==false && doPerMito==false) exit("Please select per-cell basis and/or per-mito basis");
	}

	if (batchMode==true)
	{
		parameters = File.openAsString(getDirectory("temp") + "2DBatchAnalysisTemp.txt"); 
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
	        iParameters = File.openAsString(getDirectory("temp") + "2DIntensiometricTemp.txt"); 
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

	selectWindow(input);
	for (i=1;i<=nSlices;i++)
	{
		setSlice(i);
		currentSlice = i;

		getStatistics(area, mean, min, max);
		if (max>0) 
		{
			if (nSlices == 1) name = input + " ";
			else name = input + " - Slice " + currentSlice;
			Analysis(name);
		}
	}
	
	function Analysis(inputName)
	{
		setBatchMode(true);
		selectWindow(input);
		run("Duplicate...", "duplicate");
		rename(inputName);

		var mitoCount;
		//2D analysis
		sizeFilter = 0.06;//microns^2
		run("Set Measurements...", "area perimeter shape redirect=None decimal=3");
		run("Analyze Particles...", "size="+sizeFilter+"-Infinity show=[Count Masks] display clear");
		close("Results");
		selectWindow(inputName);
		run("Analyze Particles...", "size="+sizeFilter+"-Infinity show=[Masks] display clear");

		mitoCount = Table.size("Results");

		if (doPerCell)
		{
			for (i = 0;i < mitoCount;i++)
			{
				TotalArea += parseFloat(Table.get("Area",i,"Results"));
				AR +=  parseFloat(Table.get("AR",i,"Results"));
				FF += (1/(parseFloat(Table.get("Circ.",i,"Results"))));
				TotalPerimeter += parseFloat(Table.get("Perim.",i,"Results"));
			}
			AR = AR/mitoCount;
			FF = FF/mitoCount;
		}

		mitoArea = newArray(mitoCount+1);
		mitoAR  = newArray(mitoCount+1);
		mitoFF  = newArray(mitoCount+1);
		mitoPerimeter  = newArray(mitoCount+1);
		if (doPerMito)
		{
			for (i = 0;i < mitoCount;i++)
			{
				mitoArea[i] = parseFloat(Table.get("Area",i,"Results"));
				mitoAR[i] =  parseFloat(Table.get("AR",i,"Results"));
				mitoFF[i] = (1/(parseFloat(Table.get("Circ.",i,"Results"))));
				mitoPerimeter[i] =  parseFloat(Table.get("Perim.",i,"Results"));
			}
		}
		
		if (enabledNetworkParameters.length>0)
		{
			if (doPerCell)
			{
				selectWindow("Mask of " + inputName);
				run("Duplicate...", "duplicate");
				rename(inputName + " skeleton");
				run("Skeletonize (2D/3D)");

					//Calculate mean branch diameter
					if (ArrayContains(enabledNetworkParameters,"Mean Branch Diameter")==true)
					{
						BranchDiameter = calculateMeanBranchDiameter("Mask of " + inputName,inputName + " skeleton");
					}

				selectWindow(inputName + " skeleton");
				run("Analyze Skeleton (2D/3D)", "prune=[none] calculate show");
	
				//From the detailed branch info window, calculate average branch length
				nResult = Table.size("Branch information");
				BranchLength = 0;
				for (i = 0;i < nResult;i++) 
				{
					BranchLength += parseFloat(Table.get("Branch length",i,"Branch information"));
				}
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
						if ((parseInt(Table.get("# Branches",i,"Results")))==0) Branches++;
					skeletons++;
				}
				if (isOpen(inputName + " skeleton")) close(inputName + " skeleton");
			}
		
			mitoBranches = newArray(mitoCount + 1);
			mitoBranchLength = newArray(mitoCount + 1);
			mitoBranchPoints = newArray(mitoCount + 1);
			mitoBranchDiameter= newArray(mitoCount + 1);
			mitoBranchEndPoints = newArray(mitoCount + 1);
			mitoBranchLongShort = newArray(mitoCount + 1);

			ChMask =  newArray(mitoCount + 1);
			ChMaskSD = newArray(mitoCount + 1);
			Ch2 =  newArray(mitoCount + 1);
			Ch2SD = newArray(mitoCount + 1);
			Ch3  =  newArray(mitoCount + 1);
			Ch3SD = newArray(mitoCount + 1);

			pixel_RatioSD = newArray(mitoCount + 1);
			if (doPerMito)
			{
				for (i = 0; i < mitoCount;i++)
				{
					selectWindow("Count Masks of " + inputName);
					run("Duplicate...", "duplicate");
					rename(inputName + "$t$");
	
					setThreshold(i+1, i+1);
					run("Convert to Mask", "method=Default background=Dark black");
					run("8-bit");
					run("Create Selection");
					//run("Make Inverse");
					/*
					if (batchMode==false)
					{
						run("ROI Manager...");
						selectWindow(inputName);
						run("Restore Selection");
						roiManager("add");	
						roiManager("select", roiManager("count")-1);			
						roiManager("rename", "Mito# " + (i+1));
						selectWindow(inputName + "$t$");
					}
					*/
					//Functional Analysis
						//var ChMaskT, Ch2T, Ch3T;
						if (Channel_mask!="None")
						{
							channelAnalysis(inputName + "$t$",Channel_mask);
							ChMask[i] = intensityMean;
							ChMaskSD[i] = intensitySD;
						}
						if (Channel_2!="None")
						{
							channelAnalysis(inputName + "$t$",Channel_2);
							Ch2[i] = intensityMean;
							Ch2SD[i] = intensitySD;
						}
						if (Channel_3!="None")
						{
							channelAnalysis(inputName + "$t$",Channel_3);
							Ch3[i] = intensityMean;
							Ch3SD[i] = intensitySD;
						}
						if (firstRatio!="None" && secondRatio!="None") 
						{
							calculatePerPixelSD(inputName + "$t$",firstRatio,secondRatio,thirdRatio);
							pixel_RatioSD[i] = perPixelSD;
						}
	
					selectWindow(inputName + "$t$");
					run("Crop");	
					getDimensions(w, h, c, s, f);
					run("Canvas Size...", "width=" + (w+2) + " height=" + (h+2) + " position=Center zero");
					run("Duplicate...", "duplicate");
					run("Skeletonize (2D/3D)");
					rename(inputName + "$t$ skeleton");

					//Calculate mean branch diameter
					if (ArrayContains(enabledNetworkParameters,"Mean Branch Diameter")==true)
					{
						mitoBranchDiameter[i] = calculateMeanBranchDiameter(inputName + "$t$",inputName + "$t$ skeleton");
					}

					selectWindow(inputName + "$t$ skeleton");
					run("Analyze Skeleton (2D/3D)", "prune=none calculate show");
	
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
						//Sphericals have a skeleton with zero branches, but we want to count them as a branch
						mitoBranchLongShort[i] += parseFloat(Table.get("Longest Shortest Path",j,"Results"));
						if (mitoBranchLongShort[i]==0 && mitoBranchLength[i]>0) mitoBranchLongShort[i]=mitoBranchLength[i];
						mitoBranchEndPoints[i] += parseInt(Table.get("# End-point voxels",j,"Results"));
						mitoBranchPoints[i] += parseInt(Table.get("# Junctions",j,"Results"));
					}
					if (mitoBranches[i]==0) mitoBranches[i]++;
					close(inputName + "$t$ skeleton");
					close(inputName + "$t$");
				}
				
			}
			close("Branch information");
		}
		if (isOpen(inputName)) close(inputName);
		if (isOpen("Count Masks of " + inputName)) close("Count Masks of " + inputName);
		if (isOpen("Mask of " + inputName)) close("Mask of " + inputName);
		if (isOpen("Results")) close("Results");
		setBatchMode(false);

		selectWindow(input);
		run("Select None");
		
		var tableName = "2D Analysis Data";// for " + input;
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

			for (i=0;i< mitoCount;i++)
			{
				row = Table.size(tablePerMito);
				Table.set("Image Name", row, inputName,tablePerMito);
				Table.set("Mito #", row, "Mito #" + (i + 1),tablePerMito);
				enabledMitoParameters = Array.concat(enabledMitoMorphP , enabledMitoNetworkP);
				for (c = 0; c<enabledMitoParameters.length; c++) 
				{
					Table.set(enabledMitoParameters[c],row,getMitoVariable(enabledMitoParameters[c],i),tablePerMito);
				}

				if (Channel_mask!="None") 
				{
					Table.set(Channel_mask_Name + " Intensity",row,ChMask[i],tablePerMito);
					Table.set(Channel_mask_Name + " SD",row,ChMaskSD[i],tablePerMito);
				}
				if (Channel_2!="None") 
				{
					Table.set(Channel_2_Name + " Intensity",row,Ch2[i],tablePerMito);
					Table.set(Channel_2_Name + " SD",row,Ch2SD[i],tablePerMito);
				}
				if (Channel_3!="None") 
				{
					Table.set(Channel_3_Name + " Intensity",row,Ch3[i],tablePerMito);
					Table.set(Channel_3_Name + " SD",row,Ch3SD[i],tablePerMito);
				}
	
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
						Table.set("(" + N1_Name + " / " + N2_Name + ") / " + N3_Name,row,ratio2,tablePerMito);
					}
					Table.set("Ratiometric SD (per pixel)",row,pixel_RatioSD[i],tablePerMito);
				}
			}
			Table.update;
		}
		//A fix for an intermittent error in ImageJ not updating tables
			if (doPerCell) { selectWindow(tablePerCell); Table.update; }
			if (doPerMito) { selectWindow(tablePerMito); Table.update; }
	}
	
	function getCellVariable(varName)
	{
		ans = 0;

		if (varName=="Count") ans = mitoCount;
		if (varName=="Total Area") ans = TotalArea;
		if (varName=="Mean Area") ans = TotalArea/mitoCount;
		if (varName=="Total Perimeter") ans = TotalPerimeter;
		if (varName=="Mean Perimeter") ans = TotalPerimeter/mitoCount;
		if (varName=="Mean Form Factor") ans = FF;
		if (varName=="Mean Aspect Ratio") ans = AR;
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
				if (new[1]=="area") denom = TotalArea;
				ans = getCellVariable(new[0]) / denom;
			}
		return ans;
	}

	function getMitoVariable(varName,mitoNum)
	{
		ans = 0;
		
		if (varName=="Area") ans = mitoArea[mitoNum];
		if (varName=="Perimeter") ans = mitoPerimeter[mitoNum];
		if (varName=="Form Factor") ans = mitoFF[mitoNum];
		if (varName=="Aspect Ratio") ans = mitoAR[mitoNum];
		if (varName=="Branches") ans = mitoBranches[mitoNum];
		if (varName=="Total Branch Length") ans = mitoBranchLength[mitoNum];
		if (varName=="Branch Junctions") ans = mitoBranchPoints[mitoNum];
		if (varName=="Longest Shortest Path") ans = mitoBranchLongShort[mitoNum];
		if (varName=="Branch End Points") ans = mitoBranchEndPoints[mitoNum];
		if (varName=="Mean Branch Length") ans =  mitoBranchLength[mitoNum] / mitoBranches[mitoNum];
		if (varName=="Mean Branch Diameter") ans =  mitoBranchDiameter[mitoNum];
			
		return ans;
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
						if (normal_Choice=="Area" || normal_Choice=="Show Both")
							normalNetworkParameters=Array.concat(normalNetworkParameters,network_Parameters[i] + "/area");
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

	function calculateMeanBranchDiameter(image_original,image_skeleton)
	{
		//Make 2D Euclidean Distance Map
		selectWindow(image_original);
		getPixelSize(unit, pWidth, pHeight);
		
		run("Geometry to Distance Map", "threshold=128");
		getStatistics(count, mean, min, dMax, std); 
		rename("EDT");
		
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
		getStatistics(count, mean, min, dMax, std); 
		//The mean distance of the skeleton from surface of object is radius, now multiply by 2
		meanBD = mean*2;
		if (isNaN(meanBD)) meanBD=0;
		//For punctate objects, the branch count can be 0, so we use use the maximum value from the EDT map instead.
		if (meanBD==0) meanBD=dMax*2;
		meanBD=meanBD*pWidth;
	 	close("EDT");
	 	close("32bit-skeleton");

	 	return meanBD;
	}

	function channelAnalysis(thresh,channel)
	{		
		measure = 0;
		measureSD =  0;
		
		run("Set Measurements...", "mean standard redirect=None decimal=3");
		
		imageCalculator("AND create", thresh,channel);
		rename("Intensity-temp");
			
		getStatistics(area, mean, min, max);
		if (max>0) 
		{
				selectWindow(thresh);
				run("Create Selection");
				//run("Make Inverse");
	
				selectWindow("Intensity-temp");
				run("Restore Selection");
				run("Measure");
				nResult = Table.size("Results");
				for (j = 0;j < nResult;j++) 
				{
					measure = parseFloat(Table.get("Mean",j,"Results"));
					measureSD = parseFloat(Table.get("StdDev",j,"Results"));
				}
			}
		//close("Results");
		close("Intensity-temp");

		intensityMean = measure;
		intensitySD = measureSD;
	}

	function calculatePerPixelSD(thresh,a,b,c)
	{
		first = InterpretRatio(a);
		second = InterpretRatio(b);
		third = InterpretRatio(c);
		measureSD =  0;
		
		run("Set Measurements...", "mean standard redirect=None decimal=3");
		
		imageCalculator("AND create", thresh,first);
		rename("Intensity-tempFIRST");
		imageCalculator("AND create", thresh,second);
		rename("Intensity-tempSECOND");

		imageCalculator("DIVIDE 32-bit", "Intensity-tempFIRST","Intensity-tempSECOND");
		rename("Intensity-temp");

		close("Intensity-tempFIRST");
		close("Intensity-tempSECOND");

		if (third!="None")
		{
			imageCalculator("AND create", thresh,third);
			rename("Intensity-tempTHIRD");
			imageCalculator("DIVIDE", "Intensity-temp","Intensity-tempTHIRD");
			rename("Intensity-temp");
			close("Intensity-tempTHIRD");
		}
			
		selectWindow(thresh);
		run("Create Selection");
		//run("Make Inverse");
	
		selectWindow("Intensity-temp");
		run("Restore Selection");
		run("Measure");
		nResult = Table.size("Results");
		for (j = 0;j < nResult;j++) 
		{
			measureSD = parseFloat(Table.get("StdDev",j,"Results"));
		}

		Table.reset("Results");
		close("Intensity-temp");

		perPixelSD = measureSD;
	}

	function InterpretRatio(ratioInput)
	{
		ratioOutput = "None";
		
		if (ratioInput=="Mask Channel") ratioOutput = Channel_mask;
		if (ratioInput=="Second Channel") ratioOutput = Channel_2;
		if (ratioInput=="Third Channel") ratioOutput = Channel_3;

		return ratioOutput;
	}
}
