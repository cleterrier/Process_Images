// Make_Projections macro by Christophe Leterrier
// v 3.1 05-02-14
//
// Takes a folder containing Z-stacks (with one of several channels), such as the output of the Extract_Zeiss macro
// Project them according to a selectable projection method
// The extracted images/stacks are located in a folder defined in the options.
// Other option : reset spatial scale.
// 23/11/12 added outlier pixel filtering option before projection (2x2 block, 3 sigma)
// Requires the "Remove Outliers" plugin present in Fiji
//
// 31/03/13 Added background subtraction before projection (rolling ball 50 px sliding paraboloid)
// 05/02/14 removed the "-proj" text in the exported projection names

macro "Make_Projections" {

//*************** Initialization ***************

	// Rolling ball diameter (in px) for the optionnal background subtraction
	ROLLING_DIAM = 105;
	UNSHARP_RADIUS = 2;
	UNSHARP_MASK = 0.3;

	// Default values for the Options Panel
	SIGMA_DEF = false;
	BG_DEF = false;
	UNSHARP_DEF = false;
	PROJ_METHOD_DEF = "Max Intensity";
	REM_SL_DEF = false;
	SAVE_DEF="In a folder next to the source folder";

	// Get the folder name
	INPUT_DIR=getDirectory("Select the input stacks directory");

	print("\n\n\n*** Make_Projections Log ***");
	print("");
	print("INPUT_DIR :"+INPUT_DIR);

	// Initialize choices variables
	PROJ_ARRAY = newArray("None", "Max Intensity", "Average Intensity", "Sum Slices");
	SAVE_ARRAY = newArray("In the source folder", "In a subfolder of the source folder", "In a folder next to the source folder", "In a subfolder with custom location");


//*************** Dialog ***************

	// Creation of the dialog box
	Dialog.create("Make_Projections Options");
	Dialog.addCheckbox("Remove Lower Slices", REM_SL_DEF);
	Dialog.addCheckbox("Outlier filtering before projection", SIGMA_DEF);
	Dialog.addCheckbox("Background subtraction before projection", BG_DEF);
	Dialog.addCheckbox("Unsharp Mask before projection", UNSHARP_DEF);
	Dialog.addChoice("Projection Type", PROJ_ARRAY, PROJ_METHOD_DEF);
	Dialog.addChoice("Save Images", SAVE_ARRAY, SAVE_DEF);
	Dialog.show();

	// Feeding variables from dialog choices
	REM_SL = Dialog.getCheckbox();
	SIGMA = Dialog.getCheckbox();
	BG = Dialog.getCheckbox();
	UNSHARP = Dialog.getCheckbox();
	PROJ_METHOD = Dialog.getChoice();
	SAVE_TYPE = Dialog.getChoice();

	// Get all file names
	ALL_NAMES=getFileList(INPUT_DIR);
	Array.sort(ALL_NAMES);
	ALL_EXT=newArray(ALL_NAMES.length);
	// Create extensions array
	for (i = 0; i < ALL_NAMES.length; i++) {
	//	print(ALL_NAMES[i]);
		ALL_NAMES_PARTS = getFileExtension(ALL_NAMES[i]);
		ALL_EXT[i] = ALL_NAMES_PARTS[1];
	}


//*************** Prepare processing ***************

	setBatchMode(true);

	// Create the output folder
	OUTPUT_DIR="Void";

	if (SAVE_TYPE == "In the source folder") {
		OUTPUT_DIR = INPUT_DIR;
	}

	if (SAVE_TYPE == "In a subfolder of the source folder") {
		OUTPUT_DIR = INPUT_DIR + "Projected" + File.separator;
		if (File.isDirectory(OUTPUT_DIR) == false) {
			File.makeDirectory(OUTPUT_DIR);
		}
	}

	if (SAVE_TYPE == "In a folder next to the source folder") {
		OUTPUT_DIR = File.getParent(INPUT_DIR);
		OUTPUT_NAME = File.getName(INPUT_DIR);
		OUTPUT_SHORTA = split(OUTPUT_NAME, " ");
		OUTPUT_SHORT = OUTPUT_SHORTA[0];
		OUTPUT_DIR = OUTPUT_DIR + File.separator + OUTPUT_SHORT + " flat" + File.separator;
		if (File.isDirectory(OUTPUT_DIR) == false) {
			File.makeDirectory(OUTPUT_DIR);
		}
	}

	if (SAVE_TYPE == "In a folder with custom location") {
		OUTPUT_DIR = getDirectory("Choose the save folder");
		INPUT_NAME = File.getName(INPUT_DIR);
		if (indexOf(INPUT_NAME, "Extracted") > 0) {
			ROOT_NAME = substring(INPUT_NAME, 0, lengthOf(INPUT_NAME)-10);
		}
		else {
			ROOT_NAME = INPUT_NAME;
		}
		OUTPUT_DIR = OUTPUT_DIR + File.separator + ROOT_NAME + " Projected" + File.separator;
		if (File.isDirectory(OUTPUT_DIR) == false) {
			File.makeDirectory(OUTPUT_DIR);
		}
	}

	OUTPUT_PARENT_DIR=File.getParent(OUTPUT_DIR);

	print("OUTPUT_DIR: "+OUTPUT_DIR);
	print("OUTPUT_PARENT_DIR: "+OUTPUT_PARENT_DIR);


//*************** Processing  ***************

	// Loop on all .tif extensions
	for (n=0; n<ALL_EXT.length; n++) {
		if (ALL_EXT[n]==".tif") {

			// Get the file path
			FILE_PATH=INPUT_DIR+ALL_NAMES[n];

			// Store components of the file name
			FILE_NAME=File.getName(FILE_PATH);
			FILE_DIR = File.getParent(FILE_PATH);
			FILE_SEP = getFileExtension(FILE_NAME);
			FILE_SHORTNAME = FILE_SEP[0];
			FILE_EXT = FILE_SEP[1];

			print("");
			print("INPUT_PATH:", FILE_PATH);
	//		print("FILE_NAME:", FILE_NAME);
	//		print("FILE_DIR:", FILE_DIR);
	//		print("FILE_EXT:", FILE_EXT);
	//		print("FILE_SHORTNAME:", FILE_SHORTNAME);

			open(FILE_PATH);
			STACK_ID = getImageID();

			// Remove lower slices (below the slice that has the maximum mean intensity)
			if (REM_SL == true) {
				run("Select All");
				setSlice(1);
				getStatistics(RoiA, MaxM);
				MaxI = 1;
				for (i = 2; i < nSlices + 1; i++) {
					setSlice(i);
					getStatistics(RoiA, RoiM);
					if (RoiM > MaxM) {
						MaxI = i;
						MaxM = RoiM;
					}
				}
				setSlice(1);
				for (i = 1; i < MaxI; i++) run("Delete Slice");
			}

			// Optional outlier pixels filtering before projection
			if (SIGMA == true) {
				run("Remove Outliers", "block_radius_x=3 block_radius_y=3 standard_deviations=3 stack");
			}

			// Optional background subtraction before projection
			if (BG == true) {
				run("Subtract Background...", "rolling=" + ROLLING_DIAM + " sliding stack");
			}

			if (UNSHARP == true) {
				run("Unsharp Mask...", "radius=" + UNSHARP_RADIUS + " mask=" + UNSHARP_MASK + " stack");
			}

			// Perform the projection
			if (nSlices > 1 && PROJ_METHOD != "None") run("Z Project...", " projection=[" + PROJ_METHOD + "]");
			else run("Duplicate...", "title=dummy duplicate");
			PROJ_ID = getImageID();


			// Create output file path and save the output image
			OUTPUT_PATH = OUTPUT_DIR + substring(FILE_NAME, 0, lengthOf(FILE_NAME) - 8) + substring(FILE_NAME, lengthOf(FILE_NAME) - 8, lengthOf(FILE_NAME));
			save(OUTPUT_PATH);
			print("OUTPUT_PATH: "+OUTPUT_PATH);

			// Close output image if checked
			close();

			// Close input stack
			selectImage(STACK_ID);
			close();

		}// end of IF loop on tif extensions
	}// end of FOR loop on all files



	setBatchMode("exit and display");
	print("");
	print("*** Make_Projections end ***");
	showStatus("Make Projections finished");
}


//*************** Functions ***************

function getFileExtension(Name) {
	nameparts = split(Name, ".");
	shortname = nameparts[0];
	if (nameparts.length > 2) {
		for (k = 1; k < nameparts.length - 1; k++) {
			shortname += "." + nameparts[k];
		}
	}
	extname = "." + nameparts[nameparts.length - 1];
	namearray = newArray(shortname, extname);
	return namearray;
}
