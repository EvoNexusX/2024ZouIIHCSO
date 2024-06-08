function sorted_current_group = sort_fitness(group,fitness)
    % Sort particles in a group based on their fitness

    fitness_values = fitness(group);

    % Sort the indices based on fitness values
    [~, sorted_indices] = sort(fitness_values);

    % Return sorted indices
    sorted_current_group = group(sorted_indices);
end