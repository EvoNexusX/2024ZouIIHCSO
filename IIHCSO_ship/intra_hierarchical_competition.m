function [new_velocity, new_position, new_sequence_pos,new_sequence_vel, flag] = intra_hierarchical_competition(particles,sequence, i, hierarchy,particle_swarm_hierarchy,phi,epsilon)
    [group_particles,~] = find_particle_group(particle_swarm_hierarchy,i,hierarchy);
    group_mean_position = mean(particles.pos(group_particles, :));
    
    random_index = randperm(length(group_particles), 1);
    competitor_index = group_particles(random_index);
    
    Dim = length(particles.pos(1,:));
    if (particles.fitness(i) >= particles.fitness(competitor_index))&&...
        (particles.offset(competitor_index)<=epsilon || ...
        particles.offset(competitor_index) <= particles.offset(i))
        % Update velocity and position
        R1 = rand(1,Dim);
        R2 = rand(1,Dim);
        R3 = rand(1,Dim);
        new_velocity = R1.*particles.vel(i, :) + R2.*(particles.pos(competitor_index, :)-particles.pos(i, :))... 
        + phi.*R3.*(group_mean_position-particles.pos(i, :));
        new_position = particles.pos(i, :) + new_velocity;
        
        % update sequence
        temp = [];
        r1 = floor(rand()*10);
        r2 = floor(rand()*10);
        if r1 && ~isempty(sequence(i).vel)
            temp = sequence(i).vel;
            temp = temp(:, 1:min(r1,length(temp(1,:))) );
        end
        velMinus = subtract(sequence(i).pos,sequence(competitor_index).pos);
        if r2 && ~isempty(velMinus)
           temp = [temp,velMinus(:,1:min(r2,length(velMinus(1,:))))];
        end
        
        new_sequence_vel = temp;
        new_sequence_pos = sequence(i).pos;
        if ~isempty(temp)
            for j = 1 :length(temp(1,:))
                new_sequence_pos = swap(new_sequence_pos,temp(:,j));
            end
        end
        flag = 1;
    else
        % No update if particle is inferior
        new_velocity = particles.vel(i, :);
        new_position = particles.pos(i, :);
        new_sequence_pos = sequence(i).pos;
        new_sequence_vel = sequence(i).vel;
        flag = 0;
    end
end