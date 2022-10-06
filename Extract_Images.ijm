// Extract_Images macro by Christophe Leterrier
// v3.4 04-05-2016
//
// Takes a folder of proprietary images formats (Zeiss zvi, lsm, czi or Nikon nd2) and extracts them to .tif images
// The extracted images are located in a folder defined in the menu.
// Other options : reset spatial scales, reads ROIs, split channels, add stage position in name.
// 3.2 14-04-2014 added czi format
// 3.3 20-01-2016 tweaked the save otions to be more versatile
// 3.4 04-05-2016 added position in name option
// 3.5 19-11-2016 test type using BioFormat


macro "Extract_Images" {

//*************** Initialization ***************

//	Save Settings
	saveSettings();

//	Default values for the Options Panel
	RESET_SCALE_DEF = false;
	CATCH_ROIS_DEF = false;
	SPLIT_DEF = true;
	CONVERT_DEF = true;
	SAVE_DEF = "In a folder next to the source folder";
	POS_DEF = false;

//	Initialize choices variables
//	Old options: "'Extracted' in the 'Data Edit' folder (relative)", "'Extracted' in the 'Data Edit' folder (absolute)", "Same folder in the 'Data Edit' folder"
	SAVE_ARRAY = newArray("In the source folder", "In a subfolder of the source folder", "In a folder next to the source folder", "In a folder with custom location");

//*************** Dialog 1 : get the input images folder path ***************

	INPUT_DIR = getDirectory("Select a source folder with raw images");

	print("\n\n\n*** Extract_Images Log ***");
	print("");
	print("INPUT_DIR: " + INPUT_DIR);


//*************** Dialog 2 : options ***************

//	Creation of the dialog box
	Dialog.create("Extract_Images Options");
	Dialog.addCheckbox("Reset Spatial Scale", RESET_SCALE_DEF);
	Dialog.addCheckbox("Catch ROIs", CATCH_ROIS_DEF);
	Dialog.addCheckbox("Split Channels", SPLIT_DEF);
	Dialog.addCheckbox("Convert 32-bit to 16-bit", CONVERT_DEF);
	Dialog.addChoice("Save Images", SAVE_ARRAY, SAVE_DEF);
	Dialog.addCheckbox("Save position in name", POS_DEF);
	Dialog.show();

//	Feeding variables from dialog choices
	RESET_SCALE = Dialog.getCheckbox();
	CATCH_ROIS = Dialog.getCheckbox();
	SPLIT_CH = Dialog.getCheckbox();
	CONVERT = Dialog.getCheckbox();
	SAVE_TYPE = Dialog.getChoice();
	POS = Dialog.getCheckbox();

	setBatchMode(true);


//*************** Prepare Processing (get names, open images, make output folder) ***************

//	Get all file names
	ALL_NAMES = getFileList(INPUT_DIR);
	Array.sort(ALL_NAMES);
	N_LENGTH = ALL_NAMES.length;
	ALL_EXT = newArray(N_LENGTH);
//	Create extensions array
	for (i = 0; i < N_LENGTH; i++) {
//		print(ALL_NAMES[i]);
		ALL_NAMES_PARTS = getFileExtension(ALL_NAMES[i]);
		ALL_EXT[i] = ALL_NAMES_PARTS[1];
	}

//	Create the output folder
	OUTPUT_DIR = INPUT_DIR;
	FOLDER_NAME = "ext";

	if (SPLIT_CH == true) {
		FOLDER_NAME += " split";
	}

	if (SAVE_TYPE == "In the source folder") {
		OUTPUT_DIR = INPUT_DIR;
	}

	if (SAVE_TYPE == "In a subfolder of the source folder") {
		OUTPUT_DIR = INPUT_DIR + FOLDER_NAME + File.separator;
		if (File.isDirectory(OUTPUT_DIR) == false) {
			File.makeDirectory(OUTPUT_DIR);
		}
	}

	if (SAVE_TYPE == "In a folder next to the source folder") {
		OUTPUT_DIR = File.getParent(INPUT_DIR);
		OUTPUT_NAME = File.getName(INPUT_DIR);
		OUTPUT_SHORTA = split(OUTPUT_NAME, " ");
		OUTPUT_SHORT = OUTPUT_SHORTA[0];
		OUTPUT_DIR = OUTPUT_DIR + File.separator + OUTPUT_SHORT + " " + FOLDER_NAME + File.separator;
		if (File.isDirectory(OUTPUT_DIR) == false) {
			File.makeDirectory(OUTPUT_DIR);
		}
	}

	if (SAVE_TYPE == "In a folder with custom location") {
		OUTPUT_DIR = getDirectory("Choose the custom location for the 'Extracted' folder");
		OUTPUT_DIR = OUTPUT_DIR + File.separator + FOLDER_NAME + File.separator;
		if (File.isDirectory(OUTPUT_DIR) == false) {
			File.makeDirectory(OUTPUT_DIR);
		}
	}

	OUTPUT_PARENT_DIR = File.getParent(OUTPUT_DIR);

	print("OUTPUT_DIR: " + OUTPUT_DIR);
//	print("OUTPUT_PARENT_DIR: " + OUTPUT_PARENT_DIR);

//*************** Process Images ***************

//	Loop on all .zvi or .lsm extensions
	for (n = 0; n < N_LENGTH; n++) {

//		Test if file format recognized by BioFormats (fast)
		run("Bio-Formats Macro Extensions");
		FILE_NAME = ALL_NAMES[n];
		Ext.isThisType(INPUT_DIR + FILE_NAME, IM_TYPE);
//		print(FILE_NAME);
//		print(IM_TYPE);

		if ((IM_TYPE == "true" && ALL_EXT[n] != ".tif") || ALL_EXT[n] == ".nd2") {

//		Bio Format Importer to open the multi-channel images
//			Get the file path
			FILE_PATH = INPUT_DIR + FILE_NAME;

//			Store components of the file name
			FILE_DIR = File.getParent(FILE_PATH);
			FILE_SEP = getFileExtension(FILE_NAME);
			FILE_SHORTNAME = FILE_SEP[0];
			FILE_EXT = FILE_SEP[1];

			print("");
			print("INPUT_PATH:", FILE_PATH);
//			print("FILE_NAME:", FILE_NAME);
//			print("FILE_DIR:", FILE_DIR);
//			print("FILE_EXT:", FILE_EXT);
//			print("FILE_SHORTNAME:", FILE_SHORTNAME);

//			Start BioFormats and get series number in file.
//			print("Setting Bio-Formats Id...");
			Ext.setGroupFiles("false");
			Ext.setId(FILE_PATH);
			Ext.getEffectiveSizeC(CHANNEL_COUNT);
			print("Bio-Formats Id Set");
//			showStatus("launching Bio-Formats Importer");
//			print("Launching Bio-Formats Importer...");

//			07-09-2011 added display_rois (added to ROI Manager)
//			27-09-2011 made display_rois optionnal to speed things up
			if (CATCH_ROIS==true) {
				DISPLAY=" display_rois";
				roiManager("reset");
			}
			else {
				DISPLAY="";
			}

//			Open input image
			run("Bio-Formats Importer", "open=[" + FILE_PATH + "] " + "view=Hyperstack" + " color_mode=Grayscale stack_order=Default " + DISPLAY);
			print("Bio-Formats Importer launched");
			FILE_TITLE = getTitle();
			FILE_ID = getImageID();

//			Reset spatial scale of images if checked
			if (RESET_SCALE == true) {
				print("Scale reset");
				run("Set Scale...", "distance=0 known=1 pixel=1 unit=pixel");
			}

//			Put ROIs in overlay if there is one and the option is set
			if (CATCH_ROIS==true) {
				if (roiManager("count") > 0) {
					print("ROI catched";
					run("From ROI Manager");
				}
			}

//			Encode stage position in image name
		 	if (POS == true) {
		 		Ext.getPlanePositionX(posX, 0);
		 		Ext.getPlanePositionY(posY, 0);
		 		postring = "_(" + posX + "," + posY + ")";
		 	}
		 	else postring = "";


//			If option checked, breaks the multi-channel image appart and saves as individual tifs
			if (SPLIT_CH == true && CHANNEL_COUNT > 1) {
			
				run("Split Channels");

//				Loop on each channel (each opened window)
				for(j = 0; j < CHANNEL_COUNT; j++) {

//					Construct window name (from the names created by the "Split Channels" command)
					TEMP_CHANNEL = d2s(j+1,0);
					SOURCE_WINDOW_NAME = "C" + TEMP_CHANNEL +  "-" + FILE_NAME;

//					Select source image
					selectWindow(SOURCE_WINDOW_NAME);
					resetMinAndMax();
					
//					Convert from 32-bit to 16-bit, normalizing accross the stack to avoid any saturation
					if (bitDepth() == 32 && CONVERT == true) {
						run("Enhance Contrast...", "saturated=0 normalize process_all use");
						setMinAndMax(0, 1);
						run("16-bit");
						setMinAndMax(0, 65535);
					}

//					Create output file path and save the output image
					OUTPUT_PATH = OUTPUT_DIR + FILE_SHORTNAME + postring + "-C=" + j + ".tif";
					save(OUTPUT_PATH);
					print("OUTPUT_PATH: " + OUTPUT_PATH);
					close();			
				}	// end of for loop on channels
			}

			else {
				
//				32-bit conversion requires splitting and re-merging channels if mutli-channel
				if (bitDepth() == 32 && CONVERT == true) {
					
//					Multi-channel case
					if (CHANNEL_COUNT > 1) {
						CHAN_NAMES = newArray(CHANNEL_COUNT);
						MERGE_STRING = "";
						run("Split Channels");
	
//						Loop on stacks generated from channels					
						for(j = 0; j < CHANNEL_COUNT; j++) {
	
//							Construct window name (from the names created by the "Split Channels" command) and merge string
							TEMP_CHANNEL = d2s(j+1,0);
							CHAN_NAMES[j] = "C" + TEMP_CHANNEL +  "-" + FILE_NAME;
							MERGE_STRING = MERGE_STRING + "c" + (j+1) + "=" + CHAN_NAMES[j] + " ";
		
//							Select source image
							selectWindow(CHAN_NAMES[j]);
							resetMinAndMax();
							
//							Convert from 32-bit to 16-bit, normalizing accross the stack to avoid any saturation						
							run("Enhance Contrast...", "saturated=0 normalize process_all use");
							setMinAndMax(0, 1);
							run("16-bit");
							setMinAndMax(0, 65535);
	
						} // end of loop on channels
						
//						Re-merge all channels
						print(MERGE_STRING);					
						run("Merge Channels...", MERGE_STRING + "create");
					}
					
//					Single-channel case
					else {
//							Convert from 32-bit to 16-bit, normalizing accross the stack to avoid any saturation						
							run("Enhance Contrast...", "saturated=0 normalize process_all use");
							setMinAndMax(0, 1);
							run("16-bit");
							setMinAndMax(0, 65535);				
					}
					
				}
								
				// Create output file path and save the output image
				OUTPUT_PATH = OUTPUT_DIR + FILE_SHORTNAME + postring + ".tif";
				save(OUTPUT_PATH);
				print("OUTPUT_PATH: " + OUTPUT_PATH);
				close();
			}
		}	// end of IF loop on image extensions
	}	// end of FOR loop on n extensions

//*************** Cleanup and end ***************

	// Restore settings
	restoreSettings();
	setBatchMode("exit and display");
	print("");
	print("*** Extract_Images end ***");
	showStatus("Extract Images finished");
//	exec("open", OUTPUT_DIR);
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
