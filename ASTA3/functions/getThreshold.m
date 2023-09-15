function output = getThreshold ()
% This function creates a threshold button 
% that allows the user to interactively place a horizontal line (threshold) 
% on a plot. The function then waits for the user to click on another 
% button labeled "Get Y Value". When this button is pressed, the 
% function returns the Y coordinate of the threshold line that was placed 
% on the plot. Multiple threshold setting iterations are allowed, but only 
% the last value before the "Acquire Y Value" button pressing is stored

% Variable definition for nested functions
global btnGetYValue
global yThreshold
yThreshold = [];
global xlims
% If the threshold is set in a zoomed portion of the x axis, this ensure
% that the line is ploted in the entire graph
xlims = get(gca, 'XLim'); 

% Create the threshold button
btnPlaceThreshold = uicontrol('Style', 'pushbutton', ...
    'String', 'Place threshold', ...
    'Position', [20 60 100 30], ...
    'Callback', @placeThresholdCallback);

% Callback function for threshold placement
    function placeThresholdCallback(~, ~)
        % Deactivate zoom to avoid warning message
        zoom off;
        
        % Get the click in the figure
        [~, yThreshold] = ginput(1);
        
        % Place the threshold in the plot
        hold on;
        plot(xlims, [yThreshold yThreshold], 'r--', 'LineWidth', 2);
        hold off;
        
        % Deactivate interaction with the plot
        set(gcf, 'Pointer', 'arrow');
        
        % Reactivate zoom
        zoom on;
        
        % Create the button for the value acquisition
        btnGetYValue = uicontrol('Style', 'pushbutton', ...
            'String', 'Get Y Value', ...
            'Position', [10 10 150 30], ...
            'Callback', @continueExecution);
    end

% Callback function to continue the function execution and get the Y coordinate
    function continueExecution(~, ~)
        % When the button is pressed the execution is continued, allowing
        % the function to return its output
        uiresume;
    end

% Wait until the Acquire Y Value button is pressed
uiwait;

% Delete the acquisition button

delete(btnGetYValue);

% Get the y coordinate as the function output
output = yThreshold;

end