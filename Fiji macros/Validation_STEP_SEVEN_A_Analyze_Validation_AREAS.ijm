macro "Validation_STEP_SEVEN_A_Analyze_Validation_AREAS.ijm" {

//This macro compares one or more directories to a reference
//generated images showing the overlaps and for each image calculates the 
//pixel-wise sensitivity, specificity, PPV, NPV, and dice score

//////////////////////////////////////////////////////
//CLEAN UP BEFORE STARTING
//////////////////////////////////////////////////////

//close any other windows
OpenImages = getList("image.titles");
if(OpenImages.length!=0) {
run("Close All");
}

//if it's not running already, start the ROI manager
run("ROI Manager...");

//clear out any previous ROIs
if (RoiManager.size!=0) { 
	roiManager("Deselect");  
	roiManager("Delete"); 
}

//////////////////////////////////////////////////////
//GET THE FILE PATHS AND PARAMETERS FOR ANALYSIS
//////////////////////////////////////////////////////

//Find out how many directories there are going to be to analyze
Dialog.create("Processing Setup");
Dialog.addNumber("Number comparator groups to analyze (minimum 1)",1);
Dialog.show();

number_of_comparators = Dialog.getNumber()+1; //the reference is stored in slot 0 to the minimum for this index is 2
comparator_names = newArray(number_of_comparators); 
comparator_paths = newArray(number_of_comparators);
comparator_is_Segmentation_flags = newArray(number_of_comparators); 

//get the directories for each of the user defined ROIs, the segmentations, and the output directory

  //set up the default paths
  default_path_root = "...\\your path here\\";
  default_paths = newArray(number_of_comparators);
  for (i = 0; i < number_of_comparators; i++) {
  	default_paths[i] = default_path_root;
  }

  //specify some path defaults to for debugging
  default_paths[0]= default_path_root +"Reference Annotations\\ (.zip files containing annotations)";
  default_paths[1]= default_path_root +"Segmented Images ROIs\\  (.tif files of extracted segmentations)";
  if(number_of_comparators>2){
  default_paths[2]= default_path_root +"USER" + (i-1) + " images\\";
  }
  
  //set up the default comparator names
  default_comparator_names = newArray(number_of_comparators);
  default_comparator_names[0]= "REF";
  default_comparator_names[1]= "SEG";
  for (i = 2; i < number_of_comparators; i++) {
  	default_comparator_names[i] = "USER" + (i-1);
  }

  //set up the default is_Segmentation_flags
  default_is_segmentation_flags = newArray(number_of_comparators);
  default_is_segmentation_flags[1]= true;
  
  
  //make a dialog to get info from the user
  Dialog.create("Input Directories");
  Dialog.addMessage("For user-annotated ROIS, enter the path to the annotations (as .zip collections of rois, from QuPath)");
  Dialog.addMessage("For segmentations, enter the path to segmented images (as .tif files)");
  Dialog.addMessage("WARNING: Each INPUT directory above MUST have the same number of files with the same size, order, and file name root");
  Dialog.addCheckbox("Check if Reference is a segmentation", default_is_segmentation_flags[0]);
  Dialog.addString("Reference Name", default_comparator_names[0]);
  Dialog.addDirectory("Reference annotations:", default_paths[0]);
  for (i = 1; i < number_of_comparators; i++) {
  	Dialog.addMessage("Comparator"+i);
  	Dialog.addCheckbox("Check if Comparator"+i+" is a segmentation", default_is_segmentation_flags[i]);
  	Dialog.addString("Comparator"+i+" Abbreviation: ", default_comparator_names[i]);
    Dialog.addDirectory("Comparator"+i+" Directory: ", default_paths[i] );

  }
  Dialog.addMessage("Additional directories:");
  Dialog.addDirectory("Original images:", default_path_root+"Original Images ROIs\\");
  Dialog.addDirectory("Output directory:", default_path_root+"Validation Analysis\\");
  Dialog.show();
  
  for (i = 0; i < number_of_comparators; i++) {
   		comparator_is_Segmentation_flags[i] = Dialog.getCheckbox();
   		comparator_names[i] = Dialog.getString();
    	comparator_paths[i] = Dialog.getString();
  }

  originals_path = Dialog.getString();
  output_path = Dialog.getString();

  ref_path = comparator_paths[0];
  originals_to_process_list=getFileList(originals_path); 				
  ref_to_process_list=getFileList(ref_path); 

//process the comparisons

for(aa=1;aa<number_of_comparators;aa++){

	comparator_abbreviation = comparator_names[aa];
	comparator_to_process_list=getFileList(comparator_paths[aa]); 
	
	//first process the reference vs the segmentation
	compare_to_ref(originals_path, originals_to_process_list, ref_path, ref_to_process_list,comparator_paths[aa],comparator_to_process_list,comparator_abbreviation,output_path,comparator_is_Segmentation_flags[aa]);
	
}

print("\\Clear");
print("PROCESS COMPLETE");

}

function compare_to_ref(original_image_directory, original_image_list, reference_directory, reference_image_list,test_image_directory,test_image_list,test_abbreviation,output_directory,segmentation_flag) {
//performs runs the comparisons for each group

//find the number of files (check to make sure they are the same)
if((reference_image_list.length==original_image_list.length)&&(reference_image_list.length==test_image_list.length)){
	number_of_files = reference_image_list.length;
} else {
	print("Number of images in the following directories do not match:" +
	"\n"  + reference_image_list.length + " images in: " + reference_directory +
	"\n"  + original_image_list.length + " images in: " + original_image_directory +
	"\n"  + test_image_list.length + " images in: " + test_image_directory);
	showMessage("Image numbers do not match! Check image directories in log");
	exit;
}

//setup the data to store
reference = newArray(number_of_files);
comparator = newArray(number_of_files);
TP = newArray(number_of_files);
FP = newArray(number_of_files);
FN = newArray(number_of_files);
TN = newArray(number_of_files);
Sensitivity = newArray(number_of_files);
Specificity = newArray(number_of_files);
PPV = newArray(number_of_files);
NPV = newArray(number_of_files);
dice_score = newArray(number_of_files);


//process the files
for(aa=0;aa<number_of_files;aa++) {

	//check that the files match
	if(test_file_names(original_image_list[aa],reference_image_list[aa],test_image_list[aa])){
		showMessage("Files do not match! Check log for details");
		exit;
	}

	//define the inputs
	ori = original_image_directory + original_image_list[aa];
	ref = reference_directory + reference_image_list[aa];
	test = test_image_directory + test_image_list[aa];
	out = output_directory;

	//process the data
	segmentation_data = process_images(ori,ref,test,test_abbreviation,out,segmentation_flag);

	//save the data
	reference[aa] = ref;
	comparator[aa] = test;
	TP[aa] = segmentation_data[0];
	FP[aa]  = segmentation_data[1];
	FN[aa]  = segmentation_data[2];
	TN[aa]  = segmentation_data[3];
	Sensitivity[aa]  = segmentation_data[4];
	Specificity[aa]  = segmentation_data[5];
	PPV[aa]  = segmentation_data[6];
	NPV[aa]  = segmentation_data[7];
	dice_score[aa]  = segmentation_data[8];
}



	//store the data in a table
	table_name = "Summary of Reference vs "+test_abbreviation+".csv";
	Table.create(table_name);
	Table.setColumn("reference", reference);
	Table.setColumn("comparator", comparator);
	Table.setColumn("TP", TP);
	Table.setColumn("FP", FP);
	Table.setColumn("FN", FN);
	Table.setColumn("TN", TN);
	Table.setColumn("Sensitivity", Sensitivity);
	Table.setColumn("Specificity", Specificity);
	Table.setColumn("PPV", PPV);
	Table.setColumn("NPV", NPV);
	Table.setColumn("dice_score", dice_score);

	Table.save(output_directory + table_name);
	selectWindow(table_name);
	run("Close");
}

function process_images(original,reference,test_image,test_image_abbreviation,output_dir,segmentation_flag){
	//performs the calculations for testing metrics
	
	
	//set measurements
	run("Set Measurements...", "area_fraction display redirect=None decimal=3");
	
	//close any open images
	run("Close All");
	
	//clear the roi manager
	run("ROI Manager...");
	if (RoiManager.size!=0) { 
		roiManager("Deselect");  
		roiManager("Delete"); 
	}

	//make a temp directory to store the output images in during process (will be deleted after processing)
	temp_dir = output_dir+"\\temp\\";
	File.makeDirectory(temp_dir);
	
	//load the original
	open(original);
	original_image = getTitle();
	original_root = File.getNameWithoutExtension(original);
	h = getHeight();
	w = getWidth();

	//make a reference
	newImage("Ref", "8-bit white", w, h, 1);
	roiManager("Open", reference);
	roiManager("deselect");
	roiManager("combine"); //combine all rois together
	run("Clear Outside");
	setThreshold(1, 255);
	run("Convert to Mask");
	run("Invert LUT");
	saveAs("Tiff", temp_dir+original_root+"reference.tif");
	reference_image_title = getTitle();
	roiManager("Deselect");  
	roiManager("Delete"); 

	//make a test image
	//if the test image will be created from ROIs in the ROI manager:
	if (segmentation_flag == 0){
	newImage("Test"+test_image_abbreviation, "8-bit white", w, h, 1);
	roiManager("Open", test_image);
	roiManager("deselect");
	roiManager("combine"); //combine all rois together
	run("Clear Outside");
	roiManager("Deselect");  
	roiManager("Delete"); 

	//if the test image will be created from a segmented image (and therefore no additional processing is needed)
	} else {
	open(test_image);
	}

	//same for either
	//recheck the image to make sure there is at least some positive area (if there isn't, converting to mask will invert the image)
	setThreshold(1, 255);
	run("Convert to Mask");

	run("Invert LUT");
	saveAs("Tiff", temp_dir+original_root+"_Anno_area_"+test_image_abbreviation+".tif");
	test_image_title = getTitle();
	
	//find areas true positive area
	imageCalculator("AND create", reference_image_title,test_image_title);
	saveAs("Tiff", temp_dir+original_root+"_TP_"+test_image_abbreviation+".tif");
	TP_image_title = getTitle();
	run("Measure");
	TP = getResult("%Area",0)/100;
	run("Clear Results");

	//find false positive area
	imageCalculator("XOR create", test_image_title,TP_image_title);
	saveAs("Tiff", temp_dir+original_root+"_FP_"+test_image_abbreviation+".tif");
	FP_image_title = getTitle();
	run("Measure");
	FP = getResult("%Area",0)/100;
	run("Clear Results");

	//find false negative area
	imageCalculator("XOR create", reference_image_title,TP_image_title);
	saveAs("Tiff", temp_dir+original_root+"_FN_"+test_image_abbreviation+".tif");
	FN_image_title = getTitle();
	run("Measure");
	FN = getResult("%Area",0)/100;
	run("Clear Results");

	//create a color overlay
	run("Merge Channels...", "c1=" + FP_image_title+" c2="+ TP_image_title +" c7="+ FN_image_title +" create keep");
	run("RGB Color");

	//Add a legend
	setFont("SansSerif", 8, " antialiased");
	makeText("TP: OVERLAP", 0, 0);
	run("Add Selection...", "stroke=green fill=#81000000");
	makeText("FP: COMPARATOR ONLY", 0, 9);
	run("Add Selection...", "stroke=red fill=#81000000");
	makeText("FN: REFERENCE ONLY", 0, 18);
	run("Add Selection...", "stroke=yellow fill=#81000000");
	run("Select None");
	
	//save
	saveAs("Tiff", output_dir+original_root+"_Composite_REFv" +test_image_abbreviation+".tif");
	Composite_image_title = getTitle();

	//make overlay on the original image
	selectWindow(original_image);
	run("Add Image...", "image=" + Composite_image_title +" x=0 y=0 opacity=50 zero");
	
	//Add a legend
	setFont("SansSerif", 8, " antialiased");
	makeText("TP: OVERLAP", 0, 0);
	run("Add Selection...", "stroke=green fill=#81000000");
	makeText("FP: TEST ONLY", 0, 9);
	run("Add Selection...", "stroke=red fill=#81000000");
	makeText("FN: REFERENCE ONLY", 0, 18);
	run("Add Selection...", "stroke=yellow fill=#81000000");
	run("Select None");
	
	//save 
	saveAs("Tiff", output_dir+original_root+"_Overlay_REFv"+test_image_abbreviation+".tif");
	
	//clean up
	temp_file_list=getFileList(temp_dir);
	for (i = 0; i < temp_file_list.length; i++) {
 			File.delete(temp_dir+temp_file_list[i]); //empty the directory first
	}
	File.delete(temp_dir); //delete the directory after it has been emptied
	run("Close All");
	
	//calculate the testing metrics
	TN = 1 - TP - FP - FN;
	Sensitivity = TP / (TP + FN);
	Specificity = TN / (TN + FP);
	PPV = TP / (TP + FP);
	NPV = TN / (TN + FN);
	dice_score = 2*TP/((TP+FP) + (TP+FN));

	output = newArray(TP,FP,FN,TN,Sensitivity,Specificity,PPV,NPV,dice_score);

	return output;
}

function test_file_names(file1,file2,file3) {
	//makes sure that the first 5 parts of the file name match 
	//for our experiments files have the form: genotype_reporter_sex_tag__condition_channel_otherinfo
	//this macro checks only the first 5 parts, i.e. genotype_reporter_sex_tag__condition

	file1_components = split(file1, "_"); //break up the input file name by the _ parts. The files should be of the form form genotype_reporter_sex_tag__condition_channel_otherinfo, we keep only the first 5 of these.
	file1_components = Array.slice(file1_components,0,5); //extract only the root of the filename (the last index is NOT included)
	file1_root = String.join(file1_components,"_");//join the components back together to generate the filename root

	file2_components = split(file2, "_"); //break up the input file name by the _ parts. The files should be of the form form genotype_reporter_sex_tag__condition_channel_otherinfo, we keep only the first 5 of these.
	file2_components = Array.slice(file2_components,0,5); //extract only the root of the filename (the last index is NOT included)
	file2_root = String.join(file2_components,"_");//join the components back together to generate the filename root

	file3_components = split(file3, "_"); //break up the input file name by the _ parts. The files should be of the form form genotype_reporter_sex_tag__condition_channel_otherinfo, we keep only the first 5 of these.
	file3_components = Array.slice(file3_components,0,5); //extract only the root of the filename (the last index is NOT included)
	file3_root = String.join(file3_components,"_");//join the components back together to generate the filename root


	if(!((file1_root==file2_root)&&(file1_root==file3_root))){
		print("Matching error \nFile1:" + file1_root + "\nFile2:" + file2_root + "\nFile3:" + file3_root);
		return 1;
	} else {
		return 0;
	}

}
