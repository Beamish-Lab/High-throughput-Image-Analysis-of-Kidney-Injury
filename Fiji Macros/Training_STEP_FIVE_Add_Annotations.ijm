macro "Training_STEP_FIVE_Add Annotations" {

/*
This macro adds quPath annotations to the training images, cleans the ROI names to the same name, and moves to image as overlay
This will make them compatible with U-Net training

warning: NO FILE NAME CHECKING, DOUBLE CHECK ANNOTATED IMAGES BEFORE TRAINING
warning: ONLY WORKS FOR ONE CLASS OF ANNOTATIONS (LABEL BELOW) and annotations labeled as "ignore"

*/

default_path = "\\ENTER YOUR PATH HERE\\"

//get information
Dialog.create("Enter annotation information")
Dialog.addString("Enter the name for the annotations","GFP+");
Dialog.addMessage("This macro will label all annotations as either the above label or \"ignore\"" );
Dialog.addDirectory("Unannotated Cropped Images (Original Images ROIs): ", default_path);
Dialog.addDirectory("Annotations as ROISet.zip (Annotations (from QuPath)):", default_path);
Dialog.addDirectory("Output Directory (Annotated Images for Training):", default_path);
Dialog.show();

annotation_name = Dialog.getString();
source_directory = Dialog.getString();
annotation_directory= Dialog.getString();
output_directory= Dialog.getString();

//source_directory=getDirectory("Choose a Image Directory For the Training Images"); //select directory where images are that you want to process
//annotation_directory = getDirectory("Choose a Annotation Directory (as ROISet.zip files) ");
//output_directory = getDirectory("Choose Output Directory ");


//start program
files_to_process=getFileList(source_directory); 
annotations_to_process=getFileList(annotation_directory);//make a list of the files that need to be processed
number_of_files=files_to_process.length;

roi_names_to_ignore = newArray("ignore","ignore*");

run("ROI Manager...");

for (aa=0; aa<number_of_files; aa++) {


	//target file
	current_file=files_to_process[aa];
	current_file_components = split(current_file,".");
	output_filename = current_file_components[0]+"_Annotated.tif";
	current_annotation=annotations_to_process[aa];

	//open the target image
	open(source_directory+current_file); //open target image
	run("Remove Overlay"); //if there are any overlays on the image removes them

	//open the current mask
	roiManager("Open",annotation_directory+current_annotation);
	number_of_annotations = RoiManager.size;

	//rename annotations
	for(bb = 0; bb<number_of_annotations; bb++){ 
		roiManager("Select", bb);
	
		//use this code to just remove numbers to get the root of the annotations
		current_annotation_name = Roi.getName;
		ROI_parts = split(current_annotation_name,"-");
		if(ROI_parts.length > 1) {
			current_annotation_name_root = ROI_parts[ROI_parts.length-1];
		} else {
			current_annotation_name_root = current_annotation_name;
		}

		//check if the annotation label is one that should be ignored
		if(Is_In_Array(roi_names_to_ignore,current_annotation_name_root)){
			roiManager("Rename", "ignore");
		} else {
			roiManager("Rename", annotation_name);
		}

	}

	//convert to overlay and save
	run("From ROI Manager");
	saveAs("TIFF", output_directory + output_filename);

	//clear the roi manager
	roiManager("Deselect");
	roiManager("Delete");

	run("Close All");

	print("File " + (aa+1) + " of " + number_of_files + " completed: "+current_file); //update the status in the log window
}
print("BATCH COMPLETE");
}

function Is_In_Array(array,target) {
	in_array_flag = 0;
	for (i = 0; i < array.length; i++) {
		if(array[i]==target){
			in_array_flag = 1;
		}
	}
	return in_array_flag;
}
