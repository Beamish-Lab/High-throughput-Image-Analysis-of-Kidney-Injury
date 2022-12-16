macro "Analysis_STEP_SIX_Run_Batch_from_Run_File" {

/*
This macro is part II of a two part system to batch segment multiple images
This macro generates using the run file made in part I to perform the segmentations
It outputs both a segmentation result (at full size but saved as a .zip file) and a segmentation overlay file (as a .zip file but reduced to 50% resolution)

YOU MUST have the ".caffemodel.h5" weight file already on the remote instance prior to tunning

*/

setOption("ExpandableArrays",true);

run("Close All");

//Set the defaults
default_path = "Select the Run File"
default_RSA_key_file_path = "Enter path to the your .pem key file "; 

//Obtain the location of the Run File, the Key File, and the IP address of the AWS instance to use.
Dialog.create("Processing Setup");
Dialog.addFile("RUN FILE (.csv):", default_path);
Dialog.addFile("RSA Key File:", default_RSA_key_file_path);
Dialog.addString("Unet Host IP Address:", "00.000.00.0");
Dialog.show();

run_file_with_path = Dialog.getString();
run_file_name = File.getName(run_file_with_path);
RSA_key_file_path = Dialog.getString();
UNET_host_IP = Dialog.getString();

//open the run file
Table.open(run_file_with_path); 
Table.sort("run_file_index"); //note this code assumes that file is always sorted by index and the segmentations proceed in order by index

//pull the data out of the table, then close it
run_file_index = Table.getColumn("run_file_index");
source_directory = Table.getColumn("source_directory");
source_file = Table.getColumn("source_file");
model_definition_path = Table.getColumn("model_definition_path");
model_weight_path = Table.getColumn("model_weight_path");
model_weight_file = Table.getColumn("model_weight_file");
output_root_directory = Table.getColumn("output_root_directory");
completed_flag = Table.getColumn("completed_flag");
selectWindow(run_file_name);
run("Close");

number_of_files = run_file_index.length;

//find the index of the next file that needs to be run
first_file_index = 0;
while (completed_flag[first_file_index]==1) {
	first_file_index++;
}

//find the different model weight files that will be needed
unique_weight_file_index = 0;
unique_weight_files = newArray(1);
unique_weight_files[unique_weight_file_index] = model_weight_file[first_file_index];
unique_weight_file_index++;

for (aa = first_file_index+1; aa < number_of_files; aa++) {
	if(model_weight_file[aa-1]!=model_weight_file[aa]){
		unique_weight_files[unique_weight_file_index] = model_weight_file[aa];
		unique_weight_file_index++;
	}
}

number_of_unique_weight_files = unique_weight_file_index;

//Display the run information to verify before starting
Dialog.create("RUN INFO");
Dialog.addMessage("IP: " + UNET_host_IP);
Dialog.addMessage("RSA Key File: " + RSA_key_file_path);
Dialog.addMessage("First File Directory (check path):  " + source_directory[first_file_index]);
Dialog.addMessage("Number of files to be processed:  " + (number_of_files-first_file_index));
Dialog.addMessage("First File:  " + source_file[first_file_index]);
Dialog.addMessage("Required weight files (.caffemodel.h5, ensure these are uploaded to the EC2 Instance before proceeding):");
for (i = 0; i < number_of_unique_weight_files; i++) {
	Dialog.addMessage(unique_weight_files[i]);
}
Dialog.addMessage("CANCEL TO ABORT");
Dialog.show();

for (aa = first_file_index; aa < number_of_files; aa++) {

//perform the segmentation
Perform_Segmentation(source_directory[aa],source_file[aa],model_definition_path[aa],model_weight_file[aa],RSA_key_file_path,UNET_host_IP,output_root_directory[aa]);

//mark the segmentation as complete
completed_flag[aa] = 1;

//update the completion flag in the table
Table.open(run_file_with_path); 
Table.setColumn("completed_flag", completed_flag);
Table.save(run_file_with_path);
selectWindow(run_file_name);
run("Close");

//update the log on our status
print("File " + (aa+1) + " of " + number_of_files + " completed"); //update the status in the log window
}
	
print("BATCH SEGMENTATION COMPLETED");
}
			
function Perform_Segmentation(source_path,image,definition_file_with_path,weight_file,RSA_key_file_path,UNET_host_IP,output_root_path) {
//this function performs the segmentations


	//set up output folders for the overlays and segmentations (assumed to be withing the output_root_path
	output_directory_segmentation_path = output_root_path+"\\Segmentation\\";
	output_directory_overlay_path = output_root_path+"\\Overlays\\";
	
	//set the b/c for the overlay reduced image determine this manually before starting
	min_1 = 10; // minimum for B/C adjustment  
	max_1 = 120; // maximum for B/C adjustment
	
	// define all the parameters for the UNET function call
	UNET_process = "de.unifreiburg.unet.SegmentationJob.processHyperStack"; 
	UNET_parameters = newArray(14);
		UNET_parameters[0] = "modelFilename="+definition_file_with_path;
		UNET_parameters[1] = "Tile shape (px):=500x500";
		UNET_parameters[2] = "weightsFilename="+weight_file;
		UNET_parameters[3] = "gpuId=all available";
		UNET_parameters[4] = "useRemoteHost=true";
		UNET_parameters[5] = "hostname="+UNET_host_IP;
		UNET_parameters[6] = "port=22";
		UNET_parameters[7] = "username=ubuntu";
		UNET_parameters[8] = "RSAKeyfile="+RSA_key_file_path;
		UNET_parameters[9] = "processFolder=";
		UNET_parameters[10] = "average=none";
		UNET_parameters[11] = "keepOriginal=false";
		UNET_parameters[12] = "outputScores=false";
		UNET_parameters[13] = "outputSoftmaxScores=false";
	
	UNET_parameter_argument = String.join(UNET_parameters,",");
	
	//extract the model name
	model_name_components = split(weight_file,"."); //extract the name of the file, i.e. the part before ".caffemodel.h5"
	model_name = model_name_components[0];
	
	//generate the output file names
	active_file_name = image;
	active_file_name_root = File.getNameWithoutExtension(active_file_name);
	segmentation_file_name = active_file_name_root + "_SEGMENTATION_" +"("+model_name+").zip";
	overlay_file_name = active_file_name_root + "_OVERLAY_" +"("+model_name+").zip";
	
	//open the file and run the UNET Process
	print(source_path+active_file_name);
	open(source_path+active_file_name);
	original_image_width = getWidth();
	original_image_height = getHeight();
	call(UNET_process,UNET_parameter_argument); //this line will call the UNET algorithm which will first convert the image to an appropriately scaled one taht is 32 bit then send this file to the backend for processing then generate a segmented image
	
	//save the segmentation output
	selectImage(2);
	run("8-bit"); //convert to 8 bit image to save space
	run("Scale...", "width="+original_image_width+" height="+original_image_height+" interpolation=None create"); //scales the output image back to the size of the original file (UNET scales the input to be consistent size scale, in microns, as the training images)
	saveAs("ZIP",output_directory_segmentation_path+"\\"+segmentation_file_name); //save as zip since these files are mostly 0's, saves large amounts of space
	segmentation_window_name = getTitle();
	
	//close the other images
	selectImage(2); //closes the original size segmentation output
	close();
	selectImage(1); //closes the normalized, rescaled image generated by UNET
	close();
	
	//generate an overlay image
	
	//open and scale the original images
	open(source_path+active_file_name); //reopen the original image
	setMinAndMax(min_1, max_1); //set brightness and contrast with setting input above
	run("Scale...", "x=0.5 y=0.5 interpolation=None average create"); //downscale the original image by 50% to save space (this image is for reference to qualitatively assess the accuracy of the segmentation, not for analysis)
	scaled_image_window_name = getTitle(); //store the name of the output from above
	
	//scale and modify the segmentation image
	selectImage(segmentation_window_name); 
	run("Scale...", "x=0.5 y=0.5 interpolation=None average create"); //downscale the original image by 50% to save space (this image is for reference to qualitatively assess the accuracy of the segmentation, not for analysis)
	//	run("Green"); setMinAndMax(0, 128); //convert the segmented image to bright green 
	run("Yellow"); setMinAndMax(0, 128); //convert the segmented image to bright yellow 
	//	run("Magenta"); setMinAndMax(0, 128); //convert the segmented image to bright magenta 
	scaled_segmentation_window_name = getTitle(); //store the name of the output from above
	selectImage(scaled_image_window_name);
	
	//generate and save the segmentation image
	run("Add Image...", "image=["+scaled_segmentation_window_name +"] x=0 y=0 opacity=75 zero"); //add the segmentation overlay to the reduced image
	saveAs("ZIP",output_directory_overlay_path+"\\"+overlay_file_name); //save as zip to save space
	
	run("Close All"); // close all the windows to prepare for the next image

}

