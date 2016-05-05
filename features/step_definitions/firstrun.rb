Given(/^I am on the ToS agreement screen$/) do
	check_element_exists("UIButton text:'Accept'")
end

Then(/^I touch the 'Accept' button$/) do
	touch("button index:0")
end

