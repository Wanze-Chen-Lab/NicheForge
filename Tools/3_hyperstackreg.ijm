Dialog.create("Parameter Settings");
Dialog.addDirectory("Input Directory:", "");
Dialog.addDirectory("Output Directory:", "");
Dialog.show();

// Get parameters
inputDir = Dialog.getString();
outputDir = Dialog.getString();

// Select folder containing image files
list = getFileList(inputDir);
Array.sort(list);

// Collect all valid sample IDs (e.g. 1, 2, etc.)
samples = newArray();
for (i=0; i<list.length; i++) {
    if (endsWith(list[i], "_time0.tif")) {
        prefix = replace(list[i], "_time0.tif", "");
        // Verify that all time point files exist
        if (File.exists(inputDir + prefix + "_time1.tif") && 
            File.exists(inputDir + prefix + "_time2.tif")) {
            samples = Array.concat(samples, prefix);
        }
    }
}

// Process each sample
for (s=0; s<samples.length; s++) {
    base = samples[s];
    
    // Open files in the specified order
    open(inputDir + base + "_time0.tif");    
    open(inputDir + base + "_time1.tif");
    open(inputDir + base + "_time2.tif");
    
  ch_align = 4;

ROI_pos_index = newArray(0,1,2);
ROI_neg_index = newArray(4,5,6);

file0 = base + "_time0.tif";
file1 = base + "_time1.tif";
file2 = base + "_time2.tif";


image1 = file0;
image2 = file1; 
image3 = file2; 


run("Concatenate...", "keep open image1=file0 image2=file1 image3=file2");

if (ch_align == 1) 
	run("HyperStackReg ", "transformation=Affine channel show");   // "channel" means the first channel, "channel_0" means the second channel and "channel_1" is the third one
else if (ch_align == 2)	
	run("HyperStackReg ", "transformation=Affine channel_0 show");   // "channel" means the first channel, "channel_0" means the second channel and "channel_1" is the third one
else if (ch_align == 3)	
	run("HyperStackReg ", "transformation=Affine channel_1 show");   // "channel" means the first channel, "channel_0" means the second channel and "channel_1" is the third one
else if (ch_align == 4)	
	run("HyperStackReg ", "transformation=Affine channel_2 show");   // "channel" means the first channel, "channel_0" means the second channel and "channel_1" is the third one
else if (ch_align == 5)	
	run("HyperStackReg ", "transformation=Affine channel_3 show");   // "channel" means the first channel, "channel_0" means the second channel and "channel_1" is the third one
else
	exit("the channel for alignment shall be specified");
    
  

    // Save the result
    savePath = outputDir + base + "_registered.tif";
    saveAs("Tiff", savePath);
    print("Saved to：" + savePath);
    
    // Close processed images
    run("Close All");

}

print("All samples processed!");
