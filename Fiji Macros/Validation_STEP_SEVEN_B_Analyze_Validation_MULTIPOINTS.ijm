//set one global variable to pass between functions
var max_nucleus_radius = 5; 

macro "Validation_STEP_SEVEN_B_Analyze_Validation_MULTIPOINTS" {

//Analyze the results of segmentations of nuclei. Rather than annotating these with ROIs, there are analyzed with the multipoint tool which is stored 
//in an annotated images as an overlay.  The points are then matched with the centroids of the individually detected nuclei by segmentation, thresholding, or another user
//the input image overlay should consist of only ONE ROI with all of the points identified 

//////////////////////////////////////////////////////
//CLEAN UP BEFORE STARTING
//////////////////////////////////////////////////////

//close any other windows
OpenImages = getList("image.titles");
if(OpenImages.length!=0) {
run("Close All");
}
OpenNonImages = getList("window.titles");
if(OpenNonImages.length!=0) {
	for (i = 0; i < OpenNonImages.length; i++) {
		if(OpenNonImages[i]!="Interactive Interpreter"&&OpenNonImages[i]!="Debug"){
			selectWindow(OpenNonImages[i]);
			run("Close");
		}

	}

}

//if it's not running already, start the ROI manager
run("ROI Manager...");

//clear out any previous ROIs
if (RoiManager.size!=0) { 
	roiManager("Deselect");  
	roiManager("Delete"); 
}

setOption("ExpandableArrays", true);

//////////////////////////////////////////////////////
//GET THE FILE PATHS AND PARAMETERS FOR ANALYSIS
//////////////////////////////////////////////////////

//Find out how many directories there are going to be to analyze
Dialog.create("Processing Setup");
Dialog.addNumber("Number comparator groups to analyze (minimum 1)",1);
Dialog.show();

number_of_comparators = Dialog.getNumber()+1; //the ref standard is stored in slot 0 to the minimum for this index is 2
comparator_short_names = newArray(number_of_comparators); 
comparator_paths = newArray(number_of_comparators);
comparator_is_Segmentation_flags = newArray(number_of_comparators); 

//get the directories for each of the user defined ROIs, the segmentations, and the output directory

//set up the default paths

default_path_root = "...your path here\\";
default_paths = newArray(number_of_comparators);
for (i = 0; i < number_of_comparators; i++) {
	default_paths[i] = default_path_root + "ENTER YOUR PATH HERE";
}

//specify some path defaults
default_paths[0]= default_path_root +"Reference Annotations\\";
default_paths[1]= default_path_root +"Segmented Images ROIs with Multipoints\\";
if(number_of_comparators>2){
default_paths[2]= default_path_root +"Comparator 2\\";
}
if(number_of_comparators>3){
default_paths[3]= default_path_root +"Comparator 3\\";
}

//set up the default comparator names
default_comparator_short_names = newArray(number_of_comparators);
default_comparator_short_names[0]= "REF";
default_comparator_short_names[1]= "SEG";
for (i = 2; i < number_of_comparators; i++) {
	default_comparator_short_names[i] = "USER" + (i-1);
}

//set up the default is_Segmentation_flags
default_is_segmentation_flags = newArray(number_of_comparators);
default_is_segmentation_flags[1]= true;

Dialog.create("Input Directories");
Dialog.addMessage("Add the directories for the annotated images (ALL MUST be .tif files with an overlay of the multipoints as a single ROI)");
Dialog.addMessage("WARNING: Each INPUT directory above MUST have the same number of images of the same size, order, and file root");
Dialog.addString("Reference Name: ", default_comparator_short_names[0]);
Dialog.addDirectory("Reference Directory:", default_paths[0]);
for (i = 1; i < number_of_comparators; i++) {
	Dialog.addMessage("Comparator"+i);
	Dialog.addString("Comparator"+i+" Abbreviation: ", default_comparator_short_names[i]);
Dialog.addDirectory("Comparator"+i+" Directory: ", default_paths[i] );
}
Dialog.addMessage("Additional directories:");
Dialog.addDirectory("Original images:", default_path_root+"Original Images ROIs\\");
Dialog.addDirectory("Output directory:", default_path_root+"Validation Analysis\\");
Dialog.addNumber("Maximum nucleus radius (for colocalizing points, um): ", 5);
Dialog.show();

for (i = 0; i < number_of_comparators; i++) {
		comparator_short_names[i] = Dialog.getString();
	comparator_paths[i] = Dialog.getString();
}

originals_path = Dialog.getString();
output_path = Dialog.getString();
max_nucleus_radius = Dialog.getNumber();

//make directory to stort the point data files
point_data_output_path = output_path + "Point Data Files\\";
File.makeDirectory(point_data_output_path);


//set up some parameters to use later
ref_short_name = default_comparator_short_names[0];
ref_path = comparator_paths[0];
ref_to_process_list = getFileList(ref_path); 
number_of_ref_images = ref_to_process_list.length;
originals_to_process_list = getFileList(originals_path); 			  

//////////////////////////////////////////////////////
//RUN ANALYSIS
//////////////////////////////////////////////////////

//make the ref table
for(aa = 1; aa<number_of_comparators;aa++){
	//make an array to store the data in for the summary or each comparator
	ref_standard_image_list_with_path = newArray(number_of_ref_images);
	comparator_image_list_with_path = newArray(number_of_ref_images);
	TP = newArray(number_of_ref_images);
	FN = newArray(number_of_ref_images);
	FP = newArray(number_of_ref_images);
	dice_score = newArray(number_of_ref_images);
	
	//load up the current comparator images
	comparator_short_name = comparator_short_names[aa];
	comparatory_path = comparator_paths[aa];
	comparator_to_process_list=getFileList(comparatory_path); 
	number_of_comparator_images = comparator_to_process_list.length;
	
	//check
	if(number_of_comparator_images != number_of_ref_images) waitForUser("WARNING: number of reference and comparator images do not match");
	
	//setup the folders to save the images and files for this comparator round
	current_data_file_path = point_data_output_path + ref_short_name + " vs " + comparator_short_name + "\\";
	File.makeDirectory(current_data_file_path);
	current_image_file_path = output_path + "Image Overlays (" + ref_short_name + " vs " + comparator_short_name + ")\\";
	File.makeDirectory(current_image_file_path);
		
	//start processing each of the images
	for(bb = 0; bb<number_of_comparator_images;bb++){
		
		ref_image_with_path = ref_path + ref_to_process_list[bb];
		comparator_image_with_path = comparatory_path + comparator_to_process_list[bb];
		original_image_with_path = originals_path + originals_to_process_list[bb];
				
		ref_image_name = File.getNameWithoutExtension(ref_to_process_list[bb]);
		comparator_image_name = File.getNameWithoutExtension(comparator_to_process_list[bb]);
		original_image_name = File.getNameWithoutExtension(originals_to_process_list[bb]);
	
	    ref_table_name = ref_image_name+"_("+ref_short_name+"-vs-"+comparator_short_name+")";
		comparator_table_name = comparator_image_name+"_("+comparator_short_name+"-vs-"+ref_short_name+")";
		distances_table_name = "distances";
			
		//make table of the points from the ref image
		ref_point_names = GetPointsFromImage(ref_image_with_path,ref_table_name,ref_short_name);
		ref_number_of_points = ref_point_names.length;
		
		//make table of the points from the comparator image
		comparator_point_names = GetPointsFromImage(comparator_image_with_path,comparator_table_name,comparator_short_name);
		comparator_number_of_points = comparator_point_names.length;
		
		//make a matrix of distances\
		MakeDistanceMatrix(ref_table_name,comparator_table_name,distances_table_name);
		
		//start finding the pairs of points
		//start by setting the default stage for each all the points as "NOT_MATCHED"
		not_matched_flag = "NOT_MATCHED";
		ref_pairing_status = MakeDefaultArray(ref_number_of_points,not_matched_flag);
		comparator_pairing_status = MakeDefaultArray(comparator_number_of_points,not_matched_flag);
		
		flag = 0;
		
		while (flag==0) {
			//at each iteration find the closest two points
			minimum_data = FindMatrixMinimum(distances_table_name);
			current_minimum_ref_name = minimum_data[0];
			current_minimum_row_index = minimum_data[1];
			current_minimum_comparator_name = minimum_data[2];			
			current_minimum_distance = minimum_data[3];

			if(current_minimum_distance < max_nucleus_radius){
				
				//note the paired point on the status array
				ref_pairing_index = FindArrayIndex(ref_point_names,current_minimum_ref_name);
				ref_pairing_status[ref_pairing_index] = current_minimum_comparator_name;
				
				comparator_pairing_index =  FindArrayIndex(comparator_point_names,current_minimum_comparator_name);
				comparator_pairing_status[comparator_pairing_index] = current_minimum_ref_name;
				
				//remove the current row and column from the distance matrix-->they are paired so won't be included in the next round
				selectWindow(distances_table_name);
				Table.deleteColumn(current_minimum_comparator_name);
				Table.deleteRows(current_minimum_row_index,current_minimum_row_index);
				
				//check to make sure the table still has rows and more than the label column after deleting the extras
				flag = CheckTable(distances_table_name); //function returns one if there are no rows or only one column (stopping the loop), otherwise returns zero
						
				//repeat until there are no more points that are less than the max radius
																				
			} else {
				flag = 1;
			}		
		}
		
		//close the distance table
		selectWindow(distances_table_name);
		run("Close");
		
		//append the tables with the pairing data
		selectWindow(ref_table_name);
		Table.setColumn("pairing_status", ref_pairing_status);
		selectWindow(comparator_table_name);
		Table.setColumn("pairing_status", comparator_pairing_status);

		//make an overlay of the results
		open(original_image_with_path);
		current_image_window_name = getTitle();
		MakeOverlayOfResults(current_image_window_name,ref_table_name,comparator_table_name,not_matched_flag);
		run("Labels...", "color=white font=12 draw"); //removes the overlay labels 
		output_image_file_with_path = current_image_file_path + original_image_name + "_("+ref_short_name+"-vs-"+comparator_short_name+").tif";
		saveAs("TIFF", output_image_file_with_path);
		close();
				
		//save the ref standard point table
		selectWindow(ref_table_name);
		Table.save(current_data_file_path + ref_table_name + ".csv");
		run("Close");
		
		//save the ref comparator point table
		selectWindow(comparator_table_name);
		Table.save(current_data_file_path + comparator_table_name + ".csv");
		run("Close");
		
		//store the data for this image
		ref_standard_image_list_with_path[bb] = ref_image_with_path;
		comparator_image_list_with_path[bb] = comparator_image_with_path;
		stats = CalculateDiceScore(ref_pairing_status,comparator_pairing_status,not_matched_flag);
		TP[bb] = stats[0];
		FN[bb] = stats[1];
		FP[bb] = stats[2];
		dice_score[bb] = stats[3];
	}
 	
	table_name = "Summary of REF vs "+comparator_short_name+".csv";
	Table.create(table_name);
	Table.setColumn("ref", ref_standard_image_list_with_path);
	Table.setColumn("comparator", comparator_image_list_with_path);
	Table.setColumn("TP", TP);
	Table.setColumn("FN", FN);	
	Table.setColumn("FP", FP);	
	Table.setColumn("dice_score", dice_score);
	Table.save(output_path + table_name);
	selectWindow(table_name);
	run("Close");

}

//clear the roi manager
if (RoiManager.size!=0) { 
	roiManager("Deselect");  
	roiManager("Delete"); 
}


print("ANALYSIS COMPLETE");
if(isOpen(distances_table_name)){
	selectWindow(distances_table_name);
	run("Close");
}
}		


function CalculateDiceScore(array_ref,array_compare,not_matched_flag_name){
	//calculates a dice score for two arrays that contain a list of matched and unmatched points
	output = newArray(4);
	n_1 = array_ref.length;
	n_2 = array_compare.length;
	n_paired = 0;
	for(i=0;i<n_1;i++){
		if(array_ref[i]!=not_matched_flag_name){
			n_paired++;
		}
	}
	output[0] = n_paired; //true positives TP
	output[1] = n_1 - n_paired; //missed
	output[2] = n_2 - n_paired; //false positives
	output[3] = 2*n_paired/(n_1 + n_2); //dice score
	
	return output;
}

function MakeDots(x,y,radius,fill_color,outline_color){
	
	//makes a small circle with radius (in pixels) centered at x,y (in pixels)then outlines it.
	ULx = x - radius;
	ULy = y - radius;
	width = height = 2*radius;
	//make the fill
	makeOval(ULx,ULy,width,height);
	Roi.setFillColor(fill_color);
	roiManager("Add");

	//make the outline
	makeOval(ULx,ULy,width,height);
	Roi.setStrokeWidth(0.1);
	Roi.setStrokeColor(outline_color);
	roiManager("Add");
	
}

function MakeOverlayOfResults(image_window_name,ref_table,comparator_table,not_matched_flag_name){
//make an overlay of the results on the open image
	
	//clear the roi manager
	if (RoiManager.size!=0) { 
		roiManager("Deselect");  
		roiManager("Delete"); 
	}

	
	//extract the data from the ref table
	selectWindow(ref_table);
	points_g = Table.getColumn("point_names");
	x_g = Table.getColumn("x_coordinates");
	y_g = Table.getColumn("y_coordinates");
	status_g = Table.getColumn("pairing_status");

	//extract the data from the ref table
	selectWindow(comparator_table);
	points_c = Table.getColumn("point_names");
	x_c = Table.getColumn("x_coordinates");
	y_c = Table.getColumn("y_coordinates");
	status_c = Table.getColumn("pairing_status");
		
	//open the image on which the data will be plotted
	selectWindow(image_window_name);
	height = getHeight();
	r_missed = 2*height/200;
	r_correct = 2*height/200;
	line_width = 0.5*height/200;

	
		
	//First go through all the ref standards and plot them.
	for(aa=0;aa<points_g.length;aa++){
		x = x_g[aa];
		y = y_g[aa];
		if(status_g[aa]==not_matched_flag_name){
			MakeDots(x, y, r_missed, "#FFFFFF00","#FFFFFF00");
		} else {
			//find the matching point
			index_c = FindArrayIndex(points_c,status_g[aa]);
			xc = x_c[index_c];
			yc = y_c[index_c];
			
			//plot the points and link them with a line
			makeLine(x,y,xc,yc);
			Roi.setStrokeWidth(line_width);
			Roi.setStrokeColor("green");
			roiManager("add");
			
			MakeDots(x, y, r_correct, "#FF00FF00","#FFFFFF00");
			MakeDots(xc, yc, r_correct, "#FF00FF00","#FFFF0000");
		}
	}
	
	//then go through all the comparators and plot them (only the non-matched points need to be plotted)
	for(aa=0;aa<points_c.length;aa++){
		x = x_c[aa];
		y = y_c[aa];
		if(status_c[aa]==not_matched_flag_name){
			MakeDots(x, y, 3, "#FFFF0000","#FFFF0000");	
		} 
	}
	
	//move all the data as an overlay on the current image
	run("From ROI Manager");
		
	//Add a legend
	setFont("SansSerif", 4, " antialiased");
	makeText("TP: MATCHED", 0, 0);
	run("Add Selection...", "stroke=green fill=#81000000");
	makeText("FP: COMPARATOR ONLY", 0, 5);
	run("Add Selection...", "stroke=red fill=#81000000");
	makeText("FN: REF ONLY", 0, 10);
	run("Add Selection...", "stroke=yellow fill=#81000000");
	run("Select None");
	
					
}



function FindArrayIndex(array,target){
	//finds the index in an array of a target value (must be unique)
	output = "not_found"; //set default
	flag = 0;
	for (i = 0; i < array.length; i++) {
		if(array[i]==target&&flag==0){
			output = i;
			flag = 1;
		}
		else if(array[i]==target&&flag==1){
			output = "not_unique";
		}
	}
	return output;
}

function MakeDefaultArray(array_size,default_value){
	//fills an array with a default value
	output_array = newArray(array_size);
	for(i = 0; i < output_array.length; i++) {
		output_array[i] = default_value;
	}
	return output_array;
}

function CheckTable(table1) {
	//returns a flag of 1 if the table has no rows or only 1 column (the label column)
	flag = 0;
	selectWindow(table1);
	column_names_string = Table.headings;  
	column_names = split(column_names_string,"\t");
	number_columns = column_names.length;
	number_rows = Table.size;
	if(number_columns == 1 || number_rows ==0 ) flag=1;
	return flag;
}

function FindMatrixMinimum(table1){
	//finds the minimum in a table
	selectWindow(table1);
	Table.showRowIndexes(false);
	column_names_string = Table.headings;  
	column_names = split(column_names_string,"\t");
	number_columns = column_names.length;
	row_names = Table.getColumn(column_names[0]);
	
	for(aa=1;aa<number_columns;aa++){ //note skip the first column of the table which contains only the row names
		current_column_name = column_names[aa];
		current_column_data = Table.getColumn(current_column_name);
		current_column_ranks = Array.rankPositions(current_column_data);
		current_column_minimum_row = current_column_ranks[0];
		current_column_minimum_value = current_column_data[current_column_minimum_row];
		if(aa==1) {
			minimum_column_name = current_column_name;
			minimum_row_name = row_names[current_column_minimum_row];
			minimum_row_index = current_column_minimum_row;
			minimum_value = current_column_minimum_value;
		} else if (current_column_minimum_value < minimum_value) {
			minimum_column_name = current_column_name;
			minimum_row_name = row_names[current_column_minimum_row];
			minimum_row_index = current_column_minimum_row;
			minimum_value = current_column_minimum_value;
		}
		
	}
	
	//prepare to export the data as an array that contains (minimum_row_name,minimum_row_index,minimum_column_name,minimum_value)
	output = newArray(4);
	output[0] = minimum_row_name;
	output[1] = minimum_row_index;
	output[2] = minimum_column_name;
	output[3] = minimum_value;
	
	return output;

}

function MakeDistanceMatrix(table1,table2,output_table_name) {
//make a table of distances with the points from table 1 as rows and the points from table 2 as columns
//tables must be generated by GetPointsFromImage
//ImageJ cannot work with matrix variables, so this is a work around

//get the data out of the tables to build the new table with
selectWindow(table1);
t1_point_names = Table.getColumn("point_names");
t1_x = Table.getColumn("x_coordinates");
t1_y = Table.getColumn("y_coordinates");
t1_number_of_points = t1_point_names.length;

selectWindow(table2);
t2_point_names = Table.getColumn("point_names");
t2_x = Table.getColumn("x_coordinates");
t2_y = Table.getColumn("y_coordinates");
t2_number_of_points = t2_point_names.length;


Table.create(output_table_name);
Table.setColumn("t1_point_names", t1_point_names);

for (cc = 0; cc < t2_number_of_points; cc++) {
	current_column_name = t2_point_names[cc];
	distances = newArray(t1_number_of_points); //reset the distances variable
	for(dd = 0; dd< t1_number_of_points; dd++) {
		distances[dd] = Math.sqrt(Math.sqr(t1_x[dd] - t2_x[cc]) + Math.sqr(t1_y[dd] - t2_y[cc]));
	}
	Table.setColumn(current_column_name, distances);						
}
}



function GetPointsFromImage(image_path,table_name,point_name_root) {
//open a image with a multipoint overlay and generate a table with the points and data
//point_name_root is the shorted name given to each of the point which is appended with "-" and a number

//clear the roi manager
if (RoiManager.size!=0) { 
	roiManager("Deselect");  
	roiManager("Delete"); 
}

open(image_path);
image_window = getTitle();

//move the overlay to the ROI manager for editing
run("To ROI Manager");

//Characterize the list
number_of_ROIs = RoiManager.size;

if(number_of_ROIs!=1) waitForUser("WARNING: more than one ROI detected for \n" + image_path + "\nCancel and review the image to ensure only 1 ROI present");

Last_ROI_Index = number_of_ROIs - 1;

roiManager("Select", 0);
Roi.getCoordinates(x_coordinates, y_coordinates);
number_of_points = x_coordinates.length;

//make point names
point_names = newArray(number_of_points);
for (bb=0; bb<number_of_points; bb++) {
	point_names[bb] = point_name_root + "-" + bb;
}

//make the table
Table.create(table_name);
Table.setColumn("point_names", point_names);
Table.setColumn("x_coordinates", x_coordinates);
Table.setColumn("y_coordinates", y_coordinates);

//close the image
selectWindow(image_window);
run("Close");

return point_names;

}

