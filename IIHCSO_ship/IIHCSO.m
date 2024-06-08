% IIHCSO
%------------------------------- Reference --------------------------------
% Swarm Optimization with Intra- and Inter-Hierarchical Competition 
% for Large-Scale Berth Allocation and Crane Assignment
function G_best = IIHCSO(fun_num,c,N)
    %% Read port and berth data
    test_name = fun_num + ".xlsx";
    data = xlsread(test_name);
    %% Fixed random seed for easy debugging
    s1 = RandStream('mt19937ar', 'Seed', c); 
    RandStream.setGlobalStream(s1);
    %% Initialization
    % phi --- 0.1 --- Social factor
    phi = 0.1;
    ph = 0.5;
    H = 4;
    pr = 0.1;
    Dim = length(data(:,1));
    N = N*Dim;
    epsilon0 = Dim * 1000;
    pc = 0.8;
    cp = 0.9;
    npop = 100;
    %second part code
    ub = 3000 - data(:,3)';
    lb = ones(1,Dim);
    %third part code
    ub = [ub,data(:,4)'];
    lb = [lb,ones(1,Dim)];
    ub = repmat(ub,npop,1);
    lb = repmat(lb,npop,1);
    particles.pos = rand(npop,Dim*2).*(ub-lb) + lb ;
    particles.vel = zeros(npop,Dim*2);
    particles.fitness = zeros(npop,1);
    particles.offset = zeros(npop,1);
    % Initialize the swap sequence
    empty_sequence.vel = [];
    empty_sequence.pos = [];
    sequence = repmat(empty_sequence, npop, 1);
    clear empty_sequence;
    for i = 1:npop
        if rand <= 0.1
            sequence(i).pos = randperm(Dim);
        else
            sequence(i).pos = 1:Dim;
        end
    end
    % the hierarchy at which particle
    particles.h = zeros(npop,H);
    particles.h_index = ones(npop, 1);
    particle_swarm_hierarchy = cell(H,1);
    cnt = 0;
    tot = 1;
    Best_fitness = zeros(N,1);
    Gbest = zeros(Dim*3,1);
    for i = 1 : length(particles.pos(:,1))
        [particles.fitness(i),particles.offset(i)] = Fitness(particles.pos(i,:),sequence(i).pos,data);
        if tot == 1
            Best_fitness(tot) =  particles.fitness(i);
        else
            Best_fitness(tot) = min(Best_fitness(tot-1),particles.fitness(i));
        end
        tot = tot + 1;
    end
    
    % kappa: Number of particles in each group
    % rho: Percentage of top superior particles promoted to higher hierarchy
    kappa = 10;
    rho = 0.5;
    groups = random_grouping(1:npop, kappa);
    particle_swarm_hierarchy{1} = struct('groups', groups);
    particles.h(:, 1) = 1;
    % Construct higher hierarchies
    for j = 2:H
        % Promote top rho% superior particles from each group to the next hierarchy
        tot_promoted_particles=[];
        for group_index = 1:length(groups)
            current_group = particle_swarm_hierarchy{j-1}(group_index).groups;
            sorted_current_group = sort_fitness(current_group,particles.fitness);
            num_particles_to_promote = round(rho * length(current_group));
            promoted_particles = sorted_current_group(1:num_particles_to_promote);
            tot_promoted_particles=[tot_promoted_particles,promoted_particles];
        end
        
         % Re-divide particle swarms using random grouping strategy
         groups = random_grouping(tot_promoted_particles, kappa);
         particle_swarm_hierarchy{j} = struct('groups', groups);
        
         % record the hierarchy at which particle
         particles.h_index(tot_promoted_particles) = particles.h_index(tot_promoted_particles)+1;
         particles.h(tot_promoted_particles,particles.h_index(tot_promoted_particles)) = j;
    
    end
    %% Optimization
    while(tot <= N)
        %epsilon constaint
        if tot/N <= pc
            epsilon = epsilon0*((1 - tot/N)^cp);
        else
            epsilon = 0;
        end
        update = [];
        for j = 1 : npop
            flag_Intra = 0;
            flag_Inter = 0;
            %Calcuate the hierarchy probability
            hierarchy_prob = calcuate_hierarchy_prob(particles.h_index(j));
            hierarchy = randsrc(1,1,[particles.h(j,1:particles.h_index(j));hierarchy_prob]);
            if rand() < ph || hierarchy == H
                % Intra-hierarchical competition
                [particles.vel(j, :), particles.pos(j, :),sequence(j).pos,sequence(j).vel,flag_Intra]...
                = intra_hierarchical_competition(particles,sequence, j, hierarchy,particle_swarm_hierarchy,phi,epsilon);
            else
                % Inter-hierarchical competition
                 [particles.vel(j, :), particles.pos(j, :),sequence(j).pos,sequence(j).vel,flag_Inter]...
                = inter_hierarchical_competition(particles,sequence, j, hierarchy,particle_swarm_hierarchy,phi,epsilon);
            end
            if flag_Intra || flag_Inter
                update = [update,j];
            end
            % promote from hierarchy h to h + 1;
            if flag_Inter
                hierarchy_elements=[];
                groups = particle_swarm_hierarchy{hierarchy+1};
                hierarchy_elements = [hierarchy_elements,groups(:).groups];
                if find(hierarchy_elements == j)
                    continue;
                else
                    %promote and random grouping
                    hierarchy_elements = [hierarchy_elements,j];
                    groups = random_grouping(hierarchy_elements, kappa);
                    particle_swarm_hierarchy{hierarchy+1} = struct('groups', groups);
                    particles.h_index(j) = particles.h_index(j)+1;
                    particles.h(j,particles.h_index(j)) = hierarchy+1;
                end
            end
        end
        %limit the boundary
        reflect = find(particles.pos > ub);
        Position_old = particles.pos(reflect);
        particles.pos(reflect) = ub(reflect) - mod((particles.pos(reflect) - ub(reflect)), (ub(reflect) - lb(reflect)));
        particles.vel(reflect) = particles.pos(reflect) - Position_old;
        
        reflect = find(particles.pos < lb);
        Position_old = particles.pos(reflect);
        particles.pos(reflect) = lb(reflect) + mod((lb(reflect) - particles.pos(reflect)), (ub(reflect) - lb(reflect)));
        particles.vel(reflect) = particles.pos(reflect) - Position_old;
    
        % Evaluate and update the best ans
        for i = update
            [particles.fitness(i),particles.offset(i)] = Fitness(particles.pos(i,:),sequence(i).pos,data);
            Best_fitness(tot) = min(Best_fitness(tot-1),particles.fitness(i));
            % if Best_fitness(tot) ~= Best_fitness(tot-1)
            %     Gbest = particles.pos(i,:);
            % end
            tot = tot + 1;
            if tot > N
                break;
            end
        end
        %cnt = cnt + 1;
        % repair method
        if rand() < pr
            repair_index = floor(rand()*(npop-1)+1);
            [particles.pos(repair_index,:),particles.fitness(repair_index,:),particles.offset(repair_index,:)]...
                = repair_method(particles.pos(repair_index,:),sequence(repair_index).pos,data);
        end
        % [Best_fitness(cnt),I] = min(particles.fitness);
        % if Gbest_fitness >  Best_fitness(cnt)
        %    Gbest_fitness = Best_fitness(cnt);
        %    Gbest(1:Dim) = sequence(I).pos;
        %    Gbest(Dim+1:3*Dim) = particles.pos(I,:);
        % end
        %print
        % progress = tot / N * 100; 
        % progress_str = sprintf('progress: %.2f%%', progress); 
        % disp(progress_str);
        % disp(Best_fitness(cnt));
    end
    
    %% Draw the picture
    %plot(1:tot-1,Best_fitness(1:tot-1));
    G_best = Best_fitness(tot-1);
    file_name = "IIHCSO_"+fun_num + "("+num2str(c)+")";
    writematrix(Best_fitness,file_name);
    % disp(Gbest_fitness);
    % disp(round(Gbest));
end