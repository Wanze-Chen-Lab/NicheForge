Dialog.create("Parameter Settings");
Dialog.addDirectory("Input Directory:", "");
Dialog.addDirectory("Output Directory:", "");
Dialog.addNumber("BF Channel (1-4):", 1);
Dialog.addNumber("EGFP Channel (1-4):", 2);
Dialog.addNumber("mCherry Channel (1-4):", 3);
Dialog.addNumber("Other Channel (1-4):", 4);
Dialog.addSlider("Bleed-through Coefficient", 0.01, 0.5, 0.15, 0.01);
Dialog.show();

// Get parameters
inputDir = Dialog.getString();
outputDir = Dialog.getString();
bfChan = round(Dialog.getNumber());
egfpChan = round(Dialog.getNumber());
mcherryChan = round(Dialog.getNumber());
otherChan = round(Dialog.getNumber());
bleedThrough = Dialog.getNumber();

// Main processing function
function processFile(path) {
   
        // Open image
        run("Bio-Formats Importer", "open=[" + path + "] autoscale");
        title = getTitle();
        
        // Split channels
        run("Split Channels");
        channels = newArray("C1-" + title, "C2-" + title, "C3-" + title, "C4-" + title);
        
        // Bleed-through correction
        selectWindow(channels[egfpChan-1]);
        run("Duplicate...", "title=EGFP_scaled");
        run("Multiply...", "value=" + bleedThrough);
        
        selectWindow(channels[mcherryChan-1]);
        run("Duplicate...", "title=mCherry_raw");
        imageCalculator("Subtract create", "mCherry_raw", "EGFP_scaled");
        
        // Reconstruct image (corrected key part)
        run("Merge Channels...", "c1=[" + channels[bfChan-1] + "]c2=[" + channels[egfpChan-1]+ "]c3=[Result of mCherry_raw] + create");
        
    
        // Set channel colors
     Stack.setDisplayMode("color");
		
		Stack.setChannel(bfChan);
        run("Grays");
        Stack.setChannel(egfpChan);
        run("Green");
        Stack.setChannel(mcherryChan);
        run("Red");   
        
  
        // Save result
        saveAs("Tiff", outputDir + File.separator + "corrected_" + File.getName(path));
        
        // Close windows
        while (nImages() > 0) {
            close();
        }
   
 
}

// Batch processing
list = getFileList(inputDir);
//setBatchMode(true);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i].toLowerCase(), ".tif")) {
        processFile(inputDir + File.separator + list[i]);
    }
}

print("Processing completed! Total processed: " + list.length + " files");
