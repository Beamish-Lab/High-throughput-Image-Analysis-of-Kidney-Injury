macro "Analysis_STEP_ONE_Make_Low_Resolution_Images" {

/*
This Macro take full resolution .tif images 
and makes low res images that can be used to rapidly generate the section outlines in QuPath

While not strictly necessary, these smaller files will load much more quickly without unacceptable loss of resolution 
allowing the outlines to be created quickly
*/

run("Close All");

//get the directories for each of the user defined ROIs, the segmentations, and the output directory
  default_path = "Select path here"
  Dialog.create("Processing Setup");
  Dialog.addMessage("Add the directories for the FULL SIZE images that you want to use to make section outlines")
  Dialog.addDirectory("Source Directory for whole sections:",default_path);
  Dialog.addDirectory("Source Directory for cortex/OSOM border:", default_path);
  Dialog.addNumber("Scale Factor", 4);
  Dialog.show();
  
whole_section_source_directory = Dialog.getString();
cortex_source_directory = Dialog.getString();
scale_factor = Dialog.getNumber();
reduction_factor = 1/scale_factor;
reduction_factor_string = toString(reduction_factor);


//////////////////////////////////////////////////////////////////
//RUN FOR SECTION OUTLINE DIRECTORY DIRECTORY
//////////////////////////////////////////////////////////////////

source_directory = whole_section_source_directory;

//make lists of files to process
files_to_process=getFileList(source_directory); //make a list of the files that need to be processed
number_of_files=files_to_process.length;

//set up the directory for export (in the same place as the input directory)
source_directory_components = split(source_directory, "\\"); //get path to the input
source_last_folder_name = source_directory_components[source_directory_components.length-1]; //find the name of the folder where the input is; this will be the root for the output folder
output_directory_components = Array.slice(source_directory_components,0,source_directory_components.length-1); //extract the path to the source folder one level up 
output_directory = String.join(output_directory_components,"\\")+"\\"+source_last_folder_name+" (LOW RES)"+"\\";
File.makeDirectory(output_directory);

//open, scale and increase contrast of each file, then save
for (bb=0;bb<number_of_files;bb++) {
	active_file_name = files_to_process[bb];
	open(source_directory+active_file_name);
	run("Scale...", "x="+reduction_factor_string+" y="+reduction_factor_string+" interpolation=Bilinear average create");
	run("Enhance Contrast", "saturated=0.35");
	//save
	saveAs("tiff",output_directory+active_file_name);
	run("Close All");
	
	}

//////////////////////////////////////////////////////////////////
//RUN FOR CORTEX/OSOM MARKER (USUALLY GFP) DIRECTORY
//////////////////////////////////////////////////////////////////

source_directory = cortex_source_directory;

//make lists of files to process
files_to_process=getFileList(source_directory); //make a list of the files that need to be processed
number_of_files=files_to_process.length;

//set up the directory for export (in the same place as the input directory)
source_directory_components = split(source_directory, "\\"); //get path to the input
source_last_folder_name = source_directory_components[source_directory_components.length-1]; //find the name of the folder where the input is; this will be the root for the output folder
output_directory_components = Array.slice(source_directory_components,0,source_directory_components.length-1); //extract the path to the source folder one level up 
output_directory = String.join(output_directory_components,"\\")+"\\"+source_last_folder_name+"(LOW RES)"+"\\";
File.makeDirectory(output_directory);

//open, scale and increase contrast of each file, then save
for (bb=0;bb<number_of_files;bb++) {
	active_file_name = files_to_process[bb];
	open(source_directory+active_file_name);
	run("Scale...", "x="+reduction_factor_string+" y="+reduction_factor_string+" interpolation=Bilinear average create");
	run("Enhance Contrast", "saturated=0.35");
	//save
	saveAs("tiff",output_directory+active_file_name);
	run("Close All");
	
	}
}
