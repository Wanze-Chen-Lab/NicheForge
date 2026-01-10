// Cell Identification from Bright Field Images (// CIBFI) 

// Enhancement to be implemented:
// 1) ImageJ get file list in ACSII order, by Cellpose (python) get it quite different. Coordinate the image processing to avoid waiting time.


// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   Importance Notice !!!   <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>                           <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// 1) Input image shall be name as: XXX.tif (16 bit);
// 2) DO NOT select FIJI/ImageJ windows when running;
// 3) The cellpose segmentation output shall be in the format of XXXXX_cp_masks.png. if not, rename it;
// 4) When reanalysis the images,make sure the ./Output_Results/BF_Dir/Is_BF_Ready.csv file shall be delected;



//////////////////////////////////////  1. Define the environment and parameters /////////////////////////////////////////
///////////////////////////////////////                                         //////////////////////////////////////////

#@ String (choices={"1", "2", "3", "4", "5"}, style="radioButtonHorizontal") BF_channel 	//set the brite field channel, for microwell detection
#@ String (choices={"Blue", "Green", "Yellow", "Red", "Magenta", "Grays"}, style="radioButtonHorizontal") LUT_Ch1 	//set LUT of Ch1
#@ String (choices={"Blue", "Green", "Yellow", "Red", "Magenta", "Grays"}, style="radioButtonHorizontal") LUT_Ch2	//set LUT of Ch2
#@ String (choices={"Blue", "Green", "Yellow", "Red", "Magenta", "Grays"}, style="radioButtonHorizontal") LUT_Ch3	//set LUT of Ch3
#@ String (choices={"Blue", "Green", "Yellow", "Red", "Magenta", "Grays"}, style="radioButtonHorizontal") LUT_Ch4	//set LUT of Ch4
#@ String (choices={"Blue", "Green", "Yellow", "Red", "Magenta", "Grays"}, style="radioButtonHorizontal") LUT_Ch5	//set LUT of Ch5
//#@ Double hough_threshold (value=0.65) 		//if overestablished, increase the number, maximal 1
#@ Double (value=0.85, persist=true, style="format:#.##") hough_threshold
#@ String (choices={"No", "Vertically", "Horizontally"}, style="radioButtonHorizontal") image_adjust	//Adjust the image
#@ String (choices={"Yes", "No"}, style="radioButtonHorizontal") BatchMode	//whether set in batchmode or not

// Prompt the user for the input and output directory
inputDir = getDirectory("Choose an input Directory");
//outputDir = getDirectory("Choose an Output Directory");
outputDir = inputDir + "Output_Results/";
BF_Dir = outputDir + "BF_Dir/";
File.makeDirectory(outputDir); //make a directory
File.makeDirectory(BF_Dir); //make a directory

// set batchmode, silence mode
if (BatchMode == "Yes"){setBatchMode(true);}

// Ensure Is_BF_Ready.csv is not existing
if (File.exists(BF_Dir + "Is_BF_Ready.csv")) {
    exit("The Is_BF_Ready.csv file shall not exist.");	
}

// Ensure both folders are selected
if (inputDir == "" || outputDir == "") {
    exit("Both input and output folders must be selected.");
}

// print all the user defined parameters
print(">>>>>>>>>>>>>>>>>       parameters       <<<<<<<<<<<<<<<<<    ");
print("inputDir: " + inputDir);
print("BF_Dir: " + BF_Dir);
print("outputDir: " + outputDir);
print("BF_channel: " + BF_channel);
print("LUT_Ch1: " + LUT_Ch1);
print("LUT_Ch2: " + LUT_Ch2);
print("LUT_Ch3: " + LUT_Ch3);
print("LUT_Ch4: " + LUT_Ch4);
print("LUT_Ch5: " + LUT_Ch5);
print("hough_threshold: " + hough_threshold);
print("image_adjust: " + image_adjust);
print("--------------------------------------------------------------");

// get and print the start time
iPrint_Time();


//////////////////////////    				 2. pre-processing						////////////////////////////////////////
//////////////////////////        Adjust images and Save the BF channel to BF_Dir    //////////////////////////////////////////
//////////////////////////          as input for Cellpose segmentation     	   		 //////////////////////////////////////////

// Get a list of all image files in the input folder
list = getFileList(inputDir);
list = list_onlyTiff(list);  // only keep the .tif and .tiff files

print("Input files:");
Array.print(list);
// Process each image in the input folder
print("--------------------- Saving BF images -----------------------");

for (i = 0; i < list.length; i++) {

      
        print("Processing: " + list[i]);
        // Open the current image
        open(inputDir + list[i]);
        
        // Get the image title and filename without suffix (.tif)
        imageName = getTitle();
        imageName_WOsuf = substring(imageName, 0, lengthOf(imageName)-4);  // the substring index starts from 0
          
        // flip the image up to the user's request
    	if (image_adjust == "Vertically") {
    		run("Flip Vertically", "stack");
    		print("    Image Flipped Vertically");
    		}
    	if (image_adjust == "Horizontally") {
    		run("Flip Horizontally", "stack");
    		print("    Image Flipped Horizontally");
    		}
 
        // get the slice and replicate it
        setSlice(BF_channel);
        run("Duplicate...", "title=BF_channel");
        
 		//save and close the images
		saveAs("Tiff", BF_Dir + imageName_WOsuf + "_BF.tif");
        close();
        close(imageName);  	 
}
   
// set the value to 1 to Is_BF_Ready.csv,  a sign of BF image is ready for cellpose
Table.create("Is_BF_Ready");
Table.set("Is_BF_Ready", 0, 1);  // set a value 1 to row index 0 and column "Is_BF_Ready"
Table.save(BF_Dir + "Is_BF_Ready.csv");
run("Close");

// the pre-processing of images is completed

print("--------------------------------------------------------------");
print("All BF channels has been copied to BF_Dir at:  ");
iPrint_Time();


///////////////////////////////////////       3. Detect the microwell as ROI    //////////////////////////////////////////
///////////////////////////////////////      								    //////////////////////////////////////////


// Process each image in the input folder
for (i = 0; i < list.length; i++) {
	print("--------------------------------------------------------------");
	print("Processing: " + list[i]);
    // Skip non-tif files

        
	// Open the current image
    open(inputDir + list[i]);

    // Get the image title (filename without extension)
    imageName = getTitle();
	imageName_WOsuf = substring(imageName, 0, lengthOf(imageName)-4);  // the substring index starts from 0
        
    // flip the image up to the user's request
   	if (image_adjust == "Vertically") {
    	run("Flip Vertically", "stack");
    	print("    Image Flipped Vertically");
    	}
    if (image_adjust == "Horizontally") {
    	run("Flip Horizontally", "stack");
    	print("    Image Flipped Horizontally");
    	}
                
	// assign LUTs to each channel and auto-contrast
	channel_colors = newArray(LUT_Ch1, LUT_Ch2, LUT_Ch3, LUT_Ch4, LUT_Ch5);     // store the LUT of each channel in a array
	n_channel = nSlices();		// get the number of channels
	print("    Number of channels: " + n_channel);	
	for (j = 1; j <= n_channel; j++) {
  			
		//select the image
    	selectWindow(imageName);
    	//get the channel
    	setSlice(j);
		//set the LUT
    	run(channel_colors[j-1]); //note that array start from 0
        //adjust constrast
    	run("Enhance Contrast", "saturated=0.35");
	}
                
    // find the microwell
    name_of_ScoreMap = "ScoreMap"; // make the name of the output score map
    iFind_microwell(imageName, BF_channel, name_of_ScoreMap); // output a name_of_ScoreMap image
        
    // merge the ScoreMap to original image, named as: image_wScoreMap
	image_wScoreMap = imageName_WOsuf + "_microwell_detected.tif"; 
	iMerge_channels(imageName, name_of_ScoreMap, image_wScoreMap);
	saveAs("Tiff", outputDir + image_wScoreMap);


	// close the ScoreMap to avoid taken to next run by mistake
	close(name_of_ScoreMap);
	close(imageName);

	// detect the ROI, in image: image_wScoreMap
	roiManager("reset");       //delect the exist ROIs
	imageTitle = image_wScoreMap;
	channel_of_scoremap = nSlices;
	iScoremap_to_ROI(image_wScoreMap, channel_of_scoremap);

	// rename ROI by the index +1, e.g. convert ROI[0] to 00001, ROI[1] to 00002

	
	
	//BUG: operation ROI on the image directly will severely slowdown the later operation of the ROI, e.g. looping in a lot of ROIs
	//     as when select the ROI, ImageJ will automatically locate that image where the ROI was originally generated.
	//Solution: we duplicate the ScoreMap for the ROI operation, and later we just close it without saving
	
	selectWindow(imageTitle);
	setSlice(nSlices);
	run("Duplicate...", "title=ScoreMap");

	nroi =  roiManager("count");  
	for (j = 0; j < nroi; j++) {
		roiManager("select", j);
		
			// Optimal: enlarge the outerRoi to include more cell inside, 
			// as the size of the microwell are usually underestimated.
			run("Enlarge...", "enlarge=25 pixel");
			roiManager("update");
			
		newname_ROI = "w" + IJ.pad(j+1, 5); // e.g. convert 1 to w00001 ; also note ROI index start from 0
		roiManager("rename", newname_ROI);	
	}
	
	// save the ROI
	image_wScoreMap_WOsuf = substring(image_wScoreMap, 0, lengthOf(image_wScoreMap)-4);  // the substring index starts from 0
	roiManager("Save", outputDir + image_wScoreMap_WOsuf + ".ROI.zip");

	// BUG: the ROI might be kept in the image even it is "deselect" in roiManager.
	// So run("Select None") to unselect image and ROI
	roiManager("deselect");
	run("Select None"); 
	
	// close the image
	close(image_wScoreMap);
	close("ScoreMap");
}




///////////////////////////////////////     3. wait for the Cellpose results   //////////////////////////////////////////
///////////////////////////////////////    								        //////////////////////////////////////////

// wait until cellpose_done.txt exist in the BF_Dir 
print("    Waiting for the cellpose segmentatio... ");
done = false;
while (!done) {
	done = File.exists(BF_Dir+"cellpose_done.txt");
	wait(1000);
}
print("    Moving on...");

iPrint_Time();

print("insert4");	        	       
///////////////////////////////////////    4. convert the Cellpose segmentation into ROI.zip file   //////////////////////////////////////////
///////////////////////////////////////    	   														//////////////////////////////////////////


// Get a list of all image files in the input folder
list = getFileList(BF_Dir);

// Only keep the Cellpose mask file XXX.masks.png and XXX.masks.tif 
list_new = newArray();
for (i = 0; i < list.length; i++) {
		
		if (endsWith(list[i], "masks.png") || endsWith(list[i], "masks.tif")) {
		list_new = Array.concat(list_new,list[i]);
		}
	}

list = list_new;

print("Input files:");
Array.print(list);

// Process each image in the input folder
for (i = 0; i < list.length; i++) {
	print("--------------------------------------------------------------");
	print("Processing: " + list[i]);
 
	// Open the current image
    open(BF_Dir + list[i]);

    // Get the image title (filename without extension)
    imageName = getTitle();
        
    // reset roimanager
    roiManager("reset");
    
    // convert label image to ROI, using MorpholibJ plugin
    run("Label Map to ROIs", "connectivity=C8 vertex_location=Corners name_pattern=r%05d");
    
    // save roi
    roiManager("save", BF_Dir + imageName + ".rois.zip" );
    
    // close the image
    close(imageName);
}



///////////////////////////////////////    5. count cells in microwell			   //////////////////////////////////////////
///////////////////////////////////////    	   								    	//////////////////////////////////////////

// Get a list of all image files in the input folder
list = getFileList(outputDir);

// Only keep the .tif 
list = list_onlyTiff(list);


print("Input files:");
Array.print(list);

// Process each image in the input folder
print("------------------- counting cells in each microwell ------------------");

for (i = 0; i < list.length; i++) {
	
	// open and get the image name
	open(outputDir + list[i]);	
	imageName = getTitle();
	
	// get the file name of outerRoi and innerRoi
	outerRoi_file = replace(imageName, "_microwell_detected.tif", "_microwell_detected.ROI.zip");  // XXX_microwell_detected.tif -> XXX_microwell_detected.ROI.zip
	innerRoi_file = replace(imageName, "_microwell_detected.tif", "_BF_cp_masks.png.rois.zip");  // XXX_microwell_detected.tif -> XXX_BF_cp_masks.png.rois.zip
	
	// open the outer ROI (microwell ROI)
	roiManager("reset");
	roiManager("open", outputDir + outerRoi_file); // add the path
			
	// store the indexes of group1 ROI (outerRoi)
	outerRoi = seq(0, roiManager("count") -1);
	Array.print(outerRoi);
	

	
	// open the group2 ROI (innerRoi)
	roiManager("open", BF_Dir + innerRoi_file ); // add the path
	
	// store the indexes of group2 ROI
	innerRoi = seq(outerRoi.length, roiManager("count") -1);
	Array.print(innerRoi);
	
//	// Rename the innerRoi by the outerRoi, 
//	rename_innerRoi_by_outerRoi(outerRoi, innerRoi);
	
//	roiManager("save", outputDir + outerRoi_file + ".AllRois.zip");
	
	// measure all the ROI
	roiManager("Deselect");
	run("Clear Results");

	// please check the rename_innerRoi_by_outerRoi for detail
	selectWindow(imageName);
	setSlice(1);  		// to be adjust
	// set the measurement to make sure include the "Bounding Rectangle", which will output BX, BY, Width and Height to the Results
	run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding shape integrated median limit display redirect=None decimal=9");
	roiManager("Measure");
	
	selectWindow("Results");
	result_Lable = Table.getColumn("Label");
	result_BX = Table.getColumn("BX");
	result_BY = Table.getColumn("BY");
	result_Width = Table.getColumn("Width");
	result_Height = Table.getColumn("Height");

	rename_innerRoi_by_outerRoi(outerRoi, innerRoi, result_Lable, result_BX, result_BY, result_Width, result_Height);
	
	roiManager("save", outputDir + outerRoi_file + ".AllRois.zip");
	
	// save the results
	saveAs("Results", outputDir + imageName + ".csv");
	run("Close");  // close the table

	// close the image
	close(imageName);
	
}



// all batch is completed
print("--------------------------------------------------------------");
print("Batch processing completed at:  ");
iPrint_Time();

///////////////////////////////////////       5. save Log   //////////////////////////////////////////
///////////////////////////////////////                     //////////////////////////////////////////

setBatchMode("exit and display");  // turn off the batch mode
selectWindow("Log");
saveAs("Text", outputDir + "Log.txt");

///////////////////////////////////////   The end of main script   //////////////////////////////////////////
///////////////////////////////////////                            //////////////////////////////////////////






// To detect microwell, return a "Score map"
// imageTitle = title of the input image; BF_channel = the n-th channel which is BF; name_of_ScoreMap = a new name for the output scoremap;

function iFind_microwell(imageTitle, BF_channel, name_of_ScoreMap) { 
	
		//Hough Circle Transform to detect microwell

		// Select the brightfield channel for microwell detection
		
		selectWindow(imageTitle);
		setSlice(BF_channel);
		
		//original = getTitle();
		//close("\\Others");
		//roiManager("Reset");

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
		setAutoThreshold("Default");  //  "Default", "Otsu",, "IsoData", "Triangle"
	
		// Remove particles smaller than 50px2
		run("Analyze Particles...", "size=7-Infinity show=Masks");
	
	
		// Use a Hough transform on the mask to find likely candidates
		run("Hough Circle Transform","minRadius=8, maxRadius=12, inc=1, minCircles=1, maxCircles=2500, threshold="+hough_threshold+", resolution=30, ratio=1.0, bandwidth=10, local_radius=10, reduce show_mask show_scores results_table");
	
		// BUG: ImageJ does not wait for the Hough plugin to finish, so we have to check and wait until it is done
		// we do this by checking the existence of the 'Score map' image
		done = false;
		while (!done) {
			done = isOpen("Score map");
			wait(500);
		}
		
		// Give nice lookup table 
		selectImage("Score map");
		resetMinAndMax();
		run("mpl-viridis");
		run("16-bit"); //convert to 16-bit to match original image
		
		// restore the original size, "constrain" is removed to make sure the size are exactly the same
		run("Size...", "width=" + originalWidth + " height=" + originalHeight + " depth=1 average interpolation=Bilinear");
		
		// you can keep this image for trouble shooting
		close("Duplicated");
		close("Hough");
		close("Masks");
		close("Hough Laplacian");
		close("Mask of Hough Laplacian");
		close("Centroid overlay");		
		// select Score map as activate image
		selectWindow("Score map");
		rename(name_of_ScoreMap);
}


// funciton to merge images with multichannels, return Composite image named as the Merged_image    ////////////////////////////////
// two images shall be the same size and depth                              ////////////////////////////////

function iMerge_channels(image_1, image_2, Merged_image) { 
	
	
	// duplicate the channels in image_1
	selectWindow(image_1);
	nChannel_1 =  nSlices();
	for (i = 1; i <= nChannel_1; i++) {
		channel_in_mergeImage = i;
		selectWindow(image_1);
		setSlice(i);
		run("Duplicate...", "title=To_be_merged_Ch" + channel_in_mergeImage );
	}
	
	// duplicate the channels in image_2
	selectWindow(image_2);
	nChannel_2 =  nSlices();
	for (i = 1; i <= nChannel_2; i++) {
		channel_in_mergeImage = channel_in_mergeImage + 1;
		selectWindow(image_2);
		setSlice(i);
		run("Duplicate...", "title=To_be_merged_Ch" + channel_in_mergeImage );
	}
	
	//concatenate the merge parameters
	merge_para = "";
	for (i = 1; i <= nChannel_1 + nChannel_2; i++) {
	 		
   		merge_para = merge_para + "c" + i +"=[" + "To_be_merged_Ch" + i + "] ";                          
   	  //merge_para = merge_para + "c" + i +"=[" +  "Channel_" + i + "] ";
	 }
	 		
	//merge the channels
	run("Merge Channels...", merge_para + " create");
	
	// make the composit in color
	//run("Channels Tool...");
	Property.set("CompositeProjection", "null");
	Stack.setDisplayMode("color");

	rename(Merged_image);
}

	
	
// funciton to detect ROI (microwell) from score map         ////////////////////////////////
// two images shall be the same size and depth               ////////////////////////////////

function iScoremap_to_ROI(imageTitle, channel_of_scoremap) { 

			// BUG: the ROI might be kept in the image even it is "deselect" in roiManager.
			// So run("Select None") to unselect image and ROI
			run("Select None"); 
			
			selectWindow(imageTitle);
			setSlice(channel_of_scoremap);
			run("Duplicate...", "title=channel_ROI");
		
			//threshold 
			setAutoThreshold("Default dark");
		
			// adjust the circular value for particle recognization using hough_threshold; the - 0.2 is empirically established
			circular_value = 0.6;
			
			// make mask
			run("Analyze Particles...", "size=100-Infinity pixel circularity=" + circular_value + "-1.00 show=Masks add");
			
			//save ROI and print the number
			//roiManager("Save", "/Users/Wanze/Documents/data_analysis/Image/BaF3_test_data/Output_images/" + imageTitle + "_ROI.zip");
			print("    Number of ROI detected: " + RoiManager.size);
			
			//close the "channel_ROI" and mask
			close("channel_ROI");
			close("Mask of channel_ROI");
}


///        function to print the time         //
////////////////////////////////////////////////

function iPrint_Time() { 
// function description
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		print( "    " + "Date: "+dayOfMonth+"/"+ (month+1)+"/"+year+"  Time: " +hour+":"+minute+":"+second);
}




// Function: rename_innerRoi_by_outerRoi
// Rename the innerRoi by the outerRoi, 
// e.g. if innerRois are inside a outerRoi outer1, then renmae inner1 as outer1_1, outer1_2 and so on

//   These variabes are to be defined first: 
//		// measure all the ROI
//		roiManager("Deselect");
//		run("Clear Results");
//		
//		selectWindow(imageName);
//		setSlice(1);  		// to be adjusted
//		run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding shape integrated median limit display redirect=None decimal=9");


//		roiManager("Measure");
//		
//		selectWindow("Results");

//		result_Lable = Table.getColumn("Label");
//		result_BX = Table.getColumn("BX");
//		result_BY = Table.getColumn("BY");
//		result_Width = Table.getColumn("Width");
//		result_Height = Table.getColumn("Height");

function rename_innerRoi_by_outerRoi(outerRoi, innerRoi, result_Lable, result_BX, result_BY, result_Width, result_Height) { 
	
	result_Name = newArray();     	// store the ROI name
	result_CountInWell = newArray();// store the number of cells in each well
	result_CenterX = newArray();	// store the center X
	result_CenterY = newArray();	// store the center Y
	
	// get the ROI name for the Label column, a typical label:  "image_name:ROI_name:channel..."
	for (i = 0; i < result_Lable.length; i++) {
		firstColon = indexOf(result_Lable[i], ":");
		secondColon = indexOf(result_Lable[i], ":", firstColon+1);
		result_Name[i] = substring(result_Lable[i], firstColon+1, secondColon);
	}

//print(result_Name.length);	
//print(result_Name[3]);
//wait(1000000);

	// calcualte the center of each ROI
	for (i = 0; i < result_Lable.length; i++) {
		result_CenterX[i] = result_BX[i] + result_Width[i]/2;
		result_CenterY[i] = result_BY[i] + result_Width[i]/2;
	}
	
	// looping along the outerRoi
	for (i = outerRoi[0]; i <= outerRoi[outerRoi.length-1]; i++) {
		
		// contained_count to count how many innerRois belong to this outerRoi
		contained_count = 0;
		for (j = innerRoi[0]; j <= innerRoi[innerRoi.length-1]; j++) {
			
			if ( result_CenterX[j] >= result_BX[i] && result_CenterX[j] <= result_BX[i] + result_Width[i] 
			&& result_CenterY[j] >= result_BY[i] && result_CenterY[j] <= result_BY[i] + result_Height[i]  ) {
				
				// count the n-th innerRoi in this outerRoi
				contained_count = contained_count + 1;
				
				// rename the innerRoi according to the outerRoi and count
				
				result_Name[j] = result_Name[i] + "_" + contained_count;
			}			
		}
		
		// store the number of cells in each well
		result_CountInWell[i] = contained_count;
	}
	
	// add the new name to the result table
	selectWindow("Results");
	Table.setColumn("Name", result_Name);
	Table.setColumn("CenterX", result_CenterX);
	Table.setColumn("CenterY", result_CenterY);
	Table.setColumn("result_CountInWell", result_CountInWell);
//	// creat a new table to count the cells in each well
//	Table.create("Cells_in_each_well");
//	// Add dummy values to create the columns "ROI_wells" and "Num_cells"
//	ROI_wells = newArray();
//	Num_cells = newArray();
//	Table.setColumn("ROI_wells", ROI_wells);
//	Table.setColumn("Num_cells", Num_cells);
//
//
//	for (i = outerRoi[0]; i <= outerRoi[outerRoi.length-1]; i++) {
//			
//			ROI_wells[i] =  result_Name[i];
//	}

	
	// rename the ROI in the ROI	
	for (i = 0; i < result_Lable.length; i++) {
		
		roiManager("select", i);			
		roiManager("rename", result_Name[i]);	
	}	
}




// Function: seq
// Generate sequential interger, e.g. seq(1,5) will generate a array (1,2,3,4,5)
function seq(start, end) { 
	
	seq_array = newArray(end - start + 1);
	
	for (i = 0; i < seq_array.length; i++) {
		seq_array[i] = start + i;
	}
	
	return seq_array;
}


// Function: pointInPolygon
// Implements the ray-casting algorithm. Returns 1 if (x, y) is inside the polygon defined
// by arrays polyX and polyY (with n vertices), and 0 otherwise.
function pointInPolygon(x, y, polyX, polyY, n) {
    count = 0;
    j = n - 1;
    for (i = 0; i < n; i++) {
         if (((polyY[i] > y) != (polyY[j] > y)) &&
             (x < polyX[i] + (y - polyY[i])*(polyX[j] - polyX[i])/(polyY[j] - polyY[i])))
         {
             count = count + 1;
         }
         j = i;
    }
    return (count % 2 == 1);
}




// Function: RoiCenter_in_Roi
// if the innerRoi center is inside the outerRoi, return 1, otherwise return 0;

function RoiCenter_in_Roi(outerRoi, innerRoi) { 

    // Step 1: Define the outer ROI.
	roiManager("select", outerRoi);
    getSelectionCoordinates(outerX, outerY);
    nOuter = lengthOf(outerX);
    
    // Step 2: Define the inner ROI.
	roiManager("select", innerRoi);
	getSelectionBounds(x, y, width, height);
	inner_centerX = x + width/2;
	inner_centerY = y + height/2;
    
    // Step 3: Check the center of the inner ROI against the outer ROI polygon.
    contained = 0;

    // If any inner point is not inside the outer polygon, set contained to false.
    if (pointInPolygon(inner_centerX, inner_centerY, outerX, outerY, nOuter)) {
    	
    	contained = 1;
         }
    return contained; 

}


// Function: check whether in the innerRoi is inside the outerRoi or not
// the outerRoi and innerRoi are just the indexes of these two groups of ROI
// return 1 if yes, otherwise 0

function Roi_in_Roi(outerRoi, innerRoi){ 

    // Step 1: Define the outer ROI.
	roiManager("select", outerRoi);
    getSelectionCoordinates(outerX, outerY);
    nOuter = lengthOf(outerX);
    
    // Step 2: Define the inner ROI.
	roiManager("select", innerRoi);
    getSelectionCoordinates(innerX, innerY);
    nInner = lengthOf(innerX);
    
    // Step 3: Check each point of the inner ROI against the outer ROI polygon.
    contained = 1;
    for (i = 0; i < nInner; i++) {
         // If any inner point is not inside the outer polygon, set contained to false.
         if (!pointInPolygon(innerX[i], innerY[i], outerX, outerY, nOuter)) {
             contained = 0;
             break;
         }
    }
    
    return contained; 
}


// Function: list_onlyTiff
// only keep the path of the .tiff and .tiff images

function list_onlyTiff(list) { 

	list_new = newArray();
	
	for (i = 0; i < list.length; i++) {
		
	
		if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff")) {
		list_new = Array.concat(list_new,list[i]);
		}
	}
	
	return list_new;
}

