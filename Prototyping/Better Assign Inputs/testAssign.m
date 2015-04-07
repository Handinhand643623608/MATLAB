function testAssign(x, y, z, varargin)

    fai = @() testAssignInputs;
    fat = @() testAssignTo;
    
    tai = timeit(fai);
    tat = timeit(fat);
    
    fprintf(1, 'Assign Inputs Time:     \t%d\n', tai);
    fprintf(1, 'Assign To Time:         \t%d\n', tat);


end



function testAssignInputs(x, y, z, varargin)

    inStruct = struct(...
        'AxesHandle', [],...
        'Color', [0.8 0.8 0.8],...
        'LineWidth', 5,...
        'Position', WindowPositions.CenterCenter,...
        'ShadeColor', [0.65 0.65 0.65],...
        'Size', WindowSizes.FullScreen,...
        'Title', [],...
        'Threshold', [],...
        'ThresholdColor', 'r',...
        'ThresholdLineWidth', 4,...
        'XLabel', [],...
        'YLabel', []);
    assignInputs(inStruct, varargin);


end



function testAssignTo(x, y, z, varargin)

    function Defaults
        AxesHandle = [];
        Color = [0.8, 0.8, 0.8];
        LineWidth = 5;
        Position = WindowPositions.CenterCenter;
        ShadeColor = [0.65, 0.65, 0.65];
        Size = WindowSizes.FullScreen;
        Title = [];
        Threshold = [];
        ThresholdColor = 'r';
        ThresholdLineWidth = 4;
        XLabel = [];
        YLabel = [];
    end
	assignto(@Defaults, varargin);

end