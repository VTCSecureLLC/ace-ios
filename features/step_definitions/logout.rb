
Then /^I'm preparing to log out$/ do
	touch("button marked:'Settings'")
end

Then /^I touch 'Run assistant' button$/ do
	touch("tableViewCell text:'Run assistant'") 
end

Then /^I see an alert$/ do
	wait_for_alert
end

Then /^I see the "(.*?)" alert$/ do |arg1|
 	wait_for_alert_with_title(arg1) 
end

Then /^I touch 'Launch Wizard' button$/ do
	tap_alert_button('Launch Wizard')
end
