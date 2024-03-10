% Variability and learning: visual foraging task
% K. Garner 2018/2023
% NOTES:
%
% Dimensions calibrated for 530 mm x 300 mm ASUS VG248 monitor (with viewing distance
% of 570 mm) and refresh rate of 100 Hz
%
% If running on a different monitor, remember to set the monitor
% dimensions, eye to monitor distances, and refresh rate (lines 169-178)!!!!
%
% Psychtoolbox XXXX - Flavor: 
% Matlab XXXX
%
% Task is a visual search/foraging task. Participants seek the target which
% is randomly placed behind 1 of 16 doors. There are two contexts to learn
% within each session (2 sessions in total) - 
% with 4 doors in each display being allocated p=.25
% Rate of switches between contexts depends on stage and condition 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear all the things
sca
clear all
clear mex

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% session settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make .json files functions to be written
%%%%%% across participants
% http://bids.neuroimaging.io/bids_spec.pdf
% 2. metadata file for the experiment - to go in the highest level, include
% task, pc, matlab and psychtoolbox version, eeg system (amplifier, hardware filter, cap, placement scheme, sample
% rate), red smi system, description of file structure
%%%%%% manual things
sub.num = input('sub number? ');
sub.stage = input('stage? 1 for learning, 2 for training, 3 for test ');
sub.tpoints = input('points? '); % enter points scored so far
sub.experiment = input('experiment? 1 for ts, 2 for lt ');

experiment = sub.experiment;
if experiment == 1
    exp_code = 'ts';
elseif experiment == 2
    exp_code = 'lt';
end
sub_dir = make_sub_folders(sub.num, sub.stage, exp_code);
% sub.hand = input('left or right hand? (1 or 2)?');
% sub.sex = input('sub sex (note: not gender)? (1=male,2=female,3=inter)');
% sub.age = input('sub age?');

% get sub info for setting up counterbalancing etc
% sub infos is a matrix with the following columns
% sub num, group, learning counterbalancing (1 [XY] vs 2 [YX]), 
% training counterbalancing (1 [XY] vs 2 [YX] vs 3 [.2switch]),
% test counterbalancing (something) %%% KG: will possibly add experiment in
% here also
version   = 1; % change to update output files with new versions
stage = sub.stage;
% set randomisation seed based on sub/sess number
r_num = [num2str(sub.num) num2str(sub.stage)];
r_num = str2double(r_num);
rand('state',r_num);
randstate = rand('state');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% generate trial structure for participants and setup log files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load('sub_infos.mat'); % matrix of counterbalancing info
% KG: MFORAGE: PUT NOTES HERE RE DEFINITION
% sub_infos is an nsubs x by X column matrix with the following:
% col 1 = subject number
% col 2 = training group (1 = single switch, 2 = multi-switch)
% col 3 = colour context map
% col 4 = which context learned first
% col 5 = which context goes first in train
% col 6 = complete vs partial transfer 1st

[beh_form, beh_fid] = initiate_sub_beh_file(sub.num, sub.stage, sub_dir, exp_code); % this is the behaviour and the events log

% probabilities of target location and number of doors
load('probs_cert_world_v2.mat'); % this specifies that there are 4 doors with p=0.25 each 
door_probs   = probs_cert_world;
clear probs_cert_world 

% KG: MFORAGE: will change the below
if stage == 1 % if its initial learning
    n_practice_trials = 5;
    ntrials = 200; % KG: MFORAGE - a max I put for now but we might want to reduce this
    [trials, ca_ps, cb_ps] = generate_trial_structure_learn(ntrials, sub_infos(sub.num,:), door_probs);
elseif stage == 2
    n_practice_trials = 0;
    ntrials = 4*40; % must have whole integers for p=.7/.3
    switch_prob = .3;
    [trials, ca_ps, cb_ps] = generate_trial_structure_train(ntrials, sub_infos(sub.num,:), door_probs, switch_prob);
elseif stage == 3
    n_practice_trials = 0;
    if experiment == 1
        ntrials = 4*20;
        switch_prob = .4;
        [trials, ca_ps, cb_ps] = generate_trial_structure_tstest(ntrials, sub_infos(sub.num,:), door_probs, switch_prob);
    elseif experiment == 2
        ntrials = 4*10;
        [trials, ca_ps, cb_ps] = generate_trial_structure_lttest(ntrials, sub_infos(sub.num,:), door_probs);
    end
end

door_ps = [ca_ps; cb_ps; repmat(1/16, 1, 16)]; % create a tt x door matrix for display referencing later
ndoors = length(ca_ps);

% KG: MFORAGE: keep the below but the details may change
% add the 5 practice trials to the start of the matrix
if stage == 1
    practice = [ repmat(999, n_practice_trials, 1), ...
        repmat(3, n_practice_trials, 1), ...
        datasample(1:16, n_practice_trials)', ...
        repmat(999, n_practice_trials, 1), ...
        datasample(1:100, n_practice_trials)'];
    trials   = [practice; trials];
end

write_trials_and_params_file(sub.num, stage, exp_code, trials, ...
    door_probs, sub_infos(sub.num,:), door_ps, sub_dir);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% define colour settings for worlds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Notes - changes = defining one set of greys for all door displays
% Context cue goes around the edge and will need something defined
green = [27, 158, 119]; % context X
orange = [217, 95, 2]; % context Y
base_context_learn = [green; orange];
purple = [117, 112, 179]; % transfer A
pink = [189, 41, 138]; % transfer B
transfer_context_learn = [purple; pink];
hole = [20, 20, 20];
col   = [160 160 160]; % set up the colours of the doors
doors_closed_cols = repmat([96, 96, 96]', 1, ndoors); 
door_open_col = hole;

if stage == 1
    context_cols =  [base_context_learn(1, :); ... % we counterbalance which config is assigned to A, and which is assigned to B,
                     base_context_learn(2, :); % so we hold the colours constant, which will result in counterbalancing
                     [0, 0, 0]]; % finish with practice context cols
elseif stage == 2
    context_cols = [col; col; col];
elseif stage == 3
    if experiment == 1
       context_cols =  [base_context_learn(1, :); ... % we counterbalance which config is assigned to A, and which is assigned to B,
                        base_context_learn(2, :);
                        col]; % for when there is no trial switch

    elseif experiment == 2
    context_cols =  [transfer_context_learn(1, :); ... % we counterbalance which config is assigned to A, and which is assigned to B,
                     transfer_context_learn(2, :); % so we hold the colours constant, which will result in counterbalancing
                     [0, 0, 0]]; % finish with practice context cols

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% other considerations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

breaks = 40; % how many trials inbetween breaks?
count_blocks = 0;
button_idx = 1; % which mouse button do you wish to poll? 1 = left mouse button

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% SET UP PSYCHTOOLBOX THINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up screens and mex
KbCheck;
KbName('UnifyKeyNames');
GetSecs;
AssertOpenGL
Screen('Preference', 'SkipSyncTests', 1);
PsychDebugWindowConfiguration;
monitorXdim = 530; % in mm % KG: MFORAGE: GET FOR UNSW MATTHEWS MONITORS
monitorYdim = 300; % in mm
screens = Screen('Screens');
screenNumber = max(screens);
% screenNumber = 0;
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
back_grey = 200;
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, back_grey);
ifi = Screen('GetFlipInterval', window);
waitframes = 1;
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(windowRect);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% compute pixels for background rect
pix_per_mm = screenYpixels/monitorYdim;
display_scale = .65; % VARIABLE TO SCALE the display size
display_scale_edge = .75; % scale the context indicator
base_pix   = 180*pix_per_mm*display_scale; 
backRect   = [0 0 base_pix base_pix];
edge_pix   = 180*pix_per_mm*display_scale_edge;
edgeRect   = [0 0 edge_pix edge_pix];

% and door pixels for door rects (which are defined in draw_doors.m
nDoors     = 16;
doorPix    = 26.4*pix_per_mm*display_scale; % KG: MFORAGE: May want to change now not eyetracking
[doorRects, xPos, yPos]  = define_door_rects_v2(backRect, xCenter, yCenter, doorPix);
% define arrays for later comparison
xPos = repmat(xPos, 4, 1);
yPos = repmat(yPos', 1, 4);
r = doorPix/2; % radius is the distance from center to the edge of the door

% timing % KG: MFORAGE: timing is largely governed by participant's button
% presses, not much needs to be defined here
time.ifi = Screen('GetFlipInterval', window);
time.frames_per_sec = round(1/time.ifi);

if stage == 1
    time.context_cue_on = round(1000/time.ifi); % made arbitrarily long so it won't turn off
elseif stage == 2
    time.context_cue_on = round(1000/time.ifi); % same as above but we'll only be using the grey colour
elseif stage == 3
    if experiment == 1
        time.context_cue_on = round(.75/time.ifi);
    elseif experiment == 2
        time.context_cue_on = round(1000/time.ifi); 
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% now we're ready to run through the experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SetMouse(xCenter, yCenter, window);

% things to collect during the experiment
if stage == 1
    moves_record = [];
    moves_goal = 4;
    switch_point = 0;
end
tpoints = sub.tpoints;

for count_trials = 1:length(trials(:,1))

 
    if stage == 1 && count_trials == 1
       run_instructions(window, screenYpixels);
        KbWait;
        WaitSecs(1); 
    end

    %%%%%%% trial start settings
    idxs = 0; % refresh 'door selected' idx
    % assign tgt loc and onset time
    tgt_loc = trials(count_trials, 3);
    tgt_flag = tgt_loc; %%%% where is the target
    door_select_count = 0; % track how many they got it in
    
    % set context colours according to condition
    edge_col = context_cols(trials(count_trials, 2), :); % KG: select whether it is context 1 or 2
    if stage == 3 && experiment == 1 && count_trials > 1 % only give a context cue if there is a task switch
        if trials(count_trials-1,2) == trials(count_trials,2)
            edge_col = [96 96 96];
        else 
            edge_col = edge_col;
        end
    end
           
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% run trial
    tgt_found = 0;
   
    % draw doors and start
    draw_edge(window, edgeRect, xCenter, yCenter, edge_col, 0, time.context_cue_on); 
    draw_background(window, backRect, xCenter, yCenter, col);
    draw_doors(window, doorRects, doors_closed_cols);
    trial_start = Screen('Flip', window); % use this time to determine the time of target onset
    
    while ~any(tgt_found)
        
        door_on_flag = 0; % poll until a door has been selected
        while ~any(door_on_flag) 
            
            % poll what the mouse is doing, until a door is opened
            [didx, door_on_flag, x, y] = query_door_select(door_on_flag, doors_closed_cols, window, ...
                                                                edgeRect, backRect,  xCenter, ...
                                                                yCenter, edge_col, col, doorRects, ...
                                                                beh_fid, beh_form, ...
                                                                sub.num, sub.stage,...
                                                                count_trials, trials(count_trials,2), ...
                                                                tgt_flag, ...
                                                                xPos, yPos, ...
                                                                r, door_ps(trials(count_trials,2), :), trial_start, ...
                                                                button_idx, time.context_cue_on);

        end

        door_select_count = door_select_count + 1;
        
        % door has been selected, so open it
        while any(door_on_flag) 
           % insert a function here that opens the door (if there is no
           % target), or that breaks and moves to the draw_target_v2
           % function, if the target is at the location of the selected
           % door
            
            % didx & tgt_flag info are getting here
            [tgt_found, didx, door_on_flag] = query_open_door(trial_start, sub.num, sub.stage, ...
                                                              count_trials, trials(count_trials,2), ...
                                                              door_ps(trials(count_trials,2), :), ...
                                                              tgt_flag, window, ...
                                                              backRect, edgeRect, xCenter, yCenter, edge_col, col, ...
                                                              doorRects, doors_closed_cols, ...
                                                              door_open_col,...
                                                              didx, beh_fid, beh_form, x, y, button_idx, time.context_cue_on);

        end
    end % end of trial
    
    % KG: MFORAGE: this feedback code may move dependening on other learning stages
    if stage < 3
        feedback_on = 1;
    else 
        feedback_on = 0;
    end

    points = draw_target_v2(window, edgeRect, backRect, edge_col, col, ...,
                        doorRects, doors_closed_cols, didx, ...
                        trials(count_trials,5), xCenter, yCenter, time.context_cue_on, ...
                        trial_start, door_select_count, feedback_on, ...
                        screenYpixels);
        [~,~,buttons] = GetMouse(window);
    while buttons(button_idx)
        [~,~,buttons] = GetMouse(window);
    end
    if stage == 3 && experiment == 1
    else
        WaitSecs(0.5); % just create a small gap between target offset and onset, but not on the proactive switching task 
    end
    % of next door
    tpoints = tpoints + points;



    if count_trials == n_practice_trials

        end_practice(window, screenYpixels);
        KbWait;
        WaitSecs(1);
    end
    
    if any(mod(count_trials-n_practice_trials, breaks))
    else
        if count_trials == n_practice_trials
        else
            take_a_break(window, count_trials-n_practice_trials, ntrials*2, breaks, backRect, xCenter, yCenter, screenYpixels);
            KbWait;
        end
        WaitSecs(1);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% if in stage 1, tally up how many doors they got it in and see
%%%%%%%%%%%% if you can switch them to the next phase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if stage == 1
    moves_record = [moves_record, door_select_count];
    if count_trials > n_practice_trials + 10
        go = tally_moves(moves_record, moves_goal, count_trials); % returns a true if we should proceed as normal

        % if participant has met the accuracy criteria, then bump up their
        % trial count so that they either move to the next context, or the last
        % trials
        if ~go && trials(count_trials,2) == trials(n_practice_trials+1,2)
            %next_world_intructions; % this will be a function that tells p's they are changing worlds
            trials(count_trials+1:...
                count_trials+ntrials, 2:5) = ... % here I am just shifting the next context trials up to be next, as the person has passed this context
                trials(ntrials+n_practice_trials+1:n_practice_trials+(ntrials*2),2:5);
            switch_point = count_trials;
        elseif ~go && count_trials > switch_point + 10
            % now the person has gotten sufficient accuracy for context b
            break
        end
    end
end % end stage 1 response tally
    
end

sca;
Priority(0);
Screen('CloseAll');
ShowCursor
