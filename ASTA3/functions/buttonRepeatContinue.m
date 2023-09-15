function buttonBool = buttonRepeatContinue()


% Create the buttons
button1 = uicontrol('Style', 'pushbutton', 'String', 'Repeat', ...
    'Position', [500 50 100 30], 'Callback', @pressbutton1);

button2 = uicontrol('Style', 'pushbutton', 'String', 'Continue', ...
    'Position', [650 50 100 30], 'Callback', @pressbutton2);

% Variabe to store result
result = [];

% Function for button 1
    function pressbutton1(~, ~)
        result = true;
        continueExecution
    end

% Function for button 2
    function pressbutton2(~, ~)
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

% Asign the boolean value to the function output
buttonBool = result;

delete(button1);
delete(button2);
end