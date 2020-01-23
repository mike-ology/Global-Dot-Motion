# HEADER #

scenario = "GDM: test";
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
	trial_duration = 500;
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

line_graphic {
	line_color = 255, 255, 255, 255;
	line_width = 2;
} line1;

text { caption = "PLACEHOLDER"; } text_angle_degrees;
text { caption = "PLACEHOLDER"; } text_angle_radians;
text { caption = "PLACEHOLDER"; } text_radius_x;
text { caption = "PLACEHOLDER"; } text_radius_y;
text { caption = "PLACEHOLDER"; } text_radius;
text { caption = "PLACEHOLDER"; } text_coordinates;

##########
begin_pcl;

double x_origin = 0.0;
double y_origin = 0.0;
double x_away = 0; #random(-500, 500);
double y_away = 500; #random(-500, 500);
double arc_length = 10.1;

loop
	int i = 1
until
	i > 666
begin

	pic1.clear();

	# Calculate distance from centre (radius) and angle from centre
	double radius = sqrt( (x_away*x_away) + (y_away*y_away) );
	term.print_line( "Start X2: " + string( x_away) + ", Start Y2: " + string(y_away) );
	double start_angle_radians = arctan2d(  y_away - y_origin, x_away - x_origin );

	term.print_line( "Calc. start angle (rad): " + string(start_angle_radians) );
	double start_angle_degrees = ( 180 * start_angle_radians ) / pi_value;
	term.print_line( "Calc. start angle (deg): " + string(start_angle_degrees) );
	
	# Calculate next position if away point was to move in a radial direction for a pre-defined distance
	double arc_angle_degrees = ( arc_length/(pi_value * ( radius*2)) ) * 360;
	term.print_line( "Calc. arc angle: " + string(arc_angle_degrees) );
	double new_angle_degrees = arc_angle_degrees + start_angle_degrees;
	
		# Adjust angle value if out of range
		if new_angle_degrees >= 360 then 
			new_angle_degrees = new_angle_degrees - 360;
		elseif new_angle_degrees < 0 then 
			new_angle_degrees = new_angle_degrees + 360;
		end;

	double new_angle_radians = new_angle_degrees * ( pi_value/180 );
	x_away = radius * cos( new_angle_radians );
	y_away = radius * sin( new_angle_radians );
	term.print_line( "Final X2: " + string( x_away) + ", Final Y2: " + string(y_away) );
		
	line1.clear();
	line1.add_line( x_origin, y_origin, x_away, y_away );
	line1.redraw();

	pic1.add_part( line1, 0.0, 0.0 );
	pic1.add_part( box_origin, x_origin, y_origin );
	pic1.add_part( box_dot, x_away, y_away );

	term.print_line( "Degrees: " + string(round(new_angle_degrees,2)) + ", Radians: " + string( round(new_angle_radians,2) ) );
	
	text_angle_degrees.set_caption( "Current Angle (degrees): " + string(round(new_angle_degrees,2) ), true );
	text_angle_radians.set_caption( "Current Angle (radians): " + string(round(new_angle_radians,2) ), true );
	text_radius.set_caption( "Radius length (c): " + string( round(radius,2) ), true );
	text_coordinates.set_caption( "Coordinates (x1, y1, x2, y2): " + string( round(x_origin,2) ) + ", " + string( round(y_origin,2) ) + ", " + string( round(x_away,2) ) + ", " + string( round(y_away,2) ), true );
	pic1.add_part( text_angle_degrees, 0, -150 );
	pic1.add_part( text_angle_radians, 0, -200 );
	pic1.add_part( text_radius, 0, -350 );
	pic1.add_part( text_coordinates, 0, -400 );

	trial1.present();
#	int key = response_manager.last_response();
#	if key == 2 then y_away = y_away + 1;
#	elseif key == 3 then y_away = y_away - 1;
#	elseif key == 4 then x_away = x_away - 1;
#	elseif key == 5 then x_away = x_away + 1;
#	end;

	term.print_line("");

end;
