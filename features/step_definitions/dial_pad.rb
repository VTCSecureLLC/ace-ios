
#################### 1 scenario 

Given /^I am on Dial pad screen$/ do
	check_element_exists("label text:'Enter an address'")
end

When /^I touch 'Enter an address' field$/ do
        touch("UITextField index:0")
        wait_for_keyboard	
end

Then /^I can enter letters$/ do
	keyboard_enter_text("Hello Armenia 2015")
        tap_keyboard_action_key  
end

#################### 2 scenario 

Then /^I can start enter numbers from Numpad$/ do
	touch ("button marked:'1'")  
	touch ("button marked:'2'")  
	touch ("button marked:'3'")  
	touch ("button marked:'4'")  
	touch ("button marked:'5'")  
	touch ("button marked:'6'")  
	touch ("button marked:'7'")  
	touch ("button marked:'8'")  
	touch ("button marked:'9'")  
	touch ("UIDigitButton marked:'Star'")
	touch ("button marked:'0'")  
	touch("UIDigitButton marked:'Sharp'")
end

When /^I long press the (\d+) number for '(\d+)' second$/ do |arg1, arg2|
	query = "button marked:'0'" 
	wait_for_element_exists query
	touch_hold(query, {:arg2 => arg2.to_i})
	@last_long_press_duration = arg2.to_i 
end

Then /^I should see '\+' in number input field$/ do
end

#################### 3 scenario 

When /^I enter text into the number input field$/ do
	touch ("button marked:'1'")  
	touch ("button marked:'2'")  
	touch ("button marked:'3'")  
	touch ("button marked:'4'")  
	touch ("button marked:'5'")  
	INITIAL_TEXT=query("UIAddressTextField index:'0'", :text)
end

Then /^I touch backspace button$/ do
	touch("UIButton marked:'Backspace'")
	CURRENT_TEXT=query("UIAddressTextField index:'0'", :text)
end

Then /^I compare initial and last texts$/ do
  	expect(INITIAL_TEXT[0]).not_to be == CURRENT_TEXT[0]
end

