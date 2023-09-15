function buttonBool = buttonTrueFalse()


% Create the buttons
button1 = uicontrol('Style', 'pushbutton', 'String', 'BurstCheck', ...
    'Position', [200 50 100 30], 'Callback', @pressButton1);

button2 = uicontrol('Style', 'pushbutton', 'String', 'NoBurstCheck', ...
    'Position', [350 50 100 30], 'Callback', @pressButton2);

% Variable to store result
result = [];

% Function for button 1
    function pressButton1(~, ~)
        result = true;
        continueExecution
    end

% Function for button 2
    function pressButton2(~, ~)
        result = false;
        continueExecution
    end

% Callback function to continue the function execution
    function continueExecution(~, ~)
        % When the button is pressed the execution is continued, allowing
        % the function to return its output
        uiresume;
    end

% Wait until a button is pressed
uiwait;

% Assign the boolean result to the function output
buttonBool = result;

delete(button1);
delete(button2);
end