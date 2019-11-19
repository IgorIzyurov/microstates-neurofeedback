function out = my_m_iscloser2(in1,in2,in3)


% keyboard;
% this function should just 'mark' events that can be put away. It should
% (for each time something is closer than 25) check which one is the
% biggest one. Then mark it and continue.

% in1 = where the motion exceeds the threshold
% in2 = the distance (I guess). of 25 (hard-coded!)
% in3 = actually the original values. Can be used to calculate the bigger
% one.

v=zeros(1,max(in1));
v(in1)=1;
sets={};
createset=true;
for i=1:numel(v)
    
    
    % was there a previous set?
    if createset==true && v(i)>0
        sets{end+1}=[];
        createset=false;
    end
    
    % was it bigger than thresh??
    if v(i)>0
        % add it to the set!
        sets{end}(end+1)=i;
    else
        createset=true;
    end
    
end

sets2={};
for i=1:numel(sets)
    sets2{i}=in3(sets{i});
end

% generate our set2...

sets_copy=sets;
sets2_copy=sets2;
thrown_away=[];
% now for each of the sets... find out if there's something next to it!
if numel(sets)>1
    
    collection_of_smallest={};
    doitagain=true;
    while doitagain
    
        mark=[];
        for i=1:numel(sets)-1
            % check if the next set is closer than 25?
            if min(sets{i+1}) - max(sets{i}) < in2+1
                % if so, figure out which set has more time points?
                if numel(sets{i}) < numel(sets{i+1})
                    mark=[mark i];
                elseif numel(sets{i+1}) < numel(sets{i})
                    mark=[mark i+1];
                elseif numel(sets{i}) == numel(sets{i+1})
                    if sum(sets2{i}) < sum(sets2{i+1})
                        mark=[mark i];
                    elseif sum(sets2{i+1}) < sum(sets2{i})
                        mark=[mark i+1];
                    elseif sum(sets2{i+1}) == sum(sets2{i})
                        mark=[mark i]; % choose left one.
                    end
                end
            end
        end
        mark=unique(mark);

        % remove the smallest MARKED set.
        % what IS the smallest set anyway?
        if numel(mark)>0
            smallest_samples=10000;
            smallest_area=10000;
            for imark=1:numel(mark)
                if numel(sets{mark(imark)})<smallest_samples
                    smallest_samples=numel(sets{mark(imark)});
                    smallest_area=sum(sets2{mark(imark)});
                    % smallest_area
                    % smallest_samples
                    smallest=mark(imark);
                elseif (numel(sets{mark(imark)})==smallest_samples)&&(sum(sets2{mark(imark)})<smallest_area)
                    % disp('here!')
                    smallest_samples=numel(sets{mark(imark)});
                    smallest_area=sum(sets2{mark(imark)});
                    smallest=mark(imark);
                end
            end

            % then remove it.
            collection_of_smallest=[collection_of_smallest sets(smallest)];
            
            
            
            log_sets = cell2mat(sets);
            log_smallest = [];
            for tls = 1:numel(sets)
                if tls == smallest
                    log_smallest = [log_smallest ones(size(sets{tls}))];
                else
                    log_smallest = [log_smallest zeros(size(sets{tls}))];
                end
            end
            
            % keyboard;
            
            log_matrix = [log_sets;log_smallest];
            disp(log_matrix);
            
            thrown_away = [thrown_away sets{smallest}];

            
            sets(smallest)=[];
            sets2(smallest)=[];
            % smallest
            
            doitagain=true;
        else
            doitagain=false;
        end

        
    end
    
    marked = sort([collection_of_smallest{:}]);
    
else
    marked = sets;
    
end
disp(thrown_away);    

% sets=sets_copy;
% sets2=sets2_copy;
% keyboard;


out=marked;
out=[sets{:}];



        
        


% out=in1*in2;