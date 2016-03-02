Given(/^I am on the ToS agreement screen$/) do
	check_element_exists("UIButton text:'Accept'")
end

#When(/^I see the '"ACE" Would Like to Access Your Contacts' alert$/) do
#	check_element_exists("label text:'\"ACE\" Would Like to Access Your Contacts'")
#end

#Then(/^I touch the 'OK' button$/) do
#	touch("view marked:'OK'") 
#end

#Then(/^I see the '"ACE" Would Like to Send You Notifications' alert$/) do
#  check_element_exists("label text:'\"ACE\" Would Like to Send You Notifications'") 
#end

#Then(/^I touch the 'OK' button$/) do
#	touch("view marked:'OK'") 
#end

#Then(/^I see the 'Allow "ACE" to access your location while you use the app\?' alert$/) do
#	check_element_exists("label text:'Allow \"ACE\" to access your location while you use the app\?'")
#end

#Then(/^I touch the 'Allow' button$/) do
#	touch("view marked:'Allow'")
#end

Then(/^I touch the 'Accept' button$/) do
	touch("UIButton index:9")
end

