function [group_elements, group_index] = find_particle_group(particle_swarm_hierarchy, particle_index, h)
    groups = particle_swarm_hierarchy{h};
    
    for group_index = 1:length(groups)
        if ismember(particle_index, groups(group_index).groups)
            group_elements = groups(group_index).groups;
            return;  
        end
    end
    group_elements = []; 
    group_index = [];  
end