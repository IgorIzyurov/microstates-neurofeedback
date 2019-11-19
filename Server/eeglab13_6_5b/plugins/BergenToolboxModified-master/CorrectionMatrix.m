% CorrectionMatrix.m is a function used by Bergen EEG&fMRI Toolbox for 
% EEGLAB in order to remove the fMRI artifacts on a EEG dataset recording. 
% Using this function, the pointed CURRENTSET of the EEG structure will be 
% rewriten after processing and removing the artifacts.
% 
% USAGE: 
%       [ EEG ] = CorrectionMatrix( EEG, weighting_matrix, Peak_references,
%                 onset_value, offset_value, baseline_matrix);
% 
% INPUTS:
%        EEG - is the structure loaded by the EEGLAB. This structure must
%              have a loaded dataset. This function uses internaly the 
%              dataset refered as the CURRENTSET.
% 
%        weighting_matrix - is a matrix used for correcting EEG data. This 
%                           matrix must be quadratic [ M x M ], where M is 
%                           the number of artifacts considered for
%                           correction.
% 
%        Peak_references - This matrix contains the references of each 
%                          start of the fMRI artifact for each independent
%                          EEG dataset channel. It has of
%                          [ channels  x  N�. of fMRI References found ]. 
% 
%        onset_value - is the position of the real start of each artifact,
%                      relative to the marker position. Must be expressed
%                      in data points. (e.g. -150)
% 
%        offset_value - is the position of the real end of each artifact,
%                       relative to the marker position.Must be expressed
%                      in data points. (e.g. +11200)
% 
% OUTPUT:
%        EEG - is the structure of data used by EEGLAB. This structure will
%              be rewriten with the corrected EEGdataset.
%
% See also m_rp_info, m_moving_average, m_single_motion, detectchannel,
% detectmarkers, baselinematrix

% Copyright (C) 2009 The Bergen fMRI Group
% 
% Bergen fMRI Group, Department of Biological and Medical Psychology,
% University of Bergen, Norway
% 
% Written by Emanuel Neto, 2009
% netoemanuel@gmail.com
% 
% Last Modified on 18-Jun-2009 08:07:11

function [ EEG, message ] = CorrectionMatrix( EEG, weighting_matrix, Peak_references, onset_value, offset_value)
lim1 = length(Peak_references);
lim2 = length(weighting_matrix);
residual = lim2-lim1+1;
message = '';
n_channels = EEG.nbchan;

EEG.annotations.nansamples=false(size(EEG.data));
% should already be there...
% EEG.annotations.badtemplate=false(size(EEG.data));
EEG.annotations.badcorrelation=false(size(EEG.data));

% make a copy of the EEG data (easiest = entire struct), that has been
% filtered!! > 1 Hz.

step=0;
h = waitbar(0,'Initializing');
hw=findobj(h,'Type','Patch');
set(hw,'EdgeColor',[0 1 0],'FaceColor',[0 1 0]);
total=n_channels*lim2*2;
try
    for ch = 1: n_channels+1
        if ch > n_channels
            for i = residual  : lim2
                step = step+1;
                step_srt = num2str((step/total)*100);
                waitbar(step/total,h,['Applying changes (Channel ', num2str(ch),'/',num2str(n_channels),'). Total progress: ', num2str(sprintf('%1.0f', steptosrt)),'%' ]);
                starter = fix(Peak_references(i)+onset_value);
                ender = fix(Peak_references(i)+offset_value);
                
                
                % finally, it replaces the last original data with
                % artifact-corrected data.
                EEG.data(ch-1,starter:ender) = CorrectionM(i,:);
                
            end
        else
            
            % select % filter the channel @ > 1 Hz.
            % trick 2: high-pass filter the data used to make the template
            % to avoid baseline corruption of your artifact templates.
            % for making the artifact template, use stuff from EEG2.data.

            % try
                EEG2 = pop_eegfilt(pop_select(EEG,'channel',ch), 1, 0, [], [0], 1);
            % catch
            %    keyboard;
            %    disp('filtering failed... oh well, continuing with UNfiltered data!');
            %    EEG2=EEG;
            %end
            % EEG2 has only 1 channel!!
            % maybe change the filter settings... maybe!!
            disp('filtering the data > 1 Hz (may improve artifact generation)');
            
            
            for i = residual  : lim2
                step = step+1;
                steptosrt = (step/total)*100;
                waitbar(step/total,h,['Applying changes (Channel ', num2str(ch),'/',num2str(n_channels),'). Total progress: ', num2str(sprintf('%1.0f', steptosrt)),'%' ]);
                starter = fix(Peak_references(i)+onset_value);
                ender = fix(Peak_references(i)+offset_value);
                
                % get big ender and starter..
                % keyboard;
                if i==residual
                    big_starter = starter;
                elseif i==lim2
                    big_ender = ender;
                end
                
                
                % this (first) collects EEG data in a matrix for channel
                % ch.
                A(i,:) = (EEG.data(ch,starter:ender))';
                
                % here we take things from A2 later on to make the artifact
                % template (but we do use A for checking for clipping).
                % yes, the 1 is correct!!!
                A2(i,:) = (EEG2.data(1,starter:ender))';
                if ch > 1
                    % and then replaces original data with
                    % artifact-corrected data for channel ch - 1.
                    EEG.data(ch-1,starter:ender) = CorrectionM(i,:);
                end
                
            end
            
            %%%% or here.
            %if ch==33
            %    keyboard;
            % end
            

            % fix NaN issues in HERE!
            if ch>1
                % get the vector... this is ALREADY (!!) corrected data!
                v=EEG.data(ch-1,big_starter:big_ender);

                % if nans occurred...
                if sum(isnan(v))>0

                    indices_isnan = find(isnan(v));
                    % cluster them in sets to replace them with lines.
                    sets={[indices_isnan(1)]};
                    for i=2:numel(indices_isnan)
                        if indices_isnan(i) - indices_isnan(i-1) ~=1
                            sets{end+1}=[];
                        end
                        sets{end} = [sets{end} indices_isnan(i)];
                    end
                    
                    % copy the vector...
                    v2 = v;
                    for i=1:numel(sets)
                        % replace this data in a new vector.. with a line
                        % from a to b.
                        b_value = v(sets{i}(1)-1);
                        e_value = v(sets{i}(end)+1);
                        if ~(sets{i}(1)-1) == 0 && ~((sets{i}(end)+1)>numel(v))
                            replace_step = (e_value - b_value) / (numel(sets{i}) + 1);

                            for j=1:numel(sets{i})
                                v2(sets{i}([j])) = b_value + j * replace_step;
                            end
                        end
                    end
                    
                    % log it into my annotation!!
                    EEG.annotations.nansamples(ch-1,big_starter+cell2mat(sets)-1)=true;
                    

                    v3=EEG.data(ch-1,big_starter:big_ender);
                    EEG.data(ch-1,big_starter:big_ender)=v2;
                    

                    clear v2;
                    
                    
                end
                
                
            end
            
            A;
            
   
            
            % trick 1: clipping.
            % figure out where & if it clipped somewhere (using A)...
            clipmatrix_pos=ones(size(A),class(A))*max(A(:))==A;
            clipmatrix_min=ones(size(A),class(A))*min(A(:))==A;
            
            % does it occur (positive)?
            % if clipping occurs, then probably (likely) it'll occur at the
            % same spot a bunch of times.
            % extremely unlikely that the same value occurred at the same
            % locations more than once!
            test_posclip = any(sum(clipmatrix_pos)>mean(sum(weighting_matrix'))/2);
            test_negclip = any(sum(clipmatrix_min)>mean(sum(weighting_matrix'))/2);
            clipping = or(test_posclip,test_negclip);
            
                        
%             if ch==7
%                 keyboard;
%             end
            

            if clipping
                
                
                % keyboard;
                disp('this channel clipped in some places... fixing that!');
                clipmatrix = or(clipmatrix_pos,clipmatrix_min);
                
                clipmatrix(:,find(sum(clipmatrix)>5))=true;
                
                % make sure that if a NaN occurs at one time point, all the
                % other time points would also be NaN.
                % subtraction can be done another way, but that would be
                % much more complicated; the weighting and choice of time
                % points would need to be determined for each artifact and
                % each time point. Now we can use the already-existing code
                % without too many changes.
                
                % fix A and A2 in precisely the same way...
                A(clipmatrix)=NaN;
                A2(clipmatrix)=NaN;
                

            else
                clipmatrix = zeros(size(A),class(A));
                % probably we don't use that...
            end
                

            %%%% i should probably check here if clipping occurred; replace
            %%%% those data points in the matrix with NaN. Remember where the
            %%%% NaNs are --> isNaN(A).
            %%%% also set clipping = False/True if it occurred.
            
            all_bad_correlations = [];
            for i= residual : lim2
                step = step+1;
                steptosrt = (step/total)*100;
                waitbar(step/total,h,['Applying changes (Channel ', num2str(ch),'/',num2str(n_channels),'). Total progress: ', num2str(sprintf('%1.0f', steptosrt)),'%' ]);
                
                
                % this basically does a cross-correlation check on the
                % artifact templates (to kick out ones that do not show up
                % with those motion parameters)...
                % I should probably check the weighting_matrix to take the
                %%%% NaNs into account... or do it with w.
                w=weighting_matrix(i,:)/sum(weighting_matrix(i,:));
                

                
                % and then calculates the artifact-corrected data.
                %%%% or here do something with w.
                
                % make a 'reduced' matrix:
                % this is trick 3: maybe there is in the EEG some data
                % which is quite bad. This should fix it (a bit):
                which_artifacts = find(w);
                matrix_for_cc_selection=A2(which_artifacts,:);
                matrix_for_cc_selection(:,find(sum(clipmatrix)>0))=[];
                
                
                % this is DISsimilarity (1-corrcoeff).
                % keyboard;
                anti_corr_matrix = 1-corrcoef(matrix_for_cc_selection');
                anti_corr_vector = mean(anti_corr_matrix);
                anti_corr_thresh = 2.5*median(mean(anti_corr_matrix));
                
                
                
                % check which artifacts would have a (very) bad correlation
                % w.r.t. all of the other artifacts.
                % probably NOT due to raw data.
                test_bad_correlation = anti_corr_vector > anti_corr_thresh;
                if any(test_bad_correlation)
                    
                    % if ch==n_channels
                    %     keyboard;
                    % end
                    
                    
                    all_bad_correlations = [all_bad_correlations which_artifacts(find(test_bad_correlation))];
                    
                    % fprintf('bad correlation in template ');
                    % fprintf('%d ',which_artifacts(find(test_bad_correlation)));
                    
                    
                    % examine this to see if I can do some annotation for
                    % trick 3.
                    % disp(which_artifacts(find(test_bad_correlation)));
                    which_artifacts(test_bad_correlation)=[];
                    % fprintf('still %d artifacts left for mri artifact %d.\n',numel(which_artifacts),i);
                end
                
                % do not take those for artifact template correction
                % purposes.
                w_av_template = zeros(size(w));
                w_av_template(which_artifacts)=1;
                w_av_template = w_av_template / sum(w_av_template);
                
                % here we do the final part of trick 2: taking stuff from
                % A2 (filtered data) instead of A1.
                % trick 1 was the clipping but which is done above.
                Correctionmatrix (i,:) = w_av_template*A2;
                % Correctionmatrix (i,:) = w*A;
            end
            
            all_bad_correlations=sort(unique(all_bad_correlations));
            
            
            % keyboard;
            % annotate HERE!
            % only if it makes sense w.r.t. channels and if there are any
            % bad correlations to be reported/annotated.
            if ~(ch==(n_channels+1)) && numel(all_bad_correlations)>0
                
                    
                    fprintf('channel %d, bad correlation in templates: ',ch);
                    fprintf('%d ',all_bad_correlations);
                    fprintf('.\n');
                    % keyboard;
                    % which samples??
                    
                    % this arcane formula to annotate in the trace where it
                    % went wrong with correlation between templates.
                    for j=1:numel(all_bad_correlations)
                        % keyboard;
                        begin_bad_annotation = Peak_references(1)+onset_value+(all_bad_correlations(j)-1)*size(A,2)-all_bad_correlations(j);
                        end_bad_annotation = begin_bad_annotation+size(A,2)-1;
                        EEG.annotations.badcorrelation(ch,begin_bad_annotation:end_bad_annotation)=true;
                    end
                    
                
            end
            
            


            CorrectionM(:,:) = A - Correctionmatrix;
            
            
            
        end
        
        %%%% maybe here I should do something with the data which has been
        %%%% NaNned...
        
        
        
    end
    
    
    % finally, check the weighting matrix to see which artifacts were skipped?? EEG.annotations.badtemplate=false(size(EEG.data));
    
    
    % keyboard;
    
    
    
    waitbar(1,h,'Process completed');
    close(h);
    pause(0.1);
catch
    message = [10, 'Memory index error. EEG dataset was not modifyed!', 10,10,...
        'Possible causes:',10,...
        'a) Artifact duration exceedes dataset limit. Please check if last artifacts are complete. It might be necessary to cut dataset.',10,...
        'b) Not enough memory. Please read how to handle with Large Datasets in http://www.mathworks.com/support/tech-notes/1100/1107.html',10,' '];
    warndlg(message,'Correcting Matrix','modal');
    close(h);
end



