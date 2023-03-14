macro "Analysis_STEP_EIGHT_Analyze_Segmentations" {

/*
Macro analyzes a directory of segmentation images (produced by batch segmentation and saved as .zip files)
Requires a parallel directory of section outlines 

The two directories have to have the same number of files and have matching files with the same file root (the first 5 parts of the file)
in the form: part1_part2_part3_part4_part5_part6...other info; for example: the "WT_GFP_M_0001_FA2" part of WT_GFP_M_0001_FA2_Ki67.tif

User must also specify the minimum size of particles to analyze

Generates a summary file that contains the total area of the outline, the number detections in the area, the area of the detections (all), area of detections (only those > minimum size), and the area fractions.
*/

time_stamp = Make_Time_Stamp();

//make sure the that data tables generate copy all the header and index rows/columns into excel
run("Input/Output...", "jpeg=85 gif=-1 file=.csv copy_column copy_row save_column save_row");

//clear everything out before starting
run("Close All");

if(isOpen("Results")){
	selectWindow("Results");
	run("Close");
}

run("ROI Manager...");
if (RoiManager.size!=0) { 
		roiManager("Deselect");  
		roiManager("Delete"); 
}

//set the measurements
run("Set Measurements...", "area area_fraction display redirect=None decimal=6");

//user input information for analysis

//set the directories with the data 
Dialog.create("Processing Setup");
Dialog.addMessage("CHOOSE THE DIRECTORIES FOR ANALYSIS")
Dialog.addDirectory("Segmentations (*.zip): ", "Select path to files...");
Dialog.addDirectory("Section Outlines (*.roi): ", "Select path to files...");
Dialog.addDirectory("Output directory: ","Select path where you want to store the results...");

//add the parameters
Dialog.addString("Channel 1 name (e.g. \"Ki67\"): ","C1_name"); 
Dialog.addMessage("\nEnter the size parameters\nSize: size of \"particles\" included when analyzing segmentation results\n(Typical sizes: 9 um^2 for nuclei, 314 um^2 for tubules, 0 to analyze all detections)");
Dialog.addNumber("Minimum size (um^2): ", 9);
Dialog.addMessage("Note: analysis of the all segmentation will ALSO be performed automatically");

Dialog.show();

//extract the data from the user interface
C1_directory= Dialog.getString();
section_outline_directory = Dialog.getString();
output_directory = Dialog.getString();
C1_name = Dialog.getString();
min_C1_area = Dialog.getNumber();

C1_directory = CheckForSegmentationFolder(C1_directory);

//check the files
IsOK = CompareDirectories(C1_directory,section_outline_directory);
if(IsOK!=0){
	showMessage("Matching error, see log and check files");
	exit;
}

//make lists of the files
files_to_process=getFileList(C1_directory); 
outlines_to_process=getFileList(section_outline_directory);//make a list of the files that need to be processed
number_of_files=files_to_process.length;

//set up the output data arrays
segmentation_with_path = newArray(number_of_files);
outline_with_path = newArray(number_of_files);
total_area = newArray(number_of_files);
unfiltered_C1_area = newArray(number_of_files);
C1_count = newArray(number_of_files);
filtered_C1_area = newArray(number_of_files);
unfiltered_area_fraction = newArray(number_of_files);
filtered_area_fraction = newArray(number_of_files);
percent_area = newArray(number_of_files);


//analyze the files
for (aa=0; aa<number_of_files; aa++) {

	//make note of the files and find it's first 5 parts
	current_file=files_to_process[aa];
	current_file_components = split(current_file, "_"); //break up the input file name by the _ parts. The files should be of the form genotype_reporter_sex_tag_condition_channel_otherinfo, we keep only the first 4 of these.
	current_file_components = Array.slice(current_file_components,0,5); //extract only the root of the filename (the last index is NOT included)
	image_ID = String.join(current_file_components,"_");//join the components back together to generate the filename root

	current_outline=outlines_to_process[aa];

//open the current file
	open(C1_directory+current_file);
	C1_file_window_name = getTitle();
	
	//open the section outline
	roiManager("Open",section_outline_directory+current_outline);
	
	//make binary
	selectWindow(C1_file_window_name);
	setThreshold(1, 255);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	
	//find the total area of the ROI and the area of the segmentation
	roiManager("Select", 0);
	run("Measure");
	selectWindow("Results");
	total_area[aa]= Table.get("Area",0);
	percent_area[aa]= Table.get("%Area",0);
	unfiltered_C1_area[aa] = total_area[aa] * (percent_area[aa]/100);
	
	//clean up
	run("Clear Results");
	roiManager("Deselect");  
	roiManager("Delete");
	
	//measure the area and count of the segmentations only that meet the size requirements
	roiManager("Open",section_outline_directory+current_outline);
	roiManager("Select", 0);
	run("Analyze Particles...", "size=" + min_C1_area + "-Infinity summarize"); 
	selectWindow("Summary");
	C1_count[aa] = Table.get("Count",0);	
	filtered_C1_area[aa] = Table.get("Total Area",0);	
	Table.reset("Summary"); //clear the table
	run("Close");
	
	//find the percent area
	unfiltered_area_fraction[aa] = unfiltered_C1_area[aa] / total_area[aa];
	filtered_area_fraction[aa] = filtered_C1_area[aa] / total_area[aa];
	
	//note the full path used for each file for the summary table;
	segmentation_with_path[aa] = C1_directory+current_file;
	outline_with_path[aa] = section_outline_directory+current_outline;
	
	//clean up
	run("Close All");
	roiManager("reset");
	selectWindow("Results");
	run("Close");
	
	//update status
	print("File " + (aa+1) + " of " + number_of_files + " completed: "+image_ID); //update the status in the log window
}

//make a summary table

//create and save table of results as .csv
table_name = C1_name + " Analysis Summary (" + time_stamp + ").csv";
Table.create(table_name);
Table.setColumn("Segementation file", segmentation_with_path);
Table.setColumn("Section Outline file", outline_with_path);
Table.setColumn("Total Area (um^2)", total_area);
Table.setColumn(C1_name + " area (all) (um^2)", unfiltered_C1_area);
Table.setColumn(C1_name + " Count (>" + min_C1_area + " um^2)", C1_count);
Table.setColumn(C1_name + " area (>" + min_C1_area + " um^2) (um^2)", filtered_C1_area);
Table.setColumn(C1_name + " area fraction (all)", unfiltered_area_fraction);
Table.setColumn(C1_name + " area fraction (>" + min_C1_area + " um^2)", filtered_area_fraction);
Table.setColumn(C1_name + " area (all) (um^2)", unfiltered_C1_area);
Table.save(output_directory+table_name);
run("Close");

print("ANALYSIS COMPLETE. Result location: " + output_directory+table_name);
}

////////////////////////////////////////////////////
//FUNCTIONS
////////////////////////////////////////////////////

function CompareDirectories(directory1,directory2) { 
// make sure the file lists in the two directories match in the first 5 parts of the name in the form:
//part1_part2_part3_part4_part5_part6...other info; for example: the "WT_GFP_M_0001_FA2" part of WT_GFP_M_0001_FA2_Ki67.tif

directory1_to_process = getFileList(directory1); 
directory2_to_process = getFileList(directory2);
mismatch_flag = 0;
	
	if(directory1_to_process.length!=directory2_to_process.length){
		mismatch_flag = 1;
		print("NUMBER OF FILES IN DIRECTORIES DO NOT MATCH:\nDIRECTORY 1:\n" + directory1 + "\nDIRECTORY 2:\n" + directory2);
	} else {
		n_files = directory1_to_process.length;
		for (cc=0; cc<n_files; cc++) {
		
			//find the directory 1 file name root
			directory1_file=File.getNameWithoutExtension(directory1_to_process[cc]);
			directory1_ID_components = split(directory1_file, "_"); //break up the input file name by the _ parts. The files should be of the form form genotype_reporter_sex_tag__condition_channel_otherinfo, we keep only the first 5 of these.
			directory1_ID_components = Array.slice(directory1_ID_components,0,5); //extract only the root of the filename (the last index is NOT included)
			directory1_ID = String.join(directory1_ID_components,"_");//join the components back together to generate the filename root
		
			//find the directory 2 file name root
			directory2_file=File.getNameWithoutExtension(directory2_to_process[cc]);
			directory2_ID_components = split(directory2_file, "_"); //break up the input file name by the _ parts. The files should be of the form form genotype_reporter_sex_tag__condition_channel_otherinfo, we keep only the first 5 of these.
			directory2_ID_components = Array.slice(directory2_ID_components,0,5); //extract only the root of the filename (the last index is NOT included)
			directory2_ID = String.join(directory2_ID_components,"_");//join the components back together to generate the filename root
				
			if(directory1_ID!=directory2_ID){
				mismatch_flag = mismatch_flag++;
				print("FILE MISMATCH ERROR:\nDirectory 1 file: " + directory1_file + " DOES NOT MATCH:\nDirectory 2 file: " + directory2_file + "\nDirectory 1:\n" + directory1 + "\nDirectory 2:\n" + directory2);
			}
		}
		return mismatch_flag; //returns zero if all match
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

function CheckForSegmentationFolder(directory) {
	//returns the base directory if there is no segmentation directory or the segmentation path if there is one
	directory_file_list=getFileList(directory+"Segmentation\\"); 
	n_file_list = directory_file_list.length;
	
	//if there is not a Segmentation folder, then the number of files will be 0, in which case, count the files in the original directory
	if(n_file_list==0){
		return directory;
	} else {
		return directory + "Segmentation\\";
	}

	
}
