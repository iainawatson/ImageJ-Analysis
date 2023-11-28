/////////////////////////////
// COLOCALISATION ANALYSIS //
// Author: Iain Watson     //
// Version: 1.4 06/07/18   //
/////////////////////////////
// UPDATES
// Making the Thresholding interactive to prevent over sampling of puncta
// 
// v1.2 
// As ROI maybe empty after thresholding, workarounds included to add empty results tables
// Also looks for roi's and thresholded images if already created and loads them. If the follwoing new items are required they must be deleted before running macro:
// - length_roi.zip
// - bouton_roi.zip
// - total_area_roi.zip
// - threshold of puncta1 channel
// - threshold of puncta2 channel
//
// v1.3
// create single entry change for entering  min/max information
// saves antibody information
// saves channel information
//
// v1.4
// Sets the estimated length of the spine region to analyse (default is 2 microns)
// Sets the resolution for the image if none present, saves to file,
//
// v1.4 axonal
// added sections to retrieve analysis from averaging counts per synaptic boutons measured

///////////////////////////
// Set variables here    //
///////////////////////////

//define the range of puncta size when using 'Analyze Particles'. Minimum should be set to microscope reolution limit. Use following as guide:
//iSIM = 0.02-0.25
//Leica SP5 = 0.08-2
//Make larger if objects are larger than 'puncta' size

puncta1_aplower = 0.02;
puncta1_apupper = 1;

puncta2_aplower = 0.02;
puncta2_apupper = 1;

//set radii for median filtering of puncta channels. Explore the best through trial and error. Default value of 5 works well. note:
//excellent staining may need higher radii values
//never drop below 3

p1_med_radius = 20;
p2_med_radius = 5;

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
		if (max-min!=255) {
			run("Apply LUT");
		}
	} else if (bit == 12) {
		if (max-min!=4095) {
			run("Apply LUT");
		}
	} else if (bit == 16) {
		if (max-min!=65535) {
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
		Dialog.show();
	morphab = Dialog.getString();
	p1ab = Dialog.getString();;
	p2ab = Dialog.getString();;;
	abprof = File.open(abprofiles);
	print(abprof, "Morphological Marker:");
	print(abprof, morphab);
	print(abprof, "Antibody 1:");
	print(abprof, p1ab);
	print(abprof, "Antibody 2:");
	print(abprof, p2ab);
	File.close(abprof);
} else {
	abid = File.openAsString(abprofiles);
	lines = split(abid, "\n");   // split the string by lines in the file
	morphab =  lines[1];   // turn string back in integer
	p1ab =  lines[3];
	p2ab =  lines[5];
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
		Dialog.show();
	den = Dialog.getChoice();
	p1 = Dialog.getChoice();;
	p2 = Dialog.getChoice();;;
	chprof = File.open(channelprofiles);
	print(chprof, "morphological channel:");
	print(chprof, den);
	print(chprof, "Puncta1 channel:");
	print(chprof, p1);
	print(chprof, "Puncta2 channel:");
	print(chprof, p2);
	File.close(chprof);
} else {
	channelid = File.openAsString(channelprofiles);
	lines = split(channelid, "\n");   // split the string by lines in the file
	den =  lines[1];   // turn string back in integer
	p1 =  lines[3];
	p2 =  lines[5];
}

// create personalised names for each channel

alt_name_morph = morphab + " (" + den + ")";
alt_name_p1 = p1ab + " (" + p1 + ")";
alt_name_p2 = p2ab + " (" + p2 + ")";

////////////////////////////////////////////////////////////////////////////////
// create an array of open images. These can then be cycled through later     //
// adjust below code to match the "C=x" re: channel identifier from microscope//
// Give newly opened images variable to call later from image ID              //
////////////////////////////////////////////////////////////////////////////////

rawIDS = newArray(nImages);

for (i=0; i < rawIDS.length; i++) {                                // iterate through original ids array, asign variable to original images
	selectImage(i+1);                                              // note what channels correspond to what variables
	title = getTitle();												// creates rawIDS array populated by original images
	if (matches(title, ".*" + den + ".*")) {
		dendriteID = getImageID();
		dendriteTitle = getTitle();
		rawIDS[i] = dendriteID;
	} else if (matches(title, ".*" + p1 + ".*")) {
		puncta1ID = getImageID();
		puncta1Title = getTitle();
		rawIDS[i] = puncta1ID;
	} else if (matches(title, ".*" + p2 + ".*")) {
		puncta2ID = getImageID();
		puncta2Title = getTitle();
		rawIDS[i] = puncta2ID;
	}
}

/////////////////////
//Section hacked just for matching puncta 2 to morhpohological channel
/////////////////////

puncta2ID = dendriteID;
puncta2Title = dendriteTitle;
rawIDS[2] = dendriteID;




Array.sort(rawIDS);						// sorts array low>high
Array.reverse(rawIDS);					// Ids run negatively, so earliest images are high, therefore reverse

///////////////////////////////////////////////////////////
// Interactively define min and max for each channel     //
// Create file to save values                            //
// Reload values if file already created                 //
///////////////////////////////////////////////////////////
minmaxfile = parent2 + "/min_max_values.txt"; 				// saves file in experiment folder
if (File.exists(minmaxfile) == false) {
	Dialog.create("Open multiple images of the morhpological marker from multiple conditions and test for\noptimal min/max values\nto allow for drawing length and bouton ROI's");
		Dialog.addNumber("Enter MINIMUM value for " + alt_name_morph + ":", 0);
		Dialog.addNumber("Enter MAXIMUM value for " + alt_name_morph + ":", 0);
		Dialog.show();
	denmin = Dialog.getNumber();
	denmax = Dialog.getNumber();;
	// repeat for punta1 channel
	Dialog.create("Open multiple images of the puncta1 channel from multiple conditions and test for\noptimal min/max values to allow for drawing length and bouton ROI's");
		Dialog.addNumber("Enter MINIMUM value for " + alt_name_p1 + ":", 0);
		Dialog.addNumber("Enter MAXIMUM value for " + alt_name_p1 + ":", 0);
		Dialog.show();
	p1min = Dialog.getNumber();
	p1max = Dialog.getNumber();;
	// repeat for punta2 channel
	Dialog.create("Open multiple images of the puncta2 channel from multiple conditions and test for\noptimal min/max values to allow for drawing length and bouton ROI's");
		Dialog.addNumber("Enter MINIMUM value for " + alt_name_p2 + ":", 0);
		Dialog.addNumber("Enter MAXIMUM value for " + alt_name_p2 + ":", 0);
		Dialog.show();
	p2min = Dialog.getNumber();
	p2max = Dialog.getNumber();;
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
}

//median filter reduces brightness, so compensate for thresholding, 75% works well generally
adj_p1max = 0.75 * p1max;
adj_p2max = 0.75 * p2max;

/////////////////////////////////////////////////
// get the lengths of the axons to measure     //
// save the measurements                       //
// save the roi                                //
/////////////////////////////////////////////////

if (File.exists(output+"length_roi.zip") == false) {
	selectImage(dendriteID);
	setMinAndMax(denmin, denmax);
	run("Brightness/Contrast...");
	run("Line Width...", "line=1");
	setTool("polyline");
	run("ROI Manager...");
	roiManager("Show All");
	waitForUser("Select LENGTH(S) to measure in "+alt_name_morph+" channel\nMeasure 2x 1.5µm lines starting from centre of bouton\nAdd to ROI manager using 't'. Click OK when done");
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

selectImage(puncta1ID);
wait(100);
setMinAndMax(p1min, p1max);
run("Brightness/Contrast...");
roiManager("Open", output+"length_roi.zip");
roiManager("Show All");
waitForUser("If LENGTH ROI's conflict with "+alt_name_p1+", adjust as necessary. Click OK when done");
selectImage(dendriteID);
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

selectImage(puncta2ID);
wait(100);
setMinAndMax(p2min, p2max);
run("Brightness/Contrast...");
roiManager("Open", output+"length_roi.zip");
roiManager("Show All");
waitForUser("If LENGTH ROI's conflict with "+alt_name_p2+", adjust as necessary. Click OK when done");
selectImage(dendriteID);
roiManager("Deselect");
roiManager("Measure");
saveAs("Results", output+"/results/length_results.csv");

if (isOpen("Results")) { 
	selectWindow("Results"); 
	run("Close");
}

roiManager("Deselect");
roiManager("save", output+"length_roi.zip");
roi_length_count = roiManager("count");							// final list of length measures is counted, this function is called later
roiManager("reset");

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

/////////////////////////////////////////////////////////
// draw the 'bouton' roi region around synaptic bouton //
// save the measurements                               //
// save the roi                                        //
/////////////////////////////////////////////////////////

selectImage(dendriteID);

if (File.exists(output+"bouton_roi.zip") == false) {
	roiManager("Open", output+"length_roi.zip");
	roiManager("Show All");
	roi_length_count = roiManager("count");
	setTool("polygon");
	roiManager("Select", 0);
	run("To Selection");
	waitForUser("Select AREA(S) of BOUTONS to measure in "+alt_name_morph+", add to ROI manager using 't'. Measure up to 4 per image. Click OK when done");
	for (i=roi_length_count; i<roiManager("Count"); i++) {                                     // iterates the newly created bouton regions, measures and saves them
		roiManager("Select", i);
		roiManager("measure");
	}
	saveAs("Results", output+"/results/bouton_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}

	for (i=0; i<roi_length_count; i++) {                                                       // deletes the bouton lengths and allows for just the new dendrite areas to be saved
		roiManager("Select", 0);
		roiManager("delete");
	}
	roiManager("Deselect");
	roiManager("save", output+"bouton_roi.zip");
	roiManager("reset");
} else {
	roiManager("Open", output+"bouton_roi.zip");
	roiManager("Deselect");
	roiManager("measure");
	saveAs("Results", output+"/results/bouton_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
	roiManager("reset");
}


/////////////////////////////////////////////////
// Count the total number of boutons measured  //
/////////////////////////////////////////////////

roiManager("Open", output+"bouton_roi.zip");
roi_bouton_count = roiManager("count");
//setResult("NumberOfBoutons", 0, roi_bouton_count);
//saveAs("Results", output+"/results/bouton_counts.csv");
if (isOpen("Results")) { 
	selectWindow("Results"); 
	run("Close");
}
roiManager("reset");

/*
//////////////////////////////////////////////////////////////////////////
// Sets the distance away from the dendrite to measure synatpic region  //
// Create file to save values                                           //
// Reload values if file already created                                //
//////////////////////////////////////////////////////////////////////////

//create the file and input the estimated length of spines
synapse_distance_file = parent2 + "/synaptic_region_size.txt";
if (File.exists(synapse_distance_file) == false) {
	Dialog.create("Enter the estimated length of spines to define\nsynaptic region outside the dendrite.\nDefault = 2µm");
		Dialog.addNumber("Enter distance in microns:", 2);
		Dialog.show();
	est_length = Dialog.getNumber();
	syndisfile = File.open(synapse_distance_file);
	print(syndisfile, "Estimated length of spines in microns:");
	print(syndisfile, est_length);
	File.close(syndisfile);
} else {
	syndisfile = File.openAsString(synapse_distance_file);
	lines = split(syndisfile, "\n");
	est_length =  parseInt(lines[1]);   // turn string back in integer
}

//to set 'synapse area' width the distance has to be set in pixels
getPixelSize(unit, pixelWidth, pixelHeight);
doubled_est = 2 * est_length;
synarea_pixels = doubled_est / pixelWidth;
*/
//////////////////////////////////////////////////////////////////////////////////////////
// draw the 'total' roi region around axon and bouton along lengths                     //
// save the measurements                                                                //
// save the roi                                                                         //
//////////////////////////////////////////////////////////////////////////////////////////

if (File.exists(output+"total_area_roi.zip") == false) {
	roiManager("Open", output+"length_roi.zip");
/*
	for (i=0; i<roiManager("Count"); i++) {           // Creates as wide line to control the width of synaptic area to ~+/-2 microns either side of dendrite
		roiManager("Select", i);
		//distance set from previous estimated length
		//run("Properties... ", "width=60");
		run("Properties... ", "width="+synarea_pixels);
	}
*/
	selectImage(dendriteID);
	wait(100);
	setMinAndMax(p1min, p1max);                                                    // adjust min/max as neccessary
	run("Brightness/Contrast...");   
	roiManager("Show All");
	setTool("polygon");
	run("Scale to Fit");
	waitForUser("Draw total AREA(S) of AXON and BOUTON to measure in "+alt_name_morph+", add to ROI manager using 't'. Click OK when done");

	for (i=0; i<roi_length_count; i++) {                                                         // deletes the a lengths and allows for just the new synapse areas to be saved
		roiManager("Select", 0);
		roiManager("delete");
	}

	selectImage(dendriteID);                                                             // measures area roi in dendrite channel and saves results
	roiManager("Deselect");
	roiManager("measure");
	saveAs("Results", output+"/results/total_area_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}

	roiManager("Deselect");
	roiManager("save", output+"total_area_roi.zip");
	roiManager("reset");
} else {
	selectImage(dendriteID);
	roiManager("Open", output+"total_area_roi.zip");
	roiManager("Deselect");
	roiManager("measure");
	saveAs("Results", output+"/results/total_area_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
	roiManager("reset");
}

////////////////////////////////////////////////
// Duplicate the first puncta channel         //
// Median Filter                              //
// Raw - Median = Filtered Image              //
// Threshold filtered image                   //
// Reuse thresholded image if already created //
////////////////////////////////////////////////

if (File.exists(output + "thresholded_" + puncta1Title) == false) {
	selectImage(puncta1ID);          // creates and saves a median filtered image
	run("Duplicate...", "title=median");
	selectWindow("median");
	run("Median...", "radius="+p1_med_radius);                                                             // change radius to effect blur.
	saveAs("Tiff", output + "median"+p1_med_radius+"_" + puncta1Title);                                       // change median value to reflect filter level
	median5_puncta1Title = getTitle();

	imageCalculator("Subtract create", puncta1Title,median5_puncta1Title);                         // creates and saves a filtered image
	selectImage("Result of " + puncta1Title);
	saveAs("Tiff", output + "filtered_image_" + puncta1Title);
	setMinAndMax(p1min, adj_p1max);                                                // set as necessary
	//run("Apply LUT");
	//if values remain unchanged then the apply lut will fail. check defined fucntion for code
	applylut_if_minmax_changed();
	roiManager("Open", output+"total_area_roi.zip");									// Opens synpase area to see thresholded area properly
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
	//wait(1000);
	median5_puncta2Title = getTitle();

	imageCalculator("Subtract create", puncta2Title, median5_puncta2Title);               // creates and saves a filtered image
	selectImage("Result of " + puncta2Title);
	saveAs("Tiff", output + "filtered_image_" + puncta2Title);
	//setMinAndMax(p2min, adj_p2max);
	run("Brightness/Contrast...");
	
	roiManager("Open", output+"total_area_roi.zip");
	roiManager("Select", 0);
	run("To Selection");
	waitForUser("Adjust Brightness/Contrast. Click OK when done");
	run("Select All");
	roiManager("reset");
	//run("Apply LUT");
	//if min and max are default values the apply LUT will fail, so check and skip if necessary, for 8/12/16 bit images. define as variable
	applylut_if_minmax_changed();
	roiManager("Open", output+"total_area_roi.zip");									// Opens synpase area to see thresholded area properly
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

/////////////////////////////////////////////////
// detect puncta ROI in the thresholded images //
// detect bouton puncta first               //
/////////////////////////////////////////////////

selectWindow(binary_puncta1Title);
roiManager("Open", output+"bouton_roi.zip");
roiManager("Show All");

for (i=0; i<roi_bouton_count; i++) {                                              // iterates the opened bouton regions, measures them
	roiManager("Select", i);
	run("Analyze Particles...", "size="+puncta1_aplower+"-"+puncta1_apupper+" add");                    // Summary window is detected as "results" so not sure how to gather summary results
}

for (i=0; i<roi_bouton_count; i++) {                                      // deletes the bouton regions and allows for just the new puncta roi to be saved
	roiManager("Select", 0);
	roiManager("Delete");
}

roiManager("Deselect");                                                   // generate and save the summary results
temp_count = roiManager("Count");  								// return the number of items in ROI list, because if 0 and no workaround causes error

if (temp_count>0) { 											// saves the roi
	roiManager("save", output+"bouton_puncta1_roi.zip");
	roiManager("reset");
}

selectWindow(binary_puncta2Title);                                              // Repeat for second puncta image
roiManager("Open", output+"bouton_roi.zip");
roiManager("Show All");

for (i=0; i<roi_bouton_count; i++) {                                              // iterates the opened bouton regions, measures them
	roiManager("Select", i);
	run("Analyze Particles...", "size="+puncta2_aplower+"-"+puncta2_apupper+" add");                       // Summary window is detected as "results" so not sure how to gather summary results
}

for (i=0; i<roi_bouton_count; i++) {                                              // deletes the bouton regions and allows for just the new puncta roi to be saved
	roiManager("Select", 0);
	roiManager("delete");
}

roiManager("Deselect");                                                   // generate and save the summary results
temp_count = roiManager("Count");  								// return the number of items in ROI list, because if 0 and no workaround causes error

if (temp_count>0) { 											// saves the roi
	roiManager("save", output+"bouton_puncta2_roi.zip");
	roiManager("reset");
}

/////////////////////////////////////////////////
// detect puncta ROI in the thresholded images //
// detect total area puncta (axon + bouton)                  //
/////////////////////////////////////////////////

selectWindow(binary_puncta1Title);
roiManager("Open", output+"total_area_roi.zip");
roiManager("Show All");

for (i=0; i<roi_bouton_count; i++) {                                               // iterates the opened synaptic area regions, measures them
	roiManager("Select", i);
	run("Analyze Particles...", "size="+puncta1_aplower+"-"+puncta1_apupper+" add");                    // Summary window is detected as "results" so not sure how to gather summary results
}

for (i=0; i<roi_bouton_count; i++) {                                               // deletes the synaptic area regions and allows for just the new puncta roi to be saved
	roiManager("Select", 0);
	roiManager("delete");
}

roiManager("Deselect");                                                    // deletes the synaptic area regions and allows for just the new puncta roi to be saved
temp_count = roiManager("Count");  								// return the number of items in ROI list, because if 0 and no workaround causes error

if (temp_count>0) { 											// saves the roi
	roiManager("save", output+"total_area_puncta1_roi.zip");
	roiManager("reset");
}

selectWindow(binary_puncta2Title);                                               // Repeat for second puncta image
roiManager("Open", output+"total_area_roi.zip");
roiManager("Show All");

for (i=0; i<roi_bouton_count; i++) {                                               // iterates the opened synaptic area regions, measures them
	roiManager("Select", i);
	run("Analyze Particles...", "size="+puncta2_aplower+"-"+puncta2_apupper+" add");                    // Summary window is detected as "results" so not sure how to gather summary results
}

for (i=0; i<roi_bouton_count; i++) {                                               // deletes the synaptic area regions and allows for just the new puncta roi to be saved
	roiManager("Select", 0);
	roiManager("delete");
}

roiManager("Deselect");                                                    // generate and save the summary results
temp_count = roiManager("Count");  								// return the number of items in ROI list, because if 0 and no workaround causes error

if (temp_count>0) { 											// saves the roi
	roiManager("save", output+"total_area_puncta2_roi.zip");
	roiManager("reset");
}

//////////////////////////////////////////////////////////////
// overlay puncta roi in original channels                  //
// measure mean and II intensity in identified regions      //
// if no ROI detected empty analysis files will be produced //
//////////////////////////////////////////////////////////////

selectImage(puncta1ID);

if (File.exists(output+"bouton_puncta1_roi.zip") == true) {
	roiManager("Open", output+"bouton_puncta1_roi.zip");
	roiManager("Deselect");
	roiManager("Measure");
	roiManager("reset");
	saveAs("Results", output+"/results/puncta1_bouton_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/puncta1_bouton_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}

selectImage(puncta1ID);

if (File.exists(output+"total_area_puncta1_roi.zip") == true) {
	roiManager("Open", output+"total_area_puncta1_roi.zip");
	roiManager("Deselect");
	roiManager("Measure");
	roiManager("reset");
	saveAs("Results", output+"/results/puncta1_total_area_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/puncta1_total_area_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}

selectImage(puncta2ID);

if (File.exists(output+"bouton_puncta2_roi.zip") == true) {
	roiManager("Open", output+"bouton_puncta2_roi.zip");
	roiManager("Deselect");
	roiManager("Measure");
	roiManager("reset");
	saveAs("Results", output+"/results/puncta2_bouton_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/puncta2_bouton_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}

selectImage(puncta2ID);

if (File.exists(output+"total_area_puncta2_roi.zip") == true) {
roiManager("Open", output+"total_area_puncta2_roi.zip");
	roiManager("Deselect");
	roiManager("Measure");
	roiManager("reset");
	saveAs("Results", output+"/results/puncta2_total_area_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/puncta2_total_area_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}

////////////////////////////////////////////////
// draw background regions in MAP2 channel    //
// save ROI                                   //
// load background roi's if already exist     //
////////////////////////////////////////////////

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

if (File.exists(output+"background_roi.zip") == false) {
	selectImage(dendriteID);
	setMinAndMax(denmin, denmax);
	run("Brightness/Contrast...");
	run("ROI Manager...");
	roiManager("Show All");
	setTool("polygon");
	run("Scale to Fit");
	waitForUser("Select AREA(S) of BACKGROUND in "+alt_name_morph+", add to ROI manager using 't'. Click OK when done");
	roiManager("save", output+"background_roi.zip");
	roiManager("reset");

	if (isOpen("B&C")) { 
		selectWindow("B&C"); 
		run("Close");
	}
}

///////////////////////////////////////////////////////////////////////
// check b/g regions do not conflict with staining in other channels //
///////////////////////////////////////////////////////////////////////

selectImage(puncta1ID);
wait(100);
setMinAndMax(p1min, p1max);
run("Scale to Fit");
run("Brightness/Contrast...");
roiManager("Open", output+"background_roi.zip");
roiManager("Show All");
waitForUser("If BACKGROUND ROI's conflict with "+alt_name_p1+", adjust as necessary. Click OK when done");
roiManager("Deselect");
roiManager("save", output+"background_roi.zip");
roiManager("reset");

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

selectImage(puncta2ID);
wait(100);
setMinAndMax(p2min, p2max);
run("Scale to Fit");
run("Brightness/Contrast...");
roiManager("Open", output+"background_roi.zip");
roiManager("Show All");
waitForUser("If BACKGROUND ROI's conflict with "+alt_name_p2+", adjust as necessary. Click OK when done");
roiManager("Deselect");
roiManager("save", output+"background_roi.zip");
roiManager("reset");

if (isOpen("B&C")) { 
    selectWindow("B&C"); 
    run("Close");
}

////////////////////////////////////////////////
// measure background in both puncta channels //
////////////////////////////////////////////////

roiManager("Open", output+"background_roi.zip");

selectImage(puncta1ID);                                                                // selects puncta1 channel, measures background and saves
roiManager("Deselect");
roiManager("Measure");
saveAs("Results", output+"/results/puncta1_background_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}

selectImage(puncta2ID);                                                                // selects puncta2 channel, measures background and saves
roiManager("Deselect");
roiManager("Measure");
saveAs("Results", output+"/results/puncta2_background_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

///////////////////////////////////////////////////////////////////
// More general analysis for the puncta channels                 //
// measures the synaptic and bouton regions for each channel  //
// measure background in both puncta channels                    //
///////////////////////////////////////////////////////////////////

roiManager("Open", output+"bouton_roi.zip");
roiManager("Deselect");

selectImage(puncta1ID);                                                                // selects puncta1 channel, measures dendrite roi, measures and saves
roiManager("Measure");
saveAs("Results", output+"/results/puncta1_whole_bouton_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

roiManager("Open", output+"total_area_roi.zip");
roiManager("Deselect");

selectImage(puncta1ID);															     // selects puncta1 channel, measures synaptic area roi, measures and saves
roiManager("Measure");
saveAs("Results", output+"/results/puncta1_whole_total_area_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

roiManager("Open", output+"bouton_roi.zip");
roiManager("Deselect");

selectImage(puncta2ID);                                                                // selects puncta2 channel, measures dendrite roi, measures and saves
roiManager("Measure");
saveAs("Results", output+"/results/puncta2_whole_bouton_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

roiManager("Open", output+"total_area_roi.zip");
roiManager("Deselect");

selectImage(puncta2ID);															     // selects puncta2 channel, measures synaptic area roi, measures and saves
roiManager("Measure");
saveAs("Results", output+"/results/puncta2_whole_total_area_results.csv");
if (isOpen("Results")) { 
    selectWindow("Results"); 
    run("Close");
}
roiManager("reset");

///////////////////////////////////////////////////////////////////
// Colocalisation analysis measuring overlappingintensity and ROI//
// measures the Puncta2 intensity in Puncta1 ROI and vice versa  //
// if no ROI detected empty analysis files will be produced      //
///////////////////////////////////////////////////////////////////

selectImage(puncta2ID);

if (File.exists(output+"bouton_puncta1_roi.zip") == true) {
	roiManager("Open", output+"bouton_puncta1_roi.zip");                              // measures puncta2 intensity in puncta1 roi, inside the bouton regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta1_bouton_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta1_bouton_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");

selectImage(puncta2ID);

if (File.exists(output+"total_area_puncta1_roi.zip") == true) {
	roiManager("Open", output+"total_area_puncta1_roi.zip");                        // measures puncta2 intensity in puncta1 roi, inside the synaptic area regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta1_total_area_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta1_total_area_roi_puncta2_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");

selectImage(puncta1ID);

if (File.exists(output+"bouton_puncta2_roi.zip") == true) {
	roiManager("Open", output+"bouton_puncta2_roi.zip");                              // measures puncta1 intensity in puncta2 roi, inside the bouton regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta2_bouton_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta2_bouton_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
}
roiManager("reset");

selectImage(puncta1ID);

if (File.exists(output+"total_area_puncta2_roi.zip") == true) {
	roiManager("Open", output+"total_area_puncta2_roi.zip");                        // measures puncta1 intensity in puncta2 roi, inside the synaptic area regions
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", output+"/results/coloc_puncta2_total_area_roi_puncta1_intensity_results.csv");
	if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");
	}
} else {
	run("Clear Results");
	create_empty_results();     					// Open empty results from earlier defined function
	saveAs("Results", output+"/results/coloc_puncta2_total_area_roi_puncta1_intensity_results.csv");
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
	
	run("axon representative images autostart");					// Runs the macro for representative images
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NOTES FOR IMPROVEMENT                                                                                                                                        //
// Take puncta ROI detected, measure in orginal channel, iterate ROI through original image, measure puncta, subtract b/g, if positive keep, if negative delete //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
