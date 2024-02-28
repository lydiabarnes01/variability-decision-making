function [emr_cal, didx, startTime, door_on_flag] = do_doors_for_no_eye_gaze_v3_wFix(doorClosedCol, window, backRect,  xCenter, yCenter, backCol, doorRects, ...
    REDm_info, trialStart, fid, fform, sub, sess, trial_n, cond, tgt_flag, startTime, xPos, yPos, r, fixCol, fixRect, maxFixDiam, door_probs, emr_cal, ...
    trg_id, ioObj, port_address, trg_fid, trg_frm)

% this code will check (every 10ms) whether the eyegaze is on a given door
% if so, return the idx of the door and the time that the gaze
% landed on the door,
% if the gaze is on a door for 5 consecutive recorded examples (i.e. 50 ms),
% then turn off the loop that invokes this function
start_test   = 0; % this means that a door has not yet been selected, the remainder of the function will run until this test has been passed
collect_idxs = []; % a minimum of 50 msec gaze required to open a door
sample_n = 20; % number of samples to collect before checking whether 
thresh_n = 15; % the number of samples for which a door had to be looked at 
% get refrsh rate
ifi = Screen('GetFlipInterval', window);
waitframes = 1;


    % draw the open door
    %       frames_on = .02/ifi; % ~20 ms
    tmp_door_cols          = doorClosedCol;

    % change door colour    
    draw_background(window, backRect, xCenter, yCenter, backCol);
    draw_doors(window, doorRects, tmp_door_cols);
    Screen('FillOval', window, fixCol, fixRect, maxFixDiam)
    Screen('DrawingFinished', window);
    vbl = Screen('Flip', window);
    % send trigger to say door closed
    send_trigger(trg_id, sub, sess, trial_n, cond, vbl, ioObj, port_address, trg_fid, trg_frm); 


while ~any(start_test)
        

    [x,y,t] = SMI_Redm_GetGazeCoords(REDm_info); % where is fixation?
    

 
    if ~isempty(x) % if there is a sample to use      
        
        fixPix   = 5*3.6;
        fixBase  = [0, 0, fixPix, fixPix];
        %fixRects = CenterRectOnPointd(fixBase, xCenter-.5*fixPix, yCenter-.5*fixPix);
        eyefixRects = CenterRectOnPointd(fixBase, x, y);
        
        draw_background(window, backRect, xCenter, yCenter, backCol);
        draw_doors(window, doorRects, tmp_door_cols);
        Screen('FillOval', window, fixCol, fixRect, maxFixDiam);
        Screen('FillOval', window, [0 255 0], eyefixRects);
        Screen('DrawingFinished', window);
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi); % limit samples to flip rate

        dur   = GetSecs - startTime;
        timer = GetSecs - trialStart;
        
        door_check = doorSample(xPos, yPos, x, y); % returns distance of coordinates from all door centres
        if isempty(collect_idxs)
            collect_idxs = door_check;
        else
            collect_idxs = cat(3, door_check, collect_idxs);
        end
        
        % get an idx if any
        didx = find(door_check < r);
        curr_door_prob = door_probs(didx);
        if isempty(didx)
            didx = 0;
            curr_door_prob = 0;
        end
        % send current info to output file
        fprintf(fid, fform, sub, sess, trial_n, cond, timer, 0, didx, curr_door_prob, tgt_flag, dur, x, y);
        % 'sub','sess','t','cond','onset','open_d','door','door_p','tgt_door','depress_dur','x','y'
        % have we met criteria to say a door has been selected?
        if size(collect_idxs,3) > sample_n % check that all the collected door indexes are the same value and that it has been the same for 50 ms worth of samples
            test = collect_idxs(:,:,1:sample_n);
            % does the time spent within the radius of one door centre meet
            % criteria?
            test = test < r; % get a logical array
            test = sum(test,3); % sum over array
            
            if any(find(test > thresh_n))
               
                didx = find(test > thresh_n);
                door_on_flag = 1;
                startTime    = GetSecs;
                SMI_Redm_SendMessage(sprintf('%.3f_Door_%d_init', t, didx));
                start_test   = 1;                  
            end
        end
    end
    
    % need to run an emergency eyetrack?
    [key_down, ~, key_code] = KbCheck;
    if KbName(KbName(find(key_code))) == KbName('x')
        emr_cal = 1;
        didx = NaN;
        startTime = NaN; 
        door_on_flag = NaN;
        break
    end  
    
    
    

    
end
end



  