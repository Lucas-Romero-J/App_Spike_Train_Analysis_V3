function ASTA3(filename, folderpath, experimentNumber, startTime, endTime)
% This function performs the classification of firing patterns.
% See the documentation for more detailed information about regularity
% and bursts frequency thresholds.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Arguments
% -filename: (string) name of the data file
% -folderpath: (string) path to the folder where the data file is located
% -experimentNumber: (number) numeric identifier assigned to the experiment
% -startTime: (seconds) Definition of the segment to be analyzed
% -endTime: (seconds) Definition of the segment to be analyzed
%
% An example calling to the function would be the following:
% ASTA3('dataFile004.mat', 'C:\Users\Researcher\Documents\Recordings\', 4, 900, 1800)
% In this case the experiment would only be analyzed between the 15 and 30
% minutes of recording,
%
% All of the function arguments are optional. However, if the startTime
% argument is provided, the endTime argument also has to be provided,
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Data file architecture is critical for the algorithm to work
% The current implementation is optimized for data files exported to .mat
% format from the software Spike2.
%
% The exported source file contains a struct, which contains itself
% one struct for each recorded neuron and an additional information struct.
% The relevant field in the neuronal data struct is called .times, which
% contains the times of occurence of action potentials. These are the data
% that the algorithm takes into account.
% To simplify the access to each neuron, the initial struct is transformed
% into a cell in line ####, so each row represents a neuron.
%
% If analyzing data coming from other recording system, please, organize
% the information this same way
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Classification thresholds defined as constants
REGULARITY_THRESHOLD = 0.5; % CV of ISI or CV_ISI_interBurst < 0.5 as regularity check
FAST_BURSTING_THRESHOLD = 70; % 70 Hz of intraBurst firing frequency to define fast bursts
BURSTING_THRESHOLD = 25; % Percentage of spikes in bursts to classify the neuron as bursting
MIX_BURST_THRESHOLD = 1; % Number of high frequency spikes per individual burst to classify as mix burst


% If experiment number is not provided as an argument, stablish it as a
% global variable that is increased by 1 in every execution of the function
if ~exist('experimentNumber', 'var') || isempty(experimentNumber)
    global experimentNumber
    if isempty(experimentNumber)
        experimentNumber = 1;
    else
        experimentNumber = experimentNumber + 1;
    end
end

% If the path and file are not defined when calling the function, open a
% prompt window to select the file
if ~exist('filename', 'var') && ~exist('folderpath', 'var')
    [filename,folderpath] = uigetfile('*.mat','Select a Matlab file exported from Spike 2');
end

% Data load
experimentData = struct2cell(load([folderpath filename]));

% Number of neurons calculation
nNeurons = 0;
for i = 1:size(experimentData)
    if isfield(experimentData{i,1}, 'times')
        nNeurons = nNeurons + 1;
    end
end


% If the experiment to be analyzed is divided in segments and the control
% segment start and end times are provided, extract the spikes in that
% interval
if exist('startTime','var') && ~isempty(startTime)
    % Searching first spike time
    minTime = 0;
    for n = 1:nNeurons
        localMin = min(experimentData{n,1}.times(experimentData{n,1}.times >= startTime));
        if localMin < minTime
            minTime = localMin;
        end
    end
    
    % Extract spikes within the chosen segment
    for k = 1:nNeurons
        experimentData{k,1}.times = experimentData{k,1}.times(experimentData{k,1}.times >= startTime & experimentData{k,1}.times <= endTime);
        experimentData{k,1}.times = experimentData{k,1}.times - minTime;
        experimentData{k,1}.length = length(experimentData{k,1}.times);
    end
end

% Open file to write data
arch1 = fopen('unit_classification.csv', 'a');


% Sometimes with spike2 the first element in the exported data does not
% contain spikes, this deletes that struct to prevent an error
if ~isfield(experimentData{1,1}, 'times')
    experimentData(1) = [];
end


% Searching last spike in the recording
maxTime = 0;
for n=1:nNeurons
    localMax = max(experimentData{n,1}.times);
    if localMax > maxTime
        maxTime = localMax;
    end
end

% Iterate by the number of neurons
for n = 1:nNeurons
    % Neuron's name
    unit=['U',num2str(n)];
    
    fprintf('Neuron %d/%d\n', n, nNeurons);
    
    % Extract spike times
    spikeTimes = experimentData{n,1}.times;
    
    if isempty(spikeTimes)
        fprintf(arch1,'%d,%s,%s,%.3f,%.2f\n',...
            experimentNumber,...
            unit,...
            'non firing',...
            0,...
            0);
        continue
    end
    
    % Number of action potentials fired by the neuron
    nSpikes = length(spikeTimes);
    
    % Interspike intervals vector
    isi = zeros(1, nSpikes - 1);
    % ISI calculation
    for b = 2:nSpikes
        isi(b - 1) = (spikeTimes(b) - spikeTimes(b-1));
    end
    
    % The first instant frequency element is zero
    instFreq = zeros(1, nSpikes);
    % Instant frequency calculation
    instFreq(2:end) = 1./isi;
    
    
    % Frequencies above 400 Hz are not considered so corresponding events are deleted
    spikesToKeep = instFreq < 400;
    spikeTimes = spikeTimes(spikesToKeep);
    
    
    % In case the last element is zero, last ISI would be negative and CV too. This step fix this error
    if spikeTimes(end) == 0
        spikeTimes = spikeTimes(1:(length(spikeTimes)-1));
    end
    
    
    % Interspike intervals and instant frequencies have to be recalculated
    nSpikes = length(spikeTimes);
    
    % Interspike intervals vector
    isi = zeros(1, nSpikes - 1);
    % ISI calculation
    for b = 2:nSpikes
        isi(b - 1) = (spikeTimes(b) - spikeTimes(b-1));
    end
    
    % The first instant frequency element is zero
    instFreq = zeros(1, nSpikes);
    % Instant frequency calculation
    instFreq(2:end) = 1./isi;
    
    
    % Firing frequency calculation
    firingFrequency = nSpikes/maxTime;
    
    
    % Calculates coefficient of variation (CV) considering every ISI
    cvIsi = (std(isi)/mean(isi));
    
    
    % Firing pattern classification
    clf
    
    % Instant frequency graph plotting
    plot(spikeTimes,instFreq,"*k")
    
    % Choose to detect burst mode
    burstDetection = buttonTrueFalse;
    
    
    if burstDetection == 1
        % The pattern classification can be repeated as many times as wanted
        % for each neuron
        isRepeat = true;
        while isRepeat == true
            % Set the threshold for frequency filter
            frequencyFilter = getThreshold;
            
            % This segment ensures that the threshold is properly placed to
            % avoid a fatal error
            while frequencyFilter <= 0
                disp('ERROR: Filter must be set as a positive integer, please, place it again');
                textX = xlim;
                textX = textX(1) + 5;
                textY = ylim;
                textY = textY(2)/2;
                text(textX, textY, 'ERROR, CHECK CONSOLE', 'FontSize', 20, 'Color', 'red');
                frequencyFilter = getThreshold;
            end
            % Check if there is any text present in the plot
            textHandles = findobj(gca, 'Type', 'text');
            if ~isempty(textHandles)
                % Delete all the text objects
                delete(textHandles);
            end
            
            % The instant frequencies under the threshold (and corresponding times) are extracted
            firstSpikesFilter = instFreq < frequencyFilter;
            firstSpikesTimes = spikeTimes(firstSpikesFilter);
            nFirstSpikes = length(firstSpikesTimes);
            
            % If every spike in the recording is below the threshold, the
            % neuron is not analyzed as a bursting one and only the
            % regularity is addressed, being classified as RS or IS
            % according to that
            if nFirstSpikes == length(spikeTimes)
                if cvIsi < REGULARITY_THRESHOLD
                    firingPattern = 'RS';
                else
                    firingPattern = 'IS';
                end
                break
            end
            
            % Adding an element at the beginnig of the ISI's vector allows
            % to extract intraburst intervals using the logical vector
            % opposite to firstSpikesFilter
            isi2 = [0,isi];
            burstFilter = (firstSpikesFilter == 0);
            isiIntraburst = isi2(burstFilter);
            
            % Calculates interspike intervals and instant frequencies
            % considering only the first spikes of bursts
            ISI_FirstSpikes = zeros(1, nFirstSpikes - 1);
            for b2 = 2:nFirstSpikes
                ISI_FirstSpikes(b2 - 1) = firstSpikesTimes(b2) - firstSpikesTimes(b2-1);
            end
            firstSpikesFrequencies = zeros(1, nFirstSpikes);
            firstSpikesFrequencies(2:end)=1./ISI_FirstSpikes;
            
            % Calculates instant frequencies intraburst and mean intraburst
            % frequency
            IntraburstFreq = (1./isiIntraburst);
            meanIntraBurstFreq = mean(IntraburstFreq);
            sdIntraBurstFreq = std(IntraburstFreq); % Non in use
            
            % New vector without the initial zero to calculate mean
            % interburst frequency
            firstSpikesFrequencies = firstSpikesFrequencies(2:end);
            meanInterBurstFreq = mean(firstSpikesFrequencies);
            sdInterBurstFreq = std(firstSpikesFrequencies); % Non in use
            
            % Analysis of spikes per burst and burst length
            timesIntraBurst = spikeTimes(burstFilter);% Timestamps of every spike within a burst (excepting the first spike of each burst)
            nSpikesIntraBurst = length(timesIntraBurst);
            
            % Setting the variable for the next nested loops to start
            loopStartBurstSpikes = 1;
            loopStartTotalSpikes = 1;
            bursts = [];
            while (timesIntraBurst(loopStartBurstSpikes) ~= timesIntraBurst(end))
                for currentSpikeInBurst = loopStartBurstSpikes:nSpikesIntraBurst
                    count = 0; % Spike count is set to zero
                    for currentSpikeTotal = loopStartTotalSpikes:nSpikes
                        % Look for the first coincident event between the intraburst vector and the vector containing every event
                        if (timesIntraBurst(currentSpikeInBurst) ~= spikeTimes(currentSpikeTotal))
                            continue
                        end
                        % The first spike in each burst is the one previous to the first intraburst spike
                        firstSpike = spikeTimes(currentSpikeTotal - 1);
                        count = count + 2;
                        if (timesIntraBurst(currentSpikeInBurst) == timesIntraBurst(end)) % Finish the loop if the last intraburst event is reached
                            burstLength = spikeTimes(currentSpikeTotal) - firstSpike;
                            bursts = [bursts;count,burstLength];
                        else
                            currentSpikeInBurst = currentSpikeInBurst + 1;
                            currentSpikeTotal = currentSpikeTotal + 1;
                            % If the spikes in burst match the secuence of spikes in the recording, the counting continues
                            % It stops when an spike not included in a burst is found
                            while (timesIntraBurst(currentSpikeInBurst) == spikeTimes(currentSpikeTotal))
                                count = count + 1;
                                currentSpikeTotal = currentSpikeTotal + 1;
                                if timesIntraBurst(currentSpikeInBurst) == timesIntraBurst(end) % Finish the loop if the last intraburst event is reached
                                    break
                                end
                                currentSpikeInBurst = currentSpikeInBurst + 1;
                            end
                            % Burst length is calculted as the difference between the last and first spike time in the burst
                            burstLength = spikeTimes(currentSpikeTotal - 1) - firstSpike;
                            % Number of spikes and burst length are added to the burst data array
                            bursts = [bursts;count,burstLength];
                            % The next time the nested loops initiate, they do from the first intraburst spike in the next burst
                            % and the first spike non in burst from the total spikes to avoid checking again the same coincidences
                            loopStartBurstSpikes = currentSpikeInBurst;
                            loopStartTotalSpikes = currentSpikeTotal;
                        end
                        % Both loops are stoped and restarted as long as the while condition remains true
                        if loopStartBurstSpikes == currentSpikeInBurst
                            break
                        end
                    end
                    % Both loops are stoped and restarted as long as the while condition remains true
                    if loopStartBurstSpikes == currentSpikeInBurst
                        break
                    end
                end
            end
            
            % Conditional to avoid an error when the number of spikes in bursts is 1 or less
            if isempty(bursts) || length(bursts) == 1
                % THe firing pattern can already be defined
                if cvIsi < REGULARITY_THRESHOLD % Simple regularity test
                    firingPattern = 'RS';
                else
                    firingPattern = 'IS';
                end
                break
            end
            burstSpikes = bursts(:,1);
            burstLengths = bursts(:,2);
            
            % Test for mixed burst firing
            % The threshold is set more restrictive to ensure proper classification
            highFreqFilter = IntraburstFreq > FAST_BURSTING_THRESHOLD + 10;
            highFrequencySpikes = IntraburstFreq(highFreqFilter); % Amount of spikes in burst above frequency threshold
            
            % Spikes in burst in relation to the total spikes
            percentageSpikesBurst = (sum(burstSpikes)*100)/nSpikes;
            
            %Firing pattern classification acording to the defined criteria
            if percentageSpikesBurst > BURSTING_THRESHOLD % Burst firing test
                cvIsiIntraburst = (std(isiIntraburst)/mean(isiIntraburst)); %Calculates intraburst regularity
                cvIsiInterburst = (std(ISI_FirstSpikes)/mean(ISI_FirstSpikes)); %Calculates interburst regularity
                meanSpikes = mean(burstSpikes); %Calculates mean spikes per burst
                meanBurstLenght = mean(burstLengths); %Calculates mean burst duration
                
                if cvIsiInterburst < REGULARITY_THRESHOLD % Interburst regularity test
                    if meanIntraBurstFreq > FAST_BURSTING_THRESHOLD % Fast burst test
                        firingPattern = 'RFB';
                        % The criterion to consider mixed bursting is the presence of 1 or more spikes per burst at least at 80 Hz
                    elseif length(highFrequencySpikes) >= (MIX_BURST_THRESHOLD*length(burstSpikes))
                        firingPattern = 'RMB';
                    elseif cvIsiIntraburst < REGULARITY_THRESHOLD
                        firingPattern = 'RRSB';
                    else
                        firingPattern = 'RSB';
                    end
                elseif meanIntraBurstFreq > FAST_BURSTING_THRESHOLD % Fast burst test
                    firingPattern = 'IFB';
                elseif length(highFrequencySpikes) >= (1*length(burstSpikes))
                    firingPattern = 'IMB';
                else
                    firingPattern = 'ISB';
                end
            else
                if cvIsi < REGULARITY_THRESHOLD % Simple regularity test
                    firingPattern = 'RS';
                else
                    firingPattern = 'IS';
                end
            end
            
            % Add the firing pattern to the graph
            textX = xlim;
            textX = textX(1) + 5;
            textY = ylim;
            textY = textY(2)/2;
            text(textX, textY, firingPattern, 'FontSize', 56, 'Color', 'red');
            
            % Allows the reclassification of the neuron
            isRepeat = buttonRepeatContinue;
            plot(spikeTimes,instFreq,"*k")
        end
    else
        if cvIsi < REGULARITY_THRESHOLD
            firingPattern = 'RS';
        else
            firingPattern = 'IS';
        end
    end
    
    % Data writing in file, according to the firing pattern
    if strcmpi(firingPattern,'IS') || strcmpi(firingPattern,'RS')
        fprintf(arch1,'%d,%s,%s,%.3f,%.2f\n',...
            experimentNumber,...
            unit,...
            firingPattern,...
            firingFrequency,...
            cvIsi);
    else
        fprintf(arch1,'%d,%s,%s,%.3f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n',...
            experimentNumber,...
            unit,...
            firingPattern,...
            firingFrequency,...
            cvIsiInterburst,...
            cvIsiIntraburst,...
            meanSpikes,...
            meanIntraBurstFreq,...
            meanInterBurstFreq,...
            meanBurstLenght);
    end
    
end

fclose(arch1);

end


