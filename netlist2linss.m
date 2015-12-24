%%% NETLIST2LINSS Takes a SPICE netlist and converts it to a set of
% state-space coefficient matrices. The output is symbolic so that 
% component values/parameters can be entered to the product of the 
% function.

% Author:   Ben Holmes
% Date:     2015/12/22
% Version:  0.1
% Based on SCAM by Erik Cheever:
%       http://www.swarthmore.edu/NatSci/echeeve1/Ref/mna/MNA6.html

% TODO:
%   - Add laplace domain option
%   - Add ability to extract component values from netlist (and also
%   parameters).

function [ A, B, C, D, varargout ] = netlist2linss( filename, outputNode )

% Input argument checking
if ~ischar(filename)
    error('Filename must be string');
end

if ~ischar(outputNode)
    error('Output node must be string');
end

% Parse netlist file to a cell array of lines
arguments = parseNetlist( filename );

% Parse lines to components and meta-data
[components, num, key] = parseComponents(arguments);

% Create incidence matrices that represent connections
[Nr, Nx, Nu] = createConnections( num, components );

% Create conductance matrices and irrelevant U vector
[Gr, Gx, U] = createElements( num, components );

% Find output node from named nodes
No = strcmp([key{:}], outputNode);
if sum(No) ~= 1
    error('Too many or too few outputs');
end
No = [No zeros(1, num.voltages)];

% Combine incidence and conductance matrices to find state-space matrices.
[A, B, C, D] = formSSMatrices(Nr, Nx, Nu, No, Gr, Gx, num);

end

% FORMSSMATRICES    Create state-space matrices from incidence and
% conductance matrices. 
function [A, B, C, D] = formSSMatrices(Nr, Nx, Nu, No, Gr, Gx, num)
M = [((Nr.')*Gr*Nr + (Nx.')*Gx*Nx) Nu.';...
     Nu zeros(num.voltages)];
 
% Use symbolic inverse, no loss of accuracy
Minv = inv(M);
 
% State Coefficients
statepad = [Nx zeros(num.reactive, num.voltages)]*Minv;
A = 2*Gx*statepad*([Nx zeros(num.reactive, num.voltages)].') - eye(num.reactive);
B = 2*Gx*statepad*([zeros(num.voltages,num.nodes) eye(num.voltages)].');

% Output Coefficients
C = No*Minv*([Nx zeros(num.reactive, num.voltages)].');
D = No*Minv*([zeros(num.voltages,num.nodes) eye(num.voltages)].');

end

% CREATECONNECTIONS    Creates matrices specifying the connections between
% components (incidence matrices).
function [Nr, Nx, Nu] = createConnections( num, comps )
Nr = zeros(num.resistors,num.nodes);
Nx = zeros(num.reactive,num.nodes);
Nu = zeros(num.voltages+num.currents,num.nodes);

for n=1:num.components
    if strcmp(comps(n).type, 'resistor')
        if comps(n).node(1) ~= 0 && comps(n).node(2) ~= 0
            Nr(comps(n).num, comps(n).node(1)) = 1;
            Nr(comps(n).num, comps(n).node(2)) = -1;
        elseif comps(n).node(1) ~= 0
            Nr(comps(n).num, comps(n).node(1)) = 1;
        elseif comps(n).node(2) ~= 0
            Nr(comps(n).num, comps(n).node(2)) = 1;
        else
            error('Component with both pins attached to ground!');
        end
    elseif strcmp(comps(n).type, 'reactive')
        if comps(n).node(1) ~= 0 && comps(n).node(2) ~= 0
            Nx(comps(n).num, comps(n).node(1)) = 1;
            Nx(comps(n).num, comps(n).node(2)) = -1;
        elseif comps(n).node(1) ~= 0
            Nx(comps(n).num, comps(n).node(1)) = 1;
        elseif comps(n).node(2) ~= 0
            Nx(comps(n).num, comps(n).node(2)) = 1;
        else
            error('Component with both pins attached to ground!');
        end
    elseif(strcmp(comps(n).type, 'voltage'))
        if comps(n).node(1) ~= 0 && comps(n).node(2) ~= 0
            Nu(comps(n).num, comps(n).node(1)) = 1;
            Nu(comps(n).num, comps(n).node(2)) = -1;
        elseif comps(n).node(1) ~= 0
            Nu(comps(n).num, comps(n).node(1)) = 1;
        elseif comps(n).node(2) ~= 0
            Nu(comps(n).num, comps(n).node(2)) = 1;
        else
            error('Component with both pins attached to ground!');
        end
    end
end

end

% CREATEELEMENTS    Creates diagonal matrices containing symbolic
% representations of the components in the circuit.
function [Gr, Gx, U] = createElements( num, components )
Gr = sym(zeros(num.resistors));
Gx = sym(zeros(num.reactive));
U = sym(zeros(1,num.voltages));

syms T;

for n=1:num.components
    if strcmp(components(n).id, 'R');
        Gr(components(n).num, components(n).num) = 1/sym(components(n).name);
    elseif strcmp(components(n).id, 'C');
        Gx(components(n).num, components(n).num) = (2/T)*sym(components(n).name);
    elseif strcmp(components(n).id, 'L');
        Gx(components(n).num, components(n).num) = (T/2)*sym(components(n).name);
    elseif strcmp(components(n).id, 'V') || strcmp(components(n).id, 'I');
        U(1, components(n).num) = sym(components(n).name);        
    end
end

end

% PARSENETLIST      Parses the netlist by removing invalid lines and
% storing each line in a cell.
function [ arguments ] = parseNetlist( filename )
%PARSENETLIST Parses a netlist from a text file to a list of arguments

% Open File
id = fopen(filename,'r');

n = 1;  % Index variable for parsing arguments
while(true)
    line = fgets(id);
    
    if (line == -1)
        break;
    end
    
    % Ignore comments and commands
    % Parse only the netlist
    if (~strcmp(line(1,1),'.') &&...
            ~strcmp(line(1,1),'*') &&...
            ~strcmp(line(1,1),' ') &&...
            ~strcmp(line(1,1),'\n'))
        % Split line at whitespace
        arguments{n,:} = strsplit(line);
        
        % increment arguments index
        n = n + 1;
    end
end

end

% PARSECOMPONENTS   Parses the cleaned netlist into a component struct
% containing relevant information, the number of components, and the key
% between the netlist node names and the numeric nodes used in this file.
function [ components, num, nodeKey ] = parseComponents ( arguments )
%PARSECOMPONENTS Parse the components from a parsed netlist.

num = struct('nodes',0,'resistors',0,'reactive',0,'voltages',0,...
             'currents',0,'opamps',0,'components',0);

% Components Cell Array:
% Name | Type | ID | Component # | # Pins | Node(1:3)
components = struct('name','','type','','id','','num',0,'pins',0,...
    'value',0,'node',[0 0]);
components(length(arguments)).name = '';    % Assign enough components

% Parse component names, type and letter
for n=1:length(arguments)
    % Temporarily store the argument so that it is easier to access
    firstArg = arguments{n,1}(1);
    
    % Store the name of the component
    components(n).name = char(firstArg(1));
    
    % Store the first letter
    components(n).id = firstArg{1}(1);
    
    switch(firstArg{1}(1))
        case 'R'
            components(n).type = 'resistor';
            components(n).pins = 2; % pins
            num.resistors = num.resistors + 1;
            components(n).num = num.resistors;
        case {'L', 'C'}
            components(n).type = 'reactive';
            components(n).pins = 2; % pins
            num.reactive = num.reactive + 1;
            components(n).num = num.reactive;
        case 'V'
            components(n).type = 'voltage';
            components(n).pins = 2; % pins
            num.voltages = num.voltages + 1;
            components(n).num = num.voltages;
        case 'I'
            components(n).type = 'current';
            components(n).pins = 2; % pins
            num.currents = num.currents + 1;
            components(n).num = num.currents;
        case 'D'
            components(n).type = 'diode';
            components(n).pins = 2; % pins
            num.diodes = num.diodes + 1;
            components(n).num = num.diodes;
        case {'X','O'}
            components(n).type = 'opamp';
            components(n).pins = 3; % pins
            num.opamps = num.opamps + 1;
            components(n).num = num.opamps;
        case 'G'
            components(n).type = 'transconductance';
            components(n).pins = 4;
            num.currents = num.currents + 1;
            components(n).num = num.currents;
    end
    
    % Find value of component, position is dependent on num pins.
    components(n).value = arguments{n,1}(2 + components(n).pins);
end


% Parse node positions
nodeKey = cell(1,1);    % Numeric -> String
currentNode = 1;        % Next node to be assigned

% For each line of netlist
for n=1:length(arguments)
    % Cycle through 2nd -> 4th argument
    for m=2:5
        % Check to see if the node is valid
        if((m < 4)  || ...                             % 2+ pin device
           ((m == 4) && components(n).pins > 2) ||...  % 3+ pin device
           ((m == 5) && components(n).pins > 3))       % 4 pin device
            % Check for ground
            if(strcmp(arguments{n,1}(m),'0'))
                % Assign node to ground
                components(n).node(m-1) = 0;
            else
                % Check to see if the argument is assigned
                index = [];
                for l=1:length(nodeKey)
                    if(strcmp(nodeKey{l},arguments{n,1}(m)))
                        index = l;
                        break;
                    end
                end
                
                % If not assigned, assign
                if(isempty(index))
                    % Assign the node value
                    components(n).node(m-1) = currentNode;
                    
                    % Map the string to the value
                    nodeKey{currentNode,1} = arguments{n,1}(m);
                    
                    % Update current node value and IDs
                    currentNode = currentNode + 1;
                else
                    % If assigned, copy from other place
                    components(n).node(m-1) = index;
                end
            end
        end
    end
end

% Find number of nodes
num.nodes = currentNode-1;
num.components = length(arguments);

end