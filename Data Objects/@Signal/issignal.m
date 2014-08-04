function y = issignal(x)
%ISSIGNAL Determine if an input is a Signal data object.
%
%   SYNTAX:
%   y = issignal(x)
%
%   OUTPUT:
%   y:      BOOLEAN
%           A Boolean indicating whether or not the inputted data is a Signal data object. 
%
%   INPUT:
%   x:      UNKNOWN
%           The value being tested for belonging to either the class Signal or one of its subclasses.

%% CHANGELOG
%   Written by Josh Grooms on 20140624



%% Determine if the Input is a Signal
y = isa(x, 'Signal');