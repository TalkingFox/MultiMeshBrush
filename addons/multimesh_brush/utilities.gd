func _init():
    randomize();

static func is_point_inside_circle(circle_center_position: Vector3, circle_radius: float, point: Vector3) -> bool:
    # intentionally use z instead of y. We're checking if the circle overlaps
    # from an x-z 2d perspective.
    var square_distance = pow(circle_center_position.x - point.x,2) + pow(circle_center_position.z - point.z, 2);
    var is_point_inside = square_distance <= pow(circle_radius, 2);
    return is_point_inside;

static func rand_point_inside_circle(circle_center_position: Vector3, circle_radius: float) -> Vector3:
    var random_value = randf(); # returns number between 0 and 1
    var ring = circle_radius * sqrt(random_value);
    var theta = randf() * 2 * PI;
    var x = circle_center_position.x + ring * cos(theta);
    var y = circle_center_position.y;
    var z = circle_center_position.z + ring * sin(theta);
    return Vector3(x,y,z);
