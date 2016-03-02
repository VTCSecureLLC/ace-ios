@firstrun
Feature: Accepting first run prompts
	As a user
	I must accept the initial app prompts
	So I can begin using the app

@firstrun_ios_prompts
Scenario: Accept the iOS permissions prompts
	Given I am on the ToS agreement screen
	When I see the '"ACE" Would Like to Access Your Contacts' alert
	Then I touch the 'OK' button
	Then I see the '"ACE" Would Like to Send You Notifications' alert
	Then I touch the 'OK' button
	Then I see the 'Allow "ACE" to access your location while you use the app?' alert
	Then I touch the 'Allow' button

@firstrun_tos_accept
Scenario: Accept the ToS agreement
	Given I am on the ToS Screen
	Then I touch the 'Accept' button
	
