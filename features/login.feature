
@login
Feature: Running a test
  As an IOS developer
  I want to have a sample feature file
  So I can begin testing login process

@login_scenario_1
Scenario: Start testing login process
  Given I am on the Welcome Screen
  When I touch 'Video Relay Service' button
  Then I see 'Login with Provider' screen
  Then I clear input field number 1
  Then I clear input field number 2
  And I turn "off" auto correct
  And I fill username field
  And I fill user passowrd
  Then I touch Login button
  And I wait for 5 seconds
  And I see 'Registered' text 
  Then I'm successfully logged in
