// Macro Stitch_Mosaic by Christophe Leterrier
// v1.0 05/05/201-6
// v2.0 17/09/2020 added stage position from metadata for Nikon images
// v2.1 18/09/2020 preserves scale for mosaics
// Require S. Preibisch "Grid/Collection Stitching" plugin (included in Fiji)
// Takes an input folder containing single or multi-channel tifs that have been taken as "mosaics" by hand (following an axon for example)
// The input folder can contain several mosaics, and the elements for each must be named by adding "WFa", "WFb", "WFc" etc. to a common name
// Example: my_cool_mosaic_WFa.tif, my_cool_mosaic_WFb.tif, my_cool_mosaic_WFc.tif, my_other_mosaic_WFa.tif, my_other_mosaic_WFb.tif
// Non mosaic images can exist and be named with "WF" without a,b,c... : my_non_mosaic_image_WF.tif

macro "Stitch_Mosaic" {

	setOption("ExpandableArrays", true);
	Enhance = false; // Enhance images in addition to fusing them (background subtraction, unsharp mask, contrast enhancement)
	rb_diam = 50; // diameter of the rolling ball for background substraction (50 for a 512x512 image is OK)
	um_mask = 0.3; // weight of the mask for unsharp mark (closer to 1 = sharper)
	cSat = 0.01; // % saturation for contrast enhancement
	posdata = false; // use stage position in image metadata (Nikon version)

	// Get the folder name
	inDir = getDirectory("Select a directory full of tif images");
	print("\n\n\n*** Stitch Mosaic Log ***");
	print("input folder:" + inDir);

	// Get name of input folder, parent folder, short name of input folder (before first space in name)
	parDir = File.getParent(inDir);
	inName = File.getName(inDir);
	inShortA = split(inName, " ");
	inShort = inShortA[0];

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

// Create a new folder that will have each mosaic element (individual multi-channel stacks) inside its own subfolder (necessary for the fusion plugin)
// Mosaic elements name must contain WFa, WFb, WFc etc. preceded by the SAME string.
// If some images are single (not part of a mosaic) they must contain "WF_" or "WF." in their name.

	// Make temp folder where individual folders will contain mosaic elements (single multi-channel stacks)
	tempDir = parDir + File.separator + inShort + " folders" + File.separator;
	print("Sorted folder: " + tempDir);
	if (File.isDirectory(tempDir) == false) {
		File.makeDirectory(tempDir);
	}

	mosCount = 0; // counter of mosaic number

	// scale for each mosaic
	mosPixelUnit = newArray(0);
	mosPixelWidth = newArray(0);
	mosPixelHeight = newArray(0);

	// Loop on images names
	for (i = 0; i < imN; i++) {
		// If image is first in a mosaic series (name has WFa, followers have WFb, WFc etc...)
		WFi = indexOf(imNames[i], "WFa");
		WFi2 = indexOf(imNames[i], "WFA");
		// If image is isolated (not part of mosaic) it has "WF_" or "WF." in its name
		WFn = indexOf(imNames[i], "WF.");
		WFc = indexOf(imNames[i], "WF_");
		// Store mosaic elements / individual images in separated folders
		if (WFi > -1 || WFi2 > -1 || WFn > -1 || WFc > -1) {
		// Create a subfolder of temp folder
			fName = substring(imNames[i], 0, WFi + WFi2 + WFn + WFc + 5);
			// case of a mosaic: the folder name will end with "WFm"
			if (WFi > -1 || WFi2 > -1) subName = fName + "m";
			// case of single image: the folder name will end with "WF"
			else subName = fName;
			// make the subfolder
			fDir = tempDir + subName + File.separator;
			if (File.isDirectory(fDir) == false) {
				File.makeDirectory(fDir);
			}
		// Loop on all images in input folder to find all parts of the mosaic (including the "WFa" or "WF_" / "WF." one)
			
			// get the scale for each mosaic in an array
			flag2 = 0; // flag to get scale
			
			for (j = 0; j < imN; j++) {
				if (indexOf(imNames[j], fName) > -1) { // only for images of this mosaic
								
					// open image
					open(inDir + imNames[j]);
					
					// if first image from mosaic, get scale and store in array
					flag2++; // flag to get scale at first image of the mosaic
					if (flag2 == 1) {
						getPixelSize(scaleUnit, pixelWidth, pixelHeight);
						mosPixelUnit = Array.concat(mosPixelUnit, scaleUnit);
						mosPixelWidth = Array.concat(mosPixelWidth, pixelWidth);
						mosPixelHeight = Array.concat(mosPixelHeight, pixelHeight);
						mosCount++;	// mosaic counter
						// print("mosaic #" + mosCount + ", pixel width:" + mosPixelWidth[mosCount - 1]);
					}
					
					
					// If enhancement, images are opened and background subtracted + unsharp masked then saved in subfolder
					if (Enhance == true) {	
						run("Subtract Background...", "rolling=" + rb_diam + " sliding stack");
						run("Unsharp Mask...", "radius=1 mask=" + um_mask + " stack");
					}
					
					save(fDir + imNames[j]);
					close();
				}
			}
		}
	}

	print("Number of mosaics detected: " + mosCount);


// Perform stiching using S. Preibisch's "Grid/Collection Stitching" plugin
// part of Fiji see http://imagej.net/Image_Stitching#Grid.2FCollection_Stitching

	// Create mosaics folder
	mosDir = parDir + File.separator + inShort + " mosaics" + File.separator;
	print("Mosaic folder: " + mosDir);
	if (File.isDirectory(mosDir) == false) {
		File.makeDirectory(mosDir);
	}

	//Loop on temp subfolders to process mosaics
	foldNames = getFileList(tempDir);
	for (i = 0; i < foldNames.length; i++) {
		// Stitch all images in subfolder
		if (indexOf(foldNames[i], "WFm") > -1) {
			// if using stage positions in images metadata 
			if (posdata == true) {
				// call the function to make the configuration file from stage position metadata in images (Nikon version)
				makeTileConfiguration(tempDir + foldNames[i]);
				run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by TileConfiguration] directory=[" + tempDir + foldNames[i] +"] layout_file=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap subpixel_accuracy computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
			}
			else {	
				run("Grid/Collection stitching", "type=[Unknown position] order=[All files in directory] directory=[" + tempDir + foldNames[i] +"] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 ignore_z_stage subpixel_accuracy computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
			}
		}
		// unless it's a single image
		else {
			insideNames = getFileList(tempDir + foldNames[i]);
			open(insideNames[0]);
			if (nSlices > 1) Stack.setDisplayMode("composite");
		}
		// Enhance fused image (contrast enhancement looping on channels)
		if (Enhance == true) {
			getDimensions(w, h, ch, sl, fr);
			for (j = 0; j < ch; j++) {
				if (nSlices > 1) Stack.setChannel(j+1);
				run("Enhance Contrast...", "saturated=" + cSat);
			}
		}

		// Apply stored scale
		run("Set Scale...", "distance=1 known=" + mosPixelWidth[i] + " pixel=1 unit=" + mosPixelUnit[i]);
		
		// Save resulting image
		fusedName = substring(foldNames[i], 0, lengthOf(foldNames[i]) - 1) + "_fused.tif";
		rename(fusedName);
		save(mosDir + fusedName);
		//close();
	}
	setBatchMode("exit and display");
}

function makeTileConfiguration(InputDir) {

	//	Get all file names
	AllNames = getFileList(InputDir);
	Array.sort(AllNames);
	nL = AllNames.length;
	AllExt = newArray(nL);
	
	//	Create extensions array and test if tif
	ntif = 0;
	for (i = 0; i < nL; i++) {
		AllNamesParts = getFileExtension(AllNames[i]);
		AllExt[i] = AllNamesParts[1];
		if (indexOf(toLowerCase(AllExt[i]), ".tif") > -1) ntif++; // condition to catch .tif, .tiff, .TIF, .TIFF...
	}

	NamesArray = newArray(ntif);
	XArray = newArray(ntif);
	YArray = newArray(ntif); 

	j = 0; // counter to fill tif array (restricted to tif files)
	for (i = 0; i <nL; i++) {
		if (indexOf(toLowerCase(AllExt[i]), ".tif") > -1) { // open only tif files
			open(InputDir + AllNames[i]);
			
			// get X and Y stage positions (Nikon metadata)
			XYCoor = getPropValues("dXpos,dYPos");

			// Assign name of the image,  and Y stage position in the tif array
			NamesArray[j] = AllNames[i];
			XArray[j] = XYCoor[0];
			YArray[j] = XYCoor[1];

			// Iterate tif counter
			j++;

			// close image
			close();
		}
	}

	// Transform the coordinates from Nikon to pixels
	XArrayT = NikonToPixCoor(XArray, "X");
	YArrayT = NikonToPixCoor(YArray, "Y");
	
	// Write TileConfiguration.txt file
	writeTileConfiguration(NamesArray, XArrayT, YArrayT, InputDir);

}

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


function getPropValues(keys) {
	// get values of image properties defined by a "keys" string with property names separated by commas
	// return an array of values correspoonding to each key

	// define delimiters between a property and its value, with a parenthesed version for the split 
	del1 = " = ";
	del2 = "; ";

	// get properties
	Info = Property.getInfo();
	// split by lines
	InfoArray = split(Info, "\n");
	pL = InfoArray.length;

	PropArray = newArray(pL); // array of property names
	ValArray = newArray(pL); // array of property values

	// fill the property names and values arrays
	for (l = 0; l < pL; l++) {
		
		// split each line according to delimiters defined above (del1, del2) or assign NaN if no delimiter detected
		if (indexOf(InfoArray[l], del1) > -1) LineSplit = split(InfoArray[l], "(" + del1 + ")"); // the split string is parenthesed to work as regular expression
			else if (indexOf(InfoArray[l], del2) > -1) LineSplit = split(InfoArray[l], "(" + del2 + ")");
			else LineSplit = newArray(NaN, NaN);
	
		PropArray[l] = LineSplit[0];
		ValArray[l] = LineSplit[1];

	}

	// split keys (asked property names)
	KeyArray = split(keys, ",");
	kL = KeyArray.length;
	KeyValArray = newArray(kL);

	// for each key of KeyArray, look in the PropArray property names array, and when name is found, assign corresponding value from ValArray to the corresponding KeyValArray slot
	for (k = 0; k < kL; k++) {
		flag = 0;
		for (l = 0; l < pL; l++) {
			if (PropArray[l] == KeyArray [k]) {
				flag = 1;
				KeyValArray[k] = ValArray[l];
			}
		}
		if (flag == 0) KeyValArray[k] = NaN; // if key not found, assign NaN for that slot
	}

	// return the key values array
	return KeyValArray;
}

function NikonToPixCoor(ca, coor) {

	// For Nikon scope, stage position is in µm, while Grid/Colection stitching is in pixels
	PixelSize = 0.16; // pixel size in µm
	
	// output array
	oa = newArray(ca.length);
	
	// factor to adapt X and Y direction
	if (coor == "X") f = 1;
		else if (coor == "Y") f = -1;
		else factor = 1;
		
	for (i = 0; i < ca.length; i++) {
		// set center of the first image to 0, then convert from µm to pixels
		NewCoor = ((parseFloat(ca[i]) - parseFloat(ca[0])) / PixelSize) * f;
		// round with 1 decimal
		oa[i] = toString(NewCoor, 1);
	}

	return oa;
}


function writeTileConfiguration(nameA, xA, yA, fp) {
	
	// beginning of the file
	FileString = "# Define the number of dimensions we are working on\ndim = 2\n\n# Define the image coordinates\n";
	
	// lines for each image and its coordinates
	for (n = 0; n < nameA.length; n++) {
		FileString += nameA[n] + "; ; (" + xA[n] + "," + yA[n] + ")\n";		
	}

	// save file
	File.saveString(FileString, fp + "TileConfiguration.txt");
	
}
