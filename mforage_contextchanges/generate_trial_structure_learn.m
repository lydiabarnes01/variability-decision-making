function [trial_struct, ca_ps, cb_ps] = generate_trial_structure_learn(ntrials, sub_config, door_probs)
%%%%%
% GENERATE_TRIAL_STRUCTURE_LEARN
% generate the trial structure for the initial learning stage
% which is essentially equivalent to generating 200 trials for each context
% if the person hasn't got it in that time, then we assume they can't do
% the experiment
%
%
% inputs - ntrials = number of trials in each condition 
% sub_config [1, n] = subject counterbalancing info loaded from
% 'sub_infos.mat'
% door_probs [1, ndoors] = set of target probabilities to be distributed
% among the doors
%
% 
% RETURNS:
% [trial_struct] = 5 x ntrials matrix
% col 1 = trial number
% col 2 = context - 1 or 2
% col 3 = target door for that trial
% col 4 = a priori p(tgt door)
% col 5 = target for that trial
% ca_ps = 1,ndoor vector of which p goes with which door for context a
% cb_ps = as above, but for context b

ndoors = length(door_probs);
ntargets = 100; % total number of targets to choose from
tntrials = ntrials*2;% this assumes only 2 contexts, the
% hardcoded 2 would need to change for experiments involving more than 2.
trial_struct = zeros(tntrials, 4); 

trial_struct(:,1) = 1:length(trial_struct(:,1)); % allocate trial number

% define whether context 1 or context 2 comes first - wayoooo
[ttrials, ~] = size(trial_struct);
trial_struct(1:(ttrials/2),2) = sub_config(3);
trial_struct((ttrials/2)+1:ttrials,2) = 3 - sub_config(3);

%%%%% consider making this a function
% now get the location/prob configuration for this session
% note that this is hard-coded!!!
x_mat = zeros(4,4); % this is context 1
a = x_mat;
a([6,7,9,16])=1;
b=x_mat;
b([3,5,11,13])=1; % this is context 2
% c=x_mat;
% c([2,8,12,14])=1;
% d=x_mat;
% d([1,4,10,15])=1;
bases = cat(3, a,b);

% create a vector that corresponds to which probability has been assigned
% to the target doors
loc_config = bases;
ca_ps = zeros(1,ndoors);
ca_ps(find(loc_config(:,:,sub_config(3)))) = door_probs(door_probs > 0); %sub_config(3) determines what configuration gets assigned as someone's A vs their B
cb_ps = zeros(1,ndoors);
cb_ps(find(loc_config(:,:,3-sub_config(3)))) = door_probs(door_probs > 0);
%%%%% end make function

% now generate the tgt locs for each trial in each context
ca_locs = get_locs_given_probs_v2(ntrials, ca_ps);
cb_locs = get_locs_given_probs_v2(ntrials, cb_ps);

% allocate to trial structure 
trial_struct(1:ntrials, 2) = sub_config(4); % sub_config(4) determines if someone gets a first or b first
trial_struct(ntrials+1:tntrials, 2) = 3 - sub_config(4); 

% allocate a target door to each trial
trial_struct(trial_struct(:,2) == 1, 3) = ca_locs;
trial_struct(trial_struct(:,2) == 1, 4) = max(ca_ps); % this needs to change if you ever have varying probabilities of the target doors
trial_struct(trial_struct(:,2) == 2, 3) = cb_locs;
trial_struct(trial_struct(:,2) == 2, 4) = max(cb_ps);

% now add which target will be presented on that trial
trial_struct(:,5) = 0;
trial_struct(trial_struct(:,2) == 1, 5) = randi(ntargets, 1, ntrials);
trial_struct(trial_struct(:,2) == 2, 5) = randi(ntargets, 1, ntrials);

end