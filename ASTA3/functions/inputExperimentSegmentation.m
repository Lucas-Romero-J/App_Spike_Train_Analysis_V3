function inputExperimentSegmentation()
% Prompts the user for time segment data and stimulation times, and saves
% them to a file called experimentSegmentation.mat in a subdirectory called
% configFiles.

% The input format has to be a matrix with rows representing experiments
% and columns representing times. In the controlAndLight array, the start
% and end times for each segment have to be input as consecutive columns,
% being the first 2 reserved for baseline or control segment. For
% experiments with missing segments, the empty spaces has to be filled with
% NaN. 
% For electric individual stimuli stored in stimuliTimes only the
% stimulation time has to be input (1 column per stimulus)

% It is highly recommended to create the array in a spreadsheet
% program previously and copy-paste from there.

controlAndLight = input('Insert time segment data (s) for control & light stimulation between [ ]: ');
stimuliTimes = input('Insert stimulation times (s) between [ ]: ');

% Manual input of segment names for output organization purposes
segmentNames = {};
inputBuffer = ['0'];
auxCounter = 1;
while ~isempty(inputBuffer)
    inputBuffer = input('Input experiment segment names, press only ENTER to stop data collection: ', 's');
    segmentNames{auxCounter,1} = inputBuffer;
    auxCounter = auxCounter + 1;
end
segmentNames(end) = [];

% Manual input of stimulation protocol
stimulationProtocol = {};
inputBuffer = ['0'];
auxCounter = 1;
while ~isempty(inputBuffer)
    inputBuffer = input('Input stimulation information, press only enter to stop data collection: ', 's');
    stimulationProtocol{auxCounter,1} = inputBuffer;
    auxCounter = auxCounter + 1;
end
stimulationProtocol(end) = []; % To remove the last intro press form the cell array


if ~exist('configFiles', 'dir')
    mkdir('configFiles');
end

save('configFiles\experimentSegmentation.mat', 'controlAndLight', 'stimuliTimes', 'segmentNames', 'stimulationProtocol');
disp('Experiment segmentation data saved to configFiles\experimentSegmentation.mat');
end
