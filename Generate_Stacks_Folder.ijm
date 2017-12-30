// Generate Stacks Folder Macro by Christophe Leterrier
// 20-01-2016
//
//This takes a folder full of single channel tifs with channels labeled C=0, C=1 etc... (as generated by the Extract_ZVI macro).
// • Generates stacks of raw images grouped by channel (can be used for quantification as they are raw data).
// • Also generates an overlay hyperstack, with an optionnal pre-processing (substract background / unsharp mask) for visualization.
// • Saves the single channel raw stacks and the overlay hyperstack in a "Stacks" folder.
//
// Folder Structure:
//
// •Experiment folder
// |–•Source folder
// |-•Stacks (Created from the Source folder by this macro)
//
// Updates:
// 14-11-2011: integrate automatic channel count and channel names detection
// 17-09-2012: modified to reorder the Composite overlay following the channels : C=0, C=1, C=2, C=3... (by acquisition order)
//             and adding a color code and processed flag to the overlay name (by acquisiton order of channels RGB, W = white = grays)
// 20-01-2016: added support for images of different sizes (using sequential open + Images to Stack rather than Import Image Sequence)
// 29-05-2016: Per channel settings and more flexibility in setting parameters for processing before overlay


macro "Generate_Stacks_Folder" {

	// Default Dialog Values

	BG_DEF = false;
	BG_PARA_DEF = true;
	BG_RAD_DEF = -1;

	UM_DEF = false;
	UM_RAD_DEF = 1;
	UM_W_DEF = 0.3;

	INT_DEF = true;
	INT_VAL_DEF = 0.01;

	REL_DEF = false;
	GAMMA_DEF = 1;

	FLAT_DEF = false;
	CLOSE_OVER_DEF=false;


	// Get the folder name
	INPUT_DIR = getDirectory("Select a directory full of tif images");
	print("\n\n\n*** Generates_Stacks_Folder Log ***");
	print("INPUT_DIR:" + INPUT_DIR);
	OUTPUT_NAME = File.getName(INPUT_DIR);

	// Count the number of files ending with ".tif" as the number of images
	ALL_NAMES = getFileList(INPUT_DIR);
	Array.sort(ALL_NAMES);
	IMAGE_NUMBER = 0;
	for (i = 0; i < ALL_NAMES.length; i++) {
		LENGTH = lengthOf(ALL_NAMES[i]);
		if (substring(ALL_NAMES[i],LENGTH-4,LENGTH) == ".tif") {
			IMAGE_NUMBER ++;
		}
	}
	print("IMAGE_NUMBER:" + IMAGE_NUMBER);

	// Array that stores the images names
	IMAGE_NAMES = newArray(IMAGE_NUMBER);
	for (i = 0; i < ALL_NAMES.length; i++) {
		LENGTH = lengthOf(ALL_NAMES[i]);
		if (substring(ALL_NAMES[i], LENGTH-4, LENGTH) == ".tif") {
			IMAGE_NAMES[i] = ALL_NAMES[i];
		}
	}

	// Looks at the last three characters of the name (without extension) as the channel ID
	index = 1;
	FIRST_INDEX = substring(IMAGE_NAMES[0], lengthOf(IMAGE_NAMES[0]) - 7, lengthOf(IMAGE_NAMES[0]) - 4);
	CURRENT_INDEX = substring(IMAGE_NAMES[index], lengthOf(IMAGE_NAMES[index]) - 7, lengthOf(IMAGE_NAMES[index]) - 4);
	// iterates a counter until it finds the same channel ID as the first image file, deducing the channels count
	while (FIRST_INDEX != CURRENT_INDEX) {
		index++;
		CURRENT_INDEX = substring(IMAGE_NAMES[index], lengthOf(IMAGE_NAMES[index]) - 7, lengthOf(IMAGE_NAMES[index]) - 4);
	}
	CHANNEL_COUNT = index;
	print("CHANNEL_COUNT:" + CHANNEL_COUNT);

	// As the Merge command does not take more than 6 channels, the macro will exit if there are more
	if (CHANNEL_COUNT > 6) {
		exit("Can't deal with more than 6 channels!");
	}

	//Store the channels IDs
	CHANNEL_NAMES=newArray(CHANNEL_COUNT);
	for (i = 0; i < CHANNEL_COUNT; i++) {
			CHANNEL_NAMES[i]=substring(IMAGE_NAMES[i],lengthOf(IMAGE_NAMES[i])-7,lengthOf(IMAGE_NAMES[i])-4);
	}

	// Define default colors depending on the number of channels
	DEF_COLORS = newArray(CHANNEL_COUNT);
	if (CHANNEL_COUNT == 1){
		DEF_COLORS[0] = "Grey";
	}
	else if (CHANNEL_COUNT == 2) {
		DEF_COLORS[0] = "Red";
		DEF_COLORS[1] = "Green";
	}
	else if (CHANNEL_COUNT == 3) {
		DEF_COLORS[0] = "Blue";
		DEF_COLORS[1] = "Red";
		DEF_COLORS[2] = "Green";
	}
	else if (CHANNEL_COUNT == 4) {
		DEF_COLORS[0] = "Blue";
		DEF_COLORS[1] = "Red";
		DEF_COLORS[2] = "Green";
		DEF_COLORS[3] = "Grays";
	}
	else {
		DEF_COLORS[0] = "Blue";
		DEF_COLORS[1] = "Red";
		DEF_COLORS[2] = "Green";
		for (k = 3; k < CHANNEL_COUNT; k++) {
			DEF_COLORS[k] = "Grays";
		}
	}
	// Define the choice of colors and the array that will store the choices
	COLORS = newArray("None", "Red", "Green", "Blue", "Grays", "Cyan", "Magenta", "Yellow");
	COLORS_CHOICE = newArray(CHANNEL_COUNT);
	PROCESS_REL = newArray(CHANNEL_COUNT);
	GAMMA = newArray(CHANNEL_COUNT);

	// Create the dialog box
	Dialog.create("Parameters (" + CHANNEL_COUNT + " channels)");

	Dialog.addCheckbox("Background subtraction", BG_DEF);
	Dialog.addCheckbox("Use sliding paraboloid", BG_PARA_DEF);
	Dialog.addNumber("Radius   ", BG_RAD_DEF, 0, 3, "pixels (-1 = auto)");
	Dialog.addMessage("");
	Dialog.addCheckbox("Unsharp mask", UM_DEF);
	Dialog.addNumber("Radius   ", UM_RAD_DEF, 2, 4, "pixels");
	Dialog.addNumber("Weight   ", UM_W_DEF, 2, 4, "");
	Dialog.addMessage("");
	Dialog.addCheckbox("Contrast Enhancement", INT_DEF);
	Dialog.addNumber("Saturated", INT_VAL_DEF, 2, 4, "%");
	Dialog.addMessage("");
	Dialog.addCheckbox("Flatten to RGB", FLAT_DEF);

	// Each channel gets an entry, with a choice of colors for the overlay. All channels will be used in the Composite image
	for (k = 0; k < CHANNEL_COUNT; k++) {
		Dialog.addMessage("**** Channel \"" + CHANNEL_NAMES[k] + "\" ****");
		Dialog.addChoice("Color:    ", COLORS, DEF_COLORS[k]);
		Dialog.addCheckbox("Keep relative intensities", REL_DEF);
		Dialog.addNumber("        Gamma ", GAMMA_DEF, 2, 4, "");

	}

	Dialog.show();

	// Feed the variables with the dialog values

	BG = Dialog.getCheckbox();
	BG_PARA = Dialog.getCheckbox();
	BG_RAD = Dialog.getNumber();

	UM = Dialog.getCheckbox();
	UM_RAD = Dialog.getNumber();
	UM_W = Dialog.getNumber();

	INT = Dialog.getCheckbox();
	INT_VAL = Dialog.getNumber();

	FLAT = Dialog.getCheckbox();

	for (k = 0; k < CHANNEL_COUNT; k++) {
		COLORS_CHOICE[k] = Dialog.getChoice();
		GAMMA[k] = Dialog.getNumber();
		PROCESS_REL[k] = Dialog.getCheckbox();
	}

	// Create output directory and path
	OUTPUT_DIR = File.getParent(INPUT_DIR);
	OUTPUT_NAME = File.getName(INPUT_DIR);
	OUTPUT_SHORTA = split(OUTPUT_NAME, " ");
	OUTPUT_SHORT = OUTPUT_SHORTA[0];
	OUTPUT_DIR = OUTPUT_DIR + File.separator + OUTPUT_SHORT + " stacks" + File.separator;
	if (File.isDirectory(OUTPUT_DIR) == false) {
		File.makeDirectory(OUTPUT_DIR);
	}

	setBatchMode(true);

	// Loop on all channels, imports a sequence corresponding to channel, makes a stack, saves it
	for (k=0; k<CHANNEL_COUNT; k++) {
		for (i = 0; i < IMAGE_NAMES.length; i++) {
			if (indexOf(IMAGE_NAMES[i], CHANNEL_NAMES[k]) > -1)
				open (INPUT_DIR + IMAGE_NAMES[i]);
		}
		run("Images to Stack", "method=[Copy (center)] name=" + CHANNEL_NAMES[k] + " title=[] use");
		STACK_PATH = OUTPUT_DIR + CHANNEL_NAMES[k] + ".tif";
		print("Saving " + CHANNEL_NAMES[k] + " in " + STACK_PATH);
		save(STACK_PATH);
	}

	// Process the stacks if chosen
	for (k = 0; k < CHANNEL_COUNT; k++) {

		if (COLORS_CHOICE[k] == "None") {

		}
		else {
			selectWindow(CHANNEL_NAMES[k]);
			if (BG == true) {
				if (BG_RAD == -1) BACKGROUND_RADIUS = floor(getWidth()/20) + 5;
				else BACKGROUND_RADIUS = BG_RAD;
				if (BG_PARA == true) ADDS = "sliding";
				else ADDS = "";
				run("Subtract Background...", "rolling=" + BACKGROUND_RADIUS + " " + ADDS + " stack");
			}
			if (UM == true) {
				run("Unsharp Mask...", "radius=" + UM_RAD + " mask=" + UM_W + " stack");
			}
			if (INT == true && PROCESS_REL[k] == false) {
				run("Enhance Contrast", "saturated=" + INT_VAL + " normalize process_all");
			}
			if (INT == true && PROCESS_REL[k] == true) {
				run("Enhance Contrast", "saturated=" + INT_VAL + " normalize process_all use");
			}
			if (GAMMA[k] != 1) {
				run("Gamma...", "value=" + GAMMA[k] + " stack");
			}
		}
	}


	// Generate the channels string for the Merge... command
	MERGE_STRING = "";
	for (k = 0; k < CHANNEL_COUNT; k++) {
			if (COLORS_CHOICE[k] == "None") {

			}
			else {
				MERGE_STRING += "c" + (k + 1) + "='" + CHANNEL_NAMES[k] + "' ";
			}
	}
	//print(MERGE_STRING);

	// Merge the single channel stacks into an hyperstack
	run("Merge Channels...", MERGE_STRING +"create keep ignore");
	OVERLAY_ID = getImageID();

	// Generate the color code appended to the overlay file name
	COLOR_CODE = "";
	for (k = 0; k < CHANNEL_COUNT; k++) {
		if (COLORS_CHOICE[k] == "None") letter = "n";
		else if (COLORS_CHOICE[k] == "Red") letter = "R";
		else if (COLORS_CHOICE[k] == "Green") letter = "G";
		else if (COLORS_CHOICE[k] == "Blue") letter = "B";
		else if (COLORS_CHOICE[k] == "Grays") letter = "W";
		else if (COLORS_CHOICE[k] == "Cyan") letter = "C";
		else if (COLORS_CHOICE[k] == "Magenta") letter = "M";
		else if (COLORS_CHOICE[k] == "Yellow") letter = "Y";
		COLOR_CODE += letter;
	}
	if (FLAT == true) COLOR_CODE += "f";
	else COLOR_CODE += "c";

	// Change the LUT of each channel according to the chosen colors
	selectImage(OVERLAY_ID);
	a = 1;
	for (k = 0; k < CHANNEL_COUNT; k++) {
		if (COLORS_CHOICE[k] == "None") {
			a--;
		}
		else {
			Stack.setChannel(k + a);
			run(COLORS_CHOICE[k]);
		}

	}

	// Flatten to RGB (if chosen) and transfer labels from all single channel stacks into the hyperstack
	if (FLAT == true) {
		run("Stack to RGB", "slices");
		OVERLAY_ID = getImageID();
		OVERLAY_TITLE = "C=Over(" + COLOR_CODE + ")";
		rename(OVERLAY_TITLE);
		selectWindow(CHANNEL_NAMES[0]);
			SLICES = nSlices;
		for (i = 0; i < SLICES; i++) {
			selectWindow(CHANNEL_NAMES[0]);
			setSlice(i + 1);
			SLICE_INFO = getInfo("slice.label");
			NEW_NAME = substring(SLICE_INFO, 0, lengthOf(SLICE_INFO)-3) + "over";
			selectImage(OVERLAY_ID);
			setSlice(i + 1);
			setMetadata("Label", NEW_NAME);
		}
	}
	else {
		OVERLAY_TITLE = "C=Over(" + COLOR_CODE + ")";
		rename(OVERLAY_TITLE);
		for (k = 0; k < CHANNEL_COUNT; k++) {
			selectWindow(CHANNEL_NAMES[k]);
			SLICES = nSlices;
			for (i = 0; i < SLICES; i++) {
				selectWindow(CHANNEL_NAMES[k]);
				setSlice(i + 1);
				SLICE_INFO = getInfo("slice.label");
				selectImage(OVERLAY_ID);
				Stack.setPosition(k + 1, i + 1, 0);
				setMetadata("Label", SLICE_INFO);
			}
		}
	}

	// Close single channels stacks
	for (k=0; k<CHANNEL_COUNT; k++) {
	selectWindow(CHANNEL_NAMES[k]);
	close();
	}

	// Save the overlay
	selectImage(OVERLAY_ID);
	OVER_PATH = OUTPUT_DIR + OVERLAY_TITLE + ".tif";
	save(OVER_PATH);
	print("Saving overlay in " + STACK_PATH);

	// Exit batch mode, display end status, open Stacks folder in the Finder.
	setBatchMode("exit and display");

	// display the Channels Tools to toggle channels
	run("Channels Tool...");

	print("*** Generates_Stacks_Folder end ***");
	showStatus("Generate Stacks Folder finished");
//	exec("open", OUTPUT_DIR);

}
