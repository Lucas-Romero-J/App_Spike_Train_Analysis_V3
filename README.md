# App_Spike_Train_Analysis_V3

This is an improved version of the MATLAB software for the classification of spontaneous firing patterns based on regularity, grouping of spikes into bursts, and inter- and intra-burst firing frequency.
This version is an update of the previous one, which can be found here: https://github.com/Lucas-Romero-J/App_Spike_Train_Analysis. The code is now more detailed, optimized, and allows for direct interaction with the plots for semi-automatic classification. Another update is the ability to analyze multiple experiments in a row.

Scientific Background:
This app is designed for the analysis of spontaneous activity in the dorsal horn of the spinal cord. In this area, we have described several distinct firing patterns that allow for the classification of spontaneously active neurons.
For a complete description of these neurons, we recommend the following two publications:
1.	https://pubmed.ncbi.nlm.nih.gov/27726011/
2.	https://pubmed.ncbi.nlm.nih.gov/29950700/
The algorithm was designed as part of the work for the latter publication, so please cite that work if you find this code useful.

Neuronal Classes:
In brief, we have defined eight categories of neurons, with four having irregular firing patterns and four being the regular counterparts of the former:
-	The first class is the irregular single spike neuron (IS). It is characterized by the absence of both regularity and grouping of spikes. Its regular counterpart is the regular single spike neuron (RS).
-	The irregular fast burst neuron (IFB) is characterized by the grouping of action potentials into short, high-frequency bursts. Its regular counterpart is the regular fast burst neuron (RFB), in which the bursts appear at regular intervals.
-	The irregular slow burst neuron (ISB) also fires in bursts of action potentials, but in this case, the bursts are more extended in time, and the firing frequency within them is significantly lower. Its regular counterpart is the regular slow burst neuron (RSB).
-	The irregular mixed burst neuron (IMB) shares features characteristic of both IFB and ISB neurons, containing bursts with both fast and slow firing frequency components. Hence the name. The regular counterpart is the regular mixed burst neuron (RSB).

Classification Criteria:
The following criteria were set and described in the previously reported publication and defined as constants in the code but are easy to change if desired:

For classification based on regularity, the measurement used is the coefficient of variation (CV) of the instant frequency, which is the inverse of the interspike interval (ISI). The threshold to consider a neuron regular is a CV of less than 0.5. In neurons with a bursting firing pattern, regularity is not calculated considering the total number of spikes but only taking into account the first spike of each burst. Consequently, the regularity in the occurrence of bursts is addressed.
The grouping of action potentials into bursts is defined as a percentage greater than 25% of the total spikes included in burst-like events.
For intra-burst firing frequency classification, the threshold is set at 70 Hz to distinguish fast from slow bursting.
For a neuron to be classified as mixed bursting, at least one spike in each burst has to be fired at a frequency greater than 80 Hz.

Instruction Manual:
For the automatic analysis of multiple experiments, the directory where the data files are stored must be updated in the masterASTA script. For the analysis of single experiments, the ASTA3 function can be used independently. Please read the code comments in ASTA3 to ensure proper data file structure. Once the masterASTA script is initiated, the program asks the user if the experiments have any segmentation, allowing manual input if needed. This allows the analysis of the desired control or baseline segment of the experiment. The ASTA3 function will display a representation of the neuronal activity as an instant frequency plot, with the x-axis representing time and the y-axis representing the inverse of the ISI. This allows for the visual identification of bursts of action potentials. The plot will have two associated buttons:
-	The "NoBurstCheck" button should be pressed if the user can visually confirm that the analyzed neuron does not display a bursting firing pattern. Therefore, the script will only check the regularity of the firing and classify it as IS or RS.
-	If the user knows or suspects that the neuron has a bursting pattern, then the "BurstCheck" button should be pressed. This enables a new button called "Place threshold."
-	After pressing it, the user will be able to position the pointer over the plot, which, after being clicked, will display a horizontal red dashed line. This line, acting as a threshold, should be placed in a way that separates the first spike of each burst from the rest of them. For example, if the analyzed neuron only fires duplets of action potentials, the first spikes of the duplets should be below the line, while the second spike should be above it. The position of the line relative to the y-axis is not relevant in terms of analysis procedures, as long as the spikes are clearly separated. This process can be repeated as many times as needed until a proper threshold placement is achieved.
-	Once the threshold is properly placed, the user can press the "Get Y value" button, which will initiate the firing pattern analysis. The resulting firing pattern will be displayed in the plot, along with two new buttons:
-	The "Continue" button will confirm the neuron classification, restore the plot view, and initiate the analysis of the next neuron in the file.
-	The "Repeat" button will allow the user to replace the threshold if the previous position did not successfully separate the first spikes of the bursts. To repeat this analysis, the same buttons as before have to be pressed in order.
 	
The example files in the repository provide some ideal recordings of different firing patterns, as well as a full experiment containing a number of neurons with more ambiguous firing characteristics, so the user can practice classifying them. The output file with the classification results obtained by a trained researcher is also provided for comparison.

