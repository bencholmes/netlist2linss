%%% Test script for MATLAB function netlist2linss.

% Author:   Ben Holmes
% Date:     2015/12/22
% Version:  0.1
clear;

%% Setup simulation settings
fs = 44100;
T_num = 1/fs;

%% Get circuit state-space matrices
% Create option set and specify options;
opts = netlistoptions();
opts.UseValues = true;
opts.Ts = T_num;

% Retrieve symbolic state-space matrices
[A, B, C, D] = netlist2linss('netlist.net', 'Vout', opts);

% Add symbolic circuit parameters (from potentiometers).
syms t b l

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
        for l_num = [0.1 0.9]
            % Evaluate numeric state-space matrices
            A_num = eval(subs(A,[t b l],[t_num b_num l_num]));
            B_num = eval(subs(B,[t b l],[t_num b_num l_num]));
            C_num = eval(subs(C,[t b l],[t_num b_num l_num]));
            D_num = eval(subs(D,[t b l],[t_num b_num l_num]));
            
            % Create tone-stack system
            stack = ss(A_num, B_num, C_num, D_num, T_num);
            
            % Plot
            bodeplot(stack, opts);
            hold on;
            
            % Add legend item
            leg_list{i} = sprintf('t=%.1f, l=%.1f, b=%.1f',...
                                        [t_num l_num b_num]);
            i = i+1;
        end
    end
end
% Print legend
legend(leg_list{:});