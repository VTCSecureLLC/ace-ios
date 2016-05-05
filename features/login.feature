@login
Feature: Logging into the app
	As an ACE user
	I want to log into the app

@login_successful
Scenario: Successful login
	Given I am on the Welcome Screen
	When I touch 'Select Provider' button
	Then I see a dropdown list
	Then I select 'STL Test'
	Then I touch 'Select' button
	Then I clear input field 1
	Then I clear input field 2
	And I turn "off" auto correct
	And I fill 'username' field
	And I fill 'password' field
	Then I touch 'Login' button
 
