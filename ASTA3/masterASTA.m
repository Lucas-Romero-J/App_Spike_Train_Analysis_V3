%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Software developed by Javier Lucas-Romero 
% July 2023
% This is the master script for the execution of ASTA3. 
% The purpose of this software is to provide a user-friendly tool to
% classify the different firing patterns of spontaneously active neurons
% according to their regularity, grouping of spikes in bursts and firing
% frequency in the bursts.
%
% This is an updated and improved version of the previously publised
% sofware ASTA in https://github.com/Lucas-Romero-J/App_Spike_Train_Analysis
%
% Data file structure is important for internal working of the algorithm,
% please, check ASTA3 function to ensure proper data architecture
% Example files are provided in the repository
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
close all

rand('seed',1);	% Seed for random number generation to ensure replicability


% Constant definition
% Change to set the folder where the experiments data is stored
FOLDERPATH_DATA = 'C:\Users\YourDataPathHere\';
global experimentNumber
global SAMPLING_FREQUENCY
SAMPLING_FREQUENCY = 20000;     % Select sampling frequency in Hz
% If the experiment is segmented, change path in line 64

% Add the path where the functions are stored, whichs should be a subfolder
% of the path where the master script is stored
addpath(fullfile(pwd, 'functions'));

% Preprocessing
% Loading list of files to analyze contained in the directory
fileList = dir(FOLDERPATH_DATA);

% Initialize a count for actual files
nExperiments = 0;
% Files indexes corresponding to directories in the list
fieldsToDeleteIndex = [];
% Loop through the entries in fileList and count actual files
for i = 1:length(fileList)
    % Check if the entry is a file (not a directory)
    if ~fileList(i).isdir
        nExperiments = nExperiments + 1;
    else
        fieldsToDeleteIndex = [fieldsToDeleteIndex, i];
    end
end
% Delete from the list files no corresponding to data
fileList(fieldsToDeleteIndex)=[];

if isempty(fileList)
    disp('No files present in the selected path or wrong path selection');
    return
end

% Load of experiment segments and stimulation times
segmentationTest = input('Is the experiment segmented? Y/N: ', 's');
if segmentationTest == 'Y'
    % Path where the segment definition is stored
    addpath('C:\Users\yourPathHere\configFiles');
    try
        load('experimentSegmentation.mat');
    catch
        inputExperimentSegmentation  % If the file does not exist the data is requested
        load('experimentSegmentation.mat');
    end
end

% Creates the output file with heading
arch1 = fopen('unit_classification.csv', 'a');
fprintf(arch1, '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n', ...
    'Experiment', ...
    'Unit', ...
    'Firing pattern', ...
    'Firing freq', ...
    'CV INTERBURST', ...
    'CV INTRABURST', ...
    'Spikes', ...
    'Intra-Burst Freq', ...
    'Inter-Burst Freq', ...
    'Burst length');
fclose(arch1);

% Loop for experiment analysis
for i = 1:nExperiments
    fprintf('Loading experiment %d/%d\n', i, nExperiments);
    fileName = fileList(i).name;
    experimentNumber = i;
    
    % File created with inputExperimentSegmentation function, where the
    % first and second columns correspond to start and end times of the
    % baseline recording period
    if segmentationTest == 'Y'
        startTime = controlAndLight(i,1);
        endTime = controlAndLight(i,2);
    else
        startTime = [];
        endTime = [];
    end
    
    % Function call for firing pattern analysis
    ASTA3(fileName, FOLDERPATH_DATA, experimentNumber, startTime, endTime)
end

close all