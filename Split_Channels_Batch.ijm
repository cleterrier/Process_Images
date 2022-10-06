// Split_Channels macro by Christophe Leterrier

macro "Split_Channels_Batch" {

//*************** Initialization ***************

	// Default values for the Options Panel

	ENH_DEF = false;
	ROLLING_DIAM = 50;
	UNSHARP_MASK = 0.35;
	SAT = 0.01;

	SAVE_DEF="In a folder next to the source folder";

	// Get the folder name
	INPUT_DIR=getDirectory("Select the input stacks directory");

	print("\n\n\n*** Split Channels Log ***");
	print("");
	print("INPUT_DIR :"+INPUT_DIR);

	// Initialize choices variables
	SAVE_ARRAY = newArray("In the source folder", "In a subfolder of the source folder", "In a folder next to the source folder", "In a subfolder with custom location");


//*************** Dialog ***************

	// Creation of the dialog box
	Dialog.create("Split Channels Options");
	Dialog.addCheckbox("Enhance", ENH_DEF);
	Dialog.addChoice("Save Images", SAVE_ARRAY, SAVE_DEF);
	Dialog.show();

	// Feeding variables from dialog choices
	ENH = Dialog.getCheckbox();
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
		OUTPUT_DIR = INPUT_DIR + "split" + File.separator;
		if (File.isDirectory(OUTPUT_DIR) == false) {
			File.makeDirectory(OUTPUT_DIR);
		}
	}

	if (SAVE_TYPE == "In a folder next to the source folder") {
		OUTPUT_DIR = File.getParent(INPUT_DIR);
		OUTPUT_NAME = File.getName(INPUT_DIR);
		OUTPUT_SHORTA = split(OUTPUT_NAME, " ");
		OUTPUT_SHORT = OUTPUT_SHORTA[0];
		OUTPUT_DIR = OUTPUT_DIR + File.separator + OUTPUT_SHORT + " split" + File.separator;
		if (File.isDirectory(OUTPUT_DIR) == false) {
			File.makeDirectory(OUTPUT_DIR);
		}
	}

	if (SAVE_TYPE == "In a folder with custom location") {
		OUTPUT_DIR = getDirectory("Choose the save folder");
		INPUT_NAME = File.getName(INPUT_DIR);
		OUTPUT_DIR = OUTPUT_DIR + File.separator + INPUT_NAME + " split" + File.separator;
		if (File.isDirectory(OUTPUT_DIR) == false) {
			File.makeDirectory(OUTPUT_DIR);
		}
	}

	OUTPUT_PARENT_DIR=File.getParent(OUTPUT_DIR);

	print("OUTPUT_DIR: " + OUTPUT_DIR);
	print("OUTPUT_PARENT_DIR: " + OUTPUT_PARENT_DIR);


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
			getDimensions(w, h, ch, sl, fr);

			run("Split Channels");
			for(j = 0; j < ch; j++) {
				// Construct window name (from the names created by the "Split Channels" command)
				TEMP_CHANNEL = d2s(j+1,0);
				SOURCE_WINDOW_NAME = "C" + TEMP_CHANNEL +  "-" + FILE_NAME;

				//Select source image
				selectWindow(SOURCE_WINDOW_NAME);

				// Optional enhancement
				if (ENH == true) {
					run("Subtract Background...", "rolling=" + ROLLING_DIAM + " stack");
					run("Unsharp Mask...", "radius=1 mask=" + UNSHARP_MASK + " stack");
					run("Enhance Contrast...", "saturated=" + SAT);
				}
				else {
					resetMinAndMax;
				}

				// Create output file path and save the output image
				OUTPUT_PATH = OUTPUT_DIR + FILE_SHORTNAME + "-C=" + j + ".tif";
				save(OUTPUT_PATH);
				print("OUTPUT_PATH: " + OUTPUT_PATH);
				close();
			}

		}// end of IF loop on tif extensions
	}// end of FOR loop on all files

	setBatchMode("exit and display");
	print("");
	print("*** Split Channels end ***");
	showStatus("Split Channels finished");
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
