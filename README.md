# Process Images

##What is it?

This is a macro set that we use to batch process images from various microscopes, usually multi-channels single-plane images or multi-channels z-stacks. It uses Bio-Formats for importing proprietary formats, and performs successive processing steps (projections, background subtraction, unsharp masking...). It is designed to be used on all images from an experiment, grouped in a single input folder. It ultimately provides unprocessed single-channel stacks for quantification, and a processed overlay hyperstack for exploring and visualizing the images.

##Install

Download the three macros:
- Extract_Images.ijm
- Make_Projections.ijm
- Generate_Stacks_Folder.ijm

Place them in your plugins folder, I suggest to group them in plugins/Process Images/ or plugins/added macros/Process Images/ (Fiji allows more than one level of subfolders in the plugins folder).

Download the toolset:
- Process Images.ijm

Place it in the macros/toolsets/ folder.

##Start using the macros

Start from a folder containing acquired images from a whole experiment with its different conditions (from acquisition software): "XX acquired" folder. It is advised to use a two-word name (i.e. using spaces) as the last word will be stripped and replaced by subsequent processing steps.

![M01.jpg](http://www.cleterrier.net/IJ/ProcessImage/M01.jpg)

Attention: all images processed from the initial folder must have been acquired with the same magnification, be the same type (z-stack, single plane...) and have the same number of channels.
You should be able to use any single-file format recognized by Bio-Formats as input: Zeiss zvi, czi (like in this tutorial), Nikon nd2, tif... but not multi-file formats such as Leica lif.

To launch the macros you can either:
- Select them via the Plugins>added macros>Process Images> macro folder

![M02.jpg](http://www.cleterrier.net/IJ/ProcessImage/M02.jpg)

- Alternatively, click on the rightmost button in the ImageJ toolbar (double arrow) to select the 'Process Images' custom toolset. Macros will be available via buttons on the left of the toolbar.

![M03.jpg](http://www.cleterrier.net/IJ/ProcessImage/M03.jpg)

##'Extract Images' macro

This macro will extract images from the acquisition software (as long as its format is recognized by Bio-Formats) and transform them into .tif stacks in a new folder (removing the last word of its name, and adding "ext" or "ext split" at the end depending on the selected options).

Launch by selecting Plugins>added macros>Process Images>Extract Images macro, or clicking on the first tool of the 'Process Images' toolbar (icon: image with an outward arrow pointing to the right).

Select the source folder for extraction, usually acquired images "XX acquired", click "Open" to proceed.

![M04.jpg](http://www.cleterrier.net/IJ/ProcessImage/M04.jpg)

The Options panel is displayed

![M05.jpg](http://www.cleterrier.net/IJ/ProcessImage/M05.jpg)

- Reset Spatial Scale: allows to remove spatial scale information from the extracted tifs. For standard processing, use the default unchecked box.
- Catch ROIs: will try to recover ROIs drawn on the acquisition software (can slow down considerably the process).
- Split Channels: split input stacks into single channels stacks.  For standard processing, use the default checked box.
- Save Images: Has several options for the location of the output folder. For standard processing, use the default "In a folder next of the source folder" option.
- Save position in name: retrieves the stage coordinates of the image and add them to the output name. Useful when using mosaics in certain cases.  For standard processing, use the default unchecked box.
- Press "OK" to proceed.

The macro will extract the images into a "XX ext" folder (if no split channels) or a "XX ext split" folder (if split channels). The log will recapitulate the input and output files. Some red warnings from the Bio-Format plugin will be displayed in the "Console" window, this is normal.

![M06.jpg](http://www.cleterrier.net/IJ/ProcessImage/M06.jpg)

![M07.jpg](http://www.cleterrier.net/IJ/ProcessImage/M07.jpg)

##'Make Projections' macro

If Z stacks were acquired, the next step is to project the stacks to obtain single plane projections. This is done with the "Make Projections Tool" macro. At this point it can be useful to add some enhancement steps before the projection (such as background subtraction or unsharp masking), as it will be more efficient than processing the projected image .

Launch by selecting Plugins>added macros>Process Images>Make Projections macro, or clicking on the second tool of the 'Process Images' toolbar (icon: image with an inward arrow pointing from the left).

Select the source folder for extraction, usually the extracted tifs folder "XX ext split", then click "Open" to proceed.

![M08.jpg](http://www.cleterrier.net/IJ/ProcessImage/M08.jpg)

• The Options panel is displayed

![M09.jpg](http://www.cleterrier.net/IJ/ProcessImage/M09.jpg)

- Outlier filtering before projection: rejects spurious intensity pixels and replaces them by an average of the neighboring pixels on each slice. Useful for noisy confocal images. This is done using the "Remove Outliers" command using a block radius of 3 and a standard deviation of 3. For standard processing, use the default unchecked box.
- Background subtraction before projection: performs a rolling-ball background subtraction on each slice before projection (parameters are ball radius=105 pixels, sliding paraboloid).
- Unsharp Mask before projection: applies an unsharp mask on each slice before projection (parameters are radius=2 pixels, mask weight=0.3).
- Projection Type: allows choosing the projection type. For standard processing, use the default "Max Intensity" option.
- Save Images: Has several options for the location of the output folder. For standard processing, use the default "In a folder next ot the source folder" option.
- Press "OK" to proceed.

The macro will read, project and save all images. In the end, the output "XX flat" folder will contain single-plane projections for each image (and each channel if channels were split).

![M10.jpg](http://www.cleterrier.net/IJ/ProcessImage/M10.jpg)

##'Generate Stacks Folder' macro

This macro will use single-plane, single-channel images and generate two types of output:
- A single stack grouping all images for each channel. No image enhancement will be performed on these images, are they are often the source for the quantification procedures. Attention: If using z-stacks, don't enhance at the projection step above if you want to keep "raw" images.
- Generate an overlay hyperstack with all channels that can be enhanced for visualization.

If z-stacks are processed, the source is the "XX flat" folder. If single plane images are processed, the projection step is omitted and the source is the "XX ext split" folder. Attention: split channels are necessary for this macro to work properly. Launch by selecting Plugins>added macros>Process Images>Generate Stacks Folder macro, or clicking on the third tool of the 'Process Images' toolbar (icon: pile of images). Select the source folder for extraction (see above), click "Open" to proceed.

![M11.jpg](http://www.cleterrier.net/IJ/ProcessImage/M11.jpg)

The Options panel is displayed

![M12.jpg](http://www.cleterrier.net/IJ/ProcessImage/M12.jpg)

The macro automatically detects the number of images and the number of channels (based on the end of the name "C=XX" added by the Bio-Formats importer). Attention: all images processed from the initial folder must have the same number of channels.

Options for the overlay processing (non-overlay output stacks are unprocessed):
- Background Subtraction: performs a rolling-ball background subtraction, with sliding paraboloid option (checked by default), and an adjustable radius. Use "-1" as the rolling ball radius for using an automatic radius based on the image size (r=(width/20)+5). If background subtraction has been performed before projection on z-stacks, avoid unnecessary subtraction at this stage.
- Unsharp mask: applies an usharp mask, you can specify the radius (default 1 pixel) and the mask weight (default 0.3). If unsharp mask has been performed before projection on z-stacks, avoid unnecessary sharpening at this stage.

- Contrast Enhancement: will adjust the contrast for each image, with the specified proportion of saturated pixels. Attention: by default, this adjustment is independent for each image, so the relative intensity between images / condition will not be kept (but see further options to keep relative intensity on a per-channel basis below).
- Flatten to RGB (default unchecked): will flatten the overlay hyperstack in an RGB stack (you will lose information due to merging of different colors into RGB and conversion of each component to 8-bit).

The following options that can be applied on a per-channel basis: 
- Color: allows to choose the color on the overlay.
- Keep relative intensities: box (default unchecked) will adjust the contrast for the whole channel, keeping relative intensities between each image (instead of adjusting single images independently). This is useful when batch processing all images from an experiment, and looking at effects of a condition on the labeling intensity.
- Gamma: apply a gamma correction on a per-channel basis. 1 (default) corresponds to no gamma correction.

The macro will generate an output "XX stacks folder" that contains the "C=XX.tif" unprocessed stacks for each channel, and the C=Over(XXXX).tif overlay hyperstack. "XXXX" is a code for the color of each channel (B=blue, R=Red, G=Green, W=White/Gray, etc.), with a final "c" added if any enhancement has been performed at this stage. Use Image>Colors>Channels Tool... (or ctrl+shift+Z) to display the channel tool, where you can display or hide each channel on the hyperstack.

![M13.jpg](http://www.cleterrier.net/IJ/ProcessImage/M13.jpg)

At the end of the whole procedure, you should get different subfolders that are ordered by the successive processing steps:
- "XX acquired" contains images from the acquisition software
- "XX ext" (or XX ext split) contains extracted (and channel-split) tif stacks/images 
- "XX flat" contains projected (and channel-split) images (will not be present when processing single-plane images)
- "XX stacks" are stacks by channels and an overlay hyperstack for visualization purposes.

![M14.jpg](http://www.cleterrier.net/IJ/ProcessImage/M14.jpg)
