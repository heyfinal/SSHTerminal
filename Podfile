# Uncomment the next line to define a global platform for your project
platform :ios, '17.0'

target 'SSHTerminal' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # SSH Library
  pod 'NMSSH', '~> 2.3'
  
  # Keychain wrapper (optional, using native Security framework instead)
  # pod 'KeychainAccess', '~> 4.2'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end
