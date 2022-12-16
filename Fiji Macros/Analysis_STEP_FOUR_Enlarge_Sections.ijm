macro "Analysis_STEP_FOUR_Enlarge_Sections" {

/*
Takes the LOW RES files generated from QuPath and re-enlarges them to full size from the scanned slide and makes low res images that can be used to rapidly generate the section outlines
*/

run("Close All");

//clear the roi manager
run("ROI Manager...");
if (RoiManager.size!=0) { 
	roiManager("Deselect");  
	roiManager("Delete"); 
}
	
//get the directories for the LOW RES rois and the scal factor
default_path = "enter directory here";
Dialog.create("Processing Setup");
Dialog.addMessage("Add the directories to ROIs exported from QuPath at low resolution:")
Dialog.addDirectory("Directory containing LOW RES ROIs:",default_path);
Dialog.addNumber("Scale Factor", 4);
Dialog.show();

source_directory = Dialog.getString();
scale_factor = Dialog.getNumber();
enlarge_factor_string = toString(scale_factor);

//make lists of files to process
files_to_process=getFileList(source_directory); //make a list of the files that need to be processed
number_of_files=files_to_process.length;

//set up the directory for export (in the same place as the input directory)
source_directory_components = split(source_directory, "\\"); //get path to the input
source_last_folder_name = source_directory_components[source_directory_components.length-1]; //find the name of the folder where the input is; this will be the root for the output folder
output_directory_components = Array.slice(source_directory_components,0,source_directory_components.length-1); //extract the path to the source folder one level up 
output_directory = String.join(output_directory_components,"\\")+"\\"+source_last_folder_name+" (FULL SIZE)"+"\\";
File.makeDirectory(output_directory);


//import each of the images in the directory
for (bb=0;bb<number_of_files;bb++) {
	//open the current ROI
	active_file_name = files_to_process[bb];
	open(source_directory+active_file_name);
	
	//add the roi to the manager
	roiManager("Add");
	
	//convert to overlay
	run("From ROI Manager");
	
	//remove the roi from the manager
	roiManager("Deselect");
	roiManager("Delete");
	
	//enlarge the image with overlay
	run("Scale...", "x="+enlarge_factor_string+" y="+enlarge_factor_string+" interpolation=Bilinear average create");
	
	//convert the overlay back to an roi
	run("To ROI Manager");
	
	//save the roi in the output folder
	roiManager("Save", output_directory+active_file_name);
	
	//remove the roi from the manager
	roiManager("Deselect");
	roiManager("Delete");
	
	//close all and reset
	run("Close All");
	
	}


}
