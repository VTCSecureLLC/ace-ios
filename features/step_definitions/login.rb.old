
Given /^I am on the Welcome Screen$/ do
  	check_element_exists("label text:'VATRP'")
end

When /^I touch 'Video Relay Service' button$/ do
	touch("button index:0")
end

Then /^I see 'Login with Provider' screen$/ do
  	check_element_exists("label text:'Login with Provider'")
end

Then /^I turn "(.*?)" auto correct$/ do |arg1|
	set_auto_correct_type(arg1.to_sym)
end

Then /^I fill username field$/ do
	touch("UITextField index:0")
 	wait_for_keyboard
	keyboard_enter_text("peter_3")
	tap_keyboard_action_key 
end

Then /^I fill user passowrd$/ do
	touch("UITextField index:1")
	keyboard_enter_text("topsecret")
	tap_keyboard_action_key 
	tap_keyboard_action_key 
	tap_keyboard_action_key 
end

Then /^I touch Login button$/ do
	touch("button index:2")
end

Then /^I see 'Registered' text$/ do
  	check_element_exists("label text:'Registered'")
end

Then /^I'm successfully logged in$/ do
end

CORRECTION =
       {
             default: 0, # UITextAutocorrectionTypeDefault,
             off: 1,     # UITextAutocorrectionTypeNo,
             on: 2       # UITextAutocorrectionTypeYes
       }

def auto_correct_type
   query('UITextField', :autocorrectionType).first
 end

def set_auto_correct_type(name)
  if keyboard_visible?
    fail('Cannot change the auto-correct settings if the keyboard is visible')
  end

  type = CORRECTION[name]

  unless type
    raise "Unknown auto correct type: '#{name}'. Valid names: :default, :no, :yes"
  end
  query('UITextField', [{setAutocorrectionType:type}])
end
