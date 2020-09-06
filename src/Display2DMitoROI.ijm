/*
Author: Ahsen Chaudhry
Last updated: June 14, 2019
This macro will add each mitochondrial object in 2D slices to the ROI manager. The assigned number labels to the mitochondria 
correspond to the results of the 2D Analysis command.
*/

macro Display2DMitoROI
{
	inputName = getTitle();
		isThresholded = false;
		getHistogram(values,counts,256);
		counter = 0;
		for (i = 0; i < values.length; i++) {if (counts[i]>1) counter++;}
		if (counter<=2) isThresholded = true;
		if (isThresholded==false) exit("Needs a thresholded input");
	
	var mitoCount;
	run("ROI Manager...");
	setBatchMode(true);
	sizeFilter = 0.06;//microns^2
	run("Set Measurements...", "area perimeter shape redirect=None decimal=3");
	run("Analyze Particles...", "size="+sizeFilter+"-Infinity show=[Count Masks] display clear");
	mitoCount = Table.size("Results");
	close("Results");
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
		selectWindow(inputName);
		run("Restore Selection");
		roiManager("add");	
		roiManager("select", roiManager("count")-1);			
		roiManager("rename", "Mito# " + (i+1));
		selectWindow(inputName + "$t$");
		close(inputName + "$t$");
	}
	close("Count Masks of " + inputName);
	setBatchMode(false);
	selectWindow(inputName);
}
