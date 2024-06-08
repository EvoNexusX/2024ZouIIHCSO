function res = subtract(sequence1, sequence2)
    res = [];
    for i=1:length(sequence1)
        for j=i:length(sequence1)
            if sequence2(i) == sequence1(j) && i ~= j
                res = [res, [i; j]];
                sequence1 = swap(sequence1, res(:, end));
            end
        end
    end
end