// macro for microwell quantification

//require:
// update the BIG-EPFL, PTBIOP, UCB Vision site and ImageScience 

// >>>>>>>>> Important Note <<<<<<<<<<<<< //
//if computer resource is sufficient, two FIJI/ImageJ can be run in parallel.
//DO NOT choice any image window when the script is running. 


//Parameters that matters: 
//#@ Integer (label="Number of Channels", style="slider", min=1, max=5, stepSize=1) n_channel	// Number of channels
#@ String (choices={"1", "2", "3", "4", "5"}, style="radioButtonHorizontal") BF_channel 	//set the brite field channel, for microwell detection
#@ String (choices={"Yes", "No"}, style="radioButtonHorizontal") RemoveBackground_Ch1  //set whether remove the background of this channel
#@ String (choices={"Yes", "No"}, style="radioButtonHorizontal") RemoveBackground_Ch2  //set whether remove the background of this channel
#@ String (choices={"Yes", "No"}, style="radioButtonHorizontal") RemoveBackground_Ch3  //set whether remove the background of this channel
#@ String (choices={"Yes", "No"}, style="radioButtonHorizontal") RemoveBackground_Ch4  //set whether remove the background of this channel
#@ String (choices={"Yes", "No"}, style="radioButtonHorizontal") RemoveBackground_Ch5  //set whether remove the background of this channel
#@ String (choices={"Blue", "Green", "Yellow", "Red", "Magenta", "Grays"}, style="radioButtonHorizontal") LUT_Ch1 	//set LUT of Ch1
#@ String (choices={"Blue", "Green", "Yellow", "Red", "Magenta", "Grays"}, style="radioButtonHorizontal") LUT_Ch2	//set LUT of Ch2
#@ String (choices={"Blue", "Green", "Yellow", "Red", "Magenta", "Grays"}, style="radioButtonHorizontal") LUT_Ch3	//set LUT of Ch3
#@ String (choices={"Blue", "Green", "Yellow", "Red", "Magenta", "Grays"}, style="radioButtonHorizontal") LUT_Ch4	//set LUT of Ch4
#@ String (choices={"Blue", "Green", "Yellow", "Red", "Magenta", "Grays"}, style="radioButtonHorizontal") LUT_Ch5	//set LUT of Ch5
#@ Double hough_threshold (value=0.85) 		//if overestablished, increase the number, maximal 1
#@ Integer rolling_size (value=20) 			//set the size for backgroud substration using rolling ball model
#@ Integer Threshold_background (value=78) 	//set the threshold to remove the background
#@ String (choices={"No", "Vertically", "Horizontally"}, style="radioButtonHorizontal") image_adjust	//Adjust the image

// Prompt the user for the input and output directory
inputDir = getDirectory("Choose an input Directory");
outputDir = getDirectory("Choose an Output Directory");

// Ensure both folders are selected
if (inputDir == "" || outputDir == "") {
    exit("Both input and output folders must be selected.");
}


// print all the user defined parameters
print(">>>>>>>>>>>>>>>>>       parameters       <<<<<<<<<<<<<<<<<    ");
print("inputDir: " + inputDir);
print("outputDir: " + outputDir);
//print("Number of Channels: " + n_channel);
print("BF_channel: " + BF_channel);
print("RemoveBackground_Ch1: " + RemoveBackground_Ch1);
print("RemoveBackground_Ch2: " + RemoveBackground_Ch2);
print("RemoveBackground_Ch3: " + RemoveBackground_Ch3);
print("RemoveBackground_Ch4: " + RemoveBackground_Ch4);
print("RemoveBackground_Ch5: " + RemoveBackground_Ch5);
print("LUT_Ch1: " + LUT_Ch1);
print("LUT_Ch2: " + LUT_Ch2);
print("LUT_Ch3: " + LUT_Ch3);
print("LUT_Ch4: " + LUT_Ch4);
print("LUT_Ch5: " + LUT_Ch5);
print("hough_threshold: " + hough_threshold);
print("rolling_size: " + rolling_size);
print("Threshold_background: " + Threshold_background);
print("image_adjust: " + image_adjust);
print("--------------------------------------------------------------");

// get and print the start time
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print("Image analysis started at " + "Date: "+dayOfMonth+"/"+ (month+1)+"/"+year+"  Time: " +hour+":"+minute+":"+second);


// Get a list of all image files in the input folder
list = getFileList(inputDir);

// Process each image in the input folder
for (i = 0; i < list.length; i++) {
	print("--------------------------------------------------------------");
	print("Processing: " + list[i]);
    // Skip non-tif files
    if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff")) {
        
        // Open the current image
        open(inputDir + list[i]);
        
        // Get the image title (filename without extension)
        imageName = getTitle();
        
        // Process the image (you can customize this part)
		Process_each_image(imageName);
        
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		print( "    " + imageName + " is completed at: ");
		print( "    " + "Date: "+dayOfMonth+"/"+ (month+1)+"/"+year+"  Time: " +hour+":"+minute+":"+second);
    	
    	//save the Log file
    	selectWindow("Log");
		saveAs("Text", outputDir + "Log.txt");
    }
}

// all batch is completed
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print("--------------------------------------------------------------");
print("Batch processing completed at:  " + "Date: "+dayOfMonth+"/"+ (month+1)+"/"+year+"  Time: " +hour+":"+minute+":"+second);



// define the function to process each image
function Process_each_image(image) {
	
	// adjust the channels (flip if requested) and assign LUTs
	
    	image = getTitle();
    	
    	// flip the image up to the user's request
    	if (image_adjust == "Vertically") {
    		run("Flip Vertically","stack");
    		}
    	if (image_adjust == "Horizontally") {
    		run("Flip Horizontally","stack");
    		}
    	
		// get the number of channels
    	n_channel = nSlices();
    	print("    Number of channels: " + n_channel);
    	
    	// store the LUT of each channel in a array
		channel_colors = newArray(LUT_Ch1, LUT_Ch2, LUT_Ch3, LUT_Ch4, LUT_Ch5);
		
    	// assign LUTs, duplicate and rename each channel to "Channel_n"
		for (i = 1; i <= n_channel; i++) {
			
			//select the image
    		selectWindow(image);
    		//get the channel
    		setSlice(i);
			//set the LUT
    		run(channel_colors[i-1]); //note that array start from 0
        	//adjust constrast
    		run("Enhance Contrast", "saturated=0.35");
    		//duplicate and rename the channel
    		run("Duplicate...", "title=" + "Channel_" + i);
		}
		// close the original image
		close(image);

	//Hough Circle Transform to detect microwell

		// Select the brightfield channel for microwell detection
		
		selectWindow("Channel_" + BF_channel);


		roiManager("Reset");

		//Resize Image by 10-fold, to speed up the processing a lot!
	    	//duplicate the image

	    	run("Duplicate...", "title=Duplicated");
	    	// Get the original image dimensions
	    	originalWidth = getWidth();
	    	originalHeight = getHeight();
	    	    
	    	// Calculate the new size (10-fold reduction)
	    	newWidth = originalWidth / 10;
	    	newHeight = originalHeight / 10;
	
	    	// Resize the image
	    	run("Size...", "width=" + newWidth + " height=" + newHeight + " depth=1 constrain average interpolation=Bilinear");
	    
	    	// Display the new size
	    	newWidth = getWidth();
	    	newHeight = getHeight();
	
		// Prepare for Segmentation
		run("Duplicate...", "title=[Hough]");
		
		//invert image and smooth
		run("Invert");
		run("Smooth");
		// Remove unvanted background using rolling ball algorithm
		run("Subtract Background...", "rolling=8");
		run("Smooth");
	
		// Apply laplacian to enhance edges
		run("FeatureJ Laplacian", "compute smoothing=1");
	
		// Auto-threshold and over-estimate particles
		setAutoThreshold("Default");   // "Moments" might also works
	
		// Remove particles smaller than 50px2
		run("Analyze Particles...", "size=7-Infinity show=Masks");
	
	
		// Use a Hough transform on the mask to find likely candidates
		run("Hough Circle Transform","minRadius=8, maxRadius=11, inc=1, minCircles=1, maxCircles=2500, threshold="+hough_threshold+", resolution=30, ratio=1.0, bandwidth=10, local_radius=10, reduce show_mask show_scores results_table");
	

		// we do this by checking the existence of the 'Score map' image
		done = false;
		while (!done) {
			done = isOpen("Score map");
			wait(500);
		}
	
	
	// Merge all images for easy viewing

		selectImage("Mask of Hough Laplacian");
		// Need to make all 16-bit to match original image
		run("16-bit");
		// restore the original size, "constrain" is removed to make sure the size are exactly the same
		run("Size...", "width=" + originalWidth + " height=" + originalHeight + " depth=1 average interpolation=Bilinear");
	
		// Give nice lookup table 
		selectImage("Score map");
		resetMinAndMax();
		run("mpl-viridis");
		run("16-bit"); //convert to 16-bit to match original image
		
		// restore the original size, "constrain" is removed to make sure the size are exactly the same
		run("Size...", "width=" + originalWidth + " height=" + originalHeight + " depth=1 average interpolation=Bilinear");
	

		roiManager("Reset");

		// merge all the channels including the new score map image

	    merge_para = "";
	    
		//concatenate the merge parameters
	 	for (i = 1; i <= n_channel; i++) {
   			merge_para = merge_para + "c" + i +"=[" +  "Channel_" + i + "] ";
	 	}
	 	
		n_channel_new = n_channel + 1;
		merge_para = merge_para + "c" + n_channel_new  + "=[Score map] create";
		//print(merge_para);
		
		//merge the channels
		run("Merge Channels...", merge_para);
		
		// rename the image 
		Stack.setDisplayMode("color");
		rename(image+"_microwell_detected");
		close("\\Others");
		//show the time when this session is completed
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		print("    Hough Circle Transform completed at " + "Date: "+dayOfMonth+"/"+ (month+1)+"/"+year+"  Time: " +hour+":"+minute+":"+second);


	// Generate ROI
	
		// replicate the channel4, microwell score map
		selectImage(image+"_microwell_detected");
		
		//duplicate the score map channel, 
		//for example duplicating the channel 4: run("Duplicate...", "duplicate channels=4 title=channel_ROI");
		setSlice(n_channel_new);
		run("Duplicate...", "title=channel_ROI");
		
		//theshold 
		setAutoThreshold("Default dark");
		
		// adjust the circular value for particle recognization using hough_threshold; the - 0.2 is empirically established
	
		circular_value = hough_threshold - 0.2;
		// make mask
		run("Analyze Particles...", "size=100-Infinity pixel circularity=" + circular_value + "-1.00 show=Masks add");
		//save ROI and print the number
		roiManager("Save", outputDir + image + "ROI.zip");
		print("    Number of ROI detected: " + RoiManager.size);
		
		//close the image "channel_ROI" and "Mask of channel_ROI"
		close("channel_ROI");
		close("Mask of channel_ROI");
 

	//analysis channels in ROI

		// select the channel whose background is to be removed
		selectWindow(image+"_microwell_detected");
	
		//clear results
		run("Clear Results");
		for (i=1; i<=n_channel; i++) {
  			//choose the current channel
  			setSlice(i);
  			

  			// put the yes/no value of RemoveBackground_ChX to a array, just addd a "0" to fill the array[0].
 			isRemoveBackground = newArray("0", RemoveBackground_Ch1, RemoveBackground_Ch2, RemoveBackground_Ch3, RemoveBackground_Ch4, RemoveBackground_Ch5);

  
  			//substract the background is requested
  			if (isRemoveBackground[i]== "Yes") {

  				//substract background, only the selected slice
				run("Subtract Background...", "rolling=" + rolling_size + " slice"); // important !!!

				//adjust contrast to view
				run("Enhance Contrast", "saturated=0.05");
	
				//set the measurement optios
				run("Set Measurements...", "area mean standard min center integrated median area_fraction limit display redirect=None decimal=9");
	
	  	
				setThreshold(Threshold_background, 65535, "raw");
	
				roiManager("Measure");
				resetThreshold();
     			print("    This channel is measured WITH background substracted: " + i);
  			}
  			else {
     			setAutoThreshold("Default dark"); // this might variabe image by image
     			roiManager("Measure");
     			print("    This channel is measured WITHOUT background substracted: " + i);
  			}
   		}

	// reset the roiManager for next image
    roiManager("Reset");
    
	// save and close the Results
	saveAs("Results", outputDir + image + "Results.csv");

	
	selectWindow("Results"); 
	run("Close" );
	
	//save the backgroud removed image 
	saveAs("Tiff", outputDir + image + "background_substracted.tif");
	close;
}
	
