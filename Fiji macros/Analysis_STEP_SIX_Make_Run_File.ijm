macro "Analysis_STEP_SIX_Make_Run_File" {

/*
This macro is part I of a two part system to batch segment multiple images
This macro generates a table of all the data needed to segment each file and keeps track of which files are done.

YOU MUST have the ".caffemodel.h5" weight file already on the remote instance prior to tunning


*/

//clean up 
run("Close All");

default_path = "Select path"

//Obtain the base information regarding number of directories in the run and location of the run file
Dialog.create("Processing Setup");
Dialog.addNumber("Number of source directories in run:", 4);
Dialog.addDirectory("Directory to store run file:",default_path);
Dialog.show();

number_of_directories = Dialog.getNumber();
run_file_directory = Dialog.getString();

//setup the variables for the next data entry steps
source_directories = newArray(number_of_directories);
model_definition_paths = newArray(number_of_directories);
model_weight_paths = newArray(number_of_directories);

//get the source directories from the user
Dialog.create("ENTER THE SOURCE DIRECTORIES");
for (i = 0; i < number_of_directories; i++) {
	Dialog.addMessage("SOURCE DIRECTORIES")
  	Dialog.addDirectory("CHANNEL " + (i) + ": ",default_path);
}
Dialog.show();

for (i = 0; i < number_of_directories; i++) {
	source_directories[i] = Dialog.getString();
}

//get the model directories from the user for each source directory
Dialog.create("ENTER THE MODEL DIRECTORIES");
for (i = 0; i < number_of_directories; i++) {
	source_directory_components = split(source_directories[i], "\\"); //get path to the input
	//remind the user what source directory they are entering model info for, using only the last two parts of the directory to keep it simple
	directory_string = "ENTER MODEL INFO FOR ...\\" + source_directory_components[source_directory_components.length-2]+"\\"+source_directory_components[source_directory_components.length-1]; 
	Dialog.addMessage(directory_string)
	Dialog.addFile("Model Definition (...modeldef.h5) file:", default_path);
  	Dialog.addFile("Model Weight File (...caffemodel.h5) file:", default_path);
  	Dialog.addMessage("*************************")
}
Dialog.show();

for (i = 0; i < number_of_directories; i++) {
	model_definition_paths[i] = Dialog.getString();
	model_weight_paths[i] = Dialog.getString();
}

//confirm with the user everything is correct before proceeding:
Dialog.create("CONFIRMATION");
Dialog.addMessage("SOURCE DIRECTORIES:");
for (i = 0; i < number_of_directories; i++) {
Dialog.addMessage("C"+i+": "+ source_directories[i]);
}

Dialog.addMessage("MODEL DEFINITIONS (...modeldef.h5):")
for (i = 0; i < number_of_directories; i++) {
	current_definition = File.getName(model_definition_paths[i]);
	Dialog.addMessage("C"+i+": "+current_definition);
}


Dialog.addMessage("MODEL WEIGHTS (...caffemodel.h5):")
for (i = 0; i < number_of_directories; i++) {
	current_weight = File.getName(model_weight_paths[i]);
	Dialog.addMessage("C"+i+": "+current_weight);
}

Dialog.addMessage("IS THIS INFORMATION CORRECT???");
Dialog.show();

//find the total number of files that will go in this run file
total_file_number = 0;

for (aa = 0; aa < number_of_directories; aa++) {
	subgroup_files=getFileList(source_directories[aa]); 
	total_file_number=total_file_number + subgroup_files.length;
}

//set up the variables that will be needed to generated in the run file.
run_file_index = newArray(total_file_number);	
source_directory = newArray(total_file_number);	
source_file = newArray(total_file_number);	
model_definition_path = newArray(total_file_number);	
model_weight_path = newArray(total_file_number);	
model_weight_file = newArray(total_file_number);	
output_root_directory = newArray(total_file_number);	
completed_flag = newArray(total_file_number);

//fill in the variables for the run file
time_stamp = Make_Time_Stamp();
index = 0;
for (bb = 0; bb < number_of_directories; bb++) {
	subgroup_files=getFileList(source_directories[bb]); 
	subgroup_file_number = subgroup_files.length;
	
	for (cc = 0; cc < subgroup_file_number; cc++) {
		run_file_index[index] = index;	
		source_directory[index] = source_directories[bb];	
		source_file[index] = subgroup_files[cc];
		
		//pull out the model information
		model_definition_path[index] = model_definition_paths[bb];
		model_weight_path[index] = model_weight_paths[bb];
		model_weight_file[index] = File.getName(model_weight_paths[bb]);
		model_name_components = split(model_weight_file[index],"."); //extract the name of the file
		model_name = model_name_components[0]; //for use in generating the directories
		
		//set up the output directories, made in the same directory as the source; these will be used during when the run file is executed so should not be modified after generating the run file
		source_directory_components = split(source_directory[index], "\\"); 
		source_last_folder_name = source_directory_components[source_directory_components.length-1]; //find the name of the folder where the source is (one up from the source folder); this will be the root for the output folder
		output_directory_components = Array.slice(source_directory_components,0,source_directory_components.length-1); //extract the path to the source folder one level up 
		
		//make the output root directory
		output_root_directory[index] = String.join(output_directory_components,"\\")+"\\"+source_last_folder_name+"_"+time_stamp+"("+model_name+")";
		File.makeDirectory(output_root_directory[index] );
		
		//make the output directory for the segmentation files
		output_directory_segmentation_path = output_root_directory[index]+"\\Segmentation\\";
		File.makeDirectory(output_directory_segmentation_path); //makes the directory if it's not already there
		
		//make the output directory for the overlays
		output_directory_overlay_path = output_root_directory[index]+"\\Overlays\\";
		File.makeDirectory(output_directory_overlay_path); //makes the directory if it's not already there
		
		//increase the index for the next file
		index++;
	}
}

//save the Run file as a .csv
run_file_name = "Segmentation_RUN_FILE_" + time_stamp + ".csv";
Table.create(run_file_name);
Table.setColumn("run_file_index", run_file_index);
Table.setColumn("source_directory", source_directory);
Table.setColumn("source_file", source_file);
Table.setColumn("model_definition_path", model_definition_path);
Table.setColumn("model_weight_path", model_weight_path);
Table.setColumn("model_weight_file", model_weight_file);
Table.setColumn("output_root_directory", output_root_directory);
Table.setColumn("completed_flag", completed_flag);

Table.save(run_file_directory + run_file_name);
selectWindow(run_file_name);
run("Close");

}
		

function Make_Time_Stamp () {
    //function to make a time stamp of all digits e.g. 04052021_1423 for April 5, 2021 at 2:23 PM
     getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
     if (month<9) {time_stamp_output = "0";}//month is a zero based index 
     time_stamp_output = d2s(month+1,0);//month is a zero based index 
     if (dayOfMonth<10) {time_stamp_output = time_stamp_output+"0";}
     time_stamp_output = time_stamp_output+dayOfMonth;
     time_stamp_output = time_stamp_output+year+"_";
     if (hour<10) {time_stamp_output = time_stamp_output+"0";}
     time_stamp_output = time_stamp_output+hour;
     if (minute<10) {time_stamp_output = time_stamp_output+"0";}
     time_stamp_output = time_stamp_output+minute;
     return time_stamp_output;
  }
