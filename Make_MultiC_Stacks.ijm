// Macro Make_MultiC_Stacks by Christophe Leterrier
// v1.0
// Takes an input folder containing single channel images
// Outputs a folder containing multi-channel tifs
// You must give an identifying string for each channel, and grouping will be done using what precedes this string in images names

macro "Make_MultiC_Stacks" {


	// Get the folder name
	inDir = getDirectory("Select a directory of single channel images");
	print("\n\n\n*** Make MultiC Stacks Log ***");
	print("input folder:" + inDir);

	// Get name of input folder, parent folder, short name of input folder (before first space in name)
	parDir = File.getParent(inDir);
	inName = File.getName(inDir);
	inShortA = split(inName, " ");
	inShort = inShortA[0];

	Id1_DEF = "561";


	// Creation of the dialog box
	Dialog.create("Make MultiC Stacks Options");
	Dialog.addString("Id string for Channel #1", Id1_DEF);

	Dialog.show();

	// Feeding variables from dialog choices
	Id1 = Dialog.getString();

	// Create output folder
	outDir = parDir + File.separator + inShort + " channels" + File.separator;
	print("Output folder: " + outDir);
	if (File.isDirectory(outDir) == false) {
		File.makeDirectory(outDir);
	}

	setBatchMode(true);

	// Count the number of files ending with ".tif" as the number of images
	allNames = getFileList(inDir);
	Array.sort(allNames);
	imN = 0;
	for (i = 0; i < allNames.length; i++) {
		nLength = lengthOf(allNames[i]);
		if (substring(allNames[i], nLength-4, nLength) == ".tif") {
			imN ++;
		}
	}
	print("Number of .tif images in input folder:" + imN);

	// Store the images names in an array
	imNames = newArray(imN);
	for (i = 0; i < allNames.length; i++) {
		nLength = lengthOf(allNames[i]);
		if (substring(allNames[i], nLength-4, nLength) == ".tif") {
			imNames[i] = allNames[i];
		}
	}

	// Loop on images names
	for (i = 0; i < imN; i++) {

		// If image is first channel
		C1 = lastIndexOf(imNames[i], Id1);

		if (C1 > -1) {

			fName = substring(imNames[i], 0, C1);

			// Loop on all images in input folder to find all channels that share the same string BEFORE the channel ID string
			for (j = 0; j < imN; j++) {
				if (indexOf(imNames[j], fName) > -1) {
					open(inDir + imNames[j]);
				}
			}
			// at that point all channels should be open

			run("Images to Stack", "name=Stack title=[] use");
			run("Make Composite", "display=Composite");
			save(outDir + fName + ".tif");
			close();

		} // end of if C1

	} // end of loop in image names

	setBatchMode("exit and display");
	print("\n\n\n*** Make MultiC Stacks finished ***");
		showStatus("Make MultiC Stacks finished");
}
