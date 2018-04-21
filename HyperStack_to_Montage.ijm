macro HyperStack_to_Montage {

//	setBatchMode("true");
	margin = 5;
	
	inID = getImageID();
	inTitle = getTitle();
	getDimensions(inWidth, inHeight, inChannels, inSlices, inFrames);

	outLabels = getLabels(inID);


	run("Stack to RGB", "slices keep");
	rename("RGB");
	rgbID = getImageID();

	selectImage(inID);
	run("Split Channels");

	for (c = 0; c < inChannels; c++) {
		imageName = "C" + (c+1) + "-" + inTitle;
		selectWindow(imageName);
		run("Grays");
		run("RGB Color");
		run("Canvas Size...", "width=" + (inWidth + margin)+ " height=" + inHeight + " position=Center-Left");
		makeRectangle(inWidth, 0, margin, inHeight);
		setForegroundColor(255, 255, 255);
		run("Fill", "stack");
		//waitForUser("check");
		if (c > 0) {
			previousName = "C" + c + "-" + inTitle;
			run("Combine...", "stack1=[" + previousName + "] stack2=[" + imageName + "]");
			rename(imageName);
			combineID = getImageID();
		}
	}
	
	run("Combine...", "stack1=[" + imageName + "] stack2=[RGB]");
	finalID = getImageID();
	rename(stripExt(inTitle) + "_Montage.tif");

	for (s = 0; s < inSlices; s++) {
		Stack.setPosition(1, s + 1, 1);
		setMetadata("Label", outLabels[s]);
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
