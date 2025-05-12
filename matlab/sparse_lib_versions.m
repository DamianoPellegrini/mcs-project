function sparse_lib_versions
    spparms('spumoni',2)

    load west0479
    C = west0479;
    A = C * C';
    n = size(A,1);
    b = rand(n,1);

    filename = fullfile(tempdir, 'sparse_info.txt');
    fclose(fopen(filename,'wt'));  % erase existing file
    diary(filename);

    chol(A);
    p = amd(A);
    p = colamd(A);
    x = C \ b;
    x = A \ b;

    S = C (:, 1:n-1);
    x = S \ b;

    diary off
    spparms('spumoni',0)

    hyperlink = ['<a href="matlab:edit(''' filename ''')">' filename '</a>'];
    fprintf('\n=> sparse matrix library versions (from %s):\n', hyperlink);
    fprintf(  '============================================================\n');
    
    try
        % Open the file for reading
        fileID = fopen(filename, 'r');
        if fileID == -1
            error('File could not be opened.');
        end
        
        % Read the file line by line
        while ~feof(fileID)
            line = fgets(fileID); % Get the current line
            
            % Check for the desired patterns
            if contains(line, 'version ')
                disp(['Found: ', line]); % Display the matching line
            end
            if contains(line, 'UMFPACK V')
                disp(['Found: ', line]); % Display the matching line
            end
        end
        
        % Close the file after reading
        fclose(fileID);
    catch ME
        % Handle errors gracefully
        disp(['Error: ', ME.message]);
    end
end