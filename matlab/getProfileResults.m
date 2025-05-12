function [execTime, memAllocated, memFreed] = getProfileResults()
% GETPROFILERESULTS Get the profiling results for the last profile session.
%
%   [execTime, memAllocated, memFreed] = getProfileResults()
%
%   Returns:
%     execTime     - Execution time in milliseconds
%     memAllocated - Memory allocated in bytes
%     memFreed     - Memory freed in bytes
%
%   Example:
%     [time, memAlloc, memFreed] = getProfileResults();

    p = profile('info');
    profileData = p.FunctionTable;

    % Extract both timing and memory information
    execTime = sum([profileData.TotalTime]) * 1000;
    memAllocated = sum([profileData.TotalMemAllocated]);
    memFreed = sum([profileData.TotalMemFreed]);
end
