# HEADER #

scenario = "GDM";
active_buttons = 3;
response_logging = log_active;
no_logfile = true; # default logfile not created
response_matching = legacy_matching;
default_clear_active_stimuli = true;
default_text_color = 255, 255, 255;
default_background_color = 127, 127, 127;
default_font = "Arial";
default_font_size = 36;
default_formatted_text = true;

begin;

trial {
	trial_type = fixed;
	trial_duration = 20;
	picture {} pic1;
}trial1;

# Loading the dot as a texture applied to a flat plane enables transparency to be maintained from the .png,
# which is a white dot on a transparent background (with alpha added to 'fade' the dot at it's edges.
# This allows the dot to 'brush' against other dots without creating flat edges of the graphic (which would
# be the case if a white dot on a grey background was used)

texture {
	filename = "tex1.png";
	preload = true;
} dot_tex;

plane {
   height = 9.0; 
	width = 9.0;
   emissive = 1.0, 1.0, 1.0; #this fully lights the plane without the need for light objects
   mesh_texture = dot_tex;
} plane1;

#^^^^^#

trial {
	trial_type = specific_response;
	terminator_button = 1, 2;
	trial_duration = forever;
	stimulus_event {
		picture {
			text {
				caption = "Were the dots moving in a circular motion\nin the first [1] or second [2] stimulus?";
			};
			x = 0; y = 0;
		};
		response_active = true;
		target_button = 1, 2;
	};
}response_trial;

picture {
	text {
		caption = "FEEDBACK PLACEHOLDER";
	}feedback_text;
	x = 0; y = 0;
}feedback_pic;
	
trial {
	trial_type = specific_response;
	terminator_button = 3;
	trial_duration = forever;
	stimulus_event {
		picture {
			text {
				caption = "Press SPACE to initiate the next set of trials.";
			};
			x = 0; y = 0;
		};
	};
}start_trial;
	

#####
begin_pcl;

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# User Setup

# User parameters for screen dimension
# Enter desired screen dimensions. Screens not set to these dimensions may be scaled
double req_screen_x = 1920.0;
double req_screen_y = 1080.0;
bool attempt_scaling_procedure = true;

# User parameters for logfile generation
# If filename already exists, a new file is created with an appended number
# Logfile may be optionally created on local disk (when running from network location)
string local_path = "C:/Presentation Output/Global Dot Motion 2020/";
string filename_prefix = "GDM - Participant ";
bool use_local_save = parameter_manager.get_bool( "Use Local Save", false );

#######################

# Load PCL code and subroutines from other files
include "sub_generate_prompt.pcl";
include "sub_screen_scaling.pcl";
include "sub_logfile_saving.pcl";

# Run start-up subroutines
if attempt_scaling_procedure == false then screen_check() else end;
create_logfile();


# Setup complete
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Experiment parameters
int n_down = parameter_manager.get_int( "n_down", 2 );
int n_up = parameter_manager.get_int( "n_up", 1 );

# Staircase movements - add more values here to adjust the step-size behaviour. Every second step should alternate between increases and decreases
# value 1 = size of each step at this level, value 2 = affects whether an increase or decrease occurs (also used to check whether currently stepping up or down)
array <int> array_staircase [8][2] = { { 16, -1}, { 8, 1}, {4, -1}, {2, 1}, {1, -1}, {1, 1}, {1, -1}, {1, 1} };

int num_staircases = parameter_manager.get_int( "num_staircases", 2 ); # How many individual staircases should be presented?
bool show_aperture_border = parameter_manager.get_bool( "show_aperture_border", false );;

# Stimulus parameters (coherence ignored for random stimulus)
double x_origin = 0.0;
double y_origin = 0.0;
double distance = parameter_manager.get_double( "dot_distance", 10.2 ); # used for arc-length of radial movements and radius of random movements. 5.4deg/sec in Grinter paper - current value based off a 60Hz screen
int aperture_radius = parameter_manager.get_int( "aperture_radius", 205 ); # 6.48deg in Grinter paper.
int dot_width = 9; # used to attempt to prevent overlaps with other dots - does not actually affect the pre-made dot image used in the experiment.
int num_dots = parameter_manager.get_int( "num_dots", 50 ); # 50 used in Grinter paper
int num_frames = parameter_manager.get_int( "num_frames", 26 ); #426ms in Grinter paper. Assuming 60Hz, 1 frame = 16.7ms. 426/16.7 = 25.55

array <double> dot_coords [num_dots][num_frames][2]; # array for storing the x/y coordinates of each dot on each frame
array <int> radial_direction [2] = { -1, 1 };

array <double> coords_stimulus_1 [0][0][0];
array <double> coords_stimulus_2 [0][0][0];
coords_stimulus_1.assign( dot_coords );

annulus_graphic aperture_border = new annulus_graphic();
aperture_border.set_dimensions( aperture_radius*2, aperture_radius*2, aperture_radius*2+10, aperture_radius*2+10 );
aperture_border.set_color( 255, 255, 255, 255 );
aperture_border.redraw();

# Response Data
int starting_coherence_lv = parameter_manager.get_int( "starting_coherence_level", 35 );
int current_coherence_lv;
int s;
int trial_count;
bool first_correct;
bool trial_correct;
bool level_change;
array <string> array_outcomes [0][2];

# Preload subroutines
include "sub_stimulus_generation.pcl";
include "sub_stimulus_presentation.pcl";

#---- Setup Logfile
# Logfile Header	
log.print("Global Dot Motion Task\n");
log.print("Participant ");
log.print( participant );
log.print("\n");
log.print( date_time() );
log.print("\n");
log.print( "Scale factor: " + string( scale_factor ) );
log.print( " - Note: scaling is only applied to message screens and not to stimuli in this experiment\n" );
log.print( "Staircase is " + string(n_down) + "-down/" + string(n_up) + "-up" );
log.print("\n\n");

# Logfile Table
log.print("Str.Cs.\t");
log.print("Trial\t");
log.print("SC.Pos.\t" ); 
log.print("Coh.Lv.\t"); 
log.print("Coh.Ps.\t");
log.print("Rspns.\t");
log.print("Crrct.\t");
log.print("Outcome\t" );
log.print("\n");

loop
	int staircase_count = 1
until
	staircase_count > num_staircases
begin
	
	start_trial.present();
	
	current_coherence_lv = starting_coherence_lv;
	s = 1;
	trial_count = 1;
	first_correct = false;
	array_outcomes.resize(0);

	loop
	until
		s > array_staircase.count()
	begin
		
		# randomly pick whether the first or second stimulus is coherent
		int coherent_stim = random( 1, 2 );
		
		loop
			int stim_count = 1
		until
			stim_count > 2
		begin
		
			bool is_coherent;
			if coherent_stim == stim_count then
				is_coherent = true;
			else
				is_coherent = false;
			end;

			GDM_generation( is_coherent );
			
			if stim_count == 1 then	coords_stimulus_1.assign( dot_coords )
			elseif stim_count == 2 then coords_stimulus_2.assign( dot_coords )
			end;
		
			stim_count = stim_count + 1;
		end;
		
		# present both stimuli and participant response

		stimulus_presentation(1);
		
		pic1.clear();
		pic1.present();
		wait_interval( 1000 );
		
		stimulus_presentation(2);
		
		pic1.clear();
		pic1.present();
		wait_interval( 1000 );
		
		# adjust coherence based on performance
		response_trial.present();

		int key;
		if stimulus_manager.last_stimulus_data().reaction_time()  != 0 then
			key = response_manager.last_response();
		else
			key = 0;
		end;
			
		if key == coherent_stim then
			feedback_text.set_caption( "CORRECT", true );
			trial_correct = true;
		else
			feedback_text.set_caption( "INCORRECT", true );
			trial_correct = false;
		end;
		
		#---- Determine if a level change has occurred
		
		# Special Case: If no correct trial has been registered in this loop yet, cannot be a reversal and trial repeats
		if first_correct == false then
			if trial_correct == true then
				first_correct = true;
			else
				# do nothing and restart loop immediately
				continue;
			end;
		elseif first_correct == true then
			# proceed with main part of check loop
		end;
		
		# Main checks for level change
		level_change = false; # assume no change unless detected below
		
		if trial_correct == true && s == 1 then
			# immediately change level prior to first reversal
			level_change = true;
			array_outcomes.add( { "CORRECT", "STEP DOWN" } );
		
		elseif trial_correct == true && s != 1 then
			if n_down == 1 then
				# STEP DOWN - no need to check previous trials 
				level_change = true;
				array_outcomes.add( { "CORRECT", "STEP DOWN" } );
			elseif n_down - 1 > array_outcomes.count() then
				# STEP SAME - can't possibly be enough correct trials in a row to initiate a step change
				level_change = false;
				array_outcomes.add( { "CORRECT", "STEP SAME" } );
			else
				# run loop check if previous trial responses indicate a change is necessary
				loop
					int i = 1
				until
					i > n_down - 1
				begin
					if array_outcomes[array_outcomes.count() - (i-1)][1] == "CORRECT" && array_outcomes[array_outcomes.count() - (i-1)][2] == "STEP SAME" then
						level_change = true;
						array_outcomes.add( { "CORRECT", "STEP DOWN" } );
						# STEP DOWN
						i = i + 1; # continue checking previous trials
					else
						level_change = false;
						array_outcomes.add( { "CORRECT", "STEP SAME" } );
						# STEP SAME
						break; # if finding an instance of prior trial without the same level, set level_change to false and end loop
					end;
				end;
			end;
			
		elseif trial_correct == false then
			if n_up == 1 then
				# STEP UP - no need to check previous trials 
				level_change = true;
				array_outcomes.add( { "INCORRECT", "STEP UP" } );
			elseif n_up - 1 > array_outcomes.count() then 
				# STEP SAME - can't possibly be enough correct trials in a row to initiate a step change
				level_change = false;
				array_outcomes.add( { "INCORRECT", "STEP SAME" } );
			else
				# run loop check if previous trial responses indicate a change is necessary
				loop
					int i = 1
				until
					i > n_up - 1 ##|| i > array_outcomes.count() # loop will not run or be needed if n_up == 1 || loop cannot check trials that do not exist!
				begin
					if array_outcomes[array_outcomes.count() - (i-1)][1] == "INCORRECT" && array_outcomes[array_outcomes.count() - (i-1)][2] == "STEP SAME" then
						level_change = true;
						array_outcomes.add( { "INCORRECT", "STEP UP" } );
						# STEP UP
						i = i + 1; # continue checking previous trials
					else
						level_change = false;
						array_outcomes.add( { "INCORRECT", "STEP SAME" } );
						# STEP SAME
						break; # if finding an instance of prior trial without the same level, set level_change to false and end loop
					end;
				end;
			end;
		else
			exit("Could not determine if a level change occurred or not");
		end;
				
		#---- LOG WHAT HAS HAPPENED ON THIS TRIAL
		
		log.print( staircase_count ); log.print("\t");
		log.print( trial_count); log.print("\t");
		log.print( s ); log.print("\t");
		log.print( current_coherence_lv ); log.print("\t");
		log.print( coherent_stim ); log.print("\t");
		log.print( key ); log.print("\t");
		log.print( trial_correct ); log.print("\t");
		log.print( array_outcomes[trial_count][2]); log.print("\t");
		log.print("\n");
		
		#---- Determine if a reversal is necessary
		
		if level_change == true then
			if ( array_staircase[s][2] == -1 && trial_correct == true ) || ( array_staircase[s][2] == 1 && trial_correct == false ) then
				# no reversal
			else
				# reversal - move to next position on staircase
				s = s + 1;
			end;
		else
			# no level change
		end;

		#---- SET UP PARAMETERS FOR NEXT TRIAL

		if level_change == true && s <= array_staircase.count() then
			# skip this if a level change is not required, and also
			# skip this if we have run out of positions on the staircase, loop will finish when it reaches the end
			current_coherence_lv = current_coherence_lv + array_staircase[s][1] * array_staircase[s][2];

			if current_coherence_lv > num_dots then current_coherence_lv = num_dots
			elseif current_coherence_lv < 1 then current_coherence_lv = 1
			end;

		else
			# leave level at previous value
		end;

		trial_count = trial_count + 1;	

		feedback_pic.present();
		wait_interval( 1000 );

		
	end;

	staircase_count = staircase_count + 1;
end;

#########################################################
# Subroutine to copy logfile back to the default location
# Requires the strings associated with:
#	[1] the local file path
#	[2] the file name
#	[3] if save operation is to be performed ("YES"/"NO") 

bool copy_success = sub_save_to_network( local_path, filename, use_local_save );	

if copy_success == true then
	prompt_message.set_caption( "End of experiment! Thank you!\n\nPlease notify the experimenter.\n\n<font color = '0,255,0'>LOGFILE WAS SAVED TO DEFAULT LOCATION</font>", true )
elseif copy_success == false then
	prompt_message.set_caption( "End of experiment! Thank you!\n\nPlease notify the experimenter.\n\n<font color = '255,0,0'>LOGFILE WAS SAVED TO:\n</font>" + local_path, true );
else
end;

#########################################################
create_new_prompt( 1 );

mid_button_text.set_caption( "CLOSE PROGRAM [" + response_manager.button_name( 1, false, true ) + "]", true );

prompt_trial.present();
