
@dial_pad
Feature: Running a test
  As an IOS developer
  I want to have a sample feature file
  So I can begin testing on dialpad screen

@dial_pad_scenario_1
Scenario: 1. Check if opens keyboard and allows to enter letters 
  Given I am on Dial pad screen
  When I touch 'Enter an address' field
  Then I can enter letters
  And I wait for 2 seconds

@dial_pad_scenario_2
Scenario: 2. Check all buttons enter text into the number input field
  Given I am on Dial pad screen
  Then I can start enter numbers from Numpad
  When I long press the 0 number for '1' second
  Then I should see '+' in number input field

@dial_pad_scenario_3
Scenario: 3. Check if removes one character from the input end
  Given I am on Dial pad screen
  When I enter text into the number input field
  Then I touch backspace button
  And I compare initial and last texts
