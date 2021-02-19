// Christophe Leterrier 18-04-2018
macro HyperStack_to_Montage {

//	setBatchMode(true);
	margin = 5;


	Stack.setDisplayMode("composite");
	inID = getImageID();
	inTitle = getTitle();
	getDimensions(inWidth, inHeight, inChannels, inSlices, inFrames);



	outLabels = getLabels(inID);



	selectImage(inID);
	run("Stack to RGB", "slices keep");
	rename("RGB");
	rgbID = getImageID();

	selectImage(inID);
	splitIDs = newArray(inChannels);
	splitTitles = newArray(inChannels);

	for (i = 0; i < inChannels; i++) {
		selectImage(inID);
		currC = i + 1;
		run("Duplicate...", "duplicate channels=" + currC);
		splitIDs[i] = getImageID();
		splitTitles[i] = getTitle();

		run("Grays");
		run("RGB Color");
		run("Canvas Size...", "width=" + (inWidth + margin)+ " height=" + inHeight + " position=Center-Left");
		makeRectangle(inWidth, 0, margin, inHeight);
		setForegroundColor(255, 255, 255);
		run("Fill", "stack");

		if (i > 0) {
			run("Combine...", "stack1=[" + splitTitles[i-1] + "] stack2=[" + splitTitles[i] + "]");
			rename(splitTitles[i]);
			combineID = getImageID();
		}
	}

	run("Combine...", "stack1=[" + splitTitles[inChannels - 1] + "] stack2=[RGB]");
	finalID = getImageID();
	rename(stripExt(inTitle) + "_Montage.tif");

	for (j = 0; j < inSlices; j++) {
		Stack.setPosition(1, j + 1, 1);
		setMetadata("Label", outLabels[j]);
	}
	Stack.setPosition(1, 1, 1);

//	setBatchMode("exit and display");

}

function getLabels(stackID) {
	selectImage(stackID);
	getDimensions(stackWidth, stackHeight, stackChannels, stackSlices, stackFrames);
	stackLabels = newArray(stackSlices);
	for (s = 0; s < stackSlices; s++) {
		c = 0;
		Stack.setPosition(c + 1, s + 1, 1);
		currentLabel = getMetadata("Label");
		while (currentLabel == "") {
			currentLabel = getMetadata("Label");
			c += 1;
			Stack.setPosition(c + 1, s + 1, 1);
		}
		stackLabels[s] = currentLabel;
	}
	return stackLabels;
}

function stripExt(string) {
	stringSplit = split(string, ".");
	shortName = stringSplit[0];
	for (i = 1; i < stringSplit.length-1; i++) {
		shortName += "." + stringSplit[i];
	}
	return shortName;
}
