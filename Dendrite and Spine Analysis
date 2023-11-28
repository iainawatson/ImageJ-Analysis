////////////////////////////////////////////////////////////////////
// SPINE AND DENDRITE ANAYLSIS WITH 3 WAY COLOCALISATION ANALYSIS //
// Author: Iain Watson                                            //
// Version: 1.0 01/10/18                                          //
////////////////////////////////////////////////////////////////////
//Measure the colocalisation between 3 channels eg for GFP tagged vs puncta1 and puncta2
//Requires transfection for spine analysis

///////////////////////////
// Set variables here    //
///////////////////////////

//define the range of puncta size when using 'Analyze Particles'. Minimum should be set to microscope reolution limit. Use following as guide:
//iSIM = 0.02-0.25
//Leica SP5 = 0.08-2
aplower = 0.02;
apupper = 0.25;

//set radii for median filtering of puncta channels. Explore the best through trial and error. note:
//excellent staining may need higher radii values
//when radius is low, be quite 'aggressive' with the thresholding
//never drop below 3
//very high numbers like 40 will give a gentle median subtraction. and drop the intensity of the image ~25-30%

p1_med_radius = 5;
p2_med_radius = 40;
p3_med_radius = 40;

///////////////////////////////////////////////////////////
// Define functions here                                 //
// Create an empty result table that can be called later //
// Enter min/max values for each channel here            //
///////////////////////////////////////////////////////////

// create empty table
function create_empty_results() {
	setResult("Area", 0, "0");     					// Add a Dummy results line with defined column titles
	setResult("Mean", 0, "0");
	setResult("Min", 0, "0");
	setResult("Max", 0, "0");
	setResult("IntDen", 0, "0");
	setResult("RawIntDen", 0, "0");
	IJ.deleteRows(0, 0); 							// Delete the Dummy Row from the Results but retain titles
}

if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}

//apply lut fails if min max is unchanged. define function here as a workaround. high and low values are dependent of bit depth
function applylut_if_minmax_changed() {
	bit = bitDepth();
	//min and max will have already been user defined so get current minmax to cross reference numbers
	getMinAndMax(min,max);
	//check for 8-bit images
	if (bit == 8) {
		if (min != 0 && max != 255) {
			run("Apply LUT");
		}
	} else if (bit == 12) {
		if (min != 0 && max != 4095) {
			run("Apply LUT");
		}
	} else if (bit == 16) {
		if (min != 0 && max != 65535) {
			run("Apply LUT");
		}
	} else {
		print("Bit depth of image is out of range");
	}
}	

/////////////////////////////////////////////////
// Close all windows to prevent any conflicts  //
/////////////////////////////////////////////////

if (isOpen("ROI Manager")) {
    selectWindow("ROI Manager"); 
    run("Close");
}

if (isOpen("Threshold")) { 
    selectWindow("Threshold"); 
    run("Close");
}

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

if (nImages>0) {
    waitForUser("WARNING", "Save all unsaved data.\nClick OK when done");
	run("Close All");
}

waitForUser("Drag and drop max projected images with channels seperated from a single acquisition onto ImageJ. Click OK when done");
output = getDirectory("image");
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
File.makeDirectory(output + "/results")
parent1 = File.getParent(output);
parent2 = File.getParent(parent1);

////////////////////////////////////////////////
// Input metadata if image doesn't already    //
////////////////////////////////////////////////

//creates string from data
info = getImageInfo();
//splits string into an array at end of each line
info = split(info, "\n");
res = 0;
//res variable is renamed if resolution is already set
for (i=0; i<info.length; i++) {
	if (matches(info[i], "Resolution" + ".*")) {
		res = info[i];
	}
}
//if res remains zero then input scale
if (res == 0) {
	run("Set Scale...");
	info = getImageInfo();
	info = split(info, "\n");
	//grab new resolution input
	for (i=0; i<info.length; i++) {
		if (matches(info[i], "Resolution" + ".*")) {
			res = info[i];
		}
	}
}
//save resolution to file
acq_info = parent1 + "/acquisition_information.txt";
if (File.exists(acq_info) == false) {
	acqinfo = File.open(acq_info);
	print(acqinfo, res);
	File.close(acqinfo);
}

////////////////////////////////////////////////
// Interactively define the antibody names    //
// Create file to save values                 //
// Reload values if file already created      //
////////////////////////////////////////////////

abprofiles = parent2 + "/antibody_identification.txt";			// saves file in experiment folder

if (File.exists(abprofiles) == false) {
	Dialog.create("Indentify the features from the image names.\nAntibody 1 should preferably be furthest from dendrite");
		Dialog.addString("Morpholgical Marker:", "MAP2");
		Dialog.addString("Antibody 1:", "");
		Dialog.addString("Antibody 2:", "");
		Dialog.addString("Antibody 3:", "");
		Dialog.show();
	morphab = Dialog.getString();
	p1ab = Dialog.getString();;
	p2ab = Dialog.getString();;;
	p3ab = Dialog.getString();;;;
	abprof = File.open(abprofiles);
	print(abprof, "Morphological Marker:");
	print(abprof, morphab);
	print(abprof, "Antibody 1:");
	print(abprof, p1ab);
	print(abprof, "Antibody 2:");
	print(abprof, p2ab);
	print(abprof, "Antibody 3:");
	print(abprof, p3ab);

	File.close(abprof);
} else {
	abid = File.openAsString(abprofiles);
	lines = split(abid, "\n");   // split the string by lines in the file
	morphab =  lines[1];   // turn string back in integer
	p1ab =  lines[3];
	p2ab =  lines[5];
	p3ab =  lines[7];
}

////////////////////////////////////////////////
// Interactively define the channel names     //
// Create file to save values                 //
// Reload values if file already created      //
////////////////////////////////////////////////

channelprofiles = parent2 + "/channel_identification.txt";			// saves file in experiment folder

if (File.exists(channelprofiles) == false) {
	Dialog.create("Indentify the features from the image names");
		Dialog.addChoice(morphab, newArray("C=0", "C=1", "C=2", "C=3"));
		Dialog.addChoice(p1ab + " (Puncta1)", newArray("C=0", "C=1", "C=2", "C=3"));
		Dialog.addChoice(p2ab + " (Puncta2)", newArray("C=0", "C=1", "C=2", "C=3"));
		Dialog.addChoice(p3ab + " (Puncta3)", newArray("C=0", "C=1", "C=2", "C=3"));
		Dialog.show();
	den = Dialog.getChoice();
	p1 = Dialog.getChoice();;
	p2 = Dialog.getChoice();;;
	p3 = Dialog.getChoice();;;;
	chprof = File.open(channelprofiles);
	print(chprof, "morphological channel:");
	print(chprof, den);
	print(chprof, "Puncta1 channel:");
	print(chprof, p1);
	print(chprof, "Puncta2 channel:");
	print(chprof, p2);
	print(chprof, "Puncta3 channel:");
	print(chprof, p3);
	File.close(chprof);
} else {
	channelid = File.openAsString(channelprofiles);
	lines = split(channelid, "\n");   // split the string by lines in the file
	den =  lines[1];   // turn string back in integer
	p1 =  lines[3];
	p2 =  lines[5];
	p3 =  lines[7];
}

// create personalised names for each channel

alt_name_morph = morphab + " (" + den + ")";
alt_name_p1 = p1ab + " (" + p1 + ")";
alt_name_p2 = p2ab + " (" + p2 + ")";
alt_name_p3 = p3ab + " (" + p3 + ")";

//////////////////////////////////////////////////////////////////////////////// CURRENTLY MORPH MARKER AND P1 ARE THE SAME
// create an array of open images. These can then be cycled through later     //
// adjust below code to match the "C=x" re: channel identifier from microscope//
// Give newly opened images variable to call later from image ID              //
////////////////////////////////////////////////////////////////////////////////

rawIDS = newArray(nImages);

for (i=0; i < rawIDS.length; i++) {                                // iterate through original ids array, asign variable to original images
	selectImage(i+1);                                              // note what channels correspond to what variables
	title = getTitle();												// creates rawIDS array populated by original images
	// if (matches(title, ".*" + den + ".*")) {
		// dendriteID = getImageID();
		// dendriteTitle = getTitle();
		// rawIDS[i] = dendriteID;
	// } 
	if (matches(title, ".*" + p1 + ".*")) {
		puncta1ID = getImageID();
		puncta1Title = getTitle();
		rawIDS[i] = puncta1ID;
	} else if (matches(title, ".*" + p2 + ".*")) {
		puncta2ID = getImageID();
		puncta2Title = getTitle();
		rawIDS[i] = puncta2ID;
	} else if (matches(title, ".*" + p3 + ".*")) {
		puncta3ID = getImageID();
		puncta3Title = getTitle();
		rawIDS[i] = puncta3ID;
	}
}

Array.sort(rawIDS);						// sorts array low>high
Array.reverse(rawIDS);					// Ids run negatively, so earliest images are high, therefore reverse

///////////////////////////////////////////////////////////
// Interactively define min and max for each channel     //
// Create file to save values                            //
// Reload values if file already created                 //
///////////////////////////////////////////////////////////
minmaxfile = parent2 + "/min_max_values.txt"; 				// saves file in experiment folder
if (File.exists(minmaxfile) == false) {
	Dialog.create("Open multiple images of the morhpological marker from multiple conditions and test for\noptimal min/max values\nto allow for drawing length and dendritic ROI's\nCan use file image_display_range as guidance");
		Dialog.addNumber("Enter MINIMUM value for " + alt_name_morph + ":", 0);
		Dialog.addNumber("Enter MAXIMUM value for " + alt_name_morph + ":", 0);
		Dialog.show();
	denmin = Dialog.getNumber();
	denmax = Dialog.getNumber();;
	// repeat for punta1 channel
	Dialog.create("Open multiple images of the puncta1 channel from multiple conditions and test for\noptimal min/max values to allow for drawing length and dendritic ROI's\nCan use file image_display_range as guidance");
		Dialog.addNumber("Enter MINIMUM value for " + alt_name_p1 + ":", 0);
		Dialog.addNumber("Enter MAXIMUM value for " + alt_name_p1 + ":", 0);
		Dialog.show();
	p1min = Dialog.getNumber();
	p1max = Dialog.getNumber();;
	// repeat for punta2 channel
	Dialog.create("Open multiple images of the puncta2 channel from multiple conditions and test for\noptimal min/max values to allow for drawing length and dendritic ROI's\nCan use file image_display_range as guidance");
		Dialog.addNumber("Enter MINIMUM value for " + alt_name_p2 + ":", 0);
		Dialog.addNumber("Enter MAXIMUM value for " + alt_name_p2 + ":", 0);
		Dialog.show();
	p2min = Dialog.getNumber();
	p2max = Dialog.getNumber();;
	// repeat for punta3 channel
	Dialog.create("Open multiple images of the puncta2 channel from multiple conditions and test for\noptimal min/max values to allow for drawing length and dendritic ROI's\nCan use file image_display_range as guidance");
		Dialog.addNumber("Enter MINIMUM value for " + alt_name_p3 + ":", 0);
		Dialog.addNumber("Enter MAXIMUM value for " + alt_name_p3 + ":", 0);
		Dialog.show();
	p3min = Dialog.getNumber();
	p3max = Dialog.getNumber();;
	minmax = File.open(minmaxfile);
	print(minmax, alt_name_morph + ", morphological min/max:");
	print(minmax, denmin);
	print(minmax, denmax);
	print(minmax, alt_name_p1 + ", puncta1 min/max:");
	print(minmax, p1min);
	print(minmax, p1max);
	print(minmax, alt_name_p2 + ", puncta2 min/max:");
	print(minmax, p2min);
	print(minmax, p2max);
	print(minmax, alt_name_p3 + ", puncta3 min/max:");
	print(minmax, p3min);
	print(minmax, p3max);
	File.close(minmax);
} else {
	minmaxvalues = File.openAsString(minmaxfile);
	lines = split(minmaxvalues, "\n");
	denmin =  parseInt(lines[1]);   // turn string back in integer
	denmax =  parseInt(lines[2]);
	p1min =  parseInt(lines[4]);
	p1max =  parseInt(lines[5]);
	p2min =  parseInt(lines[7]);
	p2max =  parseInt(lines[8]);
	p3min =  parseInt(lines[10]);
	p3max =  parseInt(lines[11]);
}

/////////////////////////////////////////////////
// get the lengths of the dendrites to measure //
// save the measurements                       //
// save the roi                                //
/////////////////////////////////////////////////

if (File.exists(output+"length_roi.zip") == false) {
	selectImage(puncta1ID);
	setMinAndMax(p1min, p1max);
	run("Brightness/Contrast...");
	run("Line Width...", "line=5");
	setTool("polyline");
	run("ROI Manager...");
	roiManager("Show All");
	waitForUser("Select LENGTH(S) to measure in "+alt_name_morph+" channel\nAdjust brightness and contrast if necessary\nAdd to ROI manager using 't'. Click OK when done");
} else {
	roiManager("Open", output+"length_roi.zip");
}

roiManager("Deselect");
roiManager("Measure");
saveAs("Results", output+"/results/length_results.csv");

if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("Deselect");
roiManager("save", output+"length_roi.zip");
roiManager("reset");

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

///////////////////////////////////////////////////////////////////
// check regions do not conflict with staining in other channels //
///////////////////////////////////////////////////////////////////

selectImage(puncta2ID);
setMinAndMax(p2min, p2max);
run("Brightness/Contrast...");
roiManager("Open", output+"length_roi.zip");
roiManager("Show All");
waitForUser("If LENGTH ROI's conflict with "+alt_name_p2+", adjust and click UPDATE as necessary. Click OK when done");
selectImage(puncta1ID);
roiManager("Deselect");
roiManager("Measure");
saveAs("Results", output+"/results/length_results.csv");

if (isOpen("Results")) { 
	selectWindow("Results"); 
	run("Close");
}

roiManager("Deselect");
roiManager("save", output+"length_roi.zip");
roiManager("reset");

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

selectImage(puncta3ID);
setMinAndMax(p3min, p3max);
run("Brightness/Contrast...");
roiManager("Open", output+"length_roi.zip");
roiManager("Show All");
waitForUser("If LENGTH ROI's conflict with "+alt_name_p3+", adjust and click UPDATE as necessary. Click OK when done");
selectImage(puncta1ID);
roiManager("Deselect");
roiManager("Measure");
saveAs("Results", output+"/results/length_results.csv");

if (isOpen("Results")) { 
	selectWindow("Results"); 
	run("Close");
}

roiManager("Deselect");
roiManager("save", output+"length_roi.zip");
// final list of length measures is counted, this function is called later
roi_length_count = roiManager("count");							
roiManager("reset");

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

///////////////////////////////
// draw region around spines //
// save the measurements     //
// save the roi              //
///////////////////////////////
// number of lengths 'roi_length_count'

roiManager("Open", output+"length_roi.zip");
if (File.exists(output+"area_of_interest.zip") == false) {
	selectImage(puncta1ID);
	setMinAndMax(p1min, p1max);
	run("Brightness/Contrast...");
	run("Line Width...", "line=5");
	setTool("freehand");
	run("ROI Manager...");
	roiManager("Show All");
	waitForUser("Draw an area around the areas of interest to include any spines along the lengths already drawn\nAdd to manager with 't'. Click OK when done");
} else {
	roiManager("Open", output+"area_of_interest.zip");
}

//roi_to_delete = roi_length_count * 2;
for (i=0 ; i<roi_length_count ; i++) {
	roiManager("Select", 0);
	roiManager("Delete");
}

roiManager("Deselect");
roiManager("save", output+"area_of_interest.zip");
roiManager("reset");

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

/////////////////////////////////////////////
// create regions for dendrite and spines  //
// save the measurements                   //
// save the roi                            //
/////////////////////////////////////////////
run("Select None");

//runs a median subtraction to remove too much brightness from the dendrite. When thresholding this means the spines and dendrite can 
selectImage(puncta1ID);
run("Duplicate...", "title=median");
selectWindow("median");
run("Median...", "radius=10");
median_overxp = getTitle();
imageCalculator("Subtract create", puncta1Title,median_overxp);
selectImage("Result of " + puncta1Title);
run("Brightness/Contrast...");
if (File.exists(output + "median_filtered_spines_for_thresholding.tif") == false) {
	waitForUser("adjust maximum brightness as necessary for observing spines. Click OK when done");
	run("Apply LUT");
	saveAs("Tiff", output + "median_filtered_spines_for_thresholding");
} else {
	open(output + "median_filtered_spines_for_thresholding.tif");
}	
for_thresh_ID = getImageID();
//opens the areas of interest to focus thresholding in these areas
roiManager("Open", output+"area_of_interest.zip");
roiManager("Show All");
run("Threshold...");
if (File.exists(output + "mask_of_thresholded_image.tif") == false) {
	roiManager("Select", 0);
	run("To Selection");
	waitForUser("Threshold, focusing on spines in area of interest. Click OK when done");
	run("Convert to Mask");
	saveAs("Tiff", output + "mask_of_thresholded_image");
} else {
	open(output + "mask_of_thresholded_image.tif");
}	
//create roi's for the objects within those regions of interest
for (i=0 ; i<roi_length_count ; i++) {
	selectImage(for_thresh_ID);
	roiManager("Select", i);
	run("Analyze Particles...", "  show=Masks");
	run("Create Selection");
	roiManager("Add");
}
//remove the large areas of interest
for (i=0 ; i<roi_length_count ; i++) {
	roiManager("Select", 0);
	roiManager("Delete");
}
//save raw spine and dendrite regions of interest
roiManager("Deselect");
roiManager("save", output+"raw_dendrite_spine_regions.zip");
//combine the roi regions if there are more than 1 and delete the superfluous regions. the first regions is always the combined region
if (roi_length_count > 1) {
	roiManager("Combine");
}
roiManager("Set Fill Color", "#33ff0000");
for (i=1 ; i<roi_length_count ; i++) {
	roiManager("Select", 1);
	roiManager("Delete");
}
//reselect original image and edit the regions to include missing areas or remove non spines/ dendrite regions. Edit previous ROI if already drawn
selectImage(puncta1ID);
setTool("freehand");
if (File.exists(output+"edited_dendrite_spine_regions.zip") == false) {
	roiManager("Select", 0);
	run("To Selection");	
	waitForUser("Fill areas of selection by drawing shapes, draw on top of current selection!!!\nHold shift to add to area\nHold alt to subtract from area\nUpdate selection in ROI manager when edited. Click OK when done");
	roiManager("Update");
	roiManager("Deselect");
	roiManager("save", output+"edited_dendrite_spine_regions.zip");
} else {
	roiManager("Select", 0);
	roiManager("Delete");
	roiManager("Open", output+"edited_dendrite_spine_regions.zip");
	roiManager("Select", 0);
	waitForUser("Edit areas of selection by drawing shapes, draw on top of current selection!!!\nHold shift to add to area\nHold alt to subtract from area\nUpdate selection in ROI manager when edited. Click OK when done");
	roiManager("Update");
	roiManager("Deselect");
	roiManager("save", output+"edited_dendrite_spine_regions.zip");
}
//create binary image of the overlay
roiManager("Select", 0);
run("Create Mask");
saveAs("Tiff", output + "raw_masked_image_for_spine_dendrite_identification");
roiManager("reset");
setTool("brush");
//draw and seperate the dendrite from the spines
if (File.exists(output+"edited_masked_image_for_spine_dendrite_identification.tif") == false) {
	waitForUser("Remove an other areas to exclude\nUpdate selection in ROI manager when edited\ndouble click brush tool to set width and colour\nSeperate the spines from the dendrite.  Click OK when done");
	saveAs("Tiff", output + "edited_masked_image_for_spine_dendrite_identification");
} else {
	open(output + "edited_masked_image_for_spine_dendrite_identification.tif");
}
if (File.exists(output+"spines_roi.zip") == false) {
	run("Wand Tool...", "tolerance=0 mode=4-connected");
	setTool("wand");
	waitForUser("select the dendrite(s). add to manager with t.  Click OK when done");
	roiManager("Deselect");
	roiManager("save", output+"dendrite_roi.zip");
	//should be the same number of dendritic regions, make regions white, then delete these from roi manager
	for (i=0 ; i<roi_length_count ; i++) {
		roiManager("Select", i);
		setForegroundColor(255,255,255);
		roiManager("Fill");
	}
	roiManager("Deselect");
	roiManager("Delete");
	//identify the spines within the image, above resolution of microscope as defined earlier
	run("Select All");
	run("Analyze Particles...", "size=" + aplower + "-Infinity show=Nothing add");
	roiManager("Deselect");
	roiManager("save", output+"spines_roi.zip");
}

if (isOpen("ROI Manager")) {
    selectWindow("ROI Manager"); 
    run("Close");
}

if (isOpen("Threshold")) { 
    selectWindow("Threshold"); 
    run("Close");
}

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

/////////////////////////////////////////////////////////
// Count the lengths of the dendrite and Spines rois's //
// These can be used later in the macro                //
/////////////////////////////////////////////////////////
roiManager("Open", output+"dendrite_roi.zip");
roi_dendrite_count = roiManager("Count");
roiManager("reset");
if (isOpen("ROI Manager")) {
    selectWindow("ROI Manager"); 
    run("Close");
}
roiManager("Open", output+"spines_roi.zip");
roi_spine_count = roiManager("Count");
roiManager("reset");
if (isOpen("ROI Manager")) {
    selectWindow("ROI Manager"); 
    run("Close");
}

///////////////////////////
// Close all new windows //
///////////////////////////

open_images = newArray(nImages);						// make an array of open images and fill with IDs

for (i=0 ; i<open_images.length ; i++) {
	selectImage(i + 1);
	open_images[i] = getImageID();
}
	
Array.sort(open_images);						// sorts array low>high
Array.reverse(open_images);					// Ids run negatively, so earliest images are high, therefore reverse
new_images = Array.slice(open_images, rawIDS.length, open_images.length);			// creates an array of just the new images by slicing down open_images

for (i=0 ; i<new_images.length ; i++) {						// iterates through the  new_images array and closes all images
	selectImage(new_images[i]);
	run("Close");
}

////////////////////////////////////////////////
// Duplicate the first puncta channel         //
// Median Filter                              //
// Raw - Median = Filtered Image              //
// Threshold filtered image                   //
// Reuse thresholded image if already created //
////////////////////////////////////////////////
//run("Select None");
if (File.exists(output + "thresholded_" + puncta1Title) == false) {
	selectImage(puncta1ID);          // creates and saves a median filtered image
	run("Select None");
	run("Duplicate...", "title=median");
	selectWindow("median");
	run("Median...", "radius="+p1_med_radius);                                                             // change radius to effect blur.
	saveAs("Tiff", output + "median"+p1_med_radius+"_" + puncta1Title);                                       // change median value to reflect filter level
	median5_puncta1Title = getTitle();
	imageCalculator("Subtract create", puncta1Title,median5_puncta1Title);                         // creates and saves a filtered image
	selectImage("Result of " + puncta1Title);
	saveAs("Tiff", output + "filtered_image_" + puncta1Title);
	//max will come up dark as the filtered image will be low intensity, so increase items
	p1newmax = p1max * 0.7;
	setMinAndMax(p1min, p1newmax);                                                // set as necessary
	//if values remain unchanged then the apply lut will fail. check defined fucntion for code
	//applylut_if_minmax_changed();
	run("Apply LUT");
	roiManager("Open", output+"dendrite_roi.zip");									// Opens synpase area to see thresholded area properly
	roiManager("Show All");
	run("Threshold...");                                                              // No Auto-threshold Otsu
	roiManager("Select", 0);
	run("To Selection");
	waitForUser("Click OK when done");
	run("Convert to Mask");
	saveAs("Tiff", output + "thresholded_" + puncta1Title);
	binary_puncta1Title = getTitle();
	roiManager("reset");
} else {
	open(output + "thresholded_" + puncta1Title);
	binary_puncta1Title = getTitle();
}

////////////////////////////////////////////////
// Duplicate the second puncta channel        //
// Median Filter                              //
// Raw - Median = Filtered Image              //
// Threshold filtered image                   //
// Reuse thresholded image if already created //
////////////////////////////////////////////////

if (File.exists(output + "thresholded_" + puncta2Title) == false) { 
	selectImage(puncta2ID);
	run("Duplicate...", "title=median");
	selectWindow("median");
	run("Median...", "radius="+p2_med_radius);                                                              // change radius to effect blur.
	saveAs("Tiff", output + "median"+p2_med_radius+"_" + puncta2Title);                                        // change median value to reflect filter level
	median5_puncta2Title = getTitle();
	imageCalculator("Subtract create", puncta2Title, median5_puncta2Title);               // creates and saves a filtered image
	selectImage("Result of " + puncta2Title);
	saveAs("Tiff", output + "filtered_image_" + puncta2Title);
	//max will come up dark as the filtered image will be low intensity, so increase items
	p2newmax = p2max * 0.7;
	setMinAndMax(p2min, p2newmax);
	//if min and max are default values the apply LUT will fail, so check and skip if necessary, for 8/12/16 bit images. define as variable
	//applylut_if_minmax_changed();
	run("Apply LUT");
	roiManager("Open", output+"dendrite_roi.zip");									// Opens synpase area to see thresholded area properly
	roiManager("Show All");
	run("Threshold...");
	roiManager("Select", 0);
	run("To Selection");
	waitForUser("Click OK when done");
	run("Convert to Mask");
	saveAs("Tiff", output + "thresholded_" + puncta2Title);
	binary_puncta2Title = getTitle();
	roiManager("reset");
} else {
	open(output + "thresholded_" + puncta2Title);
	binary_puncta2Title = getTitle();
}

////////////////////////////////////////////////
// Duplicate the third puncta channel        //
// Median Filter                              //
// Raw - Median = Filtered Image              //
// Threshold filtered image                   //
// Reuse thresholded image if already created //
////////////////////////////////////////////////

if (File.exists(output + "thresholded_" + puncta3Title) == false) { 
	selectImage(puncta3ID);
	run("Duplicate...", "title=median");
	selectWindow("median");
	run("Median...", "radius="+p3_med_radius);                                                              // change radius to effect blur.
	saveAs("Tiff", output + "median"+p3_med_radius+"_" + puncta3Title);                                        // change median value to reflect filter level
	median5_puncta3Title = getTitle();
	imageCalculator("Subtract create", puncta3Title, median5_puncta3Title);               // creates and saves a filtered image
	selectImage("Result of " + puncta3Title);
	saveAs("Tiff", output + "filtered_image_" + puncta3Title);
	//max will come up dark as the filtered image will be low intensity, so increase items
	p3newmax = p3max * 0.7;
	setMinAndMax(p3min, p3newmax);
	run("Apply LUT");
	roiManager("Open", output+"dendrite_roi.zip");									// Opens synpase area to see thresholded area properly
	roiManager("Show All");
	run("Threshold...");
	roiManager("Select", 0);
	run("To Selection");
	waitForUser("Click OK when done");
	run("Convert to Mask");
	saveAs("Tiff", output + "thresholded_" + puncta3Title);
	binary_puncta3Title = getTitle();
	roiManager("reset");
} else {
	open(output + "thresholded_" + puncta3Title);
	binary_puncta3Title = getTitle();
}

/////////////////////////////////////////////////
// detect puncta ROI in the thresholded images //
// detect dendritic puncta first               //
/////////////////////////////////////////////////
//detect in puncta1 cahnnel
selectWindow(binary_puncta1Title);
roiManager("Open", output+"dendrite_roi.zip");
roiManager("Show All");

for (i=0; i<roi_dendrite_count; i++) {                                              // iterates the opened dendritic regions, measures them
	roiManager("Select", i);
	run("Analyze Particles...", "size="+aplower+"-"+apupper+" add");                    // Summary window is detected as "results" so not sure how to gather summary results
}

for (i=0; i<roi_dendrite_count; i++) {                                      // deletes the dendritic regions and allows for just the new puncta roi to be saved
	roiManager("Select", 0);
	roiManager("Delete");
}

roiManager("Deselect");                                                   // generate and save the summary results
temp_count = roiManager("Count");  								// return the number of items in ROI list, because if 0 and no workaround causes error

if (temp_count>0) { 											// saves the roi
	roiManager("save", output+"dendrite_puncta1_roi.zip");
	roiManager("reset");
}

//detect in puncta2 channel
selectWindow(binary_puncta2Title);                                              // Repeat for second puncta image
roiManager("Open", output+"dendrite_roi.zip");
roiManager("Show All");

for (i=0; i<roi_dendrite_count; i++) {                                              // iterates the opened dendritic regions, measures them
	roiManager("Select", i);
	run("Analyze Particles...", "size="+aplower+"-"+apupper+" add");                       // Summary window is detected as "results" so not sure how to gather summary results
}

for (i=0; i<roi_dendrite_count; i++) {                                              // deletes the dendritic regions and allows for just the new puncta roi to be saved
	roiManager("Select", 0);
	roiManager("delete");
}

roiManager("Deselect");                                                   // generate and save the summary results
temp_count = roiManager("Count");  								// return the number of items in ROI list, because if 0 and no workaround causes error

if (temp_count>0) { 											// saves the roi
	roiManager("save", output+"dendrite_puncta2_roi.zip");
	roiManager("reset");
}

//detect in puncta 3 channel
selectWindow(binary_puncta3Title);                                              // Repeat for second puncta image
roiManager("Open", output+"dendrite_roi.zip");
roiManager("Show All");

for (i=0; i<roi_dendrite_count; i++) {                                              // iterates the opened dendritic regions, measures them
	roiManager("Select", i);
	run("Analyze Particles...", "size="+aplower+"-"+apupper+" add");                       // Summary window is detected as "results" so not sure how to gather summary results
}

for (i=0; i<roi_dendrite_count; i++) {                                              // deletes the dendritic regions and allows for just the new puncta roi to be saved
	roiManager("Select", 0);
	roiManager("delete");
}

roiManager("Deselect");                                                   // generate and save the summary results
temp_count = roiManager("Count");  								// return the number of items in ROI list, because if 0 and no workaround causes error

if (temp_count>0) { 											// saves the roi
	roiManager("save", output+"dendrite_puncta3_roi.zip");
	roiManager("reset");
}

/////////////////////////////////////////////////
// detect puncta ROI in the thresholded images //
// detect spine puncta                  //
/////////////////////////////////////////////////

selectWindow(binary_puncta1Title);
roiManager("Open", output+"spines_roi.zip");
roiManager("Show All");

for (i=0; i<roi_spine_count; i++) {                                               // iterates the opened synaptic area regions, measures them
	roiManager("Select", i);
	run("Analyze Particles...", "size="+aplower+"-"+apupper+" add");                    // Summary window is detected as "results" so not sure how to gather summary results
}

for (i=0; i<roi_spine_count; i++) {                                               // deletes the synaptic area regions and allows for just the new puncta roi to be saved
	roiManager("Select", 0);
	roiManager("delete");
}

roiManager("Deselect");                                                    // deletes the synaptic area regions and allows for just the new puncta roi to be saved
temp_count = roiManager("Count");  								// return the number of items in ROI list, because if 0 and no workaround causes error

if (temp_count>0) { 											// saves the roi
	roiManager("save", output+"spine_puncta1_roi.zip");
	roiManager("reset");
}

selectWindow(binary_puncta2Title);                                               // Repeat for second puncta image
roiManager("Open", output+"spines_roi.zip");
roiManager("Show All");

for (i=0; i<roi_spine_count; i++) {                                               // iterates the opened synaptic area regions, measures them
	roiManager("Select", i);
	run("Analyze Particles...", "size="+aplower+"-"+apupper+" add");                    // Summary window is detected as "results" so not sure how to gather summary results
}

for (i=0; i<roi_spine_count; i++) {                                               // deletes the synaptic area regions and allows for just the new puncta roi to be saved
	roiManager("Select", 0);
	roiManager("delete");
}

roiManager("Deselect");                                                    // generate and save the summary results
temp_count = roiManager("Count");  								// return the number of items in ROI list, because if 0 and no workaround causes error

if (temp_count>0) { 											// saves the roi
	roiManager("save", output+"spine_puncta2_roi.zip");
	roiManager("reset");
}

selectWindow(binary_puncta3Title);                                               // Repeat for second puncta image
roiManager("Open", output+"spines_roi.zip");
roiManager("Show All");

for (i=0; i<roi_spine_count; i++) {                                               // iterates the opened synaptic area regions, measures them
	roiManager("Select", i);
	run("Analyze Particles...", "size="+aplower+"-"+apupper+" add");                    // Summary window is detected as "results" so not sure how to gather summary results
}

for (i=0; i<roi_spine_count; i++) {                                               // deletes the synaptic area regions and allows for just the new puncta roi to be saved
	roiManager("Select", 0);
	roiManager("delete");
}

roiManager("Deselect");                                                    // generate and save the summary results
temp_count = roiManager("Count");  								// return the number of items in ROI list, because if 0 and no workaround causes error

if (temp_count>0) { 											// saves the roi
	roiManager("save", output+"spine_puncta3_roi.zip");
	roiManager("reset");
}

////////////////////////////////////////////////
// Close all new windows
////////////////////////////////////////////////

open_images = newArray(nImages);						// make an array of open images and fill with IDs

for (i=0 ; i<open_images.length ; i++) {
	selectImage(i + 1);
	open_images[i] = getImageID();
}
	
Array.sort(open_images);						// sorts array low>high
Array.reverse(open_images);					// Ids run negatively, so earliest images are high, therefore reverse
new_images = Array.slice(open_images, rawIDS.length, open_images.length);			// creates an array of just the new images by slicing down open_images

for (i=0 ; i<new_images.length ; i++) {						// iterates through the  new_images array and closes all images
	selectImage(new_images[i]);
	run("Close");
}

//////////////////////////////////////////////////////////////
// overlay puncta roi in original channels                  //
// measure mean and II intensity in identified regions      //
// if no ROI detected empty analysis files will be produced //
//////////////////////////////////////////////////////////////

selectImage(puncta1ID);

if (File.exists(output+"dendrite_puncta1_roi.zip") == true) {
	roiManager("Open", output+"dendrite_puncta1_roi.zip");
	roiManager("Deselect");
	roiManager("Measure");
	roiManager("reset");
	saveAs("Results", output+"/results/puncta1_dendrite_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/puncta1_dendrite_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}

selectImage(puncta1ID);

if (File.exists(output+"spine_puncta1_roi.zip") == true) {
	roiManager("Open", output+"spine_puncta1_roi.zip");
	roiManager("Deselect");
	roiManager("Measure");
	roiManager("reset");
	saveAs("Results", output+"/results/puncta1_spine_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/puncta1_spine_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}

selectImage(puncta2ID);

if (File.exists(output+"dendrite_puncta2_roi.zip") == true) {
	roiManager("Open", output+"dendrite_puncta2_roi.zip");
	roiManager("Deselect");
	roiManager("Measure");
	roiManager("reset");
	saveAs("Results", output+"/results/puncta2_dendrite_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/puncta2_dendrite_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}

selectImage(puncta2ID);

if (File.exists(output+"spine_puncta2_roi.zip") == true) {
roiManager("Open", output+"spine_puncta2_roi.zip");
	roiManager("Deselect");
	roiManager("Measure");
	roiManager("reset");
	saveAs("Results", output+"/results/puncta2_spine_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/puncta2_spine_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}

selectImage(puncta3ID);

if (File.exists(output+"dendrite_puncta3_roi.zip") == true) {
	roiManager("Open", output+"dendrite_puncta3_roi.zip");
	roiManager("Deselect");
	roiManager("Measure");
	roiManager("reset");
	saveAs("Results", output+"/results/puncta3_dendrite_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/puncta3_dendrite_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}

selectImage(puncta3ID);

if (File.exists(output+"spine_puncta3_roi.zip") == true) {
roiManager("Open", output+"spine_puncta3_roi.zip");
	roiManager("Deselect");
	roiManager("Measure");
	roiManager("reset");
	saveAs("Results", output+"/results/puncta3_spine_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/puncta3_spine_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}

////////////////////////////////////////////
// draw background for each channel       //
// save ROI                               //
// load background roi's if already exist //
////////////////////////////////////////////

if (isOpen("ROI Manager")) {                                                      // Close other windows first, as they imagej names them the same as the images
    selectWindow("ROI Manager"); 
    run("Close");
}

if (isOpen("Threshold")) { 
    selectWindow("Threshold"); 
    run("Close");
}

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

if (File.exists(output+"p1_background_roi.zip") == false) {
	selectImage(puncta1ID);
	p1newmax = p1max * 0.7;
	setMinAndMax(p1min, p1max);
	run("Brightness/Contrast...");
	run("ROI Manager...");
	roiManager("Show All");
	setTool("polygon");
	run("Scale to Fit");
	waitForUser("Select AREA(S) of BACKGROUND in "+alt_name_p1+", add to ROI manager using 't'. Click OK when done");
	roiManager("save", output+"p1_background_roi.zip");
	roiManager("reset");

	if (isOpen("B&C")) { 
		selectWindow("B&C"); 
		run("Close");
	}
}

if (File.exists(output+"p2_background_roi.zip") == false) {
	selectImage(puncta1ID);
	p2newmax = p2max * 0.7;
	setMinAndMax(p2min, p2max);
	run("Brightness/Contrast...");
	run("ROI Manager...");
	roiManager("Show All");
	setTool("polygon");
	run("Scale to Fit");
	waitForUser("Select AREA(S) of BACKGROUND in "+alt_name_p2+", add to ROI manager using 't'. Click OK when done");
	roiManager("save", output+"p2_background_roi.zip");
	roiManager("reset");

	if (isOpen("B&C")) { 
		selectWindow("B&C"); 
		run("Close");
	}
}

if (File.exists(output+"p3_background_roi.zip") == false) {
	selectImage(puncta1ID);
	p3newmax = p3max * 0.7;
	setMinAndMax(p3min, p3max);
	run("Brightness/Contrast...");
	run("ROI Manager...");
	roiManager("Show All");
	setTool("polygon");
	run("Scale to Fit");
	waitForUser("Select AREA(S) of BACKGROUND in "+alt_name_p3+", add to ROI manager using 't'. Click OK when done");
	roiManager("save", output+"p3_background_roi.zip");
	roiManager("reset");

	if (isOpen("B&C")) { 
		selectWindow("B&C"); 
		run("Close");
	}
}

///////////////////////////////////////////////
// measure background in all puncta channels //
///////////////////////////////////////////////

roiManager("Open", output+"p1_background_roi.zip");
selectImage(puncta1ID);                                                                // selects puncta1 channel, measures background and saves
roiManager("Deselect");
roiManager("Measure");
saveAs("Results", output+"/results/puncta1_background_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
if (isOpen("ROI Manager")) {                                                      // Close other windows first, as they imagej names them the same as the images
    selectWindow("ROI Manager"); 
    run("Close");
}

roiManager("Open", output+"p2_background_roi.zip");
selectImage(puncta2ID);                                                                // selects puncta1 channel, measures background and saves
roiManager("Deselect");
roiManager("Measure");
saveAs("Results", output+"/results/puncta2_background_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
if (isOpen("ROI Manager")) {                                                      // Close other windows first, as they imagej names them the same as the images
    selectWindow("ROI Manager"); 
    run("Close");
}

roiManager("Open", output+"p3_background_roi.zip");
selectImage(puncta3ID);                                                                // selects puncta1 channel, measures background and saves
roiManager("Deselect");
roiManager("Measure");
saveAs("Results", output+"/results/puncta3_background_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
if (isOpen("ROI Manager")) {                                                      // Close other windows first, as they imagej names them the same as the images
    selectWindow("ROI Manager"); 
    run("Close");
}

///////////////////////////////////////////////////////////////////
// More general analysis for the puncta channels                 //
// measures the synaptic and dendritic regions for each channel  //
// measure background in both puncta channels                    //
///////////////////////////////////////////////////////////////////

roiManager("Open", output+"dendrite_roi.zip");
roiManager("Deselect");

selectImage(puncta1ID);                                                                // selects puncta1 channel, measures dendrite roi, measures and saves
roiManager("Measure");
saveAs("Results", output+"/results/puncta1_general_dendrite_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

roiManager("Open", output+"spines_roi.zip");
roiManager("Deselect");

selectImage(puncta1ID);															     // selects puncta1 channel, measures synaptic area roi, measures and saves
roiManager("Measure");
saveAs("Results", output+"/results/puncta1_general_spine_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

roiManager("Open", output+"dendrite_roi.zip");
roiManager("Deselect");

selectImage(puncta2ID);                                                                // selects puncta2 channel, measures dendrite roi, measures and saves
roiManager("Measure");
saveAs("Results", output+"/results/puncta2_general_dendrite_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

roiManager("Open", output+"spines_roi.zip");
roiManager("Deselect");

selectImage(puncta2ID);															     // selects puncta2 channel, measures synaptic area roi, measures and saves
roiManager("Measure");
saveAs("Results", output+"/results/puncta2_general_spine_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

roiManager("Open", output+"dendrite_roi.zip");
roiManager("Deselect");

selectImage(puncta3ID);                                                                // selects puncta2 channel, measures dendrite roi, measures and saves
roiManager("Measure");
saveAs("Results", output+"/results/puncta3_general_dendrite_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

roiManager("Open", output+"spines_roi.zip");
roiManager("Deselect");

selectImage(puncta3ID);															     // selects puncta2 channel, measures synaptic area roi, measures and saves
roiManager("Measure");
saveAs("Results", output+"/results/puncta3_general_spine_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

///////////////////////////////////////////////////////////////////
// Colocalisation analysis measuring overlapping intensity and ROI//
// Use puncta1 ROI first, measure in all other channels          //
// if no ROI detected empty analysis files will be produced      //
///////////////////////////////////////////////////////////////////

//dendrite
selectImage(puncta2ID);
if (File.exists(output+"dendrite_puncta1_roi.zip") == true) {
	roiManager("Open", output+"dendrite_puncta1_roi.zip");                              // measures puncta2 intensity in puncta1 roi, inside the dendritic regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta1_dendritic_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta1_dendritic_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");
//spines
selectImage(puncta2ID);
if (File.exists(output+"spine_puncta1_roi.zip") == true) {
	roiManager("Open", output+"spine_puncta1_roi.zip");                        // measures puncta2 intensity in puncta1 roi, inside the synaptic area regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta1_spine_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta1_spine_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");

//dendrite
selectImage(puncta3ID);
if (File.exists(output+"dendrite_puncta1_roi.zip") == true) {
	roiManager("Open", output+"dendrite_puncta1_roi.zip");                              // measures puncta2 intensity in puncta1 roi, inside the dendritic regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta1_dendritic_roi_puncta3_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta1_dendritic_roi_puncta3_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");
//spines
selectImage(puncta3ID);
if (File.exists(output+"spine_puncta1_roi.zip") == true) {
	roiManager("Open", output+"spine_puncta1_roi.zip");                        // measures puncta2 intensity in puncta1 roi, inside the synaptic area regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta1_spine_roi_puncta3_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta1_spine_roi_puncta3_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");

///////////////////////////////////////////////////////////////////
// Colocalisation analysis measuring overlapping intensity and ROI//
// Use puncta2 ROI , measure in all other channels          //
// if no ROI detected empty analysis files will be produced      //
///////////////////////////////////////////////////////////////////

//dendrite
selectImage(puncta1ID);
if (File.exists(output+"dendrite_puncta2_roi.zip") == true) {
	roiManager("Open", output+"dendrite_puncta2_roi.zip");                              // measures puncta2 intensity in puncta1 roi, inside the dendritic regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta2_dendritic_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta2_dendritic_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");
//spines
selectImage(puncta1ID);
if (File.exists(output+"spine_puncta2_roi.zip") == true) {
	roiManager("Open", output+"spine_puncta2_roi.zip");                        // measures puncta2 intensity in puncta1 roi, inside the synaptic area regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta2_spine_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta2_spine_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");

//dendrite
selectImage(puncta3ID);
if (File.exists(output+"dendrite_puncta2_roi.zip") == true) {
	roiManager("Open", output+"dendrite_puncta2_roi.zip");                              // measures puncta2 intensity in puncta1 roi, inside the dendritic regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta2_dendritic_roi_puncta3_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta2_dendritic_roi_puncta3_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");
//spines
selectImage(puncta3ID);
if (File.exists(output+"spine_puncta2_roi.zip") == true) {
	roiManager("Open", output+"spine_puncta2_roi.zip");                        // measures puncta2 intensity in puncta1 roi, inside the synaptic area regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta2_spine_roi_puncta3_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta2_spine_roi_puncta3_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");

///////////////////////////////////////////////////////////////////
// Colocalisation analysis measuring overlapping intensity and ROI//
// Use puncta3 ROI , measure in all other channels          //
// if no ROI detected empty analysis files will be produced      //
///////////////////////////////////////////////////////////////////

//dendrite
selectImage(puncta1ID);
if (File.exists(output+"dendrite_puncta3_roi.zip") == true) {
	roiManager("Open", output+"dendrite_puncta3_roi.zip");                              // measures puncta2 intensity in puncta1 roi, inside the dendritic regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta3_dendritic_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta3_dendritic_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");
//spines
selectImage(puncta1ID);
if (File.exists(output+"spine_puncta3_roi.zip") == true) {
	roiManager("Open", output+"spine_puncta3_roi.zip");                        // measures puncta2 intensity in puncta1 roi, inside the synaptic area regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta3_spine_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta3_spine_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");

//dendrite
selectImage(puncta2ID);
if (File.exists(output+"dendrite_puncta3_roi.zip") == true) {
	roiManager("Open", output+"dendrite_puncta3_roi.zip");                              // measures puncta2 intensity in puncta1 roi, inside the dendritic regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta3_dendritic_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta3_dendritic_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");
//spines
selectImage(puncta2ID);
if (File.exists(output+"spine_puncta3_roi.zip") == true) {
	roiManager("Open", output+"spine_puncta3_roi.zip");                        // measures puncta2 intensity in puncta1 roi, inside the synaptic area regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta3_spine_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta3_spine_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");

///////////////////////////////////////////////
// Tie off loose ends!                       //
///////////////////////////////////////////////

if (isOpen("ROI Manager")) { 
    selectWindow("ROI Manager"); 
    run("Close");
}

if (isOpen("Threshold")) { 
    selectWindow("Threshold"); 
    run("Close");
}

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

Dialog.create("GET REPRESENTATIVE IMAGES");					// instead of closing all images, run dialog box to decide if to cellect representative images.
	Dialog.addCheckbox("Create representative images?",true);
Dialog.show();
	
representative_images = Dialog.getCheckbox();

if (representative_images == false) {
	run("Close All");
}

////////////////////////////////////////////////////////
// Make representative images automatically if chosen //
////////////////////////////////////////////////////////

if (representative_images == true) {
	open_images = newArray(nImages);						// make an array of open images and fill with IDs

	for (i=0 ; i<open_images.length ; i++) {
		selectImage(i + 1);
		open_images[i] = getImageID();
	}
	
	Array.sort(open_images);						// sorts array low>high
	Array.reverse(open_images);					// Ids run negatively, so earliest images are high, therefore reverse
	new_images = Array.slice(open_images, rawIDS.length, open_images.length);			// creates an array of just the new images by slicing down open_images

	for (i=0 ; i<new_images.length ; i++) {						// iterates through the  new_images array and closes all images
		selectImage(new_images[i]);
		run("Close");
	}
	
	run("3 way puncta representative images");					// Runs the macro for representative images
}
