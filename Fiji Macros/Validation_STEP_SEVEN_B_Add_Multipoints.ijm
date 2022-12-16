macro Validation_STEP_SEVEN_B_Add_Multipoints {
//starts with a directory of images and adds 
//multipoints stored on the image as an overlay at the centroid of the nuclei found by segmentations
//by default the smallest nucleus size included in 9 um2

/////////////////////////////////////////////
//CLEAN UP BEFORE STARTING
/////////////////////////////////////////////

//close any other windows
//close image windows
OpenWindows = getList("image.titles");
if(OpenWindows.length!=0) {
run("Close All");
}

//close the summary table if open
if(isOpen("Summary")) {
	selectWindow("Summary");
	run("Close");
}

//close the results table if open
if(isOpen("Results")) {
	selectWindow("Results");
	run("Close");
}


//if it's not running already, start the ROI manager
run("ROI Manager...");

//clear out any previous ROIs
if (RoiManager.size!=0) { 
	roiManager("Deselect");  
	roiManager("Delete"); 
}

/////////////////////////////////////////////
//GET and SET PARAMETERS
/////////////////////////////////////////////

//SET UP THE MEASUREMENTS
run("Set Measurements...", "centroid display redirect=None decimal=3");		
setOption("ExpandableArrays", true);						
						
//get directory and image list and min nucleus size
default_path_root = "...enter folder where segmented ROIs are located";

Dialog.create("Input parameters");
Dialog.addDirectory("Segmentation directory:", default_path_root);
Dialog.addNumber("Minimum nucleus area (for inclusion, um^2): ", 9);
Dialog.show();

seg_directory = Dialog.getString();
min_nucleus_area = Dialog.getNumber();

seg_file_list = getFileList(seg_directory);
number_of_seg_files = seg_file_list.length;


x_coordinates = newArray(0);
y_coordinates= newArray(0);

for (aa = 0; aa < number_of_seg_files; aa++) {

	//DAPI
	open(seg_directory+seg_file_list[aa]);
	
	//if there are any old overlays, remove them before starting
	run("Remove Overlay");

	getPixelSize(unit, pw, ph, pd);
	
	//find ROIs
	setThreshold(1, 255);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Fill Holes");
	run("Watershed");
	run("Analyze Particles...", "size="+min_nucleus_area+"-Infinity display");

	//extract the coordinates for each centroid
 	selectWindow("Results");
	x_coordinates_um = Table.getColumn("X");
	x_coordinates = ScaleArray(x_coordinates_um,1/pw);
	y_coordinates_um = Table.getColumn("Y");	
	y_coordinates = ScaleArray(y_coordinates_um,1/ph);
	Table.reset("Results"); //clear the table
	run("Close");
	
	//make a multipoint selection
	makeSelection("points", x_coordinates, y_coordinates);
	roiManager("Add");
	run("From ROI Manager");

	saveAs("TIFF", seg_directory+seg_file_list[aa]);	
						
	//clear the roi manager
	roiManager("Reset");  
	run("Close All");
	
}
}

function ScaleArray(array,multiplier) { 
// multiply all elements of an array by the multiplier parameter
for (i = 0; i < array.length; i++) {
	array[i] = array[i] * multiplier;
}
return array;
}

