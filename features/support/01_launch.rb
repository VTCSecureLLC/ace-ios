########################################
#                                      #
#       Important Note                 #
#                                      #
#   When running calabash-ios tests at #
#   www.xamarin.com/test-cloud         #
#   the  methods invoked by            #
#   CalabashLauncher are overridden.   #
#   It will automatically ensure       #
#   running on device, installing apps #
#   etc.                               #
#                                      #
########################################

require 'calabash-cucumber/launcher'

APP_BUNDLE_PATH = "/Users/leo/Library/Developer/Xcode/DerivedData/linphone-hdoekljewhilimduhgugkjrkjryc/Build/Products/Debug-iphonesimulator/linphone.app"

#APP_BUNDLE_PATH=`echo ~/Library/Developer/Xcode/DerivedData/$(ls -1t ~/Library/Developer/Xcode/DerivedData/ | grep linphone | head -1)/Build/Products/Debug-iphonesimulator/linphone.app`.strip

#puts "APP_BUNDLE_PATH=#{APP_BUNDLE_PATH}"

# You may uncomment the above to overwrite the APP_BUNDLE_PATH
# However the recommended approach is to let Calabash find the app itself
# or set the environment variable APP_BUNDLE_PATH


Before do |scenario|
  @calabash_launcher = Calabash::Cucumber::Launcher.new
  unless @calabash_launcher.calabash_no_launch?
    @calabash_launcher.relaunch
    @calabash_launcher.calabash_notify(self)
  end
end

After do |scenario|
  unless @calabash_launcher.calabash_no_stop?
    calabash_exit
    if @calabash_launcher.active?
      @calabash_launcher.stop
    end
  end
end

at_exit do
  launcher = Calabash::Cucumber::Launcher.new
  if launcher.simulator_target?
    launcher.simulator_launcher.stop unless launcher.calabash_no_stop?
  end
end
