
@logout
Feature: Running a test
  As an IOS developer
  I want to have a sample feature file
  So I can begin testing logout process

@logout_scenario_1
Scenario: Start testing logout process
  Then I'm preparing to log out
  And I touch 'Run assistant' button
  Then I see an alert
  Then I see the "Warning" alert
  Then I touch 'Launch Wizard' button
  And I wait for 2 seconds
