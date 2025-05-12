files = dir("matrices/*.mat"); % Get all .mat files in the matrices folder

matricesNum = length(files);

structArray = repmat(struct('os', string(computer('arch')), 'timestamp', "", 'exception', "None", 'matrixName', "", ...
    'matrixSize', 0, 'rows', 0, 'cols', 0, 'nonZeros', 0, ...
    'loadTime', 0, 'loadMem', 0, ...
    'decompTime', 0, 'decompMem', 0, ...
    'solveTime', 0, 'solveMem', 0, 'relativeError', 0), matricesNum, 1);

fprintf("- Processing %d matrices...\n", matricesNum);

for i = 1:matricesNum
    name = files(i).name;
    matrixName = erase(name, ".mat");
    fprintf("  - Processing matrix %d/%d: %s\n", i, matricesNum, matrixName);
    structArray(i).timestamp = datetime;
    structArray(i).matrixName = matrixName;

    try
        java.lang.System.gc();
        pause(10);

        % Read matrix
        fprintf("    1. Loading matrix...\n");
        profile clear;
        profile -memory on;
        matData = load(fullfile("matrices", name));
        profile off;

        [loadTime, loadMemAlloc, loadMemFreed] = getProfileResults();
        profile clear;

        A = matData.Problem.A;
        clear matData;
        [rows, cols] = size(A);
        nonZeros = nnz(A);
        aBytes = whos('A').bytes;

        fprintf("      ✓ Matrix loaded (%.2f ms), Memory used (%d) \n", loadTime, loadMemAlloc + loadMemFreed);
        fprintf("      ✓ Matrix properties:\n");
        fprintf("        - Matrix type: %s\n", class(A));
        fprintf("        - Matrix Memory Usage: %d\n", aBytes);
        fprintf("        - Matrix size: %d x %d\n", rows, cols);
        fprintf("        - Non-zero entries: %d\n", nonZeros);

        % Cholesky decomposition
        fprintf("    2. Performing Cholesky decomposition with AMD Ordering ...\n");

        profile clear;
        profile -memory on;
        [R, flag, perm] = chol(A, 'vector');
        profile off;

        [decompTime, decompMemAlloc, decompMemFreed] = getProfileResults();
        profile clear;

        % Check if the matrix is not symmetric positive definite
        if flag ~= 0
            structArray(i).exception = "The matrix is not symmetric positive definite";
            fprintf("      ⚠ Cholesky decomposition failed (%.2f ms), Memory used (%d)\n", decompTime, decompMemAlloc + decompMemFreed);

            clear A;
            clear perm;
            clear R;
            continue;
        end

        fprintf("      ✓ Cholesky decomposition completed (%.2f ms), Memory used (%d)\n", decompTime, decompMemAlloc + decompMemFreed);

        % Define expected solution
        xe = ones(cols, 1);
        b = A(perm, perm) * xe;

        clear A;
        clear perm;

        % Solve system
        fprintf("    3. Solving system...\n");
        profile clear;
        profile -memory on;
        x = R\(R'\b);
        profile off;

        [solveTime, solveMemAlloc, solveMemFreed] = getProfileResults();
        profile clear;

        fprintf("      ✓ System solved (%.2f ms)\n", solveTime);

        clear R;
        clear b;

        % Relative error
        fprintf("    4. Calculating relative error...\n");
        relativeError = norm(x - xe) / norm(xe);
        fprintf("      ✓ Relative error: %.2e\n", relativeError);

        clear x;
        clear xe;

        % Store results
        structArray(i).loadTime = loadTime;
        structArray(i).loadMem = loadMemAlloc + loadMemFreed;
        structArray(i).matrixSize = aBytes;
        structArray(i).rows = rows;
        structArray(i).cols = cols;
        structArray(i).nonZeros = nonZeros;
        structArray(i).decompTime = decompTime;
        structArray(i).decompMem = decompMemAlloc + decompMemFreed;
        structArray(i).solveTime = solveTime;
        structArray(i).solveMem = solveMemAlloc + solveMemFreed;
        structArray(i).relativeError = relativeError;
        structArray(i).exception = "";
    catch exception
        structArray(i).exception = replace(exception.message, newline, ' - ');
        warning("  ⚠ Error processing %s: %s\n", matrixName, exception.message);

        clear A;
        clear perm;
        clear R;
        clear b;
        clear x;
        clear xe;

        continue;
    end
    fprintf("  - Processed matrix %d/%d: %s\n", i, matricesNum, matrixName);
end

% Write results to CSV
resultFile = "bench_" + computer('arch') + ".csv";
fprintf("- Writing results to " + resultFile + "...\n");

results = struct2table(structArray);
writetable(results, resultFile);

fprintf("✓ Results saved.\n");
fprintf("✓ All matrices processed!\n");
