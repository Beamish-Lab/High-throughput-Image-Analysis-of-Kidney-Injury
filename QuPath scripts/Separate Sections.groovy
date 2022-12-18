// Extract individual sections from a larger qpTIFF image and stores them as a pyramidal tif file
// All regions of the images must be annotated AND classified (using a unique key such as "Row1_Column1" etc)
// To complete this operation for all the images in the project, use in conjunction with "Run ‣ Run for project" 
// In this macro "Annotations" generated in QuPath are used as ROIs to extract

//12-9-2022 JAB

//import the default methods (may be redundant)
import static qupath.lib.gui.scripting.QPEx.*

//import additional special methods for this evaluation  (may be redundant)
import qupath.lib.images.writers.ome.OMEPyramidWriter 
import qupath.lib.regions.ImageRegion 

//get details from the project
def project = getProject()
def server = getCurrentServer()

//get image name and remove the extra fluff on the end
def imageData = getCurrentImageData()
def name = imageData.getServer().getMetadata().getName() //get the full file name of the entry
def shortname = name.split('_')[0] //take only the first part of the name before the '_' that is added when 

//Make sure the location you want to save the files to exists - requires a Project
def pathOutput = buildFilePath(PROJECT_BASE_DIR, 'Extracted Multichannel Whole Sections')
mkdirs(pathOutput)

//cycle through the annotations that are classified in an images (i.e. unclassifed annotations will not be processed)

def classifiedAnnotations = getAnnotationObjects().findAll{it.getPathClass() != null} //get annotations in the image that are not null

classifiedAnnotations.each{anno ->  //this is groovy code for a loop that passes the annotation object into the loop for each

    //Name of the file and the path to where it goes in the Project
    def fileName = pathOutput+"\\"+shortname+'_'+ anno.getPathClass().getName()+'.tif'

    //For each annotation, we get its outline
    def roi = anno.getROI()

    //For each outline, we request the pixels within the bounding box of the annotation
    def requestROI = RegionRequest.createInstance(getCurrentServer().getPath(), 1, roi)

    //for each set of pixels we export as a pyramidal tif file (a standard tif is too big)
    new OMEPyramidWriter.Builder(server)
        .parallelize()
        .tileSize(512)
        .scaledDownsampling(1, 4) //generates an image with 4 levels of downsampling
        .region(requestROI)//this needs to come BEFORE "build()"
        .build()
        .writePyramid(fileName)    
}

print "DONE"
