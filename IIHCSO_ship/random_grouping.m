function groups = random_grouping(tgroup, kappa)
    NP = length(tgroup);
    % Randomly divide the population into groups of size kappa
    num_groups = ceil(NP / kappa);
    groups = cell(1, num_groups);
    % Shuffle the indices to create random groups
    shuffled_indices = randperm(NP);

    % Assign particles to groups
    for i = 1:num_groups
        group_indices = shuffled_indices((i-1)*kappa + 1 : min(i*kappa,NP));
        groups{i} = tgroup(group_indices);
    end
end