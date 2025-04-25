function path = astar(map, start_node, goal_node)
    % Initialize
    [rows, cols] = size(map);
    visited = false(rows, cols);
    came_from = zeros(rows, cols, 2);

    % Cost maps
    g_score = inf(rows, cols);
    f_score = inf(rows, cols);

    g_score(start_node(2), start_node(1)) = 0;
    f_score(start_node(2), start_node(1)) = heuristic(start_node, goal_node);

    % Priority queue (row, col, f_score)
    open_set = [start_node, f_score(start_node(2), start_node(1))];

    % Directions: N, S, E, W, NE, NW, SE, SW
    directions = [
         0, -1;
         0,  1;
         1,  0;
        -1,  0;
         1, -1;
        -1, -1;
         1,  1;
        -1,  1
    ];

    while ~isempty(open_set)
        % Sort by f_score
        [~, idx] = min(open_set(:,3));
        current = open_set(idx, 1:2);
        open_set(idx,:) = [];

        if all(current == goal_node)
            path = reconstruct_path(came_from, current);
            return;
        end

        visited(current(2), current(1)) = true;

        for i = 1:size(directions,1)
            neighbor = current + directions(i,:);
            x = neighbor(1);
            y = neighbor(2);

            if x < 1 || y < 1 || x > cols || y > rows
                continue;
            end
            if map(y,x) || visited(y,x)
                continue;
            end

            tentative_g = g_score(current(2), current(1)) + norm(directions(i,:));
            if tentative_g < g_score(y,x)
                came_from(y,x,:) = current;
                g_score(y,x) = tentative_g;
                f_score(y,x) = tentative_g + heuristic(neighbor, goal_node);

                if ~any(all(open_set(:,1:2) == neighbor, 2))
                    open_set = [open_set; neighbor, f_score(y,x)];
                end
            end
        end
    end

    warning('⚠️ No path found.');
    path = [];
end

function h = heuristic(a, b)
    h = norm(a - b);  % Euclidean
end

function path = reconstruct_path(came_from, current)
    path = current;
    while any(came_from(current(2), current(1), :))
        prev = squeeze(came_from(current(2), current(1), :))';
        path = [prev; path];
        current = prev;
    end
end
