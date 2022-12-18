macro "Training_STEP_THREE_Make_Training_ROIs [q]" {
	
//Macro helps the user extract training rois.
//output are two new directories: 
//"ROI Locations" contains .roi files that show the location on the original images 
//"ROIs (Cropped Images-ALL)" contains cropped tif files that can be used for training later
//these directories are placed in the the "[marker]-Extracted Training Images (ALL)" same root directory as the open original image file directory.
//this macro requires that you open each original image separately
//the shortcut above "[q]" can be customized, but allows the use to run the code repeatedly to generate many rois. 

/////////////////////////////////////////////////////////
//SETUP
/////////////////////////////////////////////////////////

//set up to the default ROI size the ROIs	
width_micron = 200; // in microns; can be adjusted
height_micron = width_micron; //make square ROI

//make sure the that data tables generate copy all the header and index rows/columns into excel
run("Input/Output...", "jpeg=85 gif=-1 file=.csv copy_column copy_row save_column save_row");

//make sure expandable arrays are available
setOption("ExpandableArrays",true);

run("ROI Manager...");
if (RoiManager.size!=0) { 
		roiManager("Deselect");  
		roiManager("Delete"); 
}

run("Select None");

time_stamp = Make_Time_Stamp();

/////////////////////////////////////////////////////////
//RUN
/////////////////////////////////////////////////////////

//get the name and directory of the current image
full_original_title = getTitle();
full_original_directory = getInfo("image.directory");

//extract information from the file name of the image
file_root = ExtractFileNameRoot(full_original_title);
marker = ExtractMarker(full_original_title);

//make the output directories 
project_root_directory = Directory_Up_One_Level(full_original_directory);
output_root_directory = project_root_directory+marker+"-Extracted Training Images (ALL)\\"; 
roi_directory = output_root_directory+"ROI Locations\\";
cropped_original_directory = output_root_directory+"ROIs (Cropped Images-ALL)\\";
File.makeDirectory(output_root_directory);
File.makeDirectory(roi_directory);
File.makeDirectory(cropped_original_directory);

//check to see if there are already ROIs that have been extracted in the directory, and if there are, add to them. 
ROI_number = FindROINumber(file_root,roi_directory);
roi_output_name_with_path = roi_directory + file_root + "_" + marker + "_ROI-" + ROI_number + ".roi";
cropped_original_output_name_with_path = cropped_original_directory + file_root + "_" + marker + "_ROI-" + ROI_number + ".tif";

//convert to pixels for ROI
getPixelSize(unit, pw, ph, pd);	
width_pixel = width_micron / pw;
height_pixel = height_micron / pw;						

//let the user put a point on the image in the vicinity of the desired roi																																				
setTool("point");
waitForUser("Set point at center of desired ROI and click OK");
roiManager("Add");
roiManager("Select", 0);
Roi.getCoordinates(xpoints, ypoints);
x_pixel = xpoints[0];
y_pixel = ypoints[0];

//clear the ROI Manager
roiManager("Deselect");  
roiManager("Delete"); 

//show the ROI
makeRectangle(x_pixel-width_pixel/2,y_pixel-height_pixel/2,width_pixel,height_pixel);

//as the user to adjust the roi box as needed
waitForUser("Adjust the ROI as needed and click OK\nNOTE: current ROI size is " + width_micron + "x" + height_micron + " microns");
getSelectionBounds(x_new, y_new, width_new, height_new);
x_pixel = x_new + width_new / 2;
y_pixel = y_new + height_new / 2;

x_micron = x_pixel * pw; //store as microns so can be translated to images with other scales
y_micron = y_pixel * pw; //store as microns so can be translated to images with other scales

//open and crop the original
run("Duplicate...","temp");

//make the new ROI
makeRectangle(x_pixel-width_pixel/2,y_pixel-height_pixel/2,width_pixel,height_pixel);
roiManager("Add");
roiManager("Select", 0);
roiManager("save selected", roi_output_name_with_path);

//generated the cropped original
run("Crop");
saveAs("Tiff", cropped_original_output_name_with_path);
close();

}

function ExtractFileNameRoot(current_file){
	//extracts the first five parts of the file name in the form part1_part2_part3_part4_part5_marker.tif for example extract "WT_GFP_M_0001_FA2" from "WT_GFP_M_0001_FA2_Ki67.tif"
	current_file_no_extension = File.getNameWithoutExtension(current_file); //remove the extension
	current_file_components = split(current_file_no_extension, "_"); //break up the input file name by the _ parts. 
	current_file_components = Array.slice(current_file_components,0,5); //extract only the root of the filename (the last index is NOT included)
	current_file_root = String.join(current_file_components,"_");//join the components back together to generate the filename root
	
	return current_file_root;
}

function ExtractMarker(current_file){
	//extracts the sixth part of the file name in the form part1_part2_part3_part4_part5_marker.tif for example extracts "Ki67" from "WT_GFP_M_0001_FA2_Ki67.tif"
	current_file_no_extension = File.getNameWithoutExtension(current_file); //remove the extension
	current_file_components = split(current_file_no_extension, "_"); //break up the input file name by the _ parts. The files should be of the form form genotype_reporter_sex_tag__condition_channel_otherinfo, we keep only the first 5 of these.
	marker_name = current_file_components[5];
	return marker_name;
}

function Directory_Up_One_Level(directory){
	//finds the path to the directory one level up from the input directory
  	directory_components = split(directory, "\\"); 
	if(directory_components.length !=1) {
		one_level_up_directory_components = Array.slice(directory_components,0,directory_components.length-1); //extract the path to the source folder one level up 
		one_level_up_directory = String.join(one_level_up_directory_components,"\\")+"\\";
	} else {
		one_level_up_directory = directory; //if there is no directory one level up, then return the base directory back.
	}
	return one_level_up_directory;
}

function FindROINumber(input_file_root,directory){
	//looks for the last ROI in the directory and adds one to that by counting the files in the directory that have the file root; returns 1 if no ROIs are found
	ROI_number = 1;
	file_list = getFileList(directory);
	for(aa=0;aa<file_list.length;aa++){
		current_file_root = ExtractFileNameRoot(file_list[aa]);
		if (current_file_root==input_file_root) {
			ROI_number++;
		}
	}
	return ROI_number;	
}

function FindFile(input_file_root,directory){
	//returns the full name of the file in a directory with the root (if there are zero or more than one file with the root, it will return an error)
	files_found = 0;
	file_list = getFileList(directory);
	for(aa=0;aa<file_list.length;aa++){
		current_file_root = ExtractFileNameRoot(file_list[aa]);
		if (current_file_root==input_file_root) {
			output_file = file_list[aa];
			files_found++;
		}
	}
	if (files_found==1) {
	 	return output_file;	
	} else if (files_found==0) {
		print("ERROR: NO FILE FOUND");
		print("looking for file root: " + input_file_root);
		print("in directory: " + directory);
		showMessage("Error in finding file. See log");		
	} else {
		print("ERROR: MORE THAN ONE MATCHING FILE FOUND");
		print("looking for file root: " + input_file_root);
		print("in directory: " + directory);
		showMessage("Error in finding file. See log");	
	}
}

function Make_Time_Stamp () {
	//makes a date and time stamp for file naming    
	 getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	 time_stamp_output = ""; 
	 if (month<9) {time_stamp_output = "0";}//month is a zero based index 
	 time_stamp_output = time_stamp_output+ d2s(month+1,0);//month is a zero based index 
	 if (dayOfMonth<10) {time_stamp_output = time_stamp_output+"0";}
	 time_stamp_output = time_stamp_output+dayOfMonth;
	 time_stamp_output = time_stamp_output+year+"_";
	 if (hour<10) {time_stamp_output = time_stamp_output+"0";}
	 time_stamp_output = time_stamp_output+hour;
	 if (minute<10) {time_stamp_output = time_stamp_output+"0";}
	 time_stamp_output = time_stamp_output+minute;
	 return time_stamp_output;
}
 