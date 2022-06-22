/*
Author: Ahsen Chaudhry
Last updated: April 27, 2022
This macro will add each mitochondrial object in 3D stacks to the ROI manager. The assigned number labels to the mitochondria 
correspond to the results of the 3D Analysis command.
*/

macro Display3DMitoROI
{
	inputName = getTitle();
	if (checkIfThresholded(inputName)==false) exit("Needs a thresholded input");
	run("3D Manager");
	selectWindow(inputName);
	run("Select None");
	
	Stack.getDimensions(w, h, channels, slices, frames);
	if (slices==1) exit("Needs 3D input");
	if (frames>1) 
	{
		Stack.getPosition(channel, slice, frame);
		run("Duplicate...", "duplicate");
		inputName = inputName + " Frame: " + frame;
		rename(inputName);
	}
	
	var mitoCount;

	
	run("3D OC Options", "volume surface nb_of_obj._voxels mean_distance_to_surface dots_size=5 font_size=10 " + 
	"redirect_to=none");
	getVoxelSize(width, height, depth, unit);
	voxel = width*height*depth;
	sizeFilter = 0.05 / voxel;


	run("3D Objects Counter", "threshold=50 slice=27  min.=" + sizeFilter + " max.=13369344 objects");
	//run("3D Objects Counter", "threshold=50 slice=1 min.=" + sizeFilter + " max.=13369344 objects statistics summary");
	//mitoCount = Table.size("Results");
	//close("Results");


	selectWindow("Objects map of " + inputName);
	Ext.Manager3D_AddImage();	
	Ext.Manager3D_DeselectAll();
	Ext.Manager3D_LiveRoi();
	Ext.Manager3D_DeselectAll();

/*
	mitoCount = Ext.Manager3D_Count(nb_obj);
	print(mitoCount);
	for (i = 0; i < mitoCount;i++)
	{
		Ext.Manager3D_Select(i);
		newName = inputName + " Mito # " + (i+1);
		newNum = i + 1;
		Ext.Manager3D_Rename(newName );
	}
*/	
	Ext.Manager3D_DeselectAll();
	
	close("Objects map of " + inputName);
	selectWindow(inputName);

	
	function checkIfThresholded (image)
	{
		var thres = false;
	setBatchMode(true);
		selectWindow(image);
		run("Z Project...", "projection=[Max Intensity]");
		getHistogram(values,counts,256);
		counter = 0;
		for (i = 0; i < values.length; i++) {if (counts[i]>1) counter++;}
		if (counter<=2) thres = true;
		close("MAX_" + inputName);
		selectWindow(image);
	setBatchMode(false);
		return thres;
	}
}
