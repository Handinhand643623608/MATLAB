% WARN - Issues a warning message in the command line while optionally omitting a number of stack frames.
%
%	WARN is nearly identical to the MATLAB-native function WARNING and is intended to be used anywhere the native function
%	might be. It prints an orange warning message to the console window notifying the user that something unexpected, but not
%	catastrophic, was encountered during the course of code execution. 
%
%	Unlike the native WARNING, this function allows messages to be printed as if they originated from a calling function. In
%	other words, it omits one or more stack frames from the message that is displayed. In this way, it behaves like the
%	native function THROWASCALLER. It is unknown why that functionality was not included in WARNING. 
%
%	WARN does not support message identifiers or the enabling/disabling of specific messages. 
%
%	SYNTAX:
%		warn(msg)
%		warn(msg, value1, value2,...)
%		warn(n,...)
%
%	INPUTS:
%		msg:		STRING
%					A string containing the warning message to be printed in the MATLAB console. This string may contain
%					C-style escape or formatting characters that will be filled in by the VALUE argument(s). See the SPRINTF
%					documentation for supported formatting characters.
%
%	OPTIONAL INPUTS:
%		n:			INTEGER
%					The number of frames to omit from the call stack record. For example, if a warning should appear as if it
%					is originating from the calling function (i.e. "warn as caller"), then the value of this argument should
%					be 1. Higher numbers are also supported.
%					DEFAULT: 0
%
%		value:		ANYTHING
%					One or more values that will replace formatting characters in the MSG string. Substitution of values into
%					this string occur sequentially.
%					DEFAULT: []
%
%	See also: DEPRECATED, THROWASCALLER, WARNING, WASSERT

%% CHANGELOG
%	Written by Josh Grooms on 20150212



%% FUNCTION DEFINITION
function warn(n, msg, varargin)
	
	% Fill in missing inputs
	if ischar(n)
		if (nargin > 1); varargin = { msg, varargin }; end
		msg = n;
		n = 0;
	end
	
	% Format the user's message
	msg = sprintf(msg, varargin{:});
	
	% Get the call stack & omit n frames.
	fstack = dbstack('-completenames');
	fstack(1:n+1) = [];
	
	% Create a string for printing out call stack information
	finfo = [ { fstack.file }; { fstack.line }; { fstack.name }; { fstack.line } ];	
	linktemplate = '\tIn <a href="matlab: opentoline(%s,%d)">%s at %d</a>\n';
	linkstr = repmat(linktemplate, 1, length(fstack));
	linkstr = sprintf(linkstr, finfo{:});
	
	% Print the warning (uses the undocumented [\b]\b hack to display in orange)
	warnstr = fprintf(1, '\n[\bWarning: %s\n%s]\b\n', msg, linkstr);
	
end