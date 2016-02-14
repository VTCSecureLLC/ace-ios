
When /^I'm in Keypad screen$/ do
  	switch_to_keypad_screen
end

Then /^I clear the history$/ do
	clean_history
end

Then /^I touch 'Edit' button$/ do
 	touch("button marked:'Edit'") 
end

Then /^I touch 'Delete all' button$/ do
 	touch("button marked:'Delete all'") 
end

Then /^I go to Keypad screen$/ do
  	switch_to_keypad_screen
end

Then /^I moved to keypad screen$/ do
  	switch_to_keypad_screen
end

Then /^I enter number in number input field$/ do
  	enter_invalid_user_number
end

Then /^I call with this number$/ do
	call_with_the_number
end

Then /^I see an alertView$/ do
	wait_for_alert
end

Then /^I see the "(.*?)" alertView$/ do |arg1|
 	wait_for_alert_with_title(arg1) 
end

Then /^I touch 'Cancel' button$/ do
  	tap_alert_button('Cancel')
end

Then /^I switched History screen$/ do
	switch_to_history_screen
end

Then /^I fix history initial rows count$/ do
	INITIAL_HISTORY_ROWS_COUNT = query("tableView",numberOfRowsInSection:0)
end

Then /^I repeat the steps$/ do
  	repeat_steps
end

Then /^I fix history current rows count$/ do
	HISTORY_CURRENT_ROWS_COUNT = query("tableView",numberOfRowsInSection:0)
end

Then /^I check the history rows count differences$/ do
	calculate_difference_initial_current_rows_count
end

def switch_to_keypad_screen
	touch("UIButtonLabel marked:'Keypad'")
end

def enter_invalid_user_number
        touch ("UIDigitButton marked:'Star'")
        touch ("UIDigitButton marked:'Star'")
	touch ("button marked:'9'")
        touch ("UIDigitButton marked:'Star'")
end

def call_with_the_number
	touch("UICallButton marked:'Call'")
end

def switch_to_history_screen
	touch("UIButtonLabel marked:'History'")
end

def calculate_difference_initial_current_rows_count
	expect(HISTORY_CURRENT_ROWS_COUNT[0]).to be > INITIAL_HISTORY_ROWS_COUNT[0]
end

def repeat_steps
	switch_to_keypad_screen
	enter_invalid_user_number
	call_with_the_number
	wait_for_alert
 	wait_for_alert_with_title('Call failed') 
  	tap_alert_button('Cancel')
	switch_to_history_screen
end

def clean_history 
	enter_invalid_user_number
	call_with_the_number
	wait_for_alert
 	wait_for_alert_with_title('Call failed') 
  	tap_alert_button('Cancel')
	switch_to_history_screen
end

def alert_exists?(alert_title=nil)
  if alert_title.nil?
    res = uia('uia.alert() != null')
  else
    if ios6?
      res = uia("uia.alert().staticTexts()['#{alert_title}'].label()")
    else
      res = uia("uia.alert().name() == '#{alert_title}'")
    end
  end

  if res['status'] == 'success'
    res['value']
  else
    false
  end
end

def alert_button_exists?(button_title)
  unless alert_exists?
    fail('Expected an alert to be showing')
  end

  res = uia("uia.alert().buttons()['#{button_title}']")
  if res['status'] == 'success'
    res['value']
  else
    false
  end
end

def wait_for_alert
  timeout = 4
  message = "Waited #{timeout} seconds for an alert to appear"
  options = {timeout: timeout, timeout_message: message}

  wait_for(options) do
    alert_exists?
  end
end

def wait_for_alert_with_title(alert_title)
  timeout = 4
  message = "Waited #{timeout} seconds for an alert with title '#{alert_title}' to appear"
  options = {timeout: timeout, timeout_message: message}

  wait_for(options) do
    alert_exists?(alert_title)
  end
end

def tap_alert_button(button_title)
   wait_for_alert

  res = uia("uia.alert().buttons()['#{button_title}'].tap()")
  if res['status'] != 'success'
    fail("UIA responded with:\n'#{res['value']}' when I tried to tap alert button '#{button_title}'")
  end
end

def alert_view_query_str
  if ios8? || ios9?
    "view:'_UIAlertControllerView'"
  elsif ios7?
    "view:'_UIModalItemAlertContentView'"
  else
    'UIAlertView'
  end
end

def button_views
  wait_for_alert

  if ios8? || ios9?
    query = "view:'_UIAlertControllerActionView'"
  elsif ios7?
    query = "view:'_UIModalItemAlertContentView' descendant UITableView descendant label"
  else
    query = 'UIAlertView descendant button'
  end
  query(query)
end

def button_titles
  button_views.map { |res| res['label'] }.compact
end

def leftmost_button_title
  with_min_x = button_views.min_by do |res|
    res['rect']['x']
  end
  with_min_x['label']
end

def rightmost_button_title
  with_max_x = button_views.max_by do |res|
    res['rect']['x']
  end
  with_max_x['label']
end

def all_labels
  wait_for_alert
  query = "#{alert_view_query_str} descendant label"
  query(query)
end

def non_button_views
  button_titles = button_titles()
  all_labels = all_labels()
  all_labels.select do |res|
    !button_titles.include?(res['label']) &&
	  res['label'] != nil
  end
end

def alert_message
  with_max_y = non_button_views.max_by do |res|
    res['rect']['y']
  end

  with_max_y['label']
end

def alert_title
  with_min_y = non_button_views.min_by do |res|
    res['rect']['y']
  end
  with_min_y['label']
end
