function data_object = dataobject_append_all(first_data_object,second_data_object)
% DATAOBJECT_APPEND_ALL
% Combines two data_object datastructures into a single structure.  Useful
% for combining multiple trials that have been loaded separately, for
% example.
%
% data_object = dataobject_append_all(first_data_object,second_data_object);
%
% USES: concatenate_structs.m, decell_structs.m

data_object = concatenate_structs(1,first_data_object,second_data_object);
% Fix improper cells
data_object.parameters = decell_struct(data_object.parameters,{'nuisance'});