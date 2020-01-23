# HEADER #

scenario = "GDM";
active_buttons = 5;
response_logging = log_active;
no_logfile = true; # default logfile not created
response_matching = legacy_matching;
default_clear_active_stimuli = true;
default_text_color = 255, 255, 255;
default_background_color = 0, 0, 0;
default_font = "Arial";
default_font_size = 36;
default_formatted_text = true;

begin;

trial {
	trial_type = specific_response;
	terminator_button = 1, 2, 3, 4, 5;
	trial_duration = 100;
	picture {} pic1;
}trial1;

box {
	height = 5;
	width = 5;
	color = 255, 0, 0;
}box_origin;

box {
	height = 5;
	width = 5;
	color = 0, 255, 0;
}box_dot;

#####
begin_pcl;

double x_origin = 0.0;
double y_origin = 0.0;
double distance = 10.1; # used for arc-length of radial movements and radius of random movements
int aperture_radius = 200;
int dot_width = 6;
int num_dots = 50;
int num_frames = 500;
array <double> dot_coords [num_dots][num_frames][2]; # array for storing the x/y coordinates of each dot on each frame
int coherence_lv = 50;
array <int> radial_direction [2] = { -1, 1 };

annulus_graphic aperture_border = new annulus_graphic();
aperture_border.set_dimensions( aperture_radius*2, aperture_radius*2, aperture_radius*2+10, aperture_radius*2+10 );
aperture_border.set_color( 255, 255, 255, 255 );
aperture_border.redraw();

# CREATE STARTING ARRAY

loop
	int i = 1
until
	i > num_dots
begin
	
	# randomise parameters
	double origin_distance = random(1, aperture_radius);
	double origin_angle_degrees = random(0, 359);
	double origin_angle_radians = origin_angle_degrees * ( pi_value/180 );
	
	# calculate x/y coordinates given these parameters
	double x = origin_distance * cos( origin_angle_radians );
	double y = origin_distance * sin( origin_angle_radians );

	# check to see if coordinate pair overlaps previously stored pair
	bool match_found = false;

	loop
		int h = 1
	until
		h >= i
	begin
		if x >= dot_coords[h][1][1] - (dot_width/2) && x <= dot_coords[h][1][1] + (dot_width/2) &&
			y >= dot_coords[h][1][2] - (dot_width/2) && y <= dot_coords[h][1][2] + (dot_width/2) then
			match_found = true;
		else
		end;
		
		h = h + 1;
	end;
	
	if match_found == false then
		dot_coords[i][1][1] = x;
		dot_coords[i][1][2] = y;
		i = i + 1;
		# script moves on to next dot
	else
		# i does not increment and new values are generated and checks made again
	end;
	
end;

# GENERATE DOT MOVEMENTS

radial_direction.shuffle();

loop
	int f = 2
until
	f > num_frames
begin
	
	# Randomise order of dots in array
	dot_coords.shuffle();
	# Randomly choose rotation direction of coherent dots
	
# Generate coherent, radial movements
	loop
		int c = 1
	until
		c > coherence_lv
	begin
		# Get coordinates from previous frame
		double x = dot_coords[c][f-1][1];
		double y = dot_coords[c][f-1][2];

		# Calculate distance from centre (radius) and angle from centre
		double radius = sqrt( (x*x) + (y*y) );
		double angle_radians = arctan2d(  y - y_origin, x - x_origin );
		double angle_degrees = ( 180 * angle_radians ) / pi_value;
		
#		term.print_line( "f=" + string(f) + ", c=" + string(c) + ", radius=" + string(radius) );
		# Calculate next angle from origin if dot was to move in a radial direction for a pre-defined distance
		double arc_angle_degrees = ( distance/(pi_value * ( radius*2)) ) * 360;
		double new_angle_degrees = angle_degrees + ( arc_angle_degrees * radial_direction[1]);
			# Adjust angle value if out of range
			if new_angle_degrees >= 360 then new_angle_degrees = new_angle_degrees - 360;
			elseif new_angle_degrees < 0 then new_angle_degrees = new_angle_degrees + 360;
			end;
		# Convert to radians and calculate and store coordinates for frame
		double new_angle_radians = new_angle_degrees * ( pi_value/180 );
		dot_coords[c][f][1] = radius * cos( new_angle_radians );
		dot_coords[c][f][2] = radius * sin( new_angle_radians );			
		
		c = c + 1; # coherent, radial movements will never conflict and supercede random movements, so no collision checks needed
	end;
	
# Generate random movements
	loop
		int r = coherence_lv + 1;
		int generation_attempt = 1
	until
		r > num_dots
	begin
		bool coordinates_valid = false;

		# Get coordinates from previous frame
		double x = dot_coords[r][f-1][1];
		double y = dot_coords[r][f-1][2];

		# Generate random direction to move in and calculate new coordinates
		double random_angle_degrees = random( 0, 359 );
		double random_angle_radians = random_angle_degrees * ( pi_value/180 );
		x = distance * cos( random_angle_radians ) + x;
		y = distance * sin( random_angle_radians ) + y;

		# Do the new coordinates lie within the aperture?
		bool outside_aperture = false;
		
		double radius = sqrt( (x*x) + (y*y) );
		if radius < aperture_radius then
			# retain current coordinates for now
			outside_aperture = false;
		else
			# generate new coordinates to move the dot to
			loop
			until
				coordinates_valid == true
			begin
				# randomise parameters
				double origin_distance = random(1, aperture_radius);
				double origin_angle_degrees = random(0, 359);
				double origin_angle_radians = origin_angle_degrees * ( pi_value/180 );
				
				# calculate x/y coordinates given these parameters
				x = origin_distance * cos( origin_angle_radians );
				y = origin_distance * sin( origin_angle_radians );

				# check to see if coordinate pair overlaps previously stored pair
				bool match_found = false;

				loop
					int d = 1
				until
					d >= r
				begin
					if x >= dot_coords[d][f][1] - (dot_width/2) && x <= dot_coords[d][f][1] + (dot_width/2) &&
						y >= dot_coords[d][f][2] - (dot_width/2) && y <= dot_coords[d][f][2] + (dot_width/2) then
						match_found = true;
					else
					end;
					d = d + 1;
				end;
				
				if match_found == false then
					# trigger to end loop and continue
					coordinates_valid = true;
				else
					coordinates_valid = false;
				end;
			end;
		end;

		# Given the dot is within the aperture, does it overlap another dot?
		# If dot was moved to a new random location, the coordinates have already been validated
		
		if coordinates_valid == false then
			bool match_found = false;

			loop
				int d = 1
			until
				d == r # loop until we get to the current dot we are determining coordinates for
			begin
				if x >= dot_coords[d][f][1] - (dot_width/2) && x <= dot_coords[d][f][1] + (dot_width/2) &&
					y >= dot_coords[d][f][2] - (dot_width/2) && y <= dot_coords[d][f][2] + (dot_width/2) then	
					match_found = true;
				else
				end;
				d = d + 1;
			end;
			
			# if match is still false at end of previous loop, coordinates must be valid
			if match_found == false then
				coordinates_valid = true;
				generation_attempt = 0;
			else
				generation_attempt = generation_attempt + 1;
			end;

		elseif coordinates_valid == true then
			# skip this step
		end;
			
		if coordinates_valid == true || generation_attempt > 5 then
			# store location in array and move to next dot
			# will force overlapping dots if 5 attempts to generate a unique direction fail
			dot_coords[r][f][1] = x;
			dot_coords[r][f][2] = y;			
			r = r + 1;
		else
			# this loop will repeat, beginning with generating a new random direction
			# bear in mind that if the dot moves outside the aperture, it's new position
			# will always be validated before reaching this if statement
		end;
				
	end;
	f = f + 1;

end;

##############

box_dot.set_height( dot_width );
box_dot.set_width( dot_width );

loop
	int f = 1
until
	f > num_frames
begin
	
	pic1.clear();
	pic1.add_part( aperture_border, 0, 0 );
	
	loop
		int i = 1
	until
		i > num_dots
	begin
		pic1.add_part( box_dot, dot_coords[i][f][1], dot_coords[i][f][2] );
		i = i + 1;
	end;

	trial1.present();
	f = f + 1;
end;
