//extracts section outlines (for example: cortex + OSOM) annotated in QuPath as ".roi" files that can be used by ImageJ. 
//each image in the project must have only ONE annotation that marks outline of the section to be analyzed
//input files must have the form: part1_part2_part3_part4_part5_channelname.tif. for example: WT_GFP_M_0001_FA2_Autofluoresence.tif
//the output file will have the form: part1_part2_part3_part4_part5.roi for example: WT_GFP_M_0001_FA2.roi
//12-10-22 JAB

import ij.plugin.frame.RoiManager 

for (entry in project.getImageList()) {
    def imageData = entry.readImageData()
    def hierarchy = imageData.getHierarchy()
    def annotations = hierarchy.getAnnotationObjects()
    def FullName = entry.getImageName()
    def FullName_parts = FullName.split('_')
    int last_element = FullName_parts.size()-1

    def ImageID = FullName_parts[0]
    
    //rebuild the ImageID without the last part (the part that specifies the image type) removed
    for (int i = 1; i<last_element;i++){
        ImageID = ImageID + '_' + FullName_parts[i]
    }
    
    if (annotations.size()!=0) {
    def path = buildFilePath(PROJECT_BASE_DIR, ImageID+".roi")
    def roiMan = new RoiManager(false)
    double x = 0
    double y = 0
    double downsample = 1 // Increase if you want to export to work at a lower resolution
    
    annotations.each {
      def roi = IJTools.convertToIJRoi(it.getROI(), x, y, downsample)
      roiMan.addRoi(roi)
    }
    roiMan.runCommand("Save", path) //save the roi
    
    print ImageID
    }
    
}

print "DONE"
