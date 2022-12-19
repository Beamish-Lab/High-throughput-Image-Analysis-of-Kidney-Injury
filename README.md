# High-throughput Image Analysis of Kidney Injury

The following project outlines the tools needed for U-Net assisted segmentation and analysis of kidney injury in immunofluorescence-stained whole kidney sections. Processing has three main domains: Training, Validation, and Analysis. This site provides:

**1) Detailed protocols for each domain,** including Training, Validation, and Analysis. We also include a detailed protocol for Preprocessing, which is necessary to extract single-channel, whole-section images from large, multi-channel, whole-slide \*.qptiff scan files. Detailed instructions for setting up an AWS instance, needed to perform segmentation, are also provided. Brief descriptions of each protocol follow.

**2) Fiji macros**. These are used in the above protocols to automate the processing steps and are titled to indicate the step(s) in the detailed protocols where they are used.

**3) QuPath\* scripts**. These scripts are used to automate transferring image and annotation data between QuPath and Fiji as described in the protocols. Note: these scripts are best downloaded together and stored in the script directory indicated in QuPath, (Automate--\>Shared scripts...--\>Set script directory...)

**4) A link to U-Net models**. Files can be downloaded [HERE](https://www.dropbox.com/sh/5exs7womm3l0466/AACiRo31HIvzROJ9TIdIG4naa?dl=0):

**5) A link to example project files for Preprocessing, Training, Validation, and Analysis**. Files can be downloaded [HERE](https://www.dropbox.com/sh/5exs7womm3l0466/AACiRo31HIvzROJ9TIdIG4naa?dl=0):

![](images/Overview%20Map.jpg)

## **Protocol descriptions:**

**Preprocessing**: This protocol describes how to extract individual sections from multi-section, multi-channel whole slide scans (\*.qptiff files) and split them into single channel images for downstream processing. This will take a several gigabyte-sized files and break them into smaller files that can be easily handled in subsequent steps by most computers. This protocol is a precursor to the "Training", "Validation", and "Analysis" protocols.

**Training**: This protocol outlines how to prepare a set of U-Net compatible training images for a single stain and then use these images to train a new U-Net model.

**Validation**: This protocol describes how to validate the accuracy of U-Net models, created in "Training" above.

**Analysis**: This protocol creates cortex outlines of whole kidney sections and batch-segments images using U-Net. The U-Net segmentations are then analyzed within the cortex outline to calculate useful metrics including segmentation area and count. This protocol requires trained, validated U-Net models and assumes that the "Preprocessing" protocol has been completed.

**Setting up a remote AWS instance for U-Net segmentation**: This protocol describes how to set up a remote computer (called an "Instance") that is equipped with a GPU and processing tools to efficiently perform U-Net training and segmentations used in other aspects of protocols "Training", "Validation", and "Analysis."

**REFERENCE:**

\**Bankhead, P. et al. **QuPath: Open source software for digital pathology image analysis**.* Scientific Reports\* (2017). <https://doi.org/10.1038/s41598-017-17204-5>
