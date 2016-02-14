
#################### 1 scenario 

When /^I'm waiting for incoming call$/ do
end

When /^I received the call$/ do  
	wait_for_elements_exist("label marked:'Incoming call'")
end

Then /^I accept the call$/ do
	touch("button marked:'Accept'") 
end

Then /^I tap on screen$/ do
	touch(nil, :offset => {:x => 50, :y => 0})  
end

Then /^I touch dialPad button$/ do
	touch("button marked:'Back'")
end

Then /^check dialPad existance on screen$/ do
	wait_for_elements_exist("UIDigitButton marked:'Sharp'")  
end


