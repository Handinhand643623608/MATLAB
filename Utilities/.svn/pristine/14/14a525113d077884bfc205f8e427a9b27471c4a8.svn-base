function [x,y,h] = draw_layout_new(adj,labels,node_t,x,y,type,arrow_size)
% DRAW_LAYOUT Draws a layout for a graph
%
%  [<X, Y>] = DRAW_LAYOUT(ADJ, <LABELS, ISBOX, X, Y>)
%
% Inputs :
%   ADJ     - Adjacency matrix (source, sink)
%   LABELS  - Cell array containing labels <Default : '1':'N'>
%   ISBOX   - 1 if node is a box, 0 if oval <Default : zeros>
%   X, Y    - Coordinates of nodes on the unit square <Default : calls make_layout>
%   type    - 'ch' for coherence network; 'gc' for Granger causality network
%   arrow_size - 4x1 vector containing [max size, top cutoff, min size,
%                bottom cutoff]
%
% Outputs :
%	X, Y    - Coordinates of nodes on the unit square
%   H       - Object handles
%
% Example :
%   [x, y] = draw_layout([0 1;0 0], {'Hidden','Visible'}, [1 0]');
%
% See also: MAKE_LAYOUT.

% Copyright (c) 2006-2007 BSMART group.
% by Richard Cui
% $Revision: 0.2$ $Date: 14-Sep-2007 10:52:22$
% SHIS UT-Houston, Houston, TX 77030, USA.
%
% Change History :
% Date		Time		Prog	Note
% 13-Apr-2000	 9:06 PM	ATC	Created under MATLAB 5.3.1.29215a (R11.1)

% ATC = Ali Taylan Cemgil,
% SNN - University of Nijmegen, Department of Medical Physics and Biophysics
% e-mail : cemgil@mbfys.kun.nl
%
% Modified Garth Thompson 2010 July 23
%
% Requires: BSMART
%

head_thickness = 5;

%figure;imagesc(adj);figure;

grey = [0.5 0.5 0.5];

thicknesses = adj;
% Convert thicknesses to line size specification
% Convert thicknesses to positive
arrow_size = arrow_size - min(min(thicknesses));
thicknesses = thicknesses - min(min(thicknesses));
% Convert thicknesses
thicknesses = (thicknesses - arrow_size(4))*((arrow_size(1) - arrow_size(3))/(arrow_size(2) - arrow_size(4))) + arrow_size(3);

% Convert adj to 0's and 1's
adj = adj ~= 0;
adj = double(adj);

N = size(adj,1);
if nargin<2,
    %  labels = cellstr(char(zeros(N,1)+double('+')));
    labels = cellstr(int2str((1:N)'));
end;

if nargin<3,
    node_t = zeros(N,1);
    %  node_t = rand(N,1) > 0.5;
else
    node_t = node_t(:);
end;

axis([0 1 0 1]);
set(gca,'XTick',[],'YTick',[],'box','on');
% axis('square');
%colormap(flipud(gray));

if nargin<4,
    [x y] = make_layout(adj);
end;

idx1 = find(node_t==0); wd1=[];
if ~isempty(idx1),
    [h1 wd1] = textoval(x(idx1), y(idx1), labels(idx1));
    set(h1,'LineStyle',':');
end;

idx2 = find(node_t~=0); wd2 = [];
if ~isempty(idx2),
    % [h2 wd2] = textbox(x(idx2), y(idx2), labels(idx2));
    [h2 wd2] = textoval(x(idx2), y(idx2), labels(idx2));
end;

wd = zeros(size(wd1,1)+size(wd2,1),2);
if ~isempty(idx1), wd(idx1, :) = wd1;  end;
if ~isempty(idx2), wd(idx2, :) = wd2; end;

for i=1:N,
    j = find(adj(i,:)==1);
    for k=j,
        if x(k)-x(i)==0,
            sign = 1;
            if y(i)>y(k), alpha = -pi/2; else alpha = pi/2; end;
        else
            alpha = atan((y(k)-y(i))/(x(k)-x(i)));
            if x(i)<x(k), sign = 1; else sign = -1; end;
        end;
        dy1 = sign.*wd(i,2).*sin(alpha);   dx1 = sign.*wd(i,1).*cos(alpha);
        dy2 = sign.*wd(k,2).*sin(alpha);   dx2 = sign.*wd(k,1).*cos(alpha);
        if adj(k,i)==0, % if directed edge
            % Plot the arrow if it is thick enough to register
            if thicknesses(i,k) >= 1
                ha = arrow([x(i)+dx1 y(i)+dy1],[x(k)-dx2 y(k)-dy2]);
                arrow(ha,'Length',thicknesses(i,k)*head_thickness,'Width',thicknesses(i,k));
            end
        else
            switch type
                case 'ch'
                    if max([thicknesses(i,k) thicknesses(k,i)]) > 1
                        line([x(i)+dx1 x(k)-dx2],[y(i)+dy1 y(k)-dy2],'color','k','LineWidth',max([thicknesses(i,k) thicknesses(k,i)]));
                    end
                case 'gc'
                    
                    % If A > B plot A in grey, then plot B in black next
                    if thicknesses(k,i) > thicknesses(i,k)
                        
                        if thicknesses(i,k) >= 1
                            ha = arrow([x(k)-dx2 y(k)-dy2],[x(i)+dx1 y(i)+dy1]);
                            arrow(ha,'Length',thicknesses(k,i)*head_thickness,'Width',thicknesses(k,i),'EdgeColor',grey,'FaceColor',grey);

                            ha = arrow([x(i)+dx1 y(i)+dy1],[x(k)-dx2 y(k)-dy2]);
                            arrow(ha,'Length',thicknesses(i,k)*head_thickness,'Width',thicknesses(i,k));
                        else
                            if thicknesses(k,i) >= 1
                                ha = arrow([x(k)-dx2 y(k)-dy2],[x(i)+dx1 y(i)+dy1]);
                                arrow(ha,'Length',thicknesses(k,i)*head_thickness,'Width',thicknesses(k,i));
                            end
                        end
                        
                    % Otherwise do opposite order
                    else
                        
                        if thicknesses(k,i) >= 1
                            ha = arrow([x(i)+dx1 y(i)+dy1],[x(k)-dx2 y(k)-dy2]);
                            arrow(ha,'Length',thicknesses(i,k)*head_thickness,'Width',thicknesses(i,k),'EdgeColor',grey,'FaceColor',grey);

                            ha = arrow([x(k)-dx2 y(k)-dy2],[x(i)+dx1 y(i)+dy1]);
                            arrow(ha,'Length',thicknesses(k,i)*head_thickness,'Width',thicknesses(k,i));
                        else
                            if thicknesses(i,k) >= 1
                                ha = arrow([x(i)+dx1 y(i)+dy1],[x(k)-dx2 y(k)-dy2]);
                                arrow(ha,'Length',thicknesses(i,k)*head_thickness,'Width',thicknesses(i,k));
                            end
                        end
                    end
                    
            end%switch
            %disp(['k:' num2str(k) ' i:' num2str(i)]);
            adj(k,i)=-1; % Prevent drawing lines twice
        end
    end
end

if nargout>2,
    h = zeros(length(wd),2);
    if ~isempty(idx1),
        h(idx1,:) = h1;
    end;
    if ~isempty(idx2),
        h(idx2,:) = h2;
    end;
end;

% [EOF]