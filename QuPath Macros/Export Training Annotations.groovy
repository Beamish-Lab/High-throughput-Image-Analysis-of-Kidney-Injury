//Extracts annotations made for training in QuPath as a zipped set of *.roi files (one for each annotation). 
//Input files (that are added to the projection) should be of form imageinfo.tif "WT_GFP_M_0001_IRI2_Ki67_ROI-1.tif"
//The output will be a .zip file of the form imageinfo_ROIs.zip for example "WT_GFP_M_0001_IRI2_Ki67_ROI-1_Annotations.zip"
//Each annotation should have a class and can include the class "ignore" which tell U-Net to not use that area for training.
//12-10-2022 JAB


import ij.plugin.frame.RoiManager 

for (entry in project.getImageList()) {
    def imageData = entry.readImageData()
    def hierarchy = imageData.getHierarchy()
    def annotations = hierarchy.getAnnotationObjects()
    def FullName = entry.getImageName()
    ImageID = FullName.minus(".tif")
    if (annotations.size()!=0) {
    def path = buildFilePath(PROJECT_BASE_DIR, ImageID+"_Annotations.zip")
    def roiMan = new RoiManager(false)
    double x = 0
    double y = 0
    double downsample = 1 // Increase if you want to export to work at a lower resolution
    annotations.each {
      def roi = IJTools.convertToIJRoi(it.getROI(), x, y, downsample)
      roi.setName(it.getDisplayedName())
      roiMan.addRoi(roi)
    }
    roiMan.runCommand("Save", path)
    
    print ImageID
    }
}

print "DONE"
