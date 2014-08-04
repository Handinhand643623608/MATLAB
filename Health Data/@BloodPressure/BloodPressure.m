classdef BloodPressure < hgsetget
    %BLOODPRESSURE  A data object used to keep a record of my blood pressure readings. 
    %   
    %   SYNTAX:
    %   bpData = BloodPressure(arm, date, diastolic, heartRate, systolic, user)
    %
    %   OUTPUT:
    %   bpData:         BloodPressure Object
    %                   A blood pressure data object containing the initial readings that instantiate the object.
    %
    %   INPUTS:
    %   arm:            STRING
    %                   A string indicating on which arm (left or right) the measurement was taken.
    %
    %   date:           [NUMERIC]
    %                   A date number representing the time and date at which the measurement was taken. This is
    %                   typically inputted with the MATLAB function NOW.
    %   
    %   diastolic:      [NUMERIC]
    %                   The numeric diastolic blood pressure entered in units of mmHg.
    %
    %   heartRate:      [NUMERIC]
    %                   The numeric heart rate measurement entered in units of BPM.
    %
    %   systolic:       [NUMERIC]
    %                   The numeric systolic blood pressure entered in units of mmHg.
    %
    %   user:           STRING
    %                   A string representing the user for which the measurements are taken. This can be any string, but
    %                   might as well be the user's name.
    %
    %   Written by Josh Grooms on 20131004
    %       20131005:   Added a help & reference section.
    %       20131102:   Updated PLOT method to create plots of AM vs. PM blood pressure data.
    %       20131105:   Implemented a comment property for the object to add annotations on readings.
    
    
    properties
        Arm         % A string indicating right or left arm measurement.
        Comment     % A comment string on the current measurement.
        Date        % The date number at which a reading is entered.
        Diastolic   % Diastolic blood pressure in mmHg.
        HeartRate   % Heart rate in BPM.
        Systolic    % Systolic blood pressure in mmHg.
        User        % A string with the user's name.
    end
    
    
    %% Constructor Method
    methods
        function bpData = BloodPressure(arm, comment, date, diastolic, heartRate, systolic, user)
            %BLOODPRESSURE Generate a data object to store my blood pressure values.
            
            % Deal with missing input arguments
            if nargin < 5
                error('Blood pressure objects must be initialized with a full set of data');
            else
                bpData.Arm = {upper(arm)};
                bpData.Comment = {comment};
                bpData.Date = date;
                bpData.Diastolic = diastolic;
                bpData.HeartRate = heartRate;
                bpData.Systolic = systolic;
                bpData.User = user;
            end
        end
    end
    
    
    %% Public Methods
    methods
        varargout = plot(bpData, varargin)
    end
end
            
            
                
    
    
    