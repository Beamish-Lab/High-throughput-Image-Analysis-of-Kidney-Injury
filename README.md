# High-throughput-Image-Analysis-of-Kidney-Injury

The following project outlines the strategies used in U-Net assisted modeling to analyze immunofluorescence staining of kidney injury. 

Attached within this site inlcudes protocols to pre-process multichannel whole slide scans (.qptiff files) into single channel, smaller image files that can be easily handled for most computers; train U-Net compatible images for detection of higher order structures or nuclear stains; and validate effectiveness of U-Net assisted analysis in positive area detection using a human reference. Please see "Pre-Processing," "Training," and "Validation" protocols. 

Once the training and validation of an immunofluorescence stain is completed, U-Net models can be applied to a variety of projects to accurately and quickly analyze positive area detection of cross-sectional kidney samples. 

This site also contains macros specic for ImageJ Fiji and QuPath programming to assist in processing. Protocols outline when, where, and how to use. 

To use the following site, please download publicly available macros and protocols for your own research needs. Both the protocols and macros are placed within designated folders. Other files that help guide processing are included within the main page. 

The order processing is:
      1: Pre-Processing
      2: Setting Up AWS Instance
      3: Training
      4: Validation
      5: Analysis
