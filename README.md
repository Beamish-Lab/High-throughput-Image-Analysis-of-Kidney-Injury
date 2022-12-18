# High-throughput-Image-Analysis-of-Kidney-Injury

The following project outlines the tools needed for U-Net assisted segmentation and analysis kidney injury in immunofluorescent stained whole kidney sections. Processing has three main domains: Training, Validation, and Analysis. This site provides:

**1) Detailed protocols for each domain.** We also include a detailed protocol for Preprocessing, which is necessary to extract single channel, whole section images from large, multi-channel, whole-slide \*.qptiff scan files. Detailed instructions for setting up an AWS instance, needed to perform segmentation, are also provided. Brief descriptions of each protocol follow.

**2) Fiji macros**. These are used in the above protocols to automate the processing steps and are titled to indicate the step(s) in the detailed protocol where they are used.

**3) QuPath\* scripts**. These scripts are used to automate transferring image and annotation data between QuPath and Fiji as described in the protocols. Note: these scripts are best downloaded together and stored in the script directory indicated in QuPath, (Automate--\>Shared scripts...--\>Set script directory...)

**4) Links** to this [Publically accessible Dropbox url](https://www.dropbox.com/sh/5exs7womm3l0466/AACiRo31HIvzROJ9TIdIG4naa?dl=0) that contains:

1.  U-Net model and weight files

2.  Example project files for Preprocessing and all three processing domains (Training, Validation, Analysis)

![](images/Overview%20Map.jpg){width="642"}

\*Bankhead, P. et al. **QuPath: Open source software for digital pathology image analysis**. *Scientific Reports* (2017). <https://doi.org/10.1038/s41598-017-17204-5>
