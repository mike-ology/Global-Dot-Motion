# HEADER #

scenario = "GDM";
active_buttons = 3;
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
	trial_type = fixed;
	trial_duration = 20;
	picture {} pic1;
}trial1;

box {
	height = 5;
	width = 5;
	color = 0, 255, 0;
}box_dot;

trial {
	trial_type = specific_response;
	terminator_button = 1, 2;
	trial_duration = 5000;
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
}prompt_trial;

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


# Experiment parameters
int num_staircases = 2;
double num_trials = 9; # finite number of trials in staircase for now

# Stimulus parameters (coherence ignored for random stimulus)
double x_origin = 0.0;
double y_origin = 0.0;
double distance = 10.1; # used for arc-length of radial movements and radius of random movements
int aperture_radius = 200;
int dot_width = 6;
int num_dots = 50;
int num_frames = 60;
array <double> dot_coords [num_dots][num_frames][2]; # array for storing the x/y coordinates of each dot on each frame
int starting_coherence_lv = 35;
int current_coherence_lv;
array <int> radial_direction [2] = { -1, 1 };

array <double> coords_stimulus_1 [0][0][0];
array <double> coords_stimulus_2 [0][0][0];
coords_stimulus_1.assign( dot_coords );

annulus_graphic aperture_border = new annulus_graphic();
aperture_border.set_dimensions( aperture_radius*2, aperture_radius*2, aperture_radius*2+10, aperture_radius*2+10 );
aperture_border.set_color( 255, 255, 255, 255 );
aperture_border.redraw();

box_dot.set_height( dot_width );
box_dot.set_width( dot_width );

# Create an array listing whether the 1st or 2nd stimulus is coherent and shuffle the order
int num_correct_1 = int(ceil(num_trials/2));
int num_correct_2 = int(floor(num_trials/2));
array <int> arr_correct_stimulus [int(num_trials)];
arr_correct_stimulus.fill( 1, num_correct_1, 1, 0 );
arr_correct_stimulus.fill( num_correct_1 + 1, int(num_trials), 2, 0 );
arr_correct_stimulus.shuffle();

include "sub_stimulus_generation.pcl";
include "sub_stimulus_presentation.pcl";

loop
	int staircase_count = 1
until
	staircase_count > num_staircases
begin
	
	start_trial.present();
	
	current_coherence_lv = starting_coherence_lv;

	loop
		int trial_count = 1
	until
		trial_count > num_trials
	begin
		
		loop
			int stim_count = 1
		until
			stim_count > 2
		begin
		
			bool is_coherent;
			if arr_correct_stimulus[trial_count] == stim_count then
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
		prompt_trial.present();

		term.print_line(stimulus_manager.last_stimulus_data().reaction_time());
		
		int key;
		if stimulus_manager.last_stimulus_data().reaction_time()  != 0 then
			key = response_manager.last_response();
		else
			key = 0;
		end;
		
		term.print_line(key);
		
		if key == arr_correct_stimulus[trial_count] then
			feedback_text.set_caption( "CORRECT", true );
			current_coherence_lv = current_coherence_lv - 5;
		else
			feedback_text.set_caption( "INCORRECT", true );
			current_coherence_lv = current_coherence_lv + 5;
		end;
		
		if current_coherence_lv > num_dots then current_coherence_lv = num_dots
		elseif current_coherence_lv < 0 then current_coherence_lv = 0
		end;
	
		feedback_pic.present();
		wait_interval( 1000 );

		trial_count = trial_count + 1;
		
	end;

	staircase_count = staircase_count + 1;
end;


