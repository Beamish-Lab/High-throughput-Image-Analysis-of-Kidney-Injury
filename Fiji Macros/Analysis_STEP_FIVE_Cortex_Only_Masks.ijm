macro "Analysis_STEP_FIVE_Cortex_Only_Masks" {

/*
takes the section masks and a mask that defines the cortex/OSOM border and makes a new mask of the cortex+OSOM only.
*/


//if it's not running already, start the ROI manager
run("ROI Manager...");
run("Close All");

//clear out any previous ROIs
if (RoiManager.size!=0) { 
	roiManager("Deselect");  
	roiManager("Delete"); 
}

//get the directories for each of the user defined ROIs, the segmentations, and the output directory
default_path = "Enter path here";
Dialog.create("Processing Setup");
Dialog.addMessage("Add the directories for the FULL SIZE ROIs for the WHOLE SECTIONS and CORTEX/OSOM BORDER")
Dialog.addMessage("WARNING: THE TWO DIRECTORIES MUST EXACTLY THE SAME FILE NAMES!!")
Dialog.addDirectory("WHOLE SECTIONS Source Directory:",default_path);
Dialog.addDirectory("CORTEX/OSOM BORDER Source Directory:", default_path);
Dialog.show();
  
section_outline_directory_path = Dialog.getString();
cortex_outline_directory_path = Dialog.getString();

//set up the directory for export (in the same place as the input directory)
source_directory_components = split(cortex_outline_directory_path, "\\"); //get path to the input
output_directory_components = Array.slice(source_directory_components,0,source_directory_components.length-1); //extract the path to the source folder one level up 
output_directory_root_path = String.join(output_directory_components,"\\")+"\\CORTEX ONLY OUTLINES\\";
File.makeDirectory(output_directory_root_path);

//get list of files
section_outlines_to_process=getFileList(section_outline_directory_path); //make a list of the files that need to be processed
cortex_outlines_to_process=getFileList(cortex_outline_directory_path);
number_of_files=section_outlines_to_process.length;

//find the overlap of the two ROIs and save
for (aa=0;aa<number_of_files;aa++){
	current_section_outline_file = section_outlines_to_process[aa];
	current_cortex_outline_file = cortex_outlines_to_process[aa];
	if (current_section_outline_file != current_cortex_outline_file) {
		showMessage("Matching error, check files");
		exit;
	}
	open(section_outline_directory_path+current_section_outline_file); //open the section outline
	roiManager("Add"); // move this to the roi manager
	roiManager("Open",cortex_outline_directory_path+current_cortex_outline_file); //open the cortex roi in the roi manager
	roiManager("Select", newArray(0,1)); //select the two files.
	roiManager("AND"); //find the intersection
	roiManager("Add"); //add to the roi manager
	roiManager("Select", 2); //select the new roi, it should be in the 3 spot
	roiManager("Save", output_directory_root_path+current_cortex_outline_file); //save the file
	roiManager("Deselect");  // clear out the roi manager for the next file
	roiManager("Delete"); 

	run("Close All");
	
}
}