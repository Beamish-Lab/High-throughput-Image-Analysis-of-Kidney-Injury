macro "Prepreocessing_STEP_THREE_Process Slides to Single Channel" {

/*
Open pyramidal TIFF files extracted from QuPath then separate the channels, 
uses a key file to rename, and store these files in a destination directory
*/


//set up the number of channels
setOption("ExpandableArrays", true);
channel_name = newArray;

//get the directories for each of the user defined ROIs, the segmentations, and the output directory
default_path = "T:\\add directory here\\"
Dialog.create("Processing Setup");
Dialog.addMessage("Add the path to the directory with extracted pyramidal *.tif files exported from QuPath")
Dialog.addDirectory("Source Directory:", default_path);
Dialog.show();
source_directory = Dialog.getString();

//check each slide to make sure they all have the same number of channels; files must have the format slide_other info... .tif
n_channels = CheckChannels(source_directory);  

default_channel_names = newArray("DAPI","Kim1","Vcam1","GFP","Autofluorescence","C5","C6");

if (n_channels=="ERROR") {
	waitForUser("CHANNEL NUMBER IN THE IMAGES DOES NOT MATCH\nSEE LOG FOR DETAILS);
} else {

	Dialog.create("Processing Setup");
	Dialog.addDirectory("Output Directory:", default_path);
	Dialog.addFile("Key File:", default_path);
	Dialog.addMessage("Add the channel labels (no spaces)")
	Dialog.addMessage("WARNING!!: before running macro check a file manual to ensure mapping is correct")
	
	for (i = 0; i < n_channels; i++) {
	  Dialog.addString("Channel "+i+":", default_channel_names[i],18);
	}
	Dialog.show();
	
	output_directory = Dialog.getString();
	key_file = Dialog.getString();
	
	for (i = 0; i < n_channels; i++) {
	  channel_name[i] = Dialog.getString(); 
	}
} 

channel_directory = newArray(n_channels);

for (i = 0; i < n_channels; i++) {
	print(channel_name[i]);
}

//make lists of files to process
files_to_process=getFileList(source_directory); //make a list of the files that need to be processed
number_of_files=files_to_process.length;

//import keys to convert the input images from slide labels (e.g. "KK_IRI_Middle.tif") to decrypted file root name (e.g."P28P_TR_M_3933_IRI_") 
run("Table... ", "open=["+key_file+"]");
input_filename_key = Table.getColumn("Input File Name");
output_filename_root_key = Table.getColumn("Output File Root");
number_of_key_rows = input_filename_key.length;
close(File.getName(key_file));

rolling_ball_radius = 50; //set the rolling ball radius for background subtraction

//make the directories where the files will be stored
for (aa = 0;aa<n_channels;aa++) { 
	channel_directory[aa]= output_directory+channel_name[aa];
	File.makeDirectory(channel_directory[aa]);
}

//STATIC Bio-Formats Parameters (concatenated into the input argument in the loop below)
color_mode = "color_mode=Grayscale";
rois_import = "rois_import=[ROI manager]";
split_channels = "split_channels";
view = "view=Hyperstack";
stack_order= "stack_order=XYCZT use_virtual_stack series_1";

//generate a list of output file roots for the input files with the same indices
//not this is primitive code to do this decrypting by brute force
//this algorithm assumes all the files in the directory have a unique name
//will alert user if no match is found

output_filename_roots = newArray(number_of_files);
no_match_list = newArray;
setOption("ExpandableArrays", true);
match_flag = 0;
no_match_index = 0;

for (yy=0;yy<number_of_files;yy++){
	match_flag = 0; //reset the match flag
	active_file_name = files_to_process[yy];
	for (zz=0;zz<number_of_key_rows;zz++){
		if (active_file_name==input_filename_key[zz]) {
			output_filename_roots[yy] = output_filename_root_key[zz];
			match_flag = 1;
		}
	}
	if (match_flag!=1) {
		no_match_list[no_match_index] = active_file_name;
		no_match_index = no_match_index + 1;
	}
}

if (no_match_index != 0) {
	//make list of no match images
	no_match_display = "THE FOLLOWING IMAGES WERE NOT MATCHED IN THE KEY\n";
	for (xx=0;xx<no_match_index;xx++) {
		no_match_display = no_match_display+no_match_list[xx] + "\n";
	}
	showMessageWithCancel(no_match_display+"CANCEL TO EXIT");
}

//import each of the images in the directory
for (bb=0;bb<number_of_files;bb++) {
	active_file_name = files_to_process[bb];
	active_output_filename_root = output_filename_roots[bb];

	//Define the image specific Bio-Formats Parameters (concatenated into the input argument in the loop below)
	bioformats_input = "open=["+source_directory+active_file_name+"] "+" "+
		color_mode+" "+rois_import+" "+split_channels+" "+view+" "+stack_order;

	//run bioformats to load the pyramidal tiff file
	run("Bio-Formats Importer",bioformats_input);

	//process, save and close each single channel image
	for(cc=n_channels;cc>0;cc--) {  //start from the last image imported and work backward; image indices start at 1, not 0, so 
		
		//set up the output filename from the decoded inputs
		cc_index = cc - 1; //make an index which is one less than the image number
		file_path = channel_directory[cc_index] +"\\"+ active_output_filename_root + channel_name[cc_index];
			
		//subtract background for the image
		selectImage(cc);
		run("Subtract Background...", "rolling="+rolling_ball_radius);

		//save
		saveAs("tiff",file_path);

		close();
	}
print("File " + (bb+1) + " of " + number_of_files + " completed");

}

print("FILE PROCESSING COMPLETED");
}

function CheckChannels(directory){
	//quickly opens the pyramidal tif files using bioformats and extracts the number of channels from each
	//check to make sure this is the same for all the files in the directory
	//does NOT check that the channels are the same, you need to do this before running this step. 

	file_list = getFileList(directory);
	last_slide = "no slide";
	last_n = 0;
	//STATIC Bio-Formats Parameters (concatenated into the input argument in the loop below)
	color_mode = "color_mode=Grayscale";
	rois_import = "rois_import=[ROI manager]";
	split_channels = "split_channels";
	view = "view=Hyperstack";
	stack_order= "stack_order=XYCZT use_virtual_stack series_3"; //note the series 3 is used to dramatically speed up this step//may have an error if there is no series 3 in the pyramid

	print("Chan     Slide");

	channel_error_flag = 0;
	n_channels = 0;
	for (i = 0; i < file_list.length; i++) {

		current_file_with_path = directory + file_list[i];
		current_slide = GetSlideID(current_file_with_path);

		if(current_slide!=last_slide){
			//run bioformats to load the pyramidal tiff file
			bioformats_input = "open=["+current_file_with_path+"] "+" "+
			color_mode+" "+rois_import+" "+split_channels+" "+view+" "+stack_order;
			run("Bio-Formats Importer",bioformats_input);

			//find the number of channels
			temp_array = getList("image.titles");
			new_n_channels = temp_array.length;
			print(new_n_channels+"          "+current_slide);
			run("Close All");			
			last_slide = current_slide;
		}
		if(new_n_channels!=n_channels&&i!=0) {
			channel_error_flag = 1;		
		} else {
			n_channels = new_n_channels; 
		}
	}

	if(channel_error_flag){
		return "ERROR";
	} else {
		return n_channels;
	}
}

function GetSlideID(filename) {
	filename = File.getNameWithoutExtension(filename); 
	filename_components = split(filename, "_");
	return filename_components[0];
}