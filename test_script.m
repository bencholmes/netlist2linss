%%% Test script for MATLAB function netlist2linss.

% Author:   Ben Holmes
% Date:     2015/12/22
% Version:  0.1
clear;

%% Setup simulation settings
fs = 44100;
T_num = 1/fs;

%% Get circuit state-space matrices
% Retrieve symbolic state-space matrices
[A, B, C, D] = netlist2linss('netlist.net', 'Vout');

% Add symbolic components and sampling period
syms R1 R2 R3 R4 R5 C1 C2 C3 T

% Add symbolic circuit parameters (from potentiometers).
syms t b m

%% Give components numeric values
% Resistors
R1_num = 100e3;
R2_num = (1-t)*250e3;
R3_num = t*250e3;
R4_num = b*250e3;
R5_num = m*10e3;

% Capacitors
C1_num = 250e-12;
C2_num = 100e-9;
C3_num = 47e-9;

% Parametric versions of the symbolic state space matrices
A_par = vpa(simplify(subs(A,[R1 R2 R3 R4 R5 C1 C2 C3 T],...
    [R1_num R2_num R3_num R4_num R5_num C1_num C2_num C3_num T_num])));
B_par = vpa(simplify(subs(B,[R1 R2 R3 R4 R5 C1 C2 C3 T],...
    [R1_num R2_num R3_num R4_num R5_num C1_num C2_num C3_num T_num])));
C_par = vpa(simplify(subs(C,[R1 R2 R3 R4 R5 C1 C2 C3 T],...
    [R1_num R2_num R3_num R4_num R5_num C1_num C2_num C3_num T_num])));
D_par = vpa(simplify(subs(D,[R1 R2 R3 R4 R5 C1 C2 C3 T],...
    [R1_num R2_num R3_num R4_num R5_num C1_num C2_num C3_num T_num])));


%% Print bode plots
% At different parameter settings
figure(1);
clf;
leg_list = {};
i = 1;
opts = bodeoptions();
opts.FreqUnits = 'Hz';
opts.XLim = [2 22000];
for t_num = [0.1 0.9]
    for b_num = [0.1 0.9]
        for m_num = [0.1 0.9]
            % Evaluate numeric state-space matrices
            A_num = eval(subs(A_par,[t b m],[t_num b_num m_num]));
            B_num = eval(subs(B_par,[t b m],[t_num b_num m_num]));
            C_num = eval(subs(C_par,[t b m],[t_num b_num m_num]));
            D_num = eval(subs(D_par,[t b m],[t_num b_num m_num]));
            
            % Create tone-stack system
            stack = ss(A_num, B_num, C_num, D_num, T_num);
            
            % Plot
            bodeplot(stack, opts);
            hold on;
            
            % Add legend item
            leg_list{i} = sprintf('t=%.1f, m=%.1f, b=%.1f',...
                                        [t_num m_num b_num]);
            i = i+1;
        end
    end
end
% Print legend
legend(leg_list{:});