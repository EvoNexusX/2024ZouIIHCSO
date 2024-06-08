function hierarchy_prob = calcuate_hierarchy_prob(hierarchy)
    j = 1:hierarchy;
    hierarchy_prob = (hierarchy-j + 1)./sum(j);
end

