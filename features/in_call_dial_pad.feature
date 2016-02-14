
@in_call_dial_pad
Feature: Running a test
  As an IOS developer
  I want to have a sample feature file
  So I can begin testing incoming call cases

@in_call_dial_pad_scenario_1
Scenario: 1. Incoming call screen flash
	When I'm waiting for incoming call
	And I received the call
	Then I accept the call
	Then I wait for 5 seconds
	And I tap on screen
	Then I touch dialPad button
	Then I wait for 3 seconds
	And check dialPad existance on screen
