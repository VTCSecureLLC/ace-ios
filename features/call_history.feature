
@call_history
Feature: Running a test
  As an IOS developer
  I want to have a sample feature file
  So I can begin testing in call history part

@call_history_scenario_1
Scenario: 1. Check if the record is added on outgoing call from dialpad 
	When I'm in Keypad screen
	Then I clear the history
	Then I touch 'Edit' button
	Then I touch 'Delete all' button
	Then I go to Keypad screen 
	Then I enter number in number input field
	Then I call with this number
  	And I wait for 4 seconds
  	Then I see an alertView
  	Then I see the "Call failed" alertView
  	Then I touch 'Cancel' button
	Then I switched History screen
	Then I fix history initial rows count
	Then I repeat the steps
	Then I fix history current rows count
	Then I check the history rows count differences
